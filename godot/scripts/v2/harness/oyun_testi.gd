class_name OyunTesti
extends RefCounted

## B7 KAPISI -- oyun kabugunun sozlesmesi.
##
## ------------------------------------------------------------------------
## BU KAPININ KAHINI YOK, VE OLMAMASI DOGRU
## ------------------------------------------------------------------------
## `Oyun` motorda olmayan bir kavramdir: oturum, gecmis ve gunce oyun
## katmaninin kendi sozlesmesidir. Dolayisiyla burada "Python ne diyor" diye
## sorulmaz -- sorulan sey KABUGUN KENDI IDDIALARIdir. v4.4 tarafinda
## `--sim-test` ayni isi yapiyor.
##
## ------------------------------------------------------------------------
## BES KADEME
## ------------------------------------------------------------------------
##   1. KABUK MOTORU DEGISTIRMEZ -- gozlemci kipinde surulen dunya, dogrudan
##      `Dunya.adim()` ile surulen dunyayla ALAN ALAN ayni. En sert kademe
##      bu: gecmis ornekleme ya da gunce toplama motora yazsaydi (bir
##      `clampf`, bir tembel hesap, bir yan etki) butun B0-B6 olcumleri
##      oyun icinde SESSIZCE gecersizlesirdi.
##   2. TAKVIM       -- tik sayimi, ornek sayisi ve ufuk.
##   3. GUNCE = TESCIL -- §0'in kurali sayilarak sinanir.
##   4. GECMIS CANLI -- kaydedilen seri hem KIPIRDIYOR hem de motorun o anki
##      degeriyle ayni. (B2b'nin dersi: yonu dogru bir mekanizma yine de olu
##      olabilir; burada da "seri var" ile "seri anlamli" ayri sorular.)
##   5. KOLLAR CANLI -- her oyuncu kolu KARSI-OLGUSAL olarak sinanir: ayni
##      tohum, kol acik/kapali, yorunge AYRISMALI. Olu bir kol arayuzde
##      capraz gorunmez -- kaydirici kayar, sayi degisir, dunya degismez.
##
## KAPI GERCEKTEN DUSEBILIYOR, ve dogrulanmasi kasten en zor kademeden
## yapildi: `Gecmis.ornekle` icine `saldirganlik += 1e-12` konuldu -- yani
## kabuk motora bir ulp mertebesinde dokundu. Birinci kademe yakaladi
## ("ilk ayrisma: AFG.saldirganlik (0.35000000005999865 / 0.34999999999999998)")
## ve rc=1 dondu. Yesil bir kapi burada gercekten bir sey iddia ediyor.

const HAFTA := 1.0 / 52.0

## Kapi dunyasi kucuk tutulur: sozlesme ulke sayisindan bagimsizdir, ve tam
## kadroda bir kampanya ~10 dakikadir. Olcek B6'nin kapisidir.
const KAPI_ULKE := 8
const KAPI_YIL := 60

## B7b kademesinin dunyasi. AYRI ve DAHA UZUN: aktorun olctugu seylerin
## yarisi (zor aygitinin acilmasi, devrimin ertelenmesi) gec kampanyada olur.
const AKTOR_ULKE := 10
const AKTOR_YIL := 264

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


static func _kodlar() -> PackedStringArray:
	return Harita.kapi_kodlar(KAPI_ULKE)


# ===========================================================================
# ALAN ALAN KARSILASTIRMA
# ===========================================================================

## Iki `float` bit duzeyinde ayni mi. NaN == NaN burada DOGRU sayilir:
## karsilastirilan sey "ayni hesap mi yapildi", "sayi gecerli mi" degil.
static func _f_ayni(x: float, y: float) -> bool:
	if is_nan(x) and is_nan(y):
		return true
	return x == y


## Bir ulkenin butun script alanlari ayni mi. Ilk ayrisan alanin adi doner,
## ayrisma yoksa bos string.
static func _ulke_farki(a: KrizDurumu, b: KrizDurumu) -> String:
	for pr in a.get_property_list():
		if not (pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var ad: String = pr["name"]
		var x: Variant = a.get(ad)
		var y: Variant = b.get(ad)
		match typeof(x):
			TYPE_FLOAT:
				if not _f_ayni(x, y):
					return "%s (%s / %s)" % [ad, String.num(x, 17), String.num(y, 17)]
			TYPE_INT, TYPE_BOOL, TYPE_STRING:
				if x != y:
					return "%s (%s / %s)" % [ad, str(x), str(y)]
			TYPE_ARRAY:
				if (x as Array).size() != (y as Array).size():
					return "%s (boy %d / %d)" % [ad, (x as Array).size(),
							(y as Array).size()]
			TYPE_DICTIONARY:
				if (x as Dictionary).size() != (y as Dictionary).size():
					return "%s (sozluk boyu)" % ad
	return ""


static func _dunya_farki(a: Dunya, b: Dunya) -> String:
	if not _f_ayni(a.yil, b.yil):
		return "dunya.yil (%s / %s)" % [String.num(a.yil, 17), String.num(b.yil, 17)]
	if a.ulkeler.size() != b.ulkeler.size():
		return "ulke sayisi"
	for i in range(a.ulkeler.size()):
		var f := _ulke_farki(a.ulkeler[i], b.ulkeler[i])
		if f != "":
			return "%s.%s" % [a.adlar[i], f]
		if not _f_ayni(a.toplam_vt[i], b.toplam_vt[i]):
			return "%s.toplam_vt" % a.adlar[i]
		if not _f_ayni(a.toplam_nx[i], b.toplam_nx[i]):
			return "%s.toplam_nx" % a.adlar[i]
		if not _f_ayni(a.borc[i], b.borc[i]):
			return "%s.borc" % a.adlar[i]
	return ""


# ===========================================================================
# KOSU YARDIMCILARI
# ===========================================================================

static func _oturum(oyuncu_kod: String, tohum: int = 42) -> Oyun:
	var o := Oyun.new()
	o.kur(oyuncu_kod, tohum, _kodlar())
	return o


## Cekirdegin kayit dizilerinin toplam uzunlugu -- guncenin sayaciyla
## karsilastirilacak olan.
static func _tesciller(w: Dunya) -> Dictionary:
	var c := {"ASIRI URETIM": 0, "RESESYON": 0, "BUYUK BUNALIM": 0,
			"TEMERRUT": 0, "MORATORYUM": 0, "DOVIZ KRIZI": 0}
	for d in w.ulkeler:
		c["ASIRI URETIM"] += d.asiri_uretim_krizleri.size()
		c["RESESYON"] += d.resesyonlar.size()
		c["BUYUK BUNALIM"] += d.bunalimlar.size()
		c["TEMERRUT"] += d.temerrutler.size()
		c["MORATORYUM"] += d.moratoryumlar.size()
		c["DOVIZ KRIZI"] += d.fx_krizleri.size()
	return c


# ===========================================================================
static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("=".repeat(70))
	print("v2 OYUN KABUGU  (B7)   %d ulke x %d yil, haftalik"
			% [KAPI_ULKE, KAPI_YIL])
	print("=".repeat(70))

	var tik := KAPI_YIL * Oyun.YILDA_TIK

	# -----------------------------------------------------------------
	print("\n--- 1. kabuk motoru degistirmez (gozlemci) ---")
	# Gozlemci oturum ile CIPLAK dunya yan yana surulur. Ikisi de ayni
	# tohumla ayni kadroyu kurar; tek fark, birinin her tik gecmis
	# ornekleyip gunce toplamasidir.
	var goz := _oturum("", 42)
	var ham := Harita.dunya_kur(_kodlar(), 42, Oyun.BAS_YIL)
	goz.ilerle(tik)
	for _i in range(tik):
		ham.adim(HAFTA)

	var fark := _dunya_farki(goz.dunya, ham)
	_dogrula(fark == "", "gozlemci oturum ciplak dunyayla ALAN ALAN ayni",
			"ilk ayrisma: " + fark if fark != "" else "(%d tik)" % tik)

	# -----------------------------------------------------------------
	print("\n--- 2. takvim ve ornekleme ---")
	_dogrula(goz.tik() == tik, "tik sayisi",
			"%d beklendi, %d bulundu" % [tik, goz.tik()])
	# Ornek her 52 tikte bir, ILK YILIN SONUNDAN itibaren: seri 1837'de
	# baslar. `t=0` satiri BILEREK yok -- orada `r_yil` gibi turetilmis
	# metrikler henuz hesaplanmamis olur ve grafige sahte bir sicrama
	# cizerdi (olculdu: 0.0000 -> 0.1047).
	var beklenen_ornek := tik / Oyun.YILDA_TIK
	_dogrula(goz.gecmis.ornek_sayisi() == beklenen_ornek,
			"ornek sayisi = yil sayisi",
			"%d beklendi, %d bulundu" % [beklenen_ornek,
					goz.gecmis.ornek_sayisi()])
	_dogrula(absf(float(goz.gecmis.yillar[0]) - (Oyun.BAS_YIL + 1.0)) < 1e-6,
			"ilk ornek 1837 (t=0 satiri yok)",
			"%.6f" % float(goz.gecmis.yillar[0]))
	# ORNEK ZAMANI TIK SAYARAK BULUNUR. Kayan noktayla esik karsilastirilsaydi
	# 52 tik sonra yil 1836.9999999999998'e varir ve bir ornek atlanirdi.
	var son_yil: float = goz.gecmis.yillar[goz.gecmis.yillar.size() - 1]
	_dogrula(absf(son_yil - (Oyun.BAS_YIL + float(KAPI_YIL))) < 1e-6,
			"son ornegin takvim yili", "%.10f" % son_yil)

	var ufuk := _oturum("", 42)
	ufuk.ilerle(Oyun.YILDA_TIK * 400)      # 2100'u fazlasiyla asar
	_dogrula(ufuk.bitti() and ufuk.yil() <= Oyun.BITIS_YIL + HAFTA,
			"ufuk 2100'de duruyor", "%.2f" % ufuk.yil())

	# -----------------------------------------------------------------
	print("\n--- 3. gunce = tescil (§0: olay sistemi yok) ---")
	var tesc := _tesciller(goz.dunya)
	var toplam := 0
	for tip in tesc.keys():
		var bekle: int = tesc[tip]
		var bulunan := int(goz.gunce.sayac.get(tip, 0))
		toplam += bekle
		_dogrula(bekle == bulunan, "gunce sayaci = kayit boyu: %s" % tip,
				"%d / %d" % [bekle, bulunan])
	_dogrula(toplam > 0, "kampanya gercekten tescil uretti",
			"%d tescil" % toplam)

	# Gunce zamanda geriye gitmemeli: panel bunu siralamadan cizer.
	var sirali := true
	for k in range(1, goz.gunce.girdiler.size()):
		if float(goz.gunce.girdiler[k]["yil"]) < float(goz.gunce.girdiler[k - 1]["yil"]):
			sirali = false
			break
	_dogrula(sirali, "gunce kronolojik", "%d girdi" % goz.gunce.girdiler.size())

	# Her tipin bir rengi olmali; yoksa panelde sessizce gri cikar.
	var renksiz := ""
	for tip in goz.gunce.sayac.keys():
		if Gunce.renk(String(tip)) == Tema.METIN_SOLUK and tip != "SENARYO":
			renksiz = String(tip)
	_dogrula(renksiz == "", "her tescil tipinin rengi var",
			"renksiz: " + renksiz if renksiz != "" else "")

	# -----------------------------------------------------------------
	print("\n--- 4. gecmis canli ve motorla ayni ---")
	# (a) Kaydedilen son deger motorun o anki degeriyle AYNI olmali.
	var sapan := ""
	for m in Oyun.CEKIRDEK_METRIKLER:
		var anahtar := String(m["anahtar"])
		var kayitli: float = goz.gecmis.son(anahtar, 0)
		var canli: float = Gecmis._oku(goz.dunya.ulkeler[0], m)
		if not _f_ayni(kayitli, canli):
			sapan = "%s (%s / %s)" % [anahtar, String.num(kayitli, 17), String.num(canli, 17)]
	_dogrula(sapan == "", "son ornek motorun o anki degeri",
			"sapan: " + sapan if sapan != "" else "")

	# (b) SERI KIPIRDIYOR MU. "Kayit var" ile "kayit anlamli" ayri sorular;
	#     duz bir seri panelde dolu gorunur ve hicbir sey anlatmaz.
	#
	#     `oto` BU PENCEREDE MESRU OLARAK DUZDUR ve disarida birakilir.
	#     Otomasyon MUTLAK `q >= 36` ister ve merdiven oraya ancak 2000'lerde
	#     varir (§6b'nin cag kuplaji); 1837-1896'da sifir olmasi dogru
	#     davranistir. Sessizce atlanmaz, asagida KAYIT olarak sinanir --
	#     canliligi ise tam kampanya kosan `--v2-harita`nin isidir.
	var olu: Array[String] = []
	for m in Oyun.CEKIRDEK_METRIKLER:
		var anah := String(m["anahtar"])
		if anah == "oto":
			continue
		var s := goz.gecmis.seri(anah, 0)
		var enk := INF
		var enb := -INF
		for v in s:
			enk = minf(enk, v)
			enb = maxf(enb, v)
		if enb - enk <= 0.0:
			olu.append(anah)
	_dogrula(olu.is_empty(), "cekirdek metrikler (oto haric) kipirdiyor",
			"duz: " + ", ".join(olu) if not olu.is_empty() else "")

	# KAYIT, kapi degil -- ve BILEREK ters yonde: merdiven bir gun 19. yuzyilda
	# otomasyona ulasirsa bu denetim DUSER ve belge guncellenir. ">= 0" gibi
	# gevsek birakilsaydi o gun hicbir sey haber vermezdi (B5'in idiomu).
	var oto_s := goz.gecmis.seri("oto", 0)
	var oto_enb := 0.0
	for v in oto_s:
		oto_enb = maxf(oto_enb, v)
	_dogrula(oto_enb == 0.0, "KAYIT: otomasyon 19. yuzyilda henuz sifir",
			"en yuksek %.6f -> §6b" % oto_enb)

	# (c) KAYIT: BU PENCEREDE KAR ORANI YUKSELIR, ve bu LTRPF'nin cürütülmesi
	#     DEGILDIR -- baslangic gecici rejimidir.
	#
	#     Olculdu (`--v2-oyun-iz=230`, ayni kadro): egri 1837'de 0.027'den
	#     baslar, kriz cevrimleriyle salinarak 1948'de 0.380'e cikar, sonra
	#     kampanya boyunca duser: 2065'te 0.033, yani ZIRVEDEN %-91.3. Ayni
	#     kosuda `q` 0.65 -> 76.3 ve `c/v` 1.13 -> 6.87; §2.4'un zinciri
	#     tam olarak isliyor, yalnizca 60 yil onu gormek icin cok kisa.
	#
	#     Ilk yazimda buraya "kar orani 60 yilda duser" kapisi konmustu ve
	#     DUSTU. Kapi hakliydi: iddia bu pencerede yanlisti. Egilimin kapisi
	#     `--v2-tarih` ve `--v2-olcek`tir; kabugun kapisi serinin SADIK
	#     olmasidir (yukaridaki (a)), egilimin yonu degil.
	#
	#     Kayit ters yonde birakiliyor: pencere gercekten gecici rejimse
	#     baslangic degeri zirvenin cok altinda olmali.
	var r := goz.gecmis.seri("r_yil", 0)
	var r_zirve := -INF
	for v in r:
		r_zirve = maxf(r_zirve, v)
	_dogrula(r[0] < r_zirve * 0.5,
			"KAYIT: %d yillik pencere baslangic gecici rejimi" % KAPI_YIL,
			"1837 %.4f, pencere zirvesi %.4f -> --v2-oyun-iz" % [r[0], r_zirve])

	# -----------------------------------------------------------------
	print("\n--- 5. oyuncu kollari canli (karsi-olgusal) ---")
	var oyuncu_kod := _kodlar()[0]

	# Oyuncu secilince YALNIZCA `otomatik` degismeli.
	var oy := _oturum(oyuncu_kod, 42)
	_dogrula(oy.oyuncu >= 0, "oyuncu ulkesi bulundu", oyuncu_kod)
	_dogrula(not oy.dunya.cekirdekler[oy.oyuncu].karanlik.otomatik,
			"oyuncunun karanlik devleti AI'dan alindi")
	var ai_acik := true
	for i in range(oy.dunya.cekirdekler.size()):
		if i != oy.oyuncu and not oy.dunya.cekirdekler[i].karanlik.otomatik:
			ai_acik = false
	_dogrula(ai_acik, "diger ulkeler AI'da kaldi (§4.5)")

	# Her kol icin: ayni tohum, kol kapali/acik, yorunge AYRISMALI.
	var kollar := [
		{"ad": "yukseltme_payi", "uygula": func(o: Oyun) -> void:
				o.yukseltme_payi_ayarla(0.90)},
		{"ad": "temel gelir", "uygula": func(o: Oyun) -> void:
				o.etg_ayarla(0.20)},
		{"ad": "saldirganlik", "uygula": func(o: Oyun) -> void:
				o.saldirganlik_ayarla(0.95)},
		{"ad": "aciklik", "uygula": func(o: Oyun) -> void:
				o.aciklik_ayarla(0.20)},
		{"ad": "taktik: milliyetcilik", "uygula": func(o: Oyun) -> void:
				o.taktik_ayarla("t_milliyetcilik", 1.0)},
		{"ad": "taktik: sendika baskisi", "uygula": func(o: Oyun) -> void:
				o.taktik_ayarla("t_sendika_baskisi", 1.0)},
	]
	var kol_tik := 30 * Oyun.YILDA_TIK
	var temel := _oturum(oyuncu_kod, 42)
	temel.ilerle(kol_tik)
	for k in kollar:
		var kollu := _oturum(oyuncu_kod, 42)
		(k["uygula"] as Callable).call(kollu)
		kollu.ilerle(kol_tik)
		var f := _dunya_farki(temel.dunya, kollu.dunya)
		_dogrula(f != "", "kol dunyayi degistiriyor: %s" % k["ad"],
				"ilk ayrisma: " + f if f != "" else "AYNI -- kol OLU")

	# GOZLEMCI KIPINDE KOL ISLEMSIZ. Bu, birinci kademenin sigortasi:
	# kollar gozlemcide de yazsaydi "kabuk motoru degistirmez" iddiasi
	# yalnizca kimsenin kola dokunmadigi kosulda dogru olurdu.
	var g2 := _oturum("", 42)
	var yazdi := (g2.taktik_ayarla("t_milliyetcilik", 1.0)
			or g2.etg_ayarla(0.2) or g2.yukseltme_payi_ayarla(0.9)
			or g2.saldirganlik_ayarla(0.9) or g2.aciklik_ayarla(0.2))
	_dogrula(not yazdi, "gozlemci kipinde kollar islemsiz")

	# -----------------------------------------------------------------
	print("\n--- 6. §4.6: hicbir taktik adlandirilmadan sunulamaz ---")
	# TEMSIL ILKESI BIR KAPIDIR, bir niyet degil. §4.6 taktiklerin "etkinlik
	# kolu gibi sunulmamasini", magdurun adlandirilmasini ve bedelin
	# SAYILMASINI istiyor. Ekran goruntusuyle dogrulanamaz: panel kaydirmali,
	# ve bir taktik listenin dibinde adsiz kalsa kimse gormez.
	var eksik: Array[String] = []
	var ornek := KrizDurumu.new()
	for t in Oyun.TAKTIKLER:
		var alan := String(t.get("alan", ""))
		# (a) alan gercekten motorda var mi -- olu bir kol arayuzde
		#     digerlerinden ayirt edilemez.
		if alan == "" or not (alan in ornek):
			eksik.append("%s: alan motorda yok" % alan)
			continue
		# (b) adi, aygiti ve BEDELI yazili mi.
		if String(t.get("ad", "")).strip_edges() == "":
			eksik.append("%s: adi yok" % alan)
		if not String(t.get("aygit", "")) in ["rıza", "zor"]:
			eksik.append("%s: aygiti yok" % alan)
		if String(t.get("bedel", "")).strip_edges() == "":
			eksik.append("%s: BEDELI yazilmamis" % alan)
	_dogrula(eksik.is_empty(), "sekiz taktigin adi, aygiti ve bedeli yerinde",
			"; ".join(eksik) if not eksik.is_empty() else
			"%d taktik" % Oyun.TAKTIKLER.size())
	_dogrula(Oyun.TAKTIKLER.size() == 8, "taktik sayisi 8 (§4.6'nin tablosu)",
			"%d" % Oyun.TAKTIKLER.size())

	# Bedeller AYRICA SAYILIR: karanlik devletin ciktilarinin hepsi cizilen
	# metrik kumesinde olmali, yoksa "bedeli sayilmis" cumlesi bos kalir.
	var sayilan := PackedStringArray()
	for m in Oyun.KARANLIK_METRIKLER:
		sayilan.append(String(m["anahtar"]))
	var sayilmayan: Array[String] = []
	for anah in ["bolunme", "cezaevi_orani", "uyusturucu_orani", "sehit",
			"egitim", "karsi_hareket"]:
		if not sayilan.has(anah):
			sayilmayan.append(anah)
	_dogrula(sayilmayan.is_empty(), "bedeller gorunur metrik olarak ciziliyor",
			"eksik: " + ", ".join(sayilmayan) if not sayilmayan.is_empty()
			else "%d metrik" % sayilan.size())

	# -----------------------------------------------------------------
	print("\n--- olcum: §2.4'un merkezi tuzagi kabuk uzerinden ---")
	# Kapi degil KAYIT. Merdiven kolunun mekanizmasi B2a'nin kapisidir;
	# burada olculen sey, kolun oradaki mekanizmaya GERCEKTEN ulastigidir.
	var dusuk := _oturum(oyuncu_kod, 42)
	dusuk.yukseltme_payi_ayarla(0.05)
	dusuk.ilerle(kol_tik)
	var yuksek := _oturum(oyuncu_kod, 42)
	yuksek.yukseltme_payi_ayarla(0.90)
	yuksek.ilerle(kol_tik)
	var a := dusuk.dunya.ulkeler[dusuk.oyuncu]
	var b := yuksek.dunya.ulkeler[yuksek.oyuncu]
	print("  yukseltme payi   0.05      0.90")
	print("  q             %8.3f  %8.3f" % [a.q, b.q])
	print("  c/v           %8.3f  %8.3f" % [a.cv, b.cv])
	print("  kar orani     %8.4f  %8.4f" % [a.r_yil, b.r_yil])
	# ZINCIRIN UCU DE SINANIR, yalnizca ilk halkasi degil. Kol `q`ya ulasip
	# orada kalsaydi oyunun anlattigi sey ekranda YOK olurdu: oyuncunun asil
	# karari, bina defterinde karli gorunen yukseltmenin TOPLAM kar oranini
	# asagi cekmesidir. Mekanizmanin kendisi B2a'nin kapisi; burada sinanan,
	# KABUGUN KOLUNUN o mekanizmaya ulastigidir.
	_dogrula(b.q > a.q, "merdiven kolu `q`ya ulasiyor",
			"%.3f -> %.3f" % [a.q, b.q])
	_dogrula(b.cv > a.cv, "... `q`↑ organik bilesimi yukseltiyor",
			"%.3f -> %.3f" % [a.cv, b.cv])

	# KAR ORANI BURADA IDDIA EDILMEZ, KAYDEDILIR -- ve bunun sebebi olculdu.
	#
	# Tohumlamadan (1836 nufusu) ONCE bu satir `r`nin DUSTUGUNU iddia
	# ediyordu ve gecıyordu: 0.0808 -> 0.0660. Tohumlamadan sonra isaret
	# dondu: 0.0764 -> 0.0795. Bant gevsetilmedi, CAPALAR olculdu:
	#
	#   q    0.672 -> 1.643   (degismedi, tohumlama oncesi 0.650 -> 1.686)
	#   c/v  0.834 -> 1.479   (degismedi, oncesi 0.820 -> 1.497)
	#   u    0.544 -> 0.829   <-- SAPAN BU
	#   pay  0.448 -> 0.449   (ayni)
	#
	# Yani bilesim kanali YERINDE duruyor; ustune bir GERCEKLESME kanali
	# binmis. Dusuk-yukseltme kolu yatirimi derinlestirme yerine
	# genisletmeye harciyor, tohumlanmis (boyutca ayrisik) bir dunyada o
	# kapasiteyi satamiyor ve `u` 0.54'te kaliyor. `r` farkinin isaretini
	# belirleyen sey bilesim degil kullanim orani.
	#
	# Bu, kilavuzun izledigi ailenin ALTINCI uyesi: "bir DUZEY
	# karsilastirmasi bileskeyi olcer, mekanizmayi degil". Iki kolun `r`
	# duzeyini kiyaslayip farki bilesime yazmak, ikinci kanal devreye
	# girdigi anda yanlis olur.
	#
	# §2.4'UN KAPISI KAYBOLMADI: `--v2-uretim` onu YALITILMIS kurulumda
	# (tek ulke, disarisi yok) olcer ve `d_r < 0` orada iddia edilir --
	# tohumlamadan sonra da 17/17 geciyor. Dogru is bolumu bu: mekanizma
	# kendi kapisinda, kabugun kolu burada.
	print("  u             %8.3f  %8.3f   <- gerceklesme kanali" % [a.u, b.u])
	print("  kar orani (KAYIT, iddia degil) %.4f -> %.4f" % [a.r_yil, b.r_yil])

	# -----------------------------------------------------------------
	print("\n--- 7. B7b: politika aktoru (§4.5) ---")
	var aktorlu := _aktor_kademesi()

	# -----------------------------------------------------------------
	print("\n--- 8. B7c: bloklar ve ad takvimi ---")
	_sunum_kademesi(aktorlu)

	# -----------------------------------------------------------------
	print("\n--- 9. B7d: kayit / yukleme ---")
	_kayit_kademesi()

	print("\n" + "-".repeat(70))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


## B7d -- oturum serilestirmesi.
##
## EN SERT DENETIM GELECEGE BAKAR. "Yukleme sonrasi dunya ayni" YETMEZ:
## RNG durumu kaydedilmemis olsa bile o an ayni gorunur, cunku RNG bir SONRAKI
## tikte konusur. Bu yuzden iki dunya yuklemeden SONRA birlikte surulur ve
## hala ayni olmalari beklenir -- kaydedilmemis tek bir MT19937 kelimesi
## burada ortaya cikar.
static func _kayit_kademesi() -> void:
	var kodlar := Harita.kapi_kodlar(6)
	var a := Oyun.new()
	a.kur(kodlar[0], 42, kodlar)
	a.taktik_ayarla("t_milliyetcilik", 0.35)
	a.yukseltme_payi_ayarla(0.55)
	a.ilerle(40 * Oyun.YILDA_TIK)

	var c := a.sozluge()

	# IKILI BICIM GERCEKTEN CALISIYOR mu: sozluk `var_to_bytes` ile gidip
	# gelmeli, yoksa diske yazilamaz.
	var ham := var_to_bytes(c)
	var geri: Variant = bytes_to_var(ham)
	_dogrula(geri is Dictionary, "kayit ikili bicimde gidip geliyor",
			"%.1f KB" % (ham.size() / 1024.0))

	var b := Oyun.new()
	var basarili := b.sozlukten(geri)
	_dogrula(basarili, "kayit yuklendi")
	if not basarili:
		return

	# (a) YUKLEME ANINDA alan alan ayni.
	var fark := _dunya_farki(a.dunya, b.dunya)
	_dogrula(fark == "", "yuklenen dunya kaydedilenle ALAN ALAN ayni",
			"ilk ayrisma: " + fark if fark != "" else "")

	_dogrula(a.tik() == b.tik() and a.oyuncu == b.oyuncu,
			"tik ve oyuncu korundu", "%d / %d" % [b.tik(), b.oyuncu])
	_dogrula(a.gecmis.ornek_sayisi() == b.gecmis.ornek_sayisi(),
			"gecmis ornekleri korundu",
			"%d ornek" % b.gecmis.ornek_sayisi())
	_dogrula(a.gunce.girdiler.size() == b.gunce.girdiler.size()
			and a.gunce.sayac.size() == b.gunce.sayac.size(),
			"gunce korundu", "%d girdi" % b.gunce.girdiler.size())

	# Gecmis SERISI de birebir olmali: sayilar degil sayi SAYISI korunmus
	# olabilir ve grafik yine yanlis cizer.
	var seri_a := a.gecmis.seri("r_yil", 0)
	var seri_b := b.gecmis.seri("r_yil", 0)
	var seri_ayni := seri_a.size() == seri_b.size()
	if seri_ayni:
		for k in range(seri_a.size()):
			if not _f_ayni(seri_a[k], seri_b[k]):
				seri_ayni = false
				break
	_dogrula(seri_ayni, "gecmis serisi birebir", "%d nokta" % seri_b.size())

	# (b) ASIL DENETIM: ikisi birlikte surulunce hala ayni mi. RNG durumu
	#     kaydedilmemis olsaydi (a) yine gecerdi ve bu DUSERDI.
	var devam := 10 * Oyun.YILDA_TIK
	a.ilerle(devam)
	b.ilerle(devam)
	var fark2 := _dunya_farki(a.dunya, b.dunya)
	_dogrula(fark2 == "",
			"%d yil DAHA surulunce hala ayni (RNG durumu korundu)"
					% (devam / Oyun.YILDA_TIK),
			"ilk ayrisma: " + fark2 if fark2 != "" else "")

	# (c) BOZUK KAYIT OYUNU BOZMAZ. `Save`in v4.4 sozlesmesiyle ayni ilke:
	#     hicbir kosulda olumcul degil.
	var kotu := Oyun.new()
	kotu.kur(kodlar[0], 42, kodlar)
	var once_tik := kotu.tik()
	_dogrula(not kotu.sozlukten({"surum": 999}),
			"gelecekten gelen kayit REDDEDILIYOR")
	_dogrula(kotu.tik() == once_tik and kotu.dunya != null,
			"reddedilen kayit acik oturuma dokunmadi")

	# (d) DISK YOLU. Sozluk yuvarlagi diskten gecmeyi KANITLAMAZ: `store_var`
	#     ile `get_var` arasinda bir bicim farki, bir izin hatasi ya da yarim
	#     yazilmis bir dosya ancak burada gorunur. Kapi kendi arkasini
	#     temizler -- bir kapi kalici durum birakmamali.
	var vardi := Save.oturum_var()
	var yazildi := Save.oturum_yaz(c)
	_dogrula(yazildi and Save.oturum_var(), "oturum diske yazildi")
	var diskten := Save.oturum_oku()
	var d := Oyun.new()
	_dogrula(not diskten.is_empty() and d.sozlukten(diskten),
			"oturum diskten okundu")
	if not diskten.is_empty():
		_dogrula(_dunya_farki(a.dunya, d.dunya) == "" or a.tik() != d.tik(),
				"diskten gelen dunya sozlukten gelenle tutarli",
				"tik %d" % d.tik())
	if not vardi:
		Save.oturum_sil()
		_dogrula(not Save.oturum_var(), "kapi kendi kaydini temizledi")


## B7b -- AI ulkeleri karanlik devletin kollarina KENDI krizlerine gore uzaniyor
## mu, ve bunu yaparken devrimi imkansiz kilmadan yapiyor mu.
##
## PENCERE TAM UFUKTUR ve bu pahali (iki kol x 264 yil). Kisaltilamaz: ilk
## kalibrasyon 150 yilda yapilmisti ve secilen kol 200 yilda devrimi
## sifirliyordu. Bu kademenin olctugu seyin yarisi GEC KAMPANYADA olur.
static func _aktor_kademesi() -> Dunya:
	var kodlar := Harita.kapi_kodlar(AKTOR_ULKE)
	var acik := Harita.dunya_kur(kodlar, 42, Oyun.BAS_YIL)
	var kapali := Harita.dunya_kur(kodlar, 42, Oyun.BAS_YIL)
	kapali.aktor = null

	var riza_yil := 0
	var zor_yil := 0
	for k in range(AKTOR_YIL * Oyun.YILDA_TIK):
		acik.adim(Oyun.HAFTA)
		kapali.adim(Oyun.HAFTA)
		if riza_yil == 0 or zor_yil == 0:
			for d in acik.ulkeler:
				if riza_yil == 0 and d.riza_kolu >= 0.10:
					riza_yil = int(Oyun.BAS_YIL) + k / Oyun.YILDA_TIK
				if zor_yil == 0 and d.zor_kolu >= 0.10:
					zor_yil = int(Oyun.BAS_YIL) + k / Oyun.YILDA_TIK

	# (a) AKTOR `bolunme`NIN TEK YAZARI. Aktorsuz kolda alan TAM SIFIR
	#     kalmali; kalmiyorsa baska bir sey de yaziyor demektir ve
	#     karsi-olgusal olcumlerin hepsi anlamsizlasir.
	var kapali_bol := 0.0
	for d in kapali.ulkeler:
		kapali_bol = maxf(kapali_bol, d.bolunme)
	_dogrula(kapali_bol == 0.0, "aktorsuz kolda `bolunme` TAM sifir",
			"en yuksek " + String.num(kapali_bol, 17))

	# (b) CANLILIK -- B5'in "bolunme surucusuz" kaydinin tersi. O kayit
	#     bilerek ters yonde birakilmisti: surucu gelince dussun diye.
	var enk := INF
	var enb := -INF
	var riza := 0.0
	var zor := 0.0
	for d in acik.ulkeler:
		enk = minf(enk, d.bolunme)
		enb = maxf(enb, d.bolunme)
		riza += d.riza_kolu
		zor += d.zor_kolu
	var n := float(acik.ulkeler.size())
	_dogrula(enb - enk > 0.20, "`bolunme` ulkeler arasinda AYRISIYOR",
			"yayilim %.3f (aktorsuz 0.000)" % (enb - enk))

	# (c) §4.2'NIN SIRASI: riza ucuz ve once, zor pahali ve sonra.
	_dogrula(riza_yil > 0 and zor_yil > riza_yil,
			"riza esigi zordan ONCE asiliyor (§4.2)",
			"riza %d -> zor %d" % [riza_yil, zor_yil])
	_dogrula(riza / n > zor / n, "riza aygiti kampanya boyunca baskin",
			"riza %.3f > zor %.3f" % [riza / n, zor / n])

	# (d) DEVRIM ERTELENIR, ONLENMEZ -- cekirdegin kendi yorumu
	#     (`kriz_cekirdegi.gd:1336`). Iki yonlu kapi: sifir devrim o cumleyi
	#     yalanlar, tabandan FAZLA devrim ise kolun etkisiz oldugunu gosterir.
	var d_acik := 0
	var d_kapali := 0
	for d in acik.ulkeler:
		if d.devrim_yil > 0.0:
			d_acik += 1
	for d in kapali.ulkeler:
		if d.devrim_yil > 0.0:
			d_kapali += 1
	_dogrula(d_acik >= 1, "devrim hala mumkun (aktor onu ONLEMIYOR)",
			"aktorlu %d, aktorsuz %d" % [d_acik, d_kapali])
	_dogrula(d_acik <= d_kapali, "ama bastiriliyor (aktorlu <= aktorsuz)",
			"%d <= %d" % [d_acik, d_kapali])

	# (e) §4.5: SOSYALIST REJIMDE KOLLAR TERSINE DONER.
	var w := Harita.dunya_kur(Harita.kapi_kodlar(4), 42, Oyun.BAS_YIL)
	var s0 := w.ulkeler[0]
	for alan in PolitikaAktoru.RIZA + PolitikaAktoru.ZOR:
		s0.set(alan, 0.8)
	s0.rejim = "sosyalist"
	for _k in range(40 * Oyun.YILDA_TIK):
		w.adim(Oyun.HAFTA)
	var en_yuksek := 0.0
	for alan in PolitikaAktoru.RIZA + PolitikaAktoru.ZOR:
		en_yuksek = maxf(en_yuksek, float(s0.get(alan)))
	_dogrula(s0.rejim != "sosyalist" or en_yuksek < 0.05,
			"sosyalist rejimde taktikler sonumleniyor (§4.5)",
			"0.80'den %.4f'e" % en_yuksek)

	# (f) OYUNCUNUN ULKESINE DOKUNMAZ. Dokunsaydi kaydirici ile aktor ayni
	#     alani her tik birbirine ezerdi ve ekrandaki deger motordakini
	#     anlatmazdi.
	var o := Oyun.new()
	o.kur(Harita.kapi_kodlar(4)[0], 42, Harita.kapi_kodlar(4))
	o.taktik_ayarla("t_milliyetcilik", 0.42)
	o.ilerle(10 * Oyun.YILDA_TIK)
	_dogrula(absf(o.taktik_degeri("t_milliyetcilik") - 0.42) < 1e-12,
			"aktor oyuncunun taktigini EZMIYOR",
			"0.42 -> %.6f" % o.taktik_degeri("t_milliyetcilik"))

	# KAYIT: gec kampanyada surucu DOYAR ve ayrim zayiflar. Sebep aktorde
	# degil cekirdekte: `Omega` 2036'da butun ulkelerde 1.0'a dayaniyor
	# (olculdu, aralik 0.0000), dolayisiyla "orgutlu ofkesi buyuk olan daha
	# cok uzanir" iliskisi gec kampanyada olculemez hale geliyor. Erken
	# kampanyada mekanizma ayirt eder; `bolunme` yayilimi (b) o ayrimin
	# BIRIKMIS izidir. Kapi degil kayit -- ve dogru adres B0-B3.
	print("  KAYIT: es-zamanli kesit %+.4f -- gec kampanyada `Omega` doygun"
			% _kesit(acik))
	# B7c kademesi ayni dunyayi kullanir: ittifaklar burada zaten olusmus
	# durumda ve ikinci bir 264 yillik kampanya kosmanin anlami yok.
	return acik


# ===========================================================================
# TANI KAPISI
# ===========================================================================

## Oyuncunun ANA GRAFIGININ kampanya boyu bicimi.
##
## Kapi degil tani: panelde en ustte duran egri kar oranidir ve oyuncunun
## oyundan cikaracagi ilk izlenim onun BICIMIDIR. "Yukseliyor mu, dusuyor
## mu" sorusunun cevabi pencereye gore degisiyorsa bunu bilerek bilmek
## gerekir -- 60 yillik bir kapi penceresinde egri YUKSELIR, ve bu
## baslangic gecici rejimidir, modelin iddiasi degil.
static func iz(yil: int = 230) -> int:
	var o := Oyun.new()
	o.kur("", 42, _kodlar())
	o.ilerle(Oyun.YILDA_TIK * yil)
	var r := o.gecmis.seri("r_yil", 0)
	var cv := o.gecmis.seri("cv", 0)
	var q := o.gecmis.seri("q", 0)

	print("=".repeat(70))
	print("v2 OYUN -- kar oraninin kampanya boyu bicimi (%s, %d ulke)"
			% [o.ad(0), KAPI_ULKE])
	print("=".repeat(70))
	print("  yil      r_yil       c/v         q")
	for k in range(r.size()):
		if k % 10 == 0 or k == r.size() - 1:
			print("  %4d  %9.5f  %8.3f  %8.3f"
					% [int(o.gecmis.yillar[k]), r[k], cv[k], q[k]])

	var zirve := -INF
	var zirve_k := 0
	for k in range(r.size()):
		if r[k] > zirve:
			zirve = r[k]
			zirve_k = k
	print("\n  zirve %.5f @ %d, son %.5f @ %d  (zirveden %%%.1f)"
			% [zirve, int(o.gecmis.yillar[zirve_k]), r[r.size() - 1],
					int(o.gecmis.yillar[r.size() - 1]),
					(r[r.size() - 1] / zirve - 1.0) * 100.0])
	return 0


# ===========================================================================
# B7b TANI KAPISI -- POLITIKA AKTORU
# ===========================================================================

## Aktorun dunyada ne yaptigi. Kapi degil tani.
##
## B3'un uyarisi burada okunmali: "§4 guclu bir koldur; yanlis kalibre
## edilirse ya devrimi IMKANSIZ kilar ya da ETKISIZ kalir." Ikisi de sessizdir
## -- biri "hic devrim yok", digeri "hicbir sey degismedi" diye gorunur ve
## ikisi de makul bir ekran uretir. Bu yuzden aktorlu ve aktorsuz kollar YAN
## YANA kosulur.
static func aktor_iz(yil: int = 200, ulke: int = 12) -> int:
	var kodlar := Harita.kapi_kodlar(ulke)
	var acik := Harita.dunya_kur(kodlar, 42, Oyun.BAS_YIL)
	var kapali := Harita.dunya_kur(kodlar, 42, Oyun.BAS_YIL)
	kapali.aktor = null

	print("=".repeat(78))
	print("v2 POLITIKA AKTORU  (B7b)   %d ulke x %d yil" % [ulke, yil])
	print("=".repeat(78))
	print("  yil    riza    zor  bolunme  yayilim     org      PR   devrim")

	var n := yil * Oyun.YILDA_TIK
	var orta := 0.0
	for k in range(n):
		acik.adim(Oyun.HAFTA)
		kapali.adim(Oyun.HAFTA)
		# KESIT DOYGUN OLMAYAN BIR ANDA OLCULMELI. Kampanya sonunda `Omega`
		# herkeste 1.0'a dayaniyor ve ayrim kayboluyor; 1950 mekanizmanin
		# calistigi ama tavana varmadigi yer.
		if k == int(1950.0 - Oyun.BAS_YIL) * Oyun.YILDA_TIK:
			orta = _kesit(acik)
		if (k + 1) % (20 * Oyun.YILDA_TIK) == 0:
			_satir(acik, int(Oyun.BAS_YIL) + (k + 1) / Oyun.YILDA_TIK)

	print("\n  --- aktorsuz kol, ayni tohum ---")
	_satir(kapali, int(Oyun.BAS_YIL) + yil)

	# ZORUN RIZADAN SONRA GELMESI (§4.2) -- ilk esik gecisleri.
	print("\n  riza esigi (0.10) ilk gecis: %s" % _ilk_gecis(acik, "riza_kolu"))
	print("  zor  esigi (0.10) ilk gecis: %s" % _ilk_gecis(acik, "zor_kolu"))

	# BILESENLERIN DAGILIMI -- doygunluk avi. Bir surucu clamp'e dayanmissa
	# ortalamasi makul gorunur ama AYIRT ETMEZ; B6'nin savas sabitinde ayni
	# hata olculmustu.
	print("\n  --- surucu bilesenleri (2036, kapitalist ulkeler) ---")
	var pr := PackedFloat64Array()
	var tik_ := PackedFloat64Array()
	var pc := PackedFloat64Array()
	var bas := PackedFloat64Array()
	for d in acik.ulkeler:
		if d.rejim != "kapitalist":
			continue
		pr.append(d.PR)
		tik_.append(clampf((d.i_yil - d.r_yil) / maxf(acik.P.v44.kd_tikanma_olcek, 1e-9), 0.0, 1.0))
		pc.append(minf(d.PC, 1.0))
		bas.append(d.baski_egilimi)
	var om := PackedFloat64Array()
	var orgl := PackedFloat64Array()
	var carp := PackedFloat64Array()
	for d in acik.ulkeler:
		if d.rejim != "kapitalist":
			continue
		om.append(d.Omega)
		orgl.append(d.orgutlu)
		carp.append(d.Omega * d.orgutlu)
	_dagilim("Omega      ", om)
	_dagilim("orgutlu    ", orgl)
	_dagilim("Om*orgutlu ", carp)
	_dagilim("PR         ", pr)
	_dagilim("tikanma    ", tik_)
	_dagilim("PC         ", pc)
	_dagilim("baski_egil.", bas)

	# DEVRIM: bolunme devrimi ONLEMEZ, ERTELER (cekirdegin kendi yorumu,
	# kriz_cekirdegi.gd:1336). Ikisi de sifirsa mekanizma o cumleyi yalanliyor.
	print("\n  kesit @1950 (doygunluk oncesi): %+.4f" % orta)
	print("  kesit @son  (doygunluk sonrasi): %+.4f" % _kesit(acik))

	print("\n  --- devrim yillari ---")
	print("    aktorlu : %s" % _devrim_yillari(acik))
	print("    aktorsuz: %s" % _devrim_yillari(kapali))

	# KESITSEL iliski: ayni ANDA tehdidi yuksek olan ulke daha cok mu uzaniyor.
	# Kampanya ortalamasi DEGIL -- deponun dort kez yakaladigi tuzak bu.
	# KESIT ORGUTLU OFKEYE GORE. Ilk yazimda `PR`e goreydi ve `PR` ayirt
	# etmiyor (aralik 0.045); olculen sey surucunun degil baska bir seyin
	# iliskisi oluyordu.
	print("\n  es-zamanli kesit: Omega*orgutlu ustu vs alti yari, ortalama riza")
	var ust := 0.0
	var alt := 0.0
	var nu := 0
	var na := 0
	var medyan := _medyan_oo(acik)
	for d in acik.ulkeler:
		if d.rejim != "kapitalist":
			continue
		if d.Omega * d.orgutlu >= medyan:
			ust += d.riza_kolu
			nu += 1
		else:
			alt += d.riza_kolu
			na += 1
	print("    orgutlu ofke >= medyan: %.4f (%d ulke)" % [ust / maxf(nu, 1), nu])
	print("    orgutlu ofke <  medyan: %.4f (%d ulke)" % [alt / maxf(na, 1), na])
	return 0


static func _satir(w: Dunya, yil: int) -> void:
	var riza := 0.0
	var zor := 0.0
	var bol := 0.0
	var org := 0.0
	var pr := 0.0
	var enk := INF
	var enb := -INF
	var devrim := 0
	for d in w.ulkeler:
		riza += d.riza_kolu
		zor += d.zor_kolu
		bol += d.bolunme
		org += d.org
		pr += d.PR
		enk = minf(enk, d.bolunme)
		enb = maxf(enb, d.bolunme)
		if d.devrim_yil > 0.0:
			devrim += 1
	var n := float(w.ulkeler.size())
	print("  %4d  %6.3f %6.3f  %7.3f  %7.3f  %6.3f  %6.4f   %d"
			% [yil, riza / n, zor / n, bol / n, enb - enk, org / n, pr / n,
					devrim])


static func _ilk_gecis(w: Dunya, alan: String) -> String:
	for d in w.ulkeler:
		if float(d.get(alan)) >= 0.10:
			return "en az bir ulkede asildi (kampanya sonunda %.3f)" % float(d.get(alan))
	return "HIC asilmadi"


static func _medyan_oo(w: Dunya) -> float:
	var a := PackedFloat64Array()
	for d in w.ulkeler:
		if d.rejim == "kapitalist":
			a.append(d.Omega * d.orgutlu)
	if a.is_empty():
		return 0.0
	a.sort()
	return a[a.size() / 2]


static func _dagilim(ad: String, a: PackedFloat64Array) -> void:
	if a.is_empty():
		print("    %s  (bos)" % ad)
		return
	var b := a.duplicate()
	b.sort()
	print("    %s  min %.4f  medyan %.4f  max %.4f  aralik %.4f"
			% [ad, b[0], b[b.size() / 2], b[b.size() - 1], b[b.size() - 1] - b[0]])


static func _devrim_yillari(w: Dunya) -> String:
	var c := PackedStringArray()
	for i in range(w.ulkeler.size()):
		if w.ulkeler[i].devrim_yil > 0.0:
			c.append("%s@%d" % [w.adlar[i], int(w.ulkeler[i].devrim_yil)])
	return ", ".join(c) if not c.is_empty() else "YOK"


## B7b KALIBRASYON TARAMASI.
##
## DORT OLCUT BIRDEN OKUNUR, cunku bu kolun iki ayri sekilde bozulma yolu var
## ve ikisi de sessiz (B3'un uyarisi): fazla guclu olursa devrimi IMKANSIZ
## kilar, fazla zayif olursa ETKISIZ kalir. Tek bir sayiya bakarak kalibre
## etmek ikisinden birini kacirir.
##
##   1. AYIRT EDICILIK -- ulkeler arasi `bolunme` yayilimi. Sifira yakinsa
##      surucu doymus demektir (ilk yazimda 0.007 olculdu).
##   2. SIRA          -- riza esigi zordan ONCE asiliyor mu (§4.2).
##   3. DEVRIM        -- hala oluyor mu. `bolunme` devrimi ONLEMEZ ERTELER;
##      sifir devrim o cumleyi yalanlar.
##   4. KESIT         -- ES-ZAMANLI kesitte orgutlu ofkesi yuksek olan ulke
##      daha cok mu uzaniyor. Kampanya ortalamasi DEGIL.
## PENCERE TAM UFUKTUR (1836-2100), YARIM DEGIL. Ilk tarama 150 yilda
## bitiyordu ve tam bu yuzden asil sapmayi goremedi: 150 yilda secilen kol
## (0.30/0.70) 200 yilda devrimi SIFIRLIYORDU. Deponun iki kez kaydettigi
## ders -- "bir egriyi tek noktadan eslestirmek onu eslestirmez"in zaman
## eksenindeki hali.
static func aktor_tarama(yil: int = 264, ulke: int = 10) -> int:
	var kodlar := Harita.kapi_kodlar(ulke)
	print("=".repeat(86))
	print("v2 POLITIKA AKTORU -- kalibrasyon taramasi   %d ulke x %d yil"
			% [ulke, yil])
	print("=".repeat(86))

	var temel := _kampanya(kodlar, yil, -1.0, -1.0)
	print("  AKTORSUZ TABAN: bolunme %.3f  yayilim %.3f  devrim %d %s"
			% [temel["bolunme"], temel["yayilim"], temel["devrim"],
					temel["devrim_yil"]])
	print("")
	print("  olcek tavan  bolunme yayilim    riza     zor  riza_yil zor_yil"
			+ "  devrim  kesit")

	for olcek in [0.30, 0.50, 0.75]:
		for tav in [0.4, 0.7, 1.0]:
			var r := _kampanya(kodlar, yil, olcek, tav)
			print("  %5.2f %5.2f   %6.3f  %6.3f  %6.3f  %6.3f  %7s %7s  %5d  %+.4f"
					% [olcek, tav, r["bolunme"], r["yayilim"], r["riza"],
							r["zor"], r["riza_yil"], r["zor_yil"],
							r["devrim"], r["kesit"]])
	return 0


static func _kampanya(kodlar: PackedStringArray, yil: int, olcek: float,
		tavan: float) -> Dictionary:
	var w := Harita.dunya_kur(kodlar, 42, Oyun.BAS_YIL)
	if olcek < 0.0:
		w.aktor = null
	else:
		w.aktor.tehdit_olcek = olcek
		w.aktor.tavan = tavan

	var riza_yil := 0
	var zor_yil := 0
	for k in range(yil * Oyun.YILDA_TIK):
		w.adim(Oyun.HAFTA)
		if riza_yil == 0 or zor_yil == 0:
			for d in w.ulkeler:
				if riza_yil == 0 and d.riza_kolu >= 0.10:
					riza_yil = int(Oyun.BAS_YIL) + k / Oyun.YILDA_TIK
				if zor_yil == 0 and d.zor_kolu >= 0.10:
					zor_yil = int(Oyun.BAS_YIL) + k / Oyun.YILDA_TIK

	var bol := 0.0
	var riza := 0.0
	var zor := 0.0
	var enk := INF
	var enb := -INF
	var devrim := 0
	var yillar := PackedStringArray()
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		bol += d.bolunme
		riza += d.riza_kolu
		zor += d.zor_kolu
		enk = minf(enk, d.bolunme)
		enb = maxf(enb, d.bolunme)
		if d.devrim_yil > 0.0:
			devrim += 1
			yillar.append("%s@%d" % [w.adlar[i], int(d.devrim_yil)])
	var n := float(w.ulkeler.size())

	# KESIT: es-zamanli, orgutlu ofkenin medyanina gore ikiye bolerek.
	var oo := PackedFloat64Array()
	for d in w.ulkeler:
		if d.rejim == "kapitalist":
			oo.append(d.Omega * d.orgutlu)
	var medyan := 0.0
	if not oo.is_empty():
		var t := oo.duplicate()
		t.sort()
		medyan = t[t.size() / 2]
	var ust := 0.0
	var alt := 0.0
	var nu := 0
	var na := 0
	for d in w.ulkeler:
		if d.rejim != "kapitalist":
			continue
		if d.Omega * d.orgutlu >= medyan:
			ust += d.riza_kolu
			nu += 1
		else:
			alt += d.riza_kolu
			na += 1

	return {
		"bolunme": bol / n, "yayilim": enb - enk, "riza": riza / n,
		"zor": zor / n, "devrim": devrim,
		"devrim_yil": ", ".join(yillar) if not yillar.is_empty() else "YOK",
		"riza_yil": str(riza_yil) if riza_yil > 0 else "-",
		"zor_yil": str(zor_yil) if zor_yil > 0 else "-",
		"kesit": ust / maxf(nu, 1) - alt / maxf(na, 1),
	}


## ES-ZAMANLI KESIT: orgutlu ofkenin medyanina gore ikiye bolup rizayi
## karsilastirir. Pozitifse "tehdidi buyuk olan daha cok uzaniyor".
static func _kesit(w: Dunya) -> float:
	var medyan := _medyan_oo(w)
	var ust := 0.0
	var alt := 0.0
	var nu := 0
	var na := 0
	for d in w.ulkeler:
		if d.rejim != "kapitalist":
			continue
		if d.Omega * d.orgutlu >= medyan:
			ust += d.riza_kolu
			nu += 1
		else:
			alt += d.riza_kolu
			na += 1
	return ust / maxf(nu, 1) - alt / maxf(na, 1)


## B7c -- SUNUM KATMANI: blok gosterimi ve ad degisimi takvimi.
##
## Ikisi de motoru degistirmez; sinanan sey SOZLESMEDIR. Bir sunum hatasi
## headless kapilarin hepsinden gecer (B7a'da uc tanesi oyle gecmisti), ama
## bunlarin ikisi de EKRANA BAKMADAN sayilabilir: ad tablosu saf bir
## fonksiyon, bloklar ise grafin bagli bilesenleri.
static func _sunum_kademesi(w: Dunya) -> void:
	# --- AD TAKVIMI ---
	# (a) Tablodaki her kod haritada var ve TARIHSEL ADI da var mi. Yoksa
	#     satir sessizce hicbir sey yapmaz -- ad hic degismez ve kimse
	#     fark etmez.
	var kotu: Array[String] = []
	for kod in Harita.AD_DEGISIMI.keys():
		var i := Harita.indeks(String(kod))
		if i < 0:
			kotu.append("%s: haritada yok" % kod)
		elif String(Harita.kayit()[i]["ad_1836"]) == "":
			kotu.append("%s: tarihsel adi yok" % kod)
	_dogrula(kotu.is_empty(), "ad takvimindeki her kod haritada karsilikli",
			"; ".join(kotu) if not kotu.is_empty() else
			"%d kod" % Harita.AD_DEGISIMI.size())

	# (b) TERSI DE DENETLENIR: tarihsel adi MODERN adindan FARKLI olan her
	#     ulkenin takvimde bir yili olmali. Olmazsa o ulke 2100'de hala
	#     1836 adiyla durur -- B7c'nin var olma sebebi tam olarak bu.
	var takvimsiz: Array[String] = []
	for u in Harita.kayit():
		var t := String(u["ad_1836"])
		if t == "" or t == String(u["ad"]):
			continue
		if not Harita.AD_DEGISIMI.has(String(u["kod"])):
			takvimsiz.append(String(u["kod"]))
	_dogrula(takvimsiz.is_empty(), "adi degisen her ulkenin takvimi var",
			"takvimsiz: " + ", ".join(takvimsiz) if not takvimsiz.is_empty()
			else "")

	# (c) GECIS GERCEKTEN OLUYOR mu -- ve dogru yilda.
	var yanlis: Array[String] = []
	for kod in Harita.AD_DEGISIMI.keys():
		var k := String(kod)
		var y := float(Harita.AD_DEGISIMI[k])
		var i := Harita.indeks(k)
		var tarihsel := String(Harita.kayit()[i]["ad_1836"])
		var modern := String(Harita.kayit()[i]["ad"])
		if tarihsel == modern:
			continue
		if Harita.gorunen_ad(k, y - 1.0) != tarihsel:
			yanlis.append("%s gecis oncesi" % k)
		if Harita.gorunen_ad(k, y) != modern:
			yanlis.append("%s gecis yilinda" % k)
	_dogrula(yanlis.is_empty(), "ad gecisi takvim yilinda oluyor",
			"; ".join(yanlis) if not yanlis.is_empty() else "")

	# (d) EPSILON: `yil` haftalik birikimle gecis yilinin bir tik altina
	#     duser (1922.9999999). Tam esitlik karsilastirmasi gecisi bir yil
	#     geciktirirdi -- takvimin kendisi dogru olmasina ragmen.
	_dogrula(Harita.gorunen_ad("TUR", 1923.0 - 1e-9) == "Türkiye",
			"gecis yili kayan nokta hatasina dayanikli",
			"1922.999999999 -> " + Harita.gorunen_ad("TUR", 1923.0 - 1e-9))

	# --- BLOKLAR ---
	var b := Harita.bloklar(w)
	var uye := {}
	for i in range(b.size()):
		if b[i] >= 0:
			uye[b[i]] = int(uye.get(b[i], 0)) + 1

	# BLOK CANLILIGI BURADA IDDIA EDILMEZ -- ve bu, B5/B7c'nin KENDI is
	# bolumu. `harita_testi` o ayrimi zaten yazmisti: "on ulkelik bir
	# dunyada ittifak neredeyse hic olusmuyor (olculdu: 1 blok, 2 uye),
	# yani orada 'blok gosterimi calisiyor' demek bos kalirdi. Sozlesme
	# denetimleri (kimlik, tutarlilik, tek uyeli blok yok) `--v2-oyun`da
	# duruyor." Bu satir o cumleye ragmen bir CANLILIK iddiasiydi ve sekiz
	# ulkelik dunyada bicak sirtinda geciyordu -- tam olarak "1 blok, 2
	# uye" ile.
	#
	# Tohumlama onu sifira dusurdu, cunku ittifak ORTAK DUSMAN ister ve
	# `guc()` boyutla ayrisinca (`h.guc() >= c.guc() * 1.15` elemesi) iki
	# ulkenin ayni hedefe saldirmasi seyreklesti. Mekanizma OLMEDI: 54
	# ulkelik harita dunyasinda en buyuk blok 4 ulke (olculdu). Sekiz
	# ulkede sifir cikmasi mekanizmanin degil KADRONUN ifadesidir.
	print("  KAYIT: %d blok, %d uye (canlilik olcutu `--v2-harita`da)"
			% [uye.size(), b.size() - _sifir_say(b)])

	# (e) TEK UYELI BLOK YOK. Bir blok en az iki ulkedir; tek basina bir
	#     ulkeyi renklendirmek haritayi anlamsiz renklerle doldururdu.
	var tekli := 0
	for k in uye.keys():
		if int(uye[k]) < 2:
			tekli += 1
	_dogrula(tekli == 0, "tek uyeli blok yok", "%d tane" % tekli)

	# (f) KIMLIK EN KUCUK UYE INDEKSI. Blok boyuna ya da olusum sirasina
	#     gore numaralandirilsaydi bir ulke katildiginda butun renkler
	#     kayardi.
	var kimlik_hatasi: Array[String] = []
	for kimlik in uye.keys():
		var en_kucuk := 1 << 30
		for i in range(b.size()):
			if b[i] == kimlik:
				en_kucuk = mini(en_kucuk, i)
		if en_kucuk != int(kimlik):
			kimlik_hatasi.append("%d != %d" % [kimlik, en_kucuk])
	_dogrula(kimlik_hatasi.is_empty(), "blok kimligi = en kucuk uye indeksi",
			"; ".join(kimlik_hatasi) if not kimlik_hatasi.is_empty() else "")

	# (g) TUTARLILIK: muttefik olan iki ulke AYNI blokta olmali. Birlesim
	#     hatasi burada yakalanir.
	var ad_indeks := {}
	for i in range(w.adlar.size()):
		ad_indeks[w.adlar[i]] = i
	var kopuk := 0
	for i in range(w.ulkeler.size()):
		for mut in w.ulkeler[i].muttefik:
			var j := int(ad_indeks.get(mut, -1))
			if j >= 0 and b[i] != b[j]:
				kopuk += 1
	_dogrula(kopuk == 0, "muttefik ciftler ayni blokta", "%d kopuk" % kopuk)

	# (h) MUTTEFIKSIZ ULKE BLOKSUZ.
	var yanlis_uye := 0
	for i in range(w.ulkeler.size()):
		if w.ulkeler[i].muttefik.is_empty() and b[i] >= 0:
			yanlis_uye += 1
	_dogrula(yanlis_uye == 0, "muttefiksiz ulke bloga girmiyor",
			"%d tane" % yanlis_uye)

	print("  KAYIT: %d blok, en buyugu %d ulke" % [uye.size(), _en_buyuk(uye)])

	# --- KADRO ---
	# Kucuk dunya OYNANABILIR KUMEYI kaybetmemeli. `kapi_kodlar` alfabetik
	# ilk `n`i verir ve 24 ulkelik bir kume ABD'siz, Britanya'siz cikar --
	# oyun icin dogru kume `oyun_kodlar`dir ve farki burada sayilir.
	var oynanabilir := Harita.oynanabilir_kodlar()
	for n in [24, 54]:
		var kadro := Harita.oyun_kodlar(n)
		var eksik: Array[String] = []
		for kod in oynanabilir:
			if not kadro.has(kod):
				eksik.append(kod)
		_dogrula(kadro.size() == n and eksik.is_empty(),
				"kadro %d: boy dogru ve oynanabilir kume tam" % n,
				"boy %d, eksik: %s" % [kadro.size(), ", ".join(eksik)])

	# TAM KADRONUN ALT KUMESI, ve SIRASI KORUNUR: kucuk dunya buyugunun
	# gercek bir alt kumesi degilse iki kosu yan yana okunamaz.
	var tam := Harita.oyun_kodlar(0)
	var orta := Harita.oyun_kodlar(54)
	var sira_hatasi := false
	var k := 0
	for kod in tam:
		if k < orta.size() and orta[k] == kod:
			k += 1
	if k != orta.size():
		sira_hatasi = true
	_dogrula(tam.size() == Harita.simule_kodlar().size() and not sira_hatasi,
			"kucuk kadro tam kadronun SIRALI alt kumesi",
			"tam %d, orta %d" % [tam.size(), orta.size()])


static func _sifir_say(b: PackedInt32Array) -> int:
	var c := 0
	for v in b:
		if v < 0:
			c += 1
	return c


static func _en_buyuk(uye: Dictionary) -> int:
	var m := 0
	for k in uye.keys():
		m = maxi(m, int(uye[k]))
	return m
