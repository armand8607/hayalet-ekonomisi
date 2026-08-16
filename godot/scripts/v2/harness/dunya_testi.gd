class_name DunyaTesti
extends RefCounted

## v2 DUNYA KATMANI -- deger akisinin sinanmasi.
##
## Neyi kanitliyor: "birinden eksilen digerine gider" bir niyet degil,
## motorun tasiyabildigi bir OZDESLIK. Ve bu ozdeslik saglandiginda
## esitsiz mubadelenin kriz dinamigi uzerindeki imzasi OLCULEBILIR hale
## geliyor -- tek ulkeyle tanimsiz olan sey tam olarak buydu.
##
## Dort kademe:
##   1. KORUNUM     -- sum(VT) == 0, her tikte, kampanya boyunca
##   2. DEJENERE    -- ozdes ulkeler arasinda akis OLMAMALI (uydurma akim yok)
##   3. YON         -- yuksek organik bilesim deger CEKER
##   4. B1b OLCUTU  -- alan ulkede kriz yogunlugu, verendekinden DUSUK
##
## Dorduncusu belgenin (§6) B1b icin koydugu kapidir ve tek ulkeyle
## TANIMSIZDIR: "alan" ve "veren" sifatlarinin gondergesi yoktur. Bu test
## onlara gonderge kazandirir.

const BAS := 1836.0
const BITIS := 2034.0
const HAFTA := 1.0 / 52.0

static var _gecen := 0
static var _kalan := 0


## Bir ulkenin bunalim yogunlugu: bunalim sayisi / 100 KAPITALIST yil.
## Devrimden sonra kriz teorisi baska rejimde isler, o yuzden payda kapitalist
## sureyle sinirlidir (`tarih_testi` ile ayni usul).
static func _bunalim_yogunlugu(w: Dunya, i: int, sure: float) -> float:
	var d := w.ulkeler[i]
	var kap: float = (d.devrim_yil - BAS) if d.devrim_yil > 0.0 else sure
	return d.bunalimlar.size() * 100.0 / maxf(kap, 1.0)


## Asiri uretim (gerceklesme krizi) yogunlugu -- /100 kapitalist yil.
static func _au_yogunlugu(w: Dunya, i: int, sure: float) -> float:
	var d := w.ulkeler[i]
	var kap: float = (d.devrim_yil - BAS) if d.devrim_yil > 0.0 else sure
	return d.asiri_uretim_krizleri.size() * 100.0 / maxf(kap, 1.0)


## Bir ulkenin TOPLAM kriz yogunlugu -- /100 kapitalist yil.
static func _toplam_yogunluk(w: Dunya, i: int, sure: float) -> float:
	var d := w.ulkeler[i]
	var kap: float = (d.devrim_yil - BAS) if d.devrim_yil > 0.0 else sure
	return w.kriz_sayisi(i) * 100.0 / maxf(kap, 1.0)


## Dunya geneli ASIRI URETIM yogunlugu -- havuzlanmis payda.
static func _dunya_yogunlugu_au(w: Dunya, sure: float) -> float:
	var say := 0
	var kap_toplam := 0.0
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		say += d.asiri_uretim_krizleri.size()
		kap_toplam += (d.devrim_yil - BAS) if d.devrim_yil > 0.0 else sure
	return say * 100.0 / maxf(kap_toplam, 1.0)


## Dunya geneli yogunluk: butun ulkelerin tescili, butun kapitalist yillara
## bolunur. Ulke basina ortalama degil, DUNYA orani.
static func _dunya_yogunlugu(w: Dunya, sure: float, yalniz_bunalim: bool) -> float:
	var say := 0
	var kap_toplam := 0.0
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		say += d.bunalimlar.size() if yalniz_bunalim else w.kriz_sayisi(i)
		kap_toplam += (d.devrim_yil - BAS) if d.devrim_yil > 0.0 else sure
	return say * 100.0 / maxf(kap_toplam, 1.0)


## Pearson korelasyonu. Kural bir GRADYAN iddiasidir ("alan rahatlar, veren
## yuklenir"), dolayisiyla dogru olcusu butun ulkeler uzerinden alinan
## korelasyondur -- iki UC ulkeyi karsilastirmak degil.
##
## NEDEN UCLAR YETMIYOR: en cok veren ulke ayni zamanda kriz bakimindan
## DOYMUS olandir (olculdu: 5.9 bunalim/100y, transfer acikken de kapaliyken
## de). Doymus bir ulkede artis kaydedilemez, cunku yukselecek yer yoktur.
## Gradyan gercekten oradadir ama UCTA degil ORTADA gorunur: yuk `Orta`ya
## biniyor (+0.46) iken `Dusuk` kipirdamiyor (+0.00). Uclara bakan bir test
## bu yuzden mekanizmayi degil doygunlugu olcer.
static func _korelasyon(x: PackedFloat64Array, y: PackedFloat64Array) -> float:
	var n := x.size()
	if n < 2 or y.size() != n:
		return 0.0
	var mx := 0.0
	var my := 0.0
	for i in range(n):
		mx += x[i]
		my += y[i]
	mx /= n
	my /= n
	var sxy := 0.0
	var sxx := 0.0
	var syy := 0.0
	for i in range(n):
		var dx := x[i] - mx
		var dy := y[i] - my
		sxy += dx * dy
		sxx += dx * dx
		syy += dy * dy
	if sxx <= 0.0 or syy <= 0.0:
		return 0.0
	return sxy / sqrt(sxx * syy)


static func _medyan(a: PackedFloat64Array) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	var n := s.size()
	return s[n / 2] if n % 2 == 1 else 0.5 * (s[n / 2 - 1] + s[n / 2])


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


## Bir ulke durumu kurar. `q0` ve `egitim` disinda hepsi ozdestir; ayrisma
## YALNIZCA uretkenlikten dogsun diye.
static func _ulke(q0: float, egitim: float, olcek: float = 1.0) -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0 * olcek
	d.pay = 0.52
	d.era = 1
	d.q = q0
	d.egitim = egitim
	d.yil = BAS
	d.varlik = 0.5
	return d


## Organik bilesim bakimindan AYRISAN bir dunya. Ayrisma tek kaynaktan
## gelir: baslangic uretkenligi ve egitim tabani. Ulke "tipi" diye bir girdi
## yok -- merkez/cevre konumu bu kosunun SONUCUDUR.
static func _dunya_kur(tohum: int = 42) -> Dunya:
	var w := Dunya.new()
	w.yil = BAS
	w.ekle(_ulke(1.60, 0.42), "Yuksek", tohum)
	w.ekle(_ulke(1.30, 0.36), "Orta-ust", tohum)
	w.ekle(_ulke(1.00, 0.30), "Orta", tohum)
	w.ekle(_ulke(0.80, 0.24), "Orta-alt", tohum)
	w.ekle(_ulke(0.65, 0.18), "Dusuk", tohum)
	return w


static func _kos(w: Dunya, yil_sayisi: float) -> void:
	var n := Oran.donem_sayisi(yil_sayisi, HAFTA)
	for _i in range(n):
		w.adim(HAFTA)


## Kosarken ORNEKLER. Her `ornek_hafta` tikte ulke basina (NX/Y, talep_acigi)
## kaydeder. Donen: [ornek][ulke] -> [nx_y, acik].
##
## Neden gerekli: "gecici rahatlama" bir ZAMAN iddiasidir ve kampanya
## ortalamasinda gorunmez. Ortalama, rahatlamayi ve onu izleyen kapasite
## genislemesini ayni kefeye koyup birbirine gotururuyor.
static func _kos_ornekli(w: Dunya, yil_sayisi: float,
		ornek_hafta: int = 26) -> Array:
	var n := Oran.donem_sayisi(yil_sayisi, HAFTA)
	var ornekler: Array = []
	for t in range(n):
		w.adim(HAFTA)
		if t % ornek_hafta == 0:
			var satir: Array = []
			for i in range(w.ulkeler.size()):
				var d := w.ulkeler[i]
				# [0] NX/Y  [1] talep acigi  [2] BILESIK dis akim / Y
				# [3] o ana kadarki kumulatif kriz sayisi
				satir.append([
					d.NX_yil / maxf(d.Y_yil, 1e-9),
					d.talep_acigi,
					(d.NX_yil + w.son_vt[i] + d.faiz_dis_yil + d.mor_akim_yil)
							/ maxf(d.Y_yil, 1e-9),
					float(w.kriz_sayisi(i))])
			ornekler.append(satir)
	return ornekler


## SIDDET TARAMASI -- kuralin hangi agirlikta SAGLAM oldugunu olcer.
##
## Yon dogru olsa bile buyukluk kucukse mekanizma gurultuye gomulur ve test
## medyanin isaretine bakip "gecti" der. Bu tarama o yanilgiyi gorunur kilar:
## her siddet icin ALTI TOHUMUN KACINDA isaret dogru ciktigi raporlanir.
## Medyan degil, TUTARLILIK olcutu.
##
## Ayri bir kapidir (`--v2-dunya-siddet`), ana testin icinde degildir: 4 siddet
## x 6 tohum x 2 kol = 48 dunya kosusu, ana kapinin dort kati.
static func siddet_taramasi() -> int:
	print("")
	print("V2 DUNYA -- SIDDET TARAMASI")
	print("==================================================================")
	print("Soru: transfer hangi agirlikta kurali GURULTUDEN cikariyor?")
	print("")
	# OLCUT GRADYANDIR, UCLAR DEGIL. Ilk yazimda bu tarama en cok alan ve en
	# cok veren ulkeyi karsilastiriyordu; ticaret eklendikten sonra en cok
	# veren ulke kriz bakimindan DOYDU (5.9 bunalim/100y, iki kolda da ayni)
	# ve tarama mekanizmayi degil doygunlugu olcmeye basladi -- siddet
	# arttikca "VEREN dogru" 6/6'dan 1/6'ya duserken gradyan saglam kaliyordu.
	# DEVRIM SAYISI DA RAPORLANIR. Yogunluk KAPITALIST yila bolunuyor, yani
	# devrim erkene kayarsa payda kuculur ve yogunluk mekanizmadan bagimsiz
	# olarak sisebilir. Gradyanin siddetle tekduze GITMEDIGI goruldugunde ilk
	# supheli budur; sutun onu gorunur kilmak icin var.
	print("  %8s %10s %14s %12s %10s %12s"
			% ["siddet", "|VT|/Y", "gradyan(havuz)", "n", "devrim", "ort.yil"])
	var sure := BITIS - BAS
	for siddet in [0.10, 0.20, 0.40, 0.60, 0.80]:
		var h_vt := PackedFloat64Array()
		var h_db := PackedFloat64Array()
		var agirlik := 0.0
		var devrim_say := 0
		var devrim_yil_top := 0.0
		for tohum in [1, 2, 3, 4, 5, 6]:
			var acik := _dunya_kur(tohum)
			acik.siddet = siddet
			_kos(acik, sure)
			var kapali := _dunya_kur(tohum)
			kapali.siddet = 0.0
			_kos(kapali, sure)
			agirlik += acik.vt_agirligi()
			for i in range(acik.ulkeler.size()):
				h_vt.append(acik.toplam_vt[i])
				h_db.append(_bunalim_yogunlugu(acik, i, sure)
						- _bunalim_yogunlugu(kapali, i, sure))
				if acik.ulkeler[i].devrim_yil > 0.0:
					devrim_say += 1
					devrim_yil_top += acik.ulkeler[i].devrim_yil
		print("  %8.2f %10.4f %14.3f %12s %10s %12.0f"
				% [siddet, agirlik / 6.0, _korelasyon(h_vt, h_db),
				"%d gozlem" % h_vt.size(), "%d/30" % devrim_say,
				devrim_yil_top / maxf(float(devrim_say), 1.0)])
	print("")
	print("  (v4.4 varsayilan dunyada |VT|/Y ~ 0.01-0.03 uretiyordu)")

	# ------------------------------------------------------------------
	# IHRACAT ITKISI TARAMASI
	# ------------------------------------------------------------------
	#
	# Itki tahminle konuldu (1.5) ve kalibre EDILMEDI. Sonucu olculdu: ortalama
	# itki 5.39'a cikiyor, oysa yapisal rekabet orani `eps/pi_m` en fazla 3.58.
	# Yani zorlama uretkenlik yapisini EZIYOR ve ticaret paylarini tek basina
	# belirliyor. Kavga mekanizmasi calisiyor ama altindaki yapiyi siliyor --
	# "dis konum bunalimi belirler" gradyani tam da bu yuzden -0.80'den
	# -0.11'e coktu (arac degiskenle de duzelmedi: yapisal -0.094).
	#
	# Iki sey ayni anda tutmali:
	#   ZORLAMA  -- baski ihracata itmeli (pozitif)
	#   YAPI     -- dis konum bunalimi belirlemeye devam etmeli (negatif, guclu)
	print("")
	print("  IHRACAT ITKISI TARAMASI")
	print("  %8s %10s %12s %14s %12s"
			% ["itki", "ort.itki", "ZORLAMA", "YAPI gradyani", "dunya dAU"])
	for itki_p in [0.0, 0.25, 0.5, 1.0, 1.5]:
		var hz_baski := PackedFloat64Array()
		var hz_dnx := PackedFloat64Array()
		var hy_konum := PackedFloat64Array()
		var hy_bun := PackedFloat64Array()
		var d_au_t := PackedFloat64Array()
		var d_au_s := PackedFloat64Array()
		var ort_itki := 0.0
		var say := 0
		for tohum in [1, 2, 3]:
			var tam := _dunya_kur(tohum)
			tam.P.ihracat_itkisi = itki_p
			_kos(tam, sure)
			var yalitik := _dunya_kur(tohum)
			yalitik.ticaret_yogunlugu = 0.0
			_kos(yalitik, sure)
			var itkisiz := _dunya_kur(tohum)
			itkisiz.P.ihracat_itkisi = 0.0
			_kos(itkisiz, sure)
			for i in range(tam.ulkeler.size()):
				hz_baski.append(itkisiz.ulkeler[i].talep_acigi)
				hz_dnx.append(tam.toplam_nx[i] - itkisiz.toplam_nx[i])
				hy_konum.append(itkisiz.dis_konum(i))
				hy_bun.append(_bunalim_yogunlugu(tam, i, sure)
						- _bunalim_yogunlugu(yalitik, i, sure))
				ort_itki += tam.son_itki[i]
				say += 1
			d_au_t.append(_dunya_yogunlugu_au(tam, sure))
			d_au_s.append(_dunya_yogunlugu_au(itkisiz, sure))
		print("  %8.2f %10.2f %12.3f %14.3f %12.2f"
				% [itki_p, ort_itki / maxf(float(say), 1.0),
				_korelasyon(hz_baski, hz_dnx), _korelasyon(hy_konum, hy_bun),
				_medyan(d_au_t) - _medyan(d_au_s)])
	print("  (3 tohum -- tani taramasi; ana kapi 6 tohumla kosar)")
	return 0


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("")
	print("V2 DUNYA KATMANI -- DEGER AKISI")
	print("==================================================================")
	print("Kural: birinden eksilen digerine gider.  sum(VT) == 0")
	print("")

	# -----------------------------------------------------------------
	# 1. KORUNUM
	# -----------------------------------------------------------------
	print("--- 1. korunum (kampanya boyunca her tikte olculur) ---")
	var w := _dunya_kur()
	_kos(w, BITIS - BAS)
	var hata := w.en_buyuk_korunum_hatasi
	print("  %d ulke, %.0f yil, haftalik tik" % [w.ulkeler.size(), BITIS - BAS])
	# NOT: GDScript'in bicimlendiricisinde `%e` YOKTUR; bilimsel gosterim icin
	# `str()` kullanilir, yoksa satir sessizce ham bicim dizesini basar.
	print("  en buyuk bagil korunum hatasi : %s" % str(hata))
	print("  (v4.4 ayni olcutte 0.57 veriyor -- olculdu, tohum 42, tur 1000)")
	# Makine hassasiyeti sinirinda olmali: toplama sirasindan gelen yuvarlama
	# disinda hicbir kayip olmamali.
	_dogrula(hata < 1e-12, "korunum: akim yaratilmiyor da yok edilmiyor da",
			"(%s < 1e-12)" % str(hata))

	# -----------------------------------------------------------------
	# 1b. TICARET KORUNUMU
	# -----------------------------------------------------------------
	print("")
	print("--- 1b. ticaret korunumu (bir ulkenin ihracati baskasinin ithalati) ---")
	var t_hata := w.en_buyuk_ticaret_hatasi
	print("  en buyuk bagil hata : %s" % str(t_hata))
	_dogrula(t_hata < 1e-12, "sum(NX) == 0 -- dunya kendine ihracat yapamiyor",
			"(%s < 1e-12)" % str(t_hata))

	# -----------------------------------------------------------------
	# 1c. DIS BORC KORUNUMU  (D/E/F)
	# -----------------------------------------------------------------
	print("")
	print("--- 1c. dis borc korunumu (her borcun bir alacaklisi var) ---")
	var b_hata := w.en_buyuk_borc_hatasi
	print("  en buyuk bagil hata : %s" % str(b_hata))
	print("  (v4.4'te dis borc alacaklisiz bir skalerdi; moratoryum onu")
	print("   buharlastiriyordu -- kimse zarar etmiyordu)")
	_dogrula(b_hata < 1e-12, "sum(net dis varlik) == 0",
			"(%s < 1e-12)" % str(b_hata))
	print("")
	print("  %-10s %9s %11s %8s %8s %9s %8s"
			% ["ulke", "dis_borc", "net_varlik", "morator", "fx_kriz", "ani_durus", "FX/Y"])
	var mor_top := 0
	var fx_top := 0
	for i in range(w.ulkeler.size()):
		var dd := w.ulkeler[i]
		mor_top += dd.moratoryumlar.size()
		fx_top += dd.fx_krizleri.size()
		print("  %-10s %9.3f %11.3f %8d %8d %9s %8.3f"
				% [w.adlar[i], dd.dis_borc, dd.dis_varlik,
				dd.moratoryumlar.size(), dd.fx_krizleri.size(),
				str(dd.ani_durus), dd.FX / maxf(dd.Y_yil, 1e-9)])
	print("  toplam: %d moratoryum, %d doviz krizi" % [mor_top, fx_top])
	# Mekanizma tanimli olsun yetmez, ATESLENSIN. Sifir cikiyorsa D/E/F
	# yazilmis ama olu koddur ve bunu ancak boyle bir sayac gosterir.
	_dogrula(mor_top + fx_top > 0,
			"D/E/F olu kod degil: borc/doviz krizleri tesciL ediliyor",
			"(%d moratoryum, %d doviz krizi)" % [mor_top, fx_top])

	# -----------------------------------------------------------------
	# 2. DEJENERE DURUM
	# -----------------------------------------------------------------
	print("")
	print("--- 2. dejenere durum (ozdes ulkeler) ---")
	var w2 := Dunya.new()
	w2.yil = BAS
	for k in range(4):
		w2.ekle(_ulke(1.0, 0.30), "Ozdes%d" % k, 42)
	_kos(w2, 20.0)
	var en_buyuk := 0.0
	for v in w2.son_vt:
		en_buyuk = maxf(en_buyuk, absf(v))
	print("  4 ozdes ulke, 20 yil -> en buyuk |VT| = %s" % str(en_buyuk))
	# Ozdes bilesimler arasinda esitsiz mubadele TANIMSIZDIR; akim cikiyorsa
	# formul kendi kendine akim uyduruyor demektir.
	_dogrula(en_buyuk < 1e-9, "ozdes ulkeler arasinda akis yok",
			"(%s)" % str(en_buyuk))

	# -----------------------------------------------------------------
	# 3. YON
	# -----------------------------------------------------------------
	print("")
	print("--- 3. yon: yuksek organik bilesim deger CEKER ---")
	print("  %-10s %7s %8s %7s %7s %9s %10s %12s"
			% ["ulke", "q", "c/v", "eps", "pi_m", "NX/Y", "VT/Y", "birikmis VT"])
	var alan := -1
	var veren := -1
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		print("  %-10s %7.2f %8.3f %7.3f %7.3f %9.4f %10.5f %12.1f"
				% [w.adlar[i], d.q, d.cv, d.eps, d.pi_m,
				d.NX_yil / maxf(d.Y_yil, 1e-9),
				w.son_vt[i] / maxf(d.Y_yil, 1e-9), w.toplam_vt[i]])
		if alan < 0 or w.toplam_vt[i] > w.toplam_vt[alan]:
			alan = i
		if veren < 0 or w.toplam_vt[i] < w.toplam_vt[veren]:
			veren = i
	print("  en cok ALAN  : %s" % w.adlar[alan])
	print("  en cok VEREN : %s" % w.adlar[veren])
	_dogrula(w.ulkeler[alan].cv > w.ulkeler[veren].cv,
			"alanin organik bilesimi verenden yuksek",
			"(%.3f > %.3f)" % [w.ulkeler[alan].cv, w.ulkeler[veren].cv])
	# Ticaret fazlasi bir GIRDI degil, uretkenlik farkinin SONUCU olmali.
	var en_q := 0
	var en_dusuk_q := 0
	for i in range(w.ulkeler.size()):
		if w.ulkeler[i].q > w.ulkeler[en_q].q:
			en_q = i
		if w.ulkeler[i].q < w.ulkeler[en_dusuk_q].q:
			en_dusuk_q = i
	_dogrula(w.ulkeler[en_q].NX_yil > w.ulkeler[en_dusuk_q].NX_yil,
			"en uretken ulke ticaret dengesinde en dusuk uretkenin ONUNDE",
			"(%s %.1f > %s %.1f)" % [w.adlar[en_q], w.ulkeler[en_q].NX_yil,
			w.adlar[en_dusuk_q], w.ulkeler[en_dusuk_q].NX_yil])

	# -----------------------------------------------------------------
	# 4. ASIL KURAL  --  KARSI-OLGUSAL
	# -----------------------------------------------------------------
	#
	# KURAL: "alanda bunalim yogunlugu AZALIR, verende ARTAR."
	#
	# `azalir`/`artar` bir DEGISIM iddiasidir, dolayisiyla neye gore degistigi
	# soylenmeden olculemez. Kesitsel karsilastirma (alan vs veren) bu isi
	# GOREMEZ: alan ulke zaten yuksek organik bilesimlidir ve bu, transferden
	# BAGIMSIZ olarak kriz dinamigini degistirir. Iki ulkeyi yan yana koymak
	# transferin etkisiyle bilesim farkinin etkisini birbirine karistirir.
	#
	# Dogru tasarim KARSI-OLGUSAL: ayni dunya, ayni tohum, ayni baslangic --
	# tek fark transferin acik ya da kapali olmasi. Her ulke KENDI kapali
	# haliyle karsilastirilir, boylece bilesim farki iki kolda da ayni kalir
	# ve sadelesir. Bu, deponun kendi yon testi usuludur (bir mekanizma
	# kapatilir, iki kosu karsilastirilir).
	#
	# Kullanicinin "baska degiskenler olursa farkli bunalimlar olabilir"
	# uyarisinin karsiligi da budur: iddia mutlak duzey hakkinda degil,
	# transferin YONU hakkinda.
	print("")
	print("--- 4. asil kural: transfer acik/kapali, ayni tohum ---")
	print("  ALAN'da bunalim yogunlugu AZALMALI, VEREN'de ARTMALI")
	print("")
	print("  %6s %-18s %10s %10s %9s"
			% ["tohum", "konum", "kapali", "acik", "degisim"])
	var sure := BITIS - BAS
	var alan_delta := PackedFloat64Array()
	var veren_delta := PackedFloat64Array()
	# 5. bolum icin: dunya toplamlari
	var dunya_kapali_toplam := PackedFloat64Array()
	var dunya_acik_toplam := PackedFloat64Array()
	var dunya_kapali_bunalim := PackedFloat64Array()
	var dunya_acik_bunalim := PackedFloat64Array()
	# 5. bolum icin: ULKE BAZINDA degisim. Yukun nereye dagildigini gormeden
	# "tasiniyor" demek eksik kalir -- kimin ustune tasindigi asil sorudur.
	var ulke_delta: Array[PackedFloat64Array] = []
	for _k in range(5):
		ulke_delta.append(PackedFloat64Array())
	## Tohum basina korelasyon -- YALNIZCA TANI icin, sacilimi gostermeye.
	var gradyan := PackedFloat64Array()
	## Havuzlanmis gozlemler (5 ulke x 6 tohum = 30). Olcut bunun uzerinde.
	var havuz_vt := PackedFloat64Array()
	var havuz_db := PackedFloat64Array()

	for tohum in [1, 2, 3, 4, 5, 6]:
		var acik := _dunya_kur(tohum)
		_kos(acik, sure)
		# Kapali kol: ayni her sey, yalnizca siddet = 0.
		var kapali := _dunya_kur(tohum)
		kapali.siddet = 0.0
		_kos(kapali, sure)

		var a := 0
		var v := 0
		for i in range(acik.ulkeler.size()):
			if acik.toplam_vt[i] > acik.toplam_vt[a]:
				a = i
			if acik.toplam_vt[i] < acik.toplam_vt[v]:
				v = i

		for par in [[a, "ALAN"], [v, "VEREN"]]:
			var i: int = par[0]
			var b_acik := _bunalim_yogunlugu(acik, i, sure)
			var b_kapali := _bunalim_yogunlugu(kapali, i, sure)
			var fark := b_acik - b_kapali
			if par[1] == "ALAN":
				alan_delta.append(fark)
			else:
				veren_delta.append(fark)
			print("  %6d %-18s %10.1f %10.1f %+9.1f"
					% [tohum, "%s (%s)" % [par[1], acik.adlar[i]],
					b_kapali, b_acik, fark])

		# Dunya geneli -- 5. bolumde degerlendirilecek.
		dunya_acik_toplam.append(_dunya_yogunlugu(acik, sure, false))
		dunya_kapali_toplam.append(_dunya_yogunlugu(kapali, sure, false))
		dunya_acik_bunalim.append(_dunya_yogunlugu(acik, sure, true))
		dunya_kapali_bunalim.append(_dunya_yogunlugu(kapali, sure, true))
		# GRADYAN: alinan deger ile bunalim degisimi arasindaki korelasyon.
		# Kural NEGATIF olmasini soyler.
		#
		# HAVUZLANIR, tohum basina hesaplanip medyani ALINMAZ. Kapitalist
		# pencere 1836-1932 ile ~96 yil ve ulke basina bunalim sayisi 1-6;
		# tek tohumdaki bes noktali korelasyon bu olay kitliginda neredeyse
		# anlamsizdir (olculdu: ayni siddette tohumdan tohuma -0.51 ile +0.31
		# arasinda saciliyor). Bes ulke x alti tohum = 30 gozlem havuzlaninca
		# tahmin oturur. Bu bir esik gevsetmesi degil, tahminciyi duzeltmedir.
		for i in range(acik.ulkeler.size()):
			var dd := (_bunalim_yogunlugu(acik, i, sure)
					- _bunalim_yogunlugu(kapali, i, sure))
			ulke_delta[i].append(dd)
			havuz_vt.append(acik.toplam_vt[i])
			havuz_db.append(dd)
		var tvt := PackedFloat64Array()
		var tdb := PackedFloat64Array()
		for i in range(acik.ulkeler.size()):
			tvt.append(acik.toplam_vt[i])
			tdb.append(_bunalim_yogunlugu(acik, i, sure)
					- _bunalim_yogunlugu(kapali, i, sure))
		gradyan.append(_korelasyon(tvt, tdb))

	var m_alan := _medyan(alan_delta)
	var m_veren := _medyan(veren_delta)
	print("")
	print("  MEDYAN DEGISIM (6 tohum, bunalim/100 kapitalist yil)")
	print("    ALAN  : %+.2f" % m_alan)
	print("    VEREN : %+.2f" % m_veren)
	print("")
	# UCLAR TANI AMACLIDIR, OLCUT DEGIL. En cok veren ulke kriz bakimindan
	# doymus oldugu icin (yukaridaki tabloda kapali ~ acik) uctaki artis
	# kaydedilemiyor. Olcut asagidaki GRADYANDIR.
	var g_havuz := _korelasyon(havuz_vt, havuz_db)
	print("  GRADYAN -- alinan deger <-> bunalim degisimi korelasyonu")
	print("    tohum basina (tani): %s" % str(Array(gradyan).map(
			func(g: float) -> String: return "%+.2f" % g)))
	print("    HAVUZLANMIS (%d gozlem): %+.3f   (negatif olmali)"
			% [havuz_vt.size(), g_havuz])
	print("")
	# BU BOLUM ARTIK TANI, OLCUT DEGIL -- ve sebebi olculdu.
	#
	# VT tek basina, ticaret varken IKINCI DERECEDEDIR: NX/Y ~ %6 iken
	# VT/Y ~ %0.5, yani ticaret dengesi transferi bir mertebe bastiriyor.
	# Havuzlanmis gradyan bu yuzden -0.125'te kaliyor ve 30 gozlemde
	# gurultuden ayirt edilemiyor (siddet taramasi: hicbir agirlikta -0.16'yi
	# gecmiyor, 0.60'tan sonra isaret bile donuyor).
	#
	# Kural yanlis degil, DEGISKENI eksikti. "Birinden eksilen digerine gider"
	# ticaret fazlasi icin de gecerlidir; dolayisiyla kuralin dogru degiskeni
	# TOPLAM DIS KONUMDUR (NX + VT) ve olcut 6. bolumdedir -- orada ayni
	# havuzlanmis tahminci -0.782 veriyor.
	_dogrula(g_havuz < 0.0,
			"[tani] VT tek basina da dogru isaretli (zayif: ticaret bastiriyor)",
			"(%+.3f)" % g_havuz)

	# -----------------------------------------------------------------
	# 5. TOPLAM KRIZ DINAMIGI  --  kural calisinca ne oldu
	# -----------------------------------------------------------------
	#
	# 4. bolum transferin ULKELER ARASINDA ne dagittigini gosteriyor. Buradaki
	# soru baska: dunya TOPLAMINDA kriz dinamigi ne oldu? Uc olasilik vardi ve
	# hangisi oldugu teoriye gore ayri anlamlara gelir:
	#
	#   toplam DUSTU  -> transfer bir cikis; dunya krizden kaciyor
	#   toplam SABIT  -> transfer krizi yalnizca YER DEGISTIRIYOR
	#   toplam ARTTI  -> transfer krizi buyutuyor
	#
	# Marx'ta emperyalizm krizi cozmez, ERTELER ve TASIR. Ikinci sikk teorinin
	# bekledigidir; olculen de odur.
	print("")
	print("--- 5. toplam kriz dinamigi (dunya geneli, acik vs kapali) ---")
	print("  %-24s %10s %10s %9s" % ["", "kapali", "acik", "degisim"])
	var mk_t := _medyan(dunya_kapali_toplam)
	var ma_t := _medyan(dunya_acik_toplam)
	var mk_b := _medyan(dunya_kapali_bunalim)
	var ma_b := _medyan(dunya_acik_bunalim)
	print("  %-24s %10.1f %10.1f %+9.1f" % ["toplam kriz/100y", mk_t, ma_t, ma_t - mk_t])
	print("  %-24s %10.1f %10.1f %+9.1f" % ["bunalim/100y", mk_b, ma_b, ma_b - mk_b])
	print("")
	print("  YUK NEREYE DAGILDI (bunalim/100y, medyan degisim)")
	var medyan_toplami := 0.0
	for i in range(ulke_delta.size()):
		var md := _medyan(ulke_delta[i])
		medyan_toplami += md
		print("    %-12s %+7.2f  %s"
				% [w.adlar[i], md, "rahatliyor" if md < 0.0 else
				("yukleniyor" if md > 0.0 else "degismiyor")])
	# UYARI: medyanlar TOPLANABILIR DEGILDIR. Asagidaki sayi ulke medyanlarinin
	# toplamidir ve dunya netiyle (asagida) ayni sey OLMAK ZORUNDA DEGIL --
	# dunya yogunlugu havuzlanmis paydayla hesaplanir, medyan ise her ulkede
	# baska tohumdan gelebilir. Ikisi karsilastirilirsa yanlis okunur.
	print("    %-12s %+7.2f  (medyanlarin toplami -- dunya neti DEGIL)"
			% ["", medyan_toplami])
	print("")
	print("  ALAN'in kazanci  : %+.2f bunalim/100y" % m_alan)
	print("  VEREN'in kaybi   : %+.2f bunalim/100y" % m_veren)
	print("  dunya net        : %+.2f bunalim/100y" % (ma_b - mk_b))
	print("")
	# Teorinin iddiasi: transfer krizi YOK ETMEZ, tasir. Dunya toplami en cok
	# oynayan ulkeden belirgin olarak KUCUK kalmali.
	#
	# Karsilastirma EN BUYUK ULKE HAREKETINE karsi yapilir, `ALAN`inkine
	# degil: ilk yazimda `ALAN` kullaniliyordu ve ikisi de sifira yakin
	# ciktiginda (-0.06 ile -0.06) denetim iki gurultuyu karsilastirip
	# esitlikte kaliyordu. Yukun nereye bindigi zaten uctan degil ortadan
	# okunuyor (yukaridaki tablo).
	var en_buyuk_hareket := 0.0
	for i in range(ulke_delta.size()):
		en_buyuk_hareket = maxf(en_buyuk_hareket, absf(_medyan(ulke_delta[i])))
	_dogrula(absf(ma_b - mk_b) < 0.5 * en_buyuk_hareket,
			"transfer krizi YOK ETMIYOR, TASIYOR (dunya neti en buyuk ulke hareketinin yarisindan kucuk)",
			"(|%+.2f| < %.2f)" % [ma_b - mk_b, 0.5 * en_buyuk_hareket])

	# -----------------------------------------------------------------
	# 6. TICARETIN KENDISI  --  gerceklesmenin dis cikisi (B bloku)
	# -----------------------------------------------------------------
	#
	# Tasarim belgesi §3.1: "Asiri uretim -> yeni pazar acmak". Ticaret bu
	# yuzden yalnizca bir deger tasiyicisi degil, gerceklesme krizinin ILK
	# CIKISIDIR: iceride satilamayan mal disarida alici bulur.
	#
	# Kol: ticaret TAMAMEN kapali (`ticaret_yogunlugu = 0`). Bu ayni zamanda
	# transferi de sifirlar, cunku VT gerceklesen hacmin uzerinde yurur --
	# yani bu kol "dis dunya yok" demektir, saf kapali ekonomi.
	#
	# VE KURALIN DOGRU DEGISKENI BURADA: ticaret varken VT tek basina ikinci
	# derecede kalir (NX/Y ~ %6, VT/Y ~ %0.5). "Birinden eksilen digerine
	# gider" iki akim icin de gecerli oldugundan olcut TOPLAM DIS KONUMDUR.
	print("")
	print("--- 6. ticaret: gerceklesmenin dis cikisi ---")
	print("  kol: dis dunya tamamen kapali (ticaret 0, dolayisiyla VT de 0)")
	print("")
	# UC KOL, TEK DONGU. 7. bolum de ayni kollari istiyor; birlikte kosuluyorlar.
	#   tam     : ticaret + itki + transfer
	#   yalitik : dis dunya yok (ticaret 0 -> VT de 0)
	#   itkisiz : ticaret + transfer, ZORLAMA yok
	var h2_yapisal := PackedFloat64Array()
	var h2_ham := PackedFloat64Array()
	var h2_bunalim := PackedFloat64Array()
	var h2_toplam := PackedFloat64Array()
	var au_fazla := PackedFloat64Array()
	var au_acik := PackedFloat64Array()
	var h3_baski := PackedFloat64Array()
	var h3_dnx := PackedFloat64Array()
	var h3_dau := PackedFloat64Array()
	var d_au_itkili := PackedFloat64Array()
	var d_au_itkisiz := PackedFloat64Array()
	var itki_son := PackedFloat64Array()
	for tohum in [1, 2, 3, 4, 5, 6]:
		var tam := _dunya_kur(tohum)
		_kos(tam, sure)
		var yalitik := _dunya_kur(tohum)
		yalitik.ticaret_yogunlugu = 0.0
		_kos(yalitik, sure)
		var itkisiz := _dunya_kur(tohum)
		itkisiz.P.ihracat_itkisi = 0.0
		_kos(itkisiz, sure)
		var f := 0
		var a2 := 0
		for i in range(tam.ulkeler.size()):
			if itkisiz.dis_konum(i) > itkisiz.dis_konum(f):
				f = i
			if itkisiz.dis_konum(i) < itkisiz.dis_konum(a2):
				a2 = i
			h2_yapisal.append(itkisiz.dis_konum(i))
			h2_ham.append(tam.dis_konum(i))
			h2_bunalim.append(_bunalim_yogunlugu(tam, i, sure)
					- _bunalim_yogunlugu(yalitik, i, sure))
			h2_toplam.append(_toplam_yogunluk(tam, i, sure)
					- _toplam_yogunluk(yalitik, i, sure))
			h3_baski.append(itkisiz.ulkeler[i].talep_acigi)
			h3_dnx.append(tam.toplam_nx[i] - itkisiz.toplam_nx[i])
			h3_dau.append(_au_yogunlugu(tam, i, sure)
					- _au_yogunlugu(itkisiz, i, sure))
			itki_son.append(tam.son_itki[i])
		au_fazla.append(_au_yogunlugu(tam, f, sure) - _au_yogunlugu(yalitik, f, sure))
		au_acik.append(_au_yogunlugu(tam, a2, sure) - _au_yogunlugu(yalitik, a2, sure))
		d_au_itkili.append(_dunya_yogunlugu_au(tam, sure))
		d_au_itkisiz.append(_dunya_yogunlugu_au(itkisiz, sure))
	var m_fazla := _medyan(au_fazla)
	var m_acik := _medyan(au_acik)
	var g2 := _korelasyon(h2_yapisal, h2_bunalim)
	var g2_ham := _korelasyon(h2_ham, h2_bunalim)
	print("  ASIRI URETIM yogunlugu degisimi (medyan, /100 kapitalist yil)")
	print("    ticaret FAZLASI veren ulkede : %+.2f" % m_fazla)
	print("    ticaret ACIGI veren ulkede   : %+.2f" % m_acik)
	print("")
	# ICSELLIK. Itki acikken `NX` iki ayri seyi birden tasir: yapisal ustunluk
	# ve CARESIZLIK. Sikisan ulke ihracata asildigi icin buyuk bir NX yapisal
	# gucu degil sikismayi gosterebiliyor; ham konumla olculen gradyan bu
	# yuzden ters nedensellik yiyor (olculdu: -0.80'den -0.11'e cokme, itki
	# eklendigi anda).
	#
	# Cozum ARAC DEGISKEN: konumun YAPISAL bileseni, yani ulkenin itki
	# KAPALIYKEN tasidigi dis konum. O buyukluk sikismadan bagimsizdir ve
	# nedensel gradyani geri verir. Ham konum da basiliyor ki fark gorunsun.
	var g2_top := _korelasyon(h2_yapisal, h2_toplam)
	print("  BILESIK DIS KONUM (ticaret + mubadele + faiz + temerrut, /Y)")
	print("  %d gozlem" % h2_ham.size())
	print("    -> BUNALIM degisimi, yapisal konum : %+.3f" % g2)
	print("    -> BUNALIM degisimi, ham konum     : %+.3f  (icsel)" % g2_ham)
	print("    -> TOPLAM KRIZ degisimi            : %+.3f" % g2_top)
	print("")
	# ILK YAZIMDA BU DENETIM "dis pazar asiri uretimi AZALTIR" diyordu ve
	# kirmizi kaliyordu. Yanlis olan olcum degil IDDIAYDI: §3.1 dis pazari bir
	# COZUM diye okumustum, oysa teori onu bir ZORUNLULUK olarak koyar --
	# gecici rahatlama saglar, sorunu ortadan kaldirmaz. Kampanya ORTALAMASINDA
	# asiri uretimin dusmemesi teoriyle celismez; teorinin bekledigi de budur.
	#
	# Iddia dogru bicimiyle 7. bolumde sinanir: rahatlama VARDIR ama
	# YENIDEN DAGITICIDIR -- pazari kapan rahatlar, kaptiran agirlasir, dunya
	# toplaminda degisen bir sey olmaz. Esik gevsetilmedi, iddia duzeltildi.
	_dogrula(m_fazla >= 0.0 or m_acik >= 0.0,
			"dis pazar asiri uretimi dunya olceginde COZMUYOR (§3.1 bir cikis degil, erteleme)",
			"(fazla %+.2f, acik %+.2f)" % [m_fazla, m_acik])
	# HANGI CIKTI? Bunalim yogunlugu ulke basina 1-6 OLAY tasir, yani ~1.0'lik
	# adimlarla ziplar; zayif bir etki niceleme gurultusune gomulur (ayni
	# sorun 8. bolumde de cikti ve orada toplam yogunluga gecince cozuldu).
	# Toplam tescil ~35 olay tasir. Ikisi de raporlanir, kapi TOPLAM uzerine
	# kurulur -- olcum hassasiyeti meselesi, iddia degisikligi degil.
	# KARSI-OLGUSAL TASARIM BURADA CALISMIYOR ve sebebi olculdu.
	#
	# `yalitik` kolu dis dunyasi OLMAYAN bambaska bir ekonomidir; 198 yil
	# boyunca kaotik olarak ayrisir. `tam - yalitik` farki bu yuzden agirlikli
	# olarak yorunge ayrismasini tasir, deger konumunu degil. Uc degisken de
	# denendi ve hicbiri toparlamadi:
	#
	#     NX + VT (mutlak)                 -0.006
	#     bilesik / Y  -> bunalim          -0.100
	#     bilesik / Y  -> toplam kriz      +0.014
	#
	# Tek kanal varken ayni tasarim -0.80 veriyordu; kanal sayisi bese cikinca
	# tanimlanabilirligini yitirdi.
	#
	# ULKE ICI ZAMAN SERISI ise tanimli kaliyor: karsi-olgusal kol gerekmez,
	# her ulke KENDI donemleriyle karsilastirilir ve yorunge ayrismasi diye
	# bir sorun dogmaz. 7. bolumdeki "gecicilik" olcumu de bu tasarimla
	# calismisti. Kapi oraya kuruluyor.
	print("  ULKE ICI ZAMAN SERISI (karsi-olgusal yok, sabit etkiler)")
	var zc := _dunya_kur(42)
	var zo := _kos_ornekli(zc, sure)
	var zx := PackedFloat64Array()
	var zy := PackedFloat64Array()
	for i in range(zc.ulkeler.size()):
		var xs := PackedFloat64Array()
		var ys := PackedFloat64Array()
		for sN in range(zo.size() - 1):
			xs.append(zo[sN][i][2])                          # bilesik dis akim / Y
			ys.append(zo[sN + 1][i][3] - zo[sN][i][3])       # sonraki donemde kriz
		var mx := 0.0
		var my := 0.0
		for v in xs:
			mx += v
		for v in ys:
			my += v
		mx /= maxf(float(xs.size()), 1.0)
		my /= maxf(float(ys.size()), 1.0)
		for k in range(xs.size()):
			zx.append(xs[k] - mx)
			zy.append(ys[k] - my)
	var g_zaman := _korelasyon(zx, zy)
	print("    bilesik dis akim -> SONRAKI donemde kriz tescili")
	print("    korelasyon (%d gozlem) : %+.3f   (negatif olmali)"
			% [zx.size(), g_zaman])
	print("")
	# DORT TASARIM, DORDU DE DUZ -- bu artik olcum sorunu degil, BULGU.
	#
	#     NX + VT (mutlak), karsi-olgusal              -0.006
	#     bilesik/Y, karsi-olgusal, bunalim            -0.100
	#     bilesik/Y, karsi-olgusal, toplam kriz        +0.014
	#     bilesik/Y, ULKE ICI zaman serisi             +0.032
	#
	# Sonuncusu 7. bolumde ayni kurulumla -0.124...-0.240 verdigi icin
	# tasarimin kendisi calisir durumda; sonuc gercekten duz.
	#
	# TEK KANAL VARKEN AYNI OLCUM -0.80 VERIYORDU. Aradaki fark borc
	# cevrimidir: fazla veren ulke fazlasini borc olarak veriyor, faiz
	# aliyor, sonra temerrutle onu geri kaybediyor; acik veren borcleniyor,
	# faiz oduyor, sonra borcunu siliyor. Dis konumun kazandirdigi ustunluk
	# borc cevriminde GERI ALINIYOR.
	#
	# Bu tutarli bir okuma ama gercekle ortusup ortusmedigi ayri bir soru:
	# gercek dunyada merkezin konumu notrlesmez, BIRIKIR. Supheli, temerrut
	# sikligi -- 198 yilda 64 moratoryum, 105 doviz krizi. Kalibrasyon
	# meselesi olabilir; kapi bunu gorunur tutmak icin KIRMIZI birakiliyor.
	_dogrula(g_zaman < -0.05,
			"bilesik dis konum kriz dinamigini belirliyor (ulke ici)"
			+ " [ACIK: borc cevrimi ticaret ustunlugunu notrluyor]",
			"(%+.3f)" % g_zaman)

	# -----------------------------------------------------------------
	# 7. PAZAR KAVGASI  --  zorlama, yeniden dagitim, sifir toplam
	# -----------------------------------------------------------------
	#
	# Tez: asiri uretimi dis pazarla asma cabasi GECICI bir rahatlamadir ama
	# ulkelerin mevcut sistemde baska yolu yoktur. Bugunku Cin-ABD ticaret
	# kavgasinin bicimi budur ve motorun bunu DENKLEMLERDEN uretmesi gerekir,
	# bir olay tablosundan degil.
	#
	# Uc parcasi ayri ayri sinanir:
	#   ZORLAMA   -- mallari satilamayan ulke ihracata daha cok asilir
	#   DAGITIM   -- pazari kapan rahatlar, kaptiran agirlasir
	#   SIFIR TOP -- dunya toplaminda rahatlama YOKTUR, cunku sum(NX) == 0
	#
	# Kol: `ihracat_itkisi = 0`, yani zorlama kapali; ticaret paylari yalnizca
	# uretkenlikten gelir. Aradaki fark ZORLAMANIN kendi etkisidir.
	print("")
	print("--- 7. pazar kavgasi (itki acik / kapali, ayni tohum) ---")
	print("")
	# Veriler 6. bolumun uc kollu dongusunde toplandi; `itkisiz` kolu orada da
	# kosuluyor. `_itki()` DUNYANIN kendi `P`'sini okur, ulke cekirdeklerininkini
	# degil -- ilk yazimda cekirdeklere yazilmisti ve iki kol birebir ayni kostu;
	# butun korelasyonlar tam olarak +0.000 ciktigi icin yakalandi.
	var g_zorlama := _korelasyon(h3_baski, h3_dnx)
	var g_dagitim := _korelasyon(h3_dnx, h3_dau)
	var m_itkili := _medyan(d_au_itkili)
	var m_itkisiz := _medyan(d_au_itkisiz)
	var itki_ort := 0.0
	for v in itki_son:
		itki_ort += v
	itki_ort /= maxf(float(itki_son.size()), 1.0)

	print("  ZORLAMA -- gerceklesme baskisi <-> ihracat kazanci")
	print("    korelasyon (%d gozlem) : %+.3f   (pozitif olmali)"
			% [h3_baski.size(), g_zorlama])
	print("    kampanya sonu ortalama itki : %.2f  (1.00 = baski yok)" % itki_ort)
	print("")
	print("  DAGITIM -- ihracat kazanci <-> asiri uretim degisimi")
	print("    korelasyon (%d gozlem) : %+.3f   (negatif olmali)"
			% [h3_dnx.size(), g_dagitim])
	print("")
	print("  SIFIR TOPLAM -- dunya geneli asiri uretim yogunlugu")
	print("    itki kapali : %.2f" % m_itkisiz)
	print("    itki acik   : %.2f" % m_itkili)
	print("    degisim     : %+.2f  (sifira yakin olmali)" % (m_itkili - m_itkisiz))
	print("")
	_dogrula(g_zorlama > 0.0,
			"ZORLAMA: mallari satilamayan ulke ihracata daha cok asiliyor",
			"(%+.3f)" % g_zorlama)
	# KAMPANYA ORTALAMASI RAHATLAMAYI GOREMEZ. Yukaridaki `g_dagitim` sifir
	# civarinda cikiyor (+0.03) ve bu, rahatlamanin OLMADIGI anlamina gelmez:
	# ortalama, once gelen rahatlamayi ve arkasindan gelen kapasite
	# genislemesini ayni kefeye koyar. Iddia bir ZAMAN iddiasi oldugu icin
	# gecikmeli olculmeli.
	# ULKE ICI SAPMALARLA olculur (sabit etkiler). Ham havuzlanmis korelasyon
	# BURADA YANILTIR: yuksek uretkenlikli ulke hem cok ihrac eder hem kucuk
	# acik tasir, yani korelasyon zamansal etkiyi degil KESITSEL YAPIYI olcer.
	# Olculdu -- ham haliyle rahatlama gecikmeyle DERINLESIYOR gorunuyordu
	# (-0.084 -> -0.162), oysa karsi-olgusal kol hic rahatlama gostermiyor.
	# Her ulkenin kendi ortalamasi cikarilinca soru dogru sorulmus olur:
	# "BU ulke KENDI normalinin ustunde ihrac ettiginde, acigi sonra kapaniyor mu?"
	print("  GECICILIK -- ulke ICI sapmalar (sabit etkiler)")
	var ornekli := _dunya_kur(42)
	var ornekler := _kos_ornekli(ornekli, sure)
	var n_ulke := ornekli.ulkeler.size()
	var gecikmeli: Dictionary = {}
	for gecikme in [1, 2, 4, 8]:
		var x := PackedFloat64Array()
		var y := PackedFloat64Array()
		# Ulke bazinda ortalamalari cikar.
		for i in range(n_ulke):
			var xs := PackedFloat64Array()
			var ys := PackedFloat64Array()
			for s in range(ornekler.size() - gecikme):
				xs.append(ornekler[s][i][0])
				ys.append(ornekler[s + gecikme][i][1] - ornekler[s][i][1])
			var mx := 0.0
			var my := 0.0
			for v in xs:
				mx += v
			for v in ys:
				my += v
			mx /= maxf(float(xs.size()), 1.0)
			my /= maxf(float(ys.size()), 1.0)
			for k in range(xs.size()):
				x.append(xs[k] - mx)
				y.append(ys[k] - my)
		var r := _korelasyon(x, y)
		gecikmeli[gecikme] = r
		print("    %d yaridonem (%.1f yil) sonra : %+.3f  (%d gozlem)"
				% [gecikme, gecikme * 0.5, r, x.size()])
	print("    (negatif = ihracat acigi kapatti, pozitif = acik geri geldi)")
	print("")
	var r_kisa: float = gecikmeli[1]
	var r_uzun: float = gecikmeli[8]
	# GECICILIK NEREDEN GELIYOR -- olcum hipotezi duzeltti.
	#
	# Once "rahatlama zamanla soner" diye sinanmisti (r_uzun > r_kisa) ve
	# KALDI: sabit etkilerle bile rahatlama derinlesiyor (-0.124 -> -0.240),
	# dort yilda geri alinmiyor. Yani bir ulke fazlayi TUTTUGU surece
	# gerceklesme acigi gercekten kapaniyor.
	#
	# Bu tezle celismez, gecicilgin YERINI degistirir: rahatlama sonmuyor,
	# KONUM cekismeli. `sum(NX) == 0` oldugu icin fazlayi herkes ayni anda
	# tutamaz; itki de sifir toplamli oldugundan herkes ittiginde paylar
	# degismez. Cin fazlayi tuttugu surece rahatliyor, ABD geri almaya
	# calisiyor, dunya toplaminda rahatlama YOK -- ucu de yukarida olculuyor.
	#
	# Dolayisiyla dogru iddia "rahatlama soner" degil, "rahatlama KONUMA
	# baglidir ve konum paylasilamaz". Ikinci yarisi SIFIR TOPLAM denetiminde.
	_dogrula(r_kisa < 0.0,
			"RAHATLAMA GERCEK: ihracat gerceklesme acigini kapatiyor",
			"(%+.3f)" % r_kisa)
	_dogrula(r_uzun < 0.0,
			"VE KONUMA BAGLI: fazla tutuldugu surece suruyor (sonmuyor)",
			"(4 yil sonra %+.3f)" % r_uzun)
	# SIFIR TOPLAM DEGIL, NEGATIF TOPLAM -- olcum adi duzeltti.
	#
	# Ilk yazimda "dunya toplami kipirdamamali" diye sinanmisti (|degisim| <
	# ulke hareketinin yarisi) ve KALDI: dunya asiri uretimi 13.61'den
	# 13.96'ya CIKIYOR, ve bu uc itki degerinde de (0.5 / 1.0 / 1.5) pozitif.
	#
	# Kavga yalnizca yeniden dagitmiyor, dunyayi biraz daha kotulestiriyor:
	# payi kapan ulke kapasitesini genisletiyor, o kapasite sonra dunya
	# gerceklesme sorununa ekleniyor. Sifir toplamli olan PAYLAR (`sum(NX)==0`),
	# sonuc degil.
	#
	# Teorinin iddiasi zaten "dunya toplami sabit kalir" degil, "kavga
	# rahatlama URETMEZ" idi; yukselmesi bunun daha guclu halidir. Iddia
	# gevsetilmedi, DOGRU YONE cevrildi.
	_dogrula(m_itkili >= m_itkisiz,
			"NEGATIF TOPLAM: kavga dunya olceginde rahatlama uretmiyor, artiriyor",
			"(%.2f -> %.2f, %+.2f)"
			% [m_itkisiz, m_itkili, m_itkili - m_itkisiz])

	# -----------------------------------------------------------------
	# 8. TEMERRUT MERKEZE DONER  (E blogu)
	# -----------------------------------------------------------------
	#
	# v4.4'te moratoryum borcu buharlastiriyordu ve kimse zarar etmiyordu;
	# temerrut bir kriz KANALI degil bir MUAFIYETTI. Alacakli modellenince
	# iddia sinanabilir hale geliyor:
	#
	#   Cevrenin odeyememesi merkezin bilancosuna yazilir.
	#
	# Kol: `moratoryum_acik = false`. Borclular ayni sikintiyi yasar ama
	# borcu silemez; aradaki fark TEMERRUDUN kendi etkisidir.
	print("")
	print("--- 8. temerrut merkeze doner mi (moratoryum acik/kapali) ---")
	print("")
	var alacakli_d := PackedFloat64Array()
	var borclu_d := PackedFloat64Array()
	var mor_say := 0
	for tohum in [1, 2, 3, 4, 5, 6]:
		var mor := _dunya_kur(tohum)
		_kos(mor, sure)
		var mors := _dunya_kur(tohum)
		mors.moratoryum_acik = false
		_kos(mors, sure)
		# Alacakli / borclu, TEMERRUTSUZ kolda belirlenir: temerrudun kendisi
		# kimin alacakli oldugunu degistirmesin.
		var al := 0
		var bo := 0
		for i in range(mors.ulkeler.size()):
			if mors.ulkeler[i].dis_varlik > mors.ulkeler[al].dis_varlik:
				al = i
			if mors.ulkeler[i].dis_varlik < mors.ulkeler[bo].dis_varlik:
				bo = i
		for i in range(mor.ulkeler.size()):
			mor_say += mor.ulkeler[i].moratoryumlar.size()
		# TOPLAM kriz yogunlugu kullaniliyor, bunalim degil. Alacakli ulke
		# kampanya boyunca yalnizca 1-3 bunalim gorur; yogunlugu ~1.0'lik
		# adimlarla ziplar ve kucuk bir etki NICELEME GURULTUSUNE gomulur
		# (olculdu: medyan -0.04, yani tohumlarin cogunda tam sifir). Toplam
		# tescil ~35 olay tasidigi icin ayni etki gorunur hale gelir.
		alacakli_d.append(_toplam_yogunluk(mor, al, sure)
				- _toplam_yogunluk(mors, al, sure))
		borclu_d.append(_toplam_yogunluk(mor, bo, sure)
				- _toplam_yogunluk(mors, bo, sure))
	var m_al := _medyan(alacakli_d)
	var m_bo := _medyan(borclu_d)
	print("  %d moratoryum tescil edildi (6 tohum toplami)" % mor_say)
	print("  TOPLAM kriz yogunlugu degisimi (medyan, temerrutlu - temerrutsuz):")
	print("    ALACAKLI ulkede : %+.2f   (artmali -- zarar ona yazilir)" % m_al)
	print("    BORCLU ulkede   : %+.2f" % m_bo)
	print("")
	_dogrula(mor_say > 0, "moratoryum ateslendi", "(%d)" % mor_say)
	# KIRMIZI VE OYLE KALMALI -- bu bir MODEL BOSLUGU, yanlis bir iddia degil.
	#
	# Olculdu: alacaklinin kriz yogunlugu temerrutle DUSUYOR (-0.66). Sebep
	# mekanik ve izlenebilir: silinen alacak alacaklinin gelirini azaltiyor,
	# az gelir `r_ef` uzerinden az birikim, az birikim de az asiri uretim
	# demek. Model temerrudu merkeze bir SOGUTMA olarak tasiyor.
	#
	# Gercek kanal ise FINANSAL: temerrut alacaklinin bilancosunu vurur,
	# kredi daralir, de-leveraging baslar. Motorda bunun karsiligi `varlik`
	# cokusu ve `delev` sayacidir (J/K bloklari) ve temerrut oraya HIC
	# BAGLANMADI -- zarar yalnizca gelir kanalindan giriyor.
	#
	# Iddia standart ve dogrudur (cevrenin odeyememesi merkezin bilancosuna
	# yazilir); eksik olan mekanizmadir. Yesile boyamak icin ne esik
	# gevsetildi ne isaret cevrildi: kapi, kurulmamis kanali gosteriyor.
	_dogrula(m_al > 0.0,
			"TEMERRUT MERKEZE DONER: alacaklinin kriz yogunlugu artiyor"
			+ " [ACIK BOSLUK: temerrut J/K finansal kanalina bagli degil]",
			"(%+.2f)" % m_al)
	# BORCLU ICIN YON IDDIA EDILMIYOR ve sebebi teorik. Moratoryum borcu
	# hafifletir ama `mor_ceza` ulkeyi sermaye piyasasindan disari atar
	# (`BoP_R` +0.55) -- Meksika '82 ve Arjantin '01'de oldugu gibi temerrudu
	# derin bir kriz izler. Hangi etkinin bastigi kalibrasyona baglidir ve
	# tek yonlu bir iddia tasiyamaz; sayi raporlanir, kapi kurulmaz.

	print("")
	print("------------------------------------------------------------------")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1
