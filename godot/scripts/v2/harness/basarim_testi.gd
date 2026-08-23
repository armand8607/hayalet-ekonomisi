class_name BasarimTesti
extends RefCounted

## B6 -- OLCEK. Ulke sayisi buyudukce tik maliyeti nasil buyuyor.
##
## ------------------------------------------------------------------------
## NEDEN AYRI BIR OLCUM
## ------------------------------------------------------------------------
## §6'nin tablosu B6 icin "~100 ulke, kabul edilebilir tik suresi" diyor.
## "Kabul edilebilir" tek basina olculebilir bir sey degil -- hangi makinede,
## hangi kurulumda? Bu yuzden olcum UC parcali:
##
##   1. MUTLAK maliyet (ms/tik) -- makineye baglidir, KAYIT olarak durur.
##   2. OLCEKLENME BICIMI -- makineden bagimsizdir ve asil sorulacak sey
##      budur: maliyet ulke sayisinda dogrusal mi, karesel mi, daha kotu mu?
##   3. KAMPANYA BUTCESI -- 54 ulkedeki olculmus maliyete GORE, yani ayni
##      makinede alinan iki sayinin orani. Mutlak esik koymadan "cok mu
##      yavasladi" sorusuna cevap verir.
##
## Maliyetin iki bileseni var ve ikisi ayri buyur:
##
##   ULKE DONGUSU  : n ile dogrusal (her ulke kendi cekirdegini kosar)
##   CIFT DONGUSU  : n^2 ile karesel (ticaret, transfer, abluka matrisi)
##
## 54 ulkede 1431 cift var, 100 ulkede 4950 -- yani ulke sayisi 1.85 kat
## artarken cift sayisi 3.5 kat artiyor. Karesel terimin ne zaman baskin
## hale geldigi olculmeli, tahmin edilmemeli.

const HAFTA := 1.0 / 52.0
const BAS := 1836.0
## Olcum icin kosulan sure. Kisa tutulur: burada olculen sey YORUNGE degil
## MALIYET, ve maliyet tik basina sabit oldugu icin uzun kosmak bilgi
## eklemez, yalnizca kapiyi yavaslatir.
const OLCUM_YIL := 6.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


## Verilen sayida ulkeyle bir dunya kosar; tik basina ms dondurur.
##
## ULKELER HARITA KADROSUNDAN, ilk n tanesi. Rastgele secilseydi olcum
## kosudan kosuya oynardi; kadro sirali oldugu icin (kod alfabetik) ayni n
## her zaman ayni kumeyi verir.
static func _olc(n: int, tohum: int = 42) -> Dictionary:
	var hepsi := Harita.simule_kodlar()
	var kodlar := PackedStringArray()
	for i in range(mini(n, hepsi.size())):
		kodlar.append(hepsi[i])
	var w := Harita.dunya_kur(kodlar, tohum, BAS)
	var tik := Oran.donem_sayisi(OLCUM_YIL, HAFTA)
	# ISINMA: ilk tikler onbellek kurulumunu ve ilk tahsisleri tasir.
	for _i in range(20):
		w.adim(HAFTA)
	var basla := Time.get_ticks_usec()
	for _i in range(tik):
		w.adim(HAFTA)
	var sure := float(Time.get_ticks_usec() - basla) / 1000.0
	return {
		"n": w.ulkeler.size(),
		"tik": tik,
		"ms_tik": sure / float(tik),
		"cift": w.ulkeler.size() * (w.ulkeler.size() - 1) / 2,
	}


## TANI -- olcek taramasi. Maliyet modelini `a*n + b*n^2` olarak cozer.
static func tarama() -> int:
	print("")
	print("V2 OLCEK TARAMASI  (B6) -- tik maliyeti ulke sayisiyla nasil buyuyor")
	print("==================================================================")
	var kadro := Harita.simule_kodlar().size()
	print("  kadro: %d simule ulke" % kadro)
	print("")
	print("   ulke    cift   ms/tik   ms/tik/ulke   kampanya (13728 tik)")
	print("  " + "-".repeat(62))
	var olcumler: Array = []
	for n in [5, 10, 20, 35, kadro]:
		if n > kadro:
			continue
		var o := _olc(n)
		olcumler.append(o)
		print("  %5d %7d %8.2f %13.3f %14.1f sn" % [
				int(o["n"]), int(o["cift"]), float(o["ms_tik"]),
				float(o["ms_tik"]) / float(o["n"]),
				float(o["ms_tik"]) * 13728.0 / 1000.0])

	# EN KUCUK KARELER, iki terimli model: ms = a*n + b*n^2.
	# Sabit terim YOK -- sifir ulkeli bir dunyanin maliyeti sifirdir ve
	# sabit koymak modeli veriye "uydurur", aciklamaz.
	var s_nn := 0.0
	var s_nq := 0.0
	var s_qq := 0.0
	var s_ny := 0.0
	var s_qy := 0.0
	for o in olcumler:
		var n := float(o["n"])
		var q := n * n
		var y := float(o["ms_tik"])
		s_nn += n * n
		s_nq += n * q
		s_qq += q * q
		s_ny += n * y
		s_qy += q * y
	var det := s_nn * s_qq - s_nq * s_nq
	var a := 0.0
	var b := 0.0
	if absf(det) > 1e-12:
		a = (s_ny * s_qq - s_qy * s_nq) / det
		b = (s_qy * s_nn - s_ny * s_nq) / det
	print("")
	print("  MODEL  ms/tik = %.5f*n + %.7f*n^2" % [a, b])
	print("  ulke dongusu ile cift dongusunun BASA BAS noktasi: n = %.0f"
			% (a / maxf(b, 1e-12)))
	for hedef in [54, 100, 150]:
		var tahmin := a * float(hedef) + b * float(hedef) * float(hedef)
		print("  tahmin n=%3d : %7.2f ms/tik,  kampanya %6.1f sn" % [
				hedef, tahmin, tahmin * 13728.0 / 1000.0])
	print("")
	print("  NOT: bu bir kapi degil TANIDIR. Mutlak sayilar MAKINEYE baglidir.")

	# --- SAVAS SIKLIGI ULKE SAYISIYLA NASIL DEGISIYOR -------------------
	# B4 bunu SENTETIK bir dunyada olcmustu (katmansiz, tek merdiven) ve
	# artan buldu: 5 ulke 0.27, 10 ulke 0.34, 20 ulke 0.79. B6'nin dunyasi
	# baska: harita kadrosu, uc konum basamagi, TAM KATMAN YIGINI takili.
	# Ayni sayiyi ayni kurulumda ulke sayisina gore okumak, "kadro mu
	# degisti kurulum mu" sorusunu ayirmanin tek yolu.
	print("")
	print("  SAVAS SIKLIGI (ayni kurulum, 100 yil, tohum 42)")
	print("   ulke   ilan   savas/ulke-yuzyil   zaman_pay")
	print("  " + "-".repeat(48))
	# 113 BURADA YOK: tam kadro olcumunu B6 KAPISI zaten yapiyor (0.23) ve
	# burada tekrarlamak taramaya 240 saniye ekliyordu. Tablo ulke sayisinin
	# bu kurulumda sikligi neredeyse hic degistirmedigini gostermeye yeter.
	for n in [10, 20, 40]:
		if n > kadro:
			continue
		print("  %5d %6d %18.2f %11.3f" % _savas_olc(n))

	# SIKLIK CARPANI, OYUNUN DUNYASINDA. B4 bunu 20 ulkelik SENTETIK bir
	# kolda secti (5.0); yukaridaki tablo o secimin buraya tasinmadigini
	# gosteriyor. Tarama 40 ulkede kosuyor -- tablo ulke sayisinin bu
	# kurulumda sikligi neredeyse hic degistirmedigini gosterdigi icin
	# 113'te kosmanin bilgi degeri yok, maliyeti uc kat.
	print("")
	print("  SIKLIK CARPANI (40 ulke, ayni kurulum, 100 yil)")
	print("  siklik   ilan   savas/ulke-yuzyil   zaman_pay")
	print("  " + "-".repeat(48))
	for siklik in [5.0, 15.0, 30.0, 60.0]:
		var r := _savas_olc(40, 42, 100.0, float(siklik))
		print("  %6.1f %6d %18.2f %11.3f" % [siklik, r[1], r[2], r[3]])
	print("  tarihsel capa: 1-4 savas/ulke-yuzyil, zamanin %5-15'i")
	return 0


## Bir dunyada 100 yillik savas sikligini olcer.
## Doner: [n, ilan, savas/ulke-yuzyil, zaman_pay]
static func _savas_olc(n: int, tohum: int = 42, yil: float = 100.0,
		siklik: float = -1.0) -> Array:
	var hepsi := Harita.simule_kodlar()
	var kodlar := PackedStringArray()
	for i in range(mini(n, hepsi.size())):
		kodlar.append(hepsi[i])
	var w := Harita.dunya_kur(kodlar, tohum, BAS)
	if siklik >= 0.0:
		w.savas.P.savas_siklik = siklik
	var tik := Oran.donem_sayisi(yil, HAFTA)
	for _i in range(tik):
		w.adim(HAFTA)
	var savas_donem := 0
	for d in w.ulkeler:
		savas_donem += d.savas_toplam
	var nf := float(w.ulkeler.size())
	return [w.ulkeler.size(), w.savas.ilan_sayisi,
			float(w.savas.ilan_sayisi) / (nf * yil / 100.0),
			float(savas_donem) / (nf * float(tik))]


# ===========================================================================
# B6 KAPISI
# ===========================================================================
## Tam kadroda kosulan kampanya. 100 yil, cunku iki olcum de zaman ister:
## savas siklik bandi ve korunum ozdeslikleri. Tam kampanya (264 yil) bu
## olcumlere bir sey eklemez, yalnizca kapiyi uc katina cikarirdi.
const KAPI_YIL := 100.0


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("")
	print("V2 OLCEK -- B6 KAPISI")
	print("==================================================================")

	var kodlar := Harita.simule_kodlar()
	_dogrula(kodlar.size() >= 100, "simule kadro >= 100 (§5.6 'tam dunya')",
			"= %d ulke" % kodlar.size())

	# --- TAM KADRODA BIR KAMPANYA -------------------------------------
	var w := Harita.dunya_kur(kodlar, 42, BAS)
	var tik := Oran.donem_sayisi(KAPI_YIL, HAFTA)
	var basla := Time.get_ticks_msec()
	for _i in range(tik):
		w.adim(HAFTA)
	var sure := float(Time.get_ticks_msec() - basla)
	var ms_tik := sure / float(tik)
	print("")
	print("  %d ulke x %.0f yil = %d tik, %.1f sn (%.2f ms/tik)"
			% [w.ulkeler.size(), KAPI_YIL, tik, sure / 1000.0, ms_tik])

	# --- 1. KORUNUM OLCEK ALTINDA -------------------------------------
	# `--v2-dunya` bunlari BES ulkede olcuyor. Korunum ozdeslikleri cift
	# uzerinde tanimli oldugu icin risk tam da olcekte: 6328 ciftte biriken
	# yuvarlama, bes ciftte gorunmez. Ozdeslik gercekten ozdeslikse ulke
	# sayisindan BAGIMSIZ olmali -- sinanan bu.
	print("")
	print("1. KORUNUM -- ozdeslikler ulke sayisindan bagimsiz mi")
	print("------------------------------------------------------------------")
	_dogrula(w.en_buyuk_korunum_hatasi < 1e-9,
			"deger transferi korunuyor (sum VT = 0)",
			"en buyuk bagil hata %s" % w.en_buyuk_korunum_hatasi)
	_dogrula(w.en_buyuk_ticaret_hatasi < 1e-9,
			"ticaret korunuyor (sum NX = 0)",
			"en buyuk bagil hata %s" % w.en_buyuk_ticaret_hatasi)
	_dogrula(w.en_buyuk_borc_hatasi < 1e-9,
			"borc korunuyor (alacak = borc)",
			"en buyuk bagil hata %s" % w.en_buyuk_borc_hatasi)

	# --- 2. MALIYET BICIMI --------------------------------------------
	# Mutlak sure MAKINEYE baglidir, dolayisiyla esik olamaz. Ama BICIM
	# baglidir degil: maliyet a*n + b*n^2 ise, ulke sayisini k kat
	# buyutmek maliyeti en fazla k^2 kat buyutur. Daha kotusu (gizli bir
	# kubik terim, olcekle patlayan bir sozluk) BURADA yakalanir.
	print("")
	print("2. MALIYET BICIMI -- gizli bir kubik terim var mi")
	print("------------------------------------------------------------------")
	var kucuk := _olc(20)
	var oran_n := float(w.ulkeler.size()) / 20.0
	var oran_maliyet := ms_tik / maxf(float(kucuk["ms_tik"]), 1e-9)
	print("     n=20 %.2f ms/tik  ->  n=%d %.2f ms/tik   (ulke %.2fx, maliyet %.2fx)"
			% [float(kucuk["ms_tik"]), w.ulkeler.size(), ms_tik,
			oran_n, oran_maliyet])
	_dogrula(oran_maliyet < oran_n * oran_n,
			"maliyet en fazla KARESEL buyuyor",
			"%.2fx < %.2fx" % [oran_maliyet, oran_n * oran_n])

	# --- 3. SAVAS SIKLIGI, ~100 ULKEDE --------------------------------
	# B4 bunu 20 ulkede kalibre etti ve NOTU DUSTU: "olcut B6'da ~100
	# ulkeyle yeniden okunmalidir". Sebep yapisal -- baglayici kisit
	# olasilik degil HEDEF BULUNABILIRLIGIYDI, ve o ulke sayisiyla artar.
	print("")
	print("3. SAVAS SIKLIGI -- B4'un capasi ~100 ulkede hala tutuyor mu")
	print("------------------------------------------------------------------")
	var savas_donem := 0
	for d in w.ulkeler:
		savas_donem += d.savas_toplam
	var n_ulke := float(w.ulkeler.size())
	var zaman_pay := float(savas_donem) / (n_ulke * float(tik))
	var ulke_yuzyil := n_ulke * KAPI_YIL / 100.0
	var siklik := float(w.savas.ilan_sayisi) / ulke_yuzyil
	print("     %d ilan, zamanin %%%.1f'i savasta, %.2f savas/ulke-yuzyil"
			% [w.savas.ilan_sayisi, zaman_pay * 100.0, siklik])
	print("     tarihsel capa: zamanin %5-15'i, ulke basina yuzyilda 1-4 savas")
	# KAPI BILEREK TERS YONDE -- B5'in `bolunme` denetimiyle ayni bicimde.
	#
	# Olculdu ve capa TUTMUYOR: 0.23 savas/ulke-yuzyil, capa 1-4. Carpani
	# 38'e cikarmak sikligi bant icine sokuyor (1.45, zamanin %11.1'i) AMA
	# §3.1'in nedensel imzasini kiriyor: savasa girenin kar orani, o anda
	# digerlerinin ALTINDA olmaktan cikiyor (-0.0067 -> +0.00235). Deponun
	# hiyerarsisinde bant ayarlanabilir, yon ayarlanamaz -- bu yuzden
	# carpan yerinde birakildi ve eksiklik KAYIT olarak duruyor
	# (bkz. `kriz_param.gd::savas_siklik`, tasarim belgesi §6h).
	#
	# Denetim "hala dusuk mu" diye soruyor: ilan olasiligi doyuma gitmeyen
	# bir bicimde yeniden yazildigi gun BU KAPI DUSER ve belge guncellenir.
	_dogrula(siklik < 1.0,
			"KAYIT: savas sikligi capanin ALTINDA (carpan secici degil)",
			"%.2f < 1.0 capa -- §6h" % siklik)
	_dogrula(zaman_pay < 0.05,
			"KAYIT: savasta gecen zaman capanin ALTINDA",
			"%%%.1f < %%5 -- §6h" % (zaman_pay * 100.0))

	print("")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


## TEK NOKTA OLCUMU -- kalibrasyon icin. `--v2-savas-siklik=DEGER[:ulke]`.
##
## Ayri bir kapi olmasinin sebebi butce: tam kadroda 100 yil ~240 sn surer,
## dolayisiyla dort degeri tek kosuda taramak zaman asimina girer. Secim
## KARAR VERILEN kurulumda (tam kadro) yapilmali, 40 ulkelik ucuz kolda
## degil -- B4'un `savas_siklik = 5.0`i tam olarak bu yuzden tasinmadi.
static func savas_noktasi(siklik: float, n: int = -1) -> int:
	var kadro := Harita.simule_kodlar().size()
	var ulke := n if n > 0 else kadro
	print("")
	print("SAVAS SIKLIGI TEK NOKTA: siklik %.1f, %d ulke, 100 yil" % [siklik, ulke])
	var r := _savas_olc(ulke, 42, 100.0, siklik)
	print("  ilan %d, %.2f savas/ulke-yuzyil, zamanin %%%.1f'i savasta"
			% [r[1], r[2], float(r[3]) * 100.0])
	print("  capa: 1-4 savas/ulke-yuzyil, zamanin %5-15'i")
	return 0
