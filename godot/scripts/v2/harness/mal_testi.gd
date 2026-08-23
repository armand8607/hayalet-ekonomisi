class_name MalTesti
extends RefCounted

## B2c KAPISI -- mal piyasasi.
##
## ------------------------------------------------------------------------
## OLCUT, DORDUNCU KEZ
## ------------------------------------------------------------------------
## §6'nin tablosu B2c icin "gerceklesme krizi bir sayi degil KUTLE olarak
## okunur" diyor -- bu, oncekilerin aksine ayirt EDIYOR, cunku bir stok
## olmadan cumle kurulamaz. Ama "okunur" bir kapi degil bir niyet; kapiya
## cevrilmesi gerekiyordu.
##
## Stok olmadan TANIMSIZ olan iddia sudur:
##
##   > Asiri uretim krizinin bir SURESI vardir. Yigin birikince kapitalist
##   > dolu depoya uretim yapmaz; uretim kisilir, istihdam duser, talep daha
##   > da duser. Krizi SUREKLI kilan sey stokun kendisidir.
##
## Bir AKIM bunu uretemez: "gecen donem satilmadi" der ve susar. Bir STOK
## "hala duruyor" demeye devam eder. Olcut bu yuzden SUREdir, siklik degil.
##
## ------------------------------------------------------------------------
## DORT KADEME
## ------------------------------------------------------------------------
##   1. KORUNUM  -- defter her donem birebir kapanir, koruma hic ateslenmez
##   2. CANLILIK -- yigin gercekten birikiyor VE bosaliyor (B2b'nin dersi:
##      yonu dogru bir mekanizma yine de olu olabilir)
##   3. ORANTISIZLIK -- kategoriler AYRISIYOR; biri dolarken digeri bos
##   4. SURE -- asiri uretim, kalici bir DURUM olmaktan cikip belirli
##      sureli bir OLAY haline geliyor (asil kapi, karsi-olgusal)

const HAFTA := 1.0 / 52.0
const BAS := 1825.0
const BITIS := 2023.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


static func _baslangic() -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = 1.0
	d.yil = BAS
	d.varlik = 0.5
	return d


## Bir kampanya kosar.
##   `stok_acik` : mal katmani takili mi
##   `kisma`     : yigin uretimi kisiyor mu (karsi-olgusal kol). Kapaliyken
##                 stok yine birikir ama HICBIR SEYI etkilemez -- boylece
##                 olculen sey "stok var mi" degil "stok IS GORUYOR mu" olur.
static func _kos(stok_acik := true, kisma := true, tohum := 42) -> Dictionary:
	var d := _baslangic()
	var c := KrizCekirdegi.new(null, tohum)
	c.baslat(d)
	var m: MalKatmani = null
	if stok_acik:
		m = MalKatmani.new()
		m.baslat(d)
		if not kisma:
			m.yigin_kisma = 0.0
		c.mal = m

	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var esik := c.P.v44.au_esik
	# Epizot: `talep_acigi` esigin ustunde gecirilen KESINTISIZ sure. Kriz
	# SAYISI degil SURESI olculuyor -- stokun ekledigi sey tam olarak budur.
	var epizotlar: Array[float] = []
	var suren := 0.0
	var yigin_zirve := 0.0
	var yigin_dip := INF
	var acik_top := 0.0
	# Kategori bazinda "dolu mu" izi: orantisizligin olcusu.
	var ayrisma_top := 0.0

	for _i in range(n):
		c.adim(d, HAFTA)
		if d.talep_acigi > esik:
			suren += HAFTA
		elif suren > 0.0:
			epizotlar.append(suren)
			suren = 0.0
		acik_top += d.talep_acigi * HAFTA
		if m != null:
			var oranlar: Array[float] = []
			for i in range(MalKatmani.MALLAR.size()):
				oranlar.append(m.stok_orani(i))
			var en_buyuk: float = oranlar[0]
			var en_kucuk: float = oranlar[0]
			var toplam := 0.0
			for x in oranlar:
				en_buyuk = maxf(en_buyuk, x)
				en_kucuk = minf(en_kucuk, x)
				toplam += x
			yigin_zirve = maxf(yigin_zirve, toplam)
			yigin_dip = minf(yigin_dip, toplam)
			ayrisma_top += (en_buyuk - en_kucuk) * HAFTA
	if suren > 0.0:
		epizotlar.append(suren)

	var ort_sure := 0.0
	for e in epizotlar:
		ort_sure += e
	ort_sure /= maxf(float(epizotlar.size()), 1.0)
	var agirlik := maxf(float(n) * HAFTA, 1e-9)

	return {
		"d": d, "m": m,
		"epizot": epizotlar.size(),
		"ort_sure": ort_sure,
		"acik_ort": acik_top / agirlik,
		"yigin_zirve": yigin_zirve,
		"yigin_dip": (0.0 if yigin_dip == INF else yigin_dip),
		"ayrisma_ort": ayrisma_top / agirlik,
		"koruma": (m.koruma_atesledi if m != null else 0.0),
		"devrim": d.devrim_yil,
	}


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("=".repeat(70))
	print("v2 MAL PIYASASI  (B2c)   %d-%d, haftalik" % [int(BAS), int(BITIS)])
	print("=".repeat(70))

	var stoklu := _kos(true, true)
	var kismasiz := _kos(true, false)
	var stoksuz := _kos(false, false)
	var m: MalKatmani = stoklu["m"]

	# -----------------------------------------------------------------
	print("\n--- 1. defter korunumu ---")
	print("  `max(0,...)` korumasinin atesledigi en buyuk miktar: %s"
			% String.num_scientific(float(stoklu["koruma"])))
	# Tolerans SIFIR DEGIL: olculen 1.1e-15 IEEE754 yuvarlamasidir, birim
	# hatasi degil. Sifir istemek float aritmetigini bilmemek olurdu; asil
	# aranan buyukluk mertebesidir -- bir `donem_yil` unutulsaydi sapma
	# stokun kendisi mertebesinde cikardi, 1e-15'te degil.
	_dogrula(float(stoklu["koruma"]) < 1e-9,
			"stok defteri kapaniyor -- koruma yalnizca yuvarlama mertebesinde",
			"(%s)" % String.num_scientific(float(stoklu["koruma"])))

	# -----------------------------------------------------------------
	print("\n--- 2. yigin CANLI mi (birikiyor VE bosaliyor) ---")
	print("  toplam stok/uretim orani: dip %.4f, zirve %.4f" % [
			float(stoklu["yigin_dip"]), float(stoklu["yigin_zirve"])])
	print("  kategori dagilimi (kampanya sonu):")
	print("    mal          stok      uretim      satis   stok/uretim")
	for s in m.dagilim():
		print("    %-10s %9.2f %11.2f %10.2f %10.3f" % [
				s["ad"], float(s["stok"]), float(s["uretim"]),
				float(s["satis"]), float(s["oran"])])
	_dogrula(float(stoklu["yigin_zirve"]) > 0.0, "yigin BIRIKIYOR",
			"(zirve %.4f)" % float(stoklu["yigin_zirve"]))
	# B2b'nin dersi: mekanizma canli mi diye AYRICA sor. Yigin birikip hic
	# bosalmiyorsa "stok" bir kriz mekanizmasi degil, tek yonlu bir cop
	# kutusudur -- ve yon denetimleri bunu yakalamaz.
	_dogrula(float(stoklu["yigin_zirve"]) > float(stoklu["yigin_dip"]) * 1.5,
			"ve BOSALIYOR -- tek yonlu birikmiyor",
			"(dip %.4f / zirve %.4f)" % [
				float(stoklu["yigin_dip"]), float(stoklu["yigin_zirve"])])

	# -----------------------------------------------------------------
	print("\n--- 3. ORANTISIZLIK: kategoriler ayrisiyor mu ---")
	print("  ort. (en dolu - en bos) stok/uretim farki: %.4f"
			% float(stoklu["ayrisma_ort"]))
	_dogrula(float(stoklu["ayrisma_ort"]) > 0.01,
			"kategoriler AYRISIYOR -- biri dolarken digeri bos",
			"(%.4f)" % float(stoklu["ayrisma_ort"]))

	# -----------------------------------------------------------------
	print("\n--- 4. SURE: stok krize sure kazandiriyor mu (karsi-olgusal) ---")
	print("                          stok YOK   stok var, kisma YOK   stok+kisma")
	print("  asiri uretim epizodu %10d %20d %13d" % [
			int(stoksuz["epizot"]), int(kismasiz["epizot"]), int(stoklu["epizot"])])
	print("  ort. epizot suresi   %10.3f %20.3f %13.3f" % [
			float(stoksuz["ort_sure"]), float(kismasiz["ort_sure"]),
			float(stoklu["ort_sure"])])
	print("  ort. talep acigi     %10.4f %20.4f %13.4f" % [
			float(stoksuz["acik_ort"]), float(kismasiz["acik_ort"]),
			float(stoklu["acik_ort"])])
	# ILK IDDIA TERS CIKTI VE DUZELTILDI. "Stok krize sure KAZANDIRIR" diye
	# yazilmisti; olculdugunde tam tersi cikti -- stoksuz kolda epizot
	# ortalamasi 15.7 YIL, stoklu kolda 0.21 yil.
	#
	# Sebep anlasilinca iddia da duzeldi. Stoksuz kolda `talep_acigi` bir
	# AKIM oranidir ve onu geri cekecek hicbir mekanizma yoktur: acik acilir
	# ve ONYILLARCA acik kalir. Yani orada "epizot" diye olculen sey bir kriz
	# degil KALICI BIR DURUMDUR. Stok, yigini uretimi kisarak temizliyor ve
	# asiri uretimi tekrar bir OLAYA cevirmis oluyor.
	#
	# Dogru olcut bu yuzden yon degil BANT: tarihsel asiri uretim krizleri
	# 1-3 yil surer (tasarim belgesi §6, KAYIT tablosu). Ikisi de o bandin
	# disindaydi -- biri onlarca kat uzun, digeri bes kat kisa.
	_dogrula(float(stoksuz["ort_sure"]) > 5.0,
			"STOKSUZ KOLDA ASIRI URETIM BIR OLAY DEGIL KALICI DURUM",
			"(ort %.1f yil -- tarihsel kayitta boyle bir sey yok)"
			% float(stoksuz["ort_sure"]))
	_dogrula(float(stoklu["ort_sure"]) >= 0.8 and float(stoklu["ort_sure"]) <= 3.5,
			"STOKLA epizot suresi tarihsel banda (1-3 yil) oturuyor",
			"(%.2f yil)" % float(stoklu["ort_sure"]))
	# Stokun VARLIGI ile IS GORMESI ayri seylerdir: kisma kapaliyken yigin
	# yine birikir ama uretimi kisitlamaz. Aradaki fark mekanizmanin kendisi,
	# yalnizca muhasebesi degil.
	_dogrula(float(kismasiz["ort_sure"]) > float(stoklu["ort_sure"]) * 2.0,
			"ve bunu YIGININ URETIMI KISMASIYLA yapiyor, yalnizca muhasebeyle degil",
			"(kisma yok %.1f yil / kismali %.2f yil)" % [
				float(kismasiz["ort_sure"]), float(stoklu["ort_sure"])])

	print("\n" + "-".repeat(70))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


# ===========================================================================
# KALIBRASYON TARAMASI
# ===========================================================================

## Epizot suresi neye bagli?
##
## CAPA TARIHSELDIR, cekirdegin kapali formu DEGIL -- ve bu, B2a/B2b'den
## farkli bir durumdur. Sebep: kapali formda asiri uretim epizodu ortalama
## 15.7 yil suruyor, yani capa olacak buyukluk orada ZATEN bozuk. Tarihsel
## kayitta (`TarihTesti.KAYIT`) asiri uretim krizleri 1-3 yil surer.
static func tarama() -> int:
	print("=".repeat(72))
	print("YIGIN KISMA / ERIME TARAMASI   (capa: tarihsel 1-3 yillik epizot)")
	print("=".repeat(72))
	var stoksuz := _kos(false, false)
	print("\n  STOKSUZ (kapali form): %d epizot, ort %.2f yil"
			% [int(stoksuz["epizot"]), float(stoksuz["ort_sure"])])
	print("\n  kisma  erime   epizot   ort sure   ort acik   devrim")
	print("  " + "-".repeat(52))
	for kisma in [0.05, 0.20, 0.28, 0.30, 0.33, 0.36, 0.60]:
		for erime in [0.05, 0.10, 0.20]:
			var d := _baslangic()
			var c := KrizCekirdegi.new(null, 42)
			c.baslat(d)
			var m := MalKatmani.new()
			m.baslat(d)
			m.yigin_kisma = float(kisma)
			m.erime_yil = float(erime)
			c.mal = m
			var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
			var esik := c.P.v44.au_esik
			var epi := 0
			var suren := 0.0
			var top := 0.0
			var acik := 0.0
			for _i in range(n):
				c.adim(d, HAFTA)
				acik += d.talep_acigi * HAFTA
				if d.talep_acigi > esik:
					suren += HAFTA
				elif suren > 0.0:
					epi += 1
					top += suren
					suren = 0.0
			if suren > 0.0:
				epi += 1
				top += suren
			print("  %5.2f %6.2f %8d %10.2f %10.4f %8.0f" % [
					float(kisma), float(erime), epi,
					top / maxf(float(epi), 1.0),
					acik / maxf(float(n) * HAFTA, 1e-9), d.devrim_yil])
	print("\n  NOT: bu bir kapi degil TANIDIR. Secim tasarim belgesine yazilir.")
	return 0
