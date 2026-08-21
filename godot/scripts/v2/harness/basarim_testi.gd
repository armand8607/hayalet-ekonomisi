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
	return 0
