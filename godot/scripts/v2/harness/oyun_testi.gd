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
	_dogrula(b.r_yil < a.r_yil, "... ve kar orani DUSUYOR (§2.4'un tuzagi)",
			"%.4f -> %.4f" % [a.r_yil, b.r_yil])

	print("\n" + "-".repeat(70))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


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
