class_name OlcekTesti
extends RefCounted

## v2 kriz cekirdeginin OLCEK DEGISMEZLIK testi.
##
## Neyi kaniti: aynı baslangictan aynı YIL SAYISI kadar kosuldugunda, donem
## uzunlugu (haftalik / aylik / v4.4 turu / yillik) yorungeyi DEGISTIRMEZ.
##
## Neden bu test var: v4.4'ten taşımanın en olası sessiz hatasi, tur basina
## (0.27 yil) tanimli parametreleri haftalik (0.0192 yil) bir donguye oldugu
## gibi kopyalamaktir. Motor o zaman 14 KAT HIZLI kosar -- kar orani birkac
## yilda coker, kampanya anlamsizlasir -- ve bu OYNAYARAK FARK EDILMEZ, cunku
## egriler makul gorunur, yalnizca takvim yanlistir.
##
## Test uc kademelidir:
##   1. `q` KESINLIK  -- geri beslemesiz buyume, donemden bagimsiz olmali
##   2. YORUNGE       -- geri beslemeli buyuklukler yakin kalmali
##   3. TUZAK         -- naif kopyalamanin gercekten felaket oldugunu gosterir
##
## Ucuncusu olmadan digerleri "tesadufen geciyor olabilir"; tuzagin buyuklugu
## olculmeden kacinildigi soylenemez.

const HAFTA := 1.0 / 52.0
const AY := 1.0 / 12.0
const V44_TUR := 0.27
const YIL := 1.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


## Testin baslangic durumu. Erken sanayi (cag 2) bir merkez ulke buyuklugunde.
static func _baslangic() -> KrizDurumu:
	var d := KrizDurumu.new()
	d.K = 320.0
	d.L_etkin = 110.0
	d.hafta_saati = 1.0
	d.pay = 0.52
	d.e = 0.90
	d.u = 0.82
	d.era = 2
	d.ito = 1.0
	d.q = 1.0
	d.oto = 0.0
	d.varlik = 0.5
	d.i_yil = 0.04
	d.i_spec_yil = 0.05
	return d


## `yil` kadar kosar ve son durumu dondurur.
static func _kos(donem_yil: float, yil: float, param: KrizParam = null,
		cag_sabit := false) -> KrizDurumu:
	var d := _baslangic()
	var cekirdek := KrizCekirdegi.new(param)
	cekirdek.cag_sabit = cag_sabit
	# Cag sabitlenmisse test q'nun KAPALI FORMULUNU sinar; doyum q'ya bagli
	# oldugu icin o da sabitlenmeli, yoksa test donem cevrimini degil doyum
	# egrisini olcer.
	cekirdek.doyum_sabit = cag_sabit
	cekirdek.baslat(d)
	var n := Oran.donem_sayisi(yil, donem_yil)
	for _i in range(n):
		cekirdek.adim(d, donem_yil)
	return d


static func _bagil(a: float, b: float) -> float:
	return absf(a - b) / maxf(absf(b), 1e-12)


## GDScript'in `%` bicimlendiricisinde `%e` YOKTUR (yalnizca s/d/f/x/o/c).
## Cok kucuk bagil farklari okunur kilmak icin bilimsel gosterime cevirir.
static func _bilimsel(x: float) -> String:
	return String.num_scientific(x)


## On yilda bir durumu basar. Kriz makinesi sessiz kalinca sebebini bulmanin
## tek yolu bu: hangi buyukluk esige hic yaklasmiyor, hangisi sikismis?
static func iz(yil: float = 100.0, donem_yil: float = HAFTA,
		bas_yil: float = 1836.0) -> void:
	var d := _baslangic()
	d.yil = bas_yil
	var cekirdek := KrizCekirdegi.new()
	cekirdek.baslat(d)
	var n := Oran.donem_sayisi(yil, donem_yil)
	var adim_basi := maxi(1, n / 10)
	print("")
	print("V2 CEKIRDEK IZI -- %d yil, %d donem" % [int(yil), n])
	print("  (C/I/D sutunlari Y_pot'a ORANDIR -- D>1 ise talep BAGLAMAZ)")
	print("  (K/Y yillik sermaye-hasila; u kapasite kullanimi; acik talep_acigi)")
	print("  (var/Y balon; i_s-r Minsky kapisi: NEGATIFSE balon hic sismez)")
	print("%6s %3s %8s %6s %6s %6s %6s %6s %6s %7s %7s %6s %6s %7s"
			% ["yil", "cag", "Y_pot", "C/Yp", "I/Yp", "D/Yp", "K/Y", "u",
				"cv", "i", "r", "yenile", "e", "i_s-r"])
	for i in range(n):
		cekirdek.adim(d, donem_yil)
		if i % adim_basi == 0 or i == n - 1:
			var yp := maxf(d.Y_pot_yil, 1e-9)
			print("%6.0f %3d %8.1f %6.3f %6.3f %6.3f %6.2f %6.3f %6.2f %7.4f %7.4f %6.3f %6.3f %7.4f"
					% [d.yil, d.era, d.Y_pot_yil, d.C_yil / yp, d.I_yil / yp,
						d.D_yil / yp, d.K / maxf(d.Y_yil, 1e-9), d.u, d.cv,
						d.i_yil, d.r_yil, d.yenileme_orani, d.e,
						d.i_spec_yil - d.r_yil])
	print("  krizler: asiri_uretim=%d resesyon=%d bunalim=%d delev=%d rejim=%s"
			% [d.asiri_uretim_krizleri.size(), d.resesyonlar.size(),
				d.bunalimlar.size(), d.delev, d.rejim])


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	var yil := 100.0

	print("")
	print("V2 KRIZ CEKIRDEGI -- OLCEK DEGISMEZLIK TESTI")
	print("==================================================================")
	print("  baslangic : K=320  q=1.0  pay=0.52  cag 2")
	print("  sure      : %d yil (1836-1936)" % int(yil))
	print("")

	var hafta := _kos(HAFTA, yil)
	var ay := _kos(AY, yil)
	var tur := _kos(V44_TUR, yil)
	var yillik := _kos(YIL, yil)

	# -- 1. q KESINLIK ------------------------------------------------------
	# q buyumesi geri beslemesizdir (cag tablosundan gelir), dolayisiyla
	# KAPALI FORMULU vardir:  q = q0 * (1 + qg_yil)^(gecen_yil)
	# Bu, `Oran.donem_buyume`'yi tek basina ve dogrudan sinar.
	#
	# DIKKAT -- gecen sure her donemde AYNI DEGILDIR. 0.27 yil 100'u tam
	# bolmez: 370 tur = 99.9 yil, 100 yil degil. Bu bir olcekleme hatasi
	# degil, sure ayriklastirmasidir; karsilastirma bu yuzden ham q uzerinden
	# degil, HER KOSUNUN KENDI GECEN SURESINE gore yapilir. (Ilk yazimda ham
	# q karsilastirilmisti ve test bu yuzden yanlis yere "kaldi" diyordu.)
	# CAG SABIT: kapali formul `qg`'nin sabit olmasini gerektirir. Cag
	# ilerlemesi acikken bu test cevrimi degil CAG TABLOSUNU olcer -- ilk
	# yazimda oyle oldu ve test yanlis yere "kaldi" dedi.
	print("--- 1. q kesinligi (kapali formule karsi, cag sabit) ---")
	var qg_yil := Oran.v44_buyume(float(Tables.ERAS[2]["qg"]))
	print("  qg = %.6f/yil (cag 2)" % qg_yil)
	for c in [["haftalik", HAFTA], ["aylik", AY], ["v4.4 turu", V44_TUR], ["yillik", YIL]]:
		var donem: float = c[1]
		var s := _kos(donem, yil, null, true)
		var gecen := float(Oran.donem_sayisi(yil, donem)) * donem
		var beklenen: float = 1.0 * pow(1.0 + qg_yil, gecen)
		var fark := _bagil(s.q, beklenen)
		print("    %-10s gecen %.3f yil | q %.6f | beklenen %.6f"
				% [c[0], gecen, s.q, beklenen])
		_dogrula(fark < 1e-9, "q kapali formule uyuyor: %s" % c[0],
				"(bagil fark %s)" % _bilimsel(fark))

	# -- 2. YORUNGE ---------------------------------------------------------
	# K, r ve canli_pay geri beslemelidir; donem kisaldikca integrasyon
	# hatasi kucuur ama yorunge AYNI kalmalidir.
	print("")
	print("--- 2. yorunge (geri beslemeli buyuklukler) ---")
	print("  %-12s %10s %10s %10s %10s" % ["", "K", "r (yil)", "c/v", "varlik"])
	for c in [["haftalik", hafta], ["aylik", ay], ["v4.4 turu", tur], ["yillik", yillik]]:
		var s: KrizDurumu = c[1]
		print("  %-12s %10.3f %10.5f %10.4f %10.3f" % [c[0], s.K, s.r_yil, s.cv, s.varlik])

	for c in [["aylik", ay], ["v4.4 turu", tur]]:
		var s: KrizDurumu = c[1]
		var dk := _bagil(s.K, hafta.K)
		var dr := _bagil(s.r_yil, hafta.r_yil)
		_dogrula(dk < 0.05, "K: haftalik <-> %s" % c[0], "(bagil fark %.3f)" % dk)
		_dogrula(dr < 0.05, "r: haftalik <-> %s" % c[0], "(bagil fark %.3f)" % dr)

	# Yillik adim en kaba integrasyon; daha gevsek bant.
	_dogrula(_bagil(yillik.K, hafta.K) < 0.15, "K: haftalik <-> yillik",
			"(bagil fark %.3f)" % _bagil(yillik.K, hafta.K))

	# -- 2b. KRIZ SAYACLARI -------------------------------------------------
	# Asil sinama budur: yorungenin yakin olmasi yetmez, KRIZ MAKINESI de ayni
	# sayida ve turde olay uretmeli. Krizler esik gecisleridir, dolayisiyla
	# tam esitlik beklenmez -- beklenen, ayni buyukluk mertebesi.
	#
	# YILLIK ADIM BILEREK DISARIDA. 1 yillik bir adim, patlayip sonen bir
	# balonu cozemez: esik iki olcum arasinda gecilip geri donebilir. Bu bir
	# hata degil, ayriklastirmanin sinuridir -- ve haftalik kosmamizin
	# sebebidir.
	print("")
	print("--- 2b. kriz makinesi (esik gecisleri) ---")
	print("  %-12s %10s %10s %10s %10s" % ["", "asiri ur.", "resesyon", "bunalim", "minsky"])
	for c in [["haftalik", hafta], ["aylik", ay], ["v4.4 turu", tur], ["yillik", yillik]]:
		var s: KrizDurumu = c[1]
		print("  %-12s %10d %10d %10d %10d" % [c[0],
				s.asiri_uretim_krizleri.size(), s.resesyonlar.size(),
				s.bunalimlar.size(), s.minsky_sayac])
	for c in [["aylik", ay], ["v4.4 turu", tur]]:
		var s: KrizDurumu = c[1]
		var f_res := absi(s.resesyonlar.size() - hafta.resesyonlar.size())
		var f_bun := absi(s.bunalimlar.size() - hafta.bunalimlar.size())
		_dogrula(f_res <= 2, "resesyon sayisi: haftalik <-> %s" % c[0],
				"(%d vs %d)" % [hafta.resesyonlar.size(), s.resesyonlar.size()])
		_dogrula(f_bun <= 2, "bunalim sayisi: haftalik <-> %s" % c[0],
				"(%d vs %d)" % [hafta.bunalimlar.size(), s.bunalimlar.size()])

	# -- 3. TUZAK -----------------------------------------------------------
	# Naif kopyalama: tur basina tanimli parametreleri HAFTALIK donguye
	# oldugu gibi vermek. `donem_yil = V44_TUR` diyerek 5200 hafta yerine
	# 5200 TUR kosmak buna denktir -- yani 14 kat fazla zaman.
	print("")
	print("--- 3. 14 katlik tuzak (kacinildigi olculuyor) ---")
	var naif := _baslangic()
	var cek := KrizCekirdegi.new()
	cek.baslat(naif)
	var naif_n := Oran.donem_sayisi(yil, HAFTA)     # 5200 donem
	for _i in range(naif_n):
		cek.adim(naif, V44_TUR)                     # ...ama TUR uzunluguyla
	print("  dogru  (5200 hafta = 100 yil) : K=%.1f  q=%.3f  r=%.5f"
			% [hafta.K, hafta.q, hafta.r_yil])
	print("  naif   (5200 tur   = 1404 yil): K=%.1f  q=%.3f  r=%.5f"
			% [naif.K, naif.q, naif.r_yil])
	var kat := naif.q / maxf(hafta.q, 1e-9)
	print("  uretkenlik farki: %.0f kat" % kat)
	_dogrula(kat > 100.0, "tuzak gercek ve buyuk",
			"(naif kosu %.0f kat sapiyor)" % kat)
	_dogrula(hafta.q < naif.q, "dogru kosu tuzaga DUSMEMIS")

	# -- 4. LTRPF yonu ------------------------------------------------------
	# Cekirdegin asil iddiasi: q yukselirken c/v yukselmeli, r dusmeli.
	print("")
	print("--- 4. LTRPF yonu (cekirdegin asil iddiasi) ---")
	# ISINMA. Ilk adimlar baslangic durumunun gecici hallenmesidir (talep
	# acigi %60'tan sifira duser, r sicrar). LTRPF bir EGILIMDIR, gecici bir
	# sicramanin ustunden olculemez -- olcum 10 yillik isinmadan SONRA baslar.
	# (Ilk yazimda 1. adimdan olculuyordu ve test bu yuzden yanlis yere
	# "kaldi" diyordu.)
	var bas := _baslangic()
	var cek2 := KrizCekirdegi.new()
	cek2.baslat(bas)
	var isinma := Oran.donem_sayisi(10.0, HAFTA)
	for _i in range(isinma):
		cek2.adim(bas, HAFTA)
	var q0 := bas.q
	var cv0 := bas.cv
	var r0 := bas.r_yil
	print("  (10 yillik isinmadan sonra olculuyor)")
	for _i in range(Oran.donem_sayisi(yil, HAFTA) - isinma):
		cek2.adim(bas, HAFTA)
	print("  q    %.4f -> %.4f" % [q0, bas.q])
	print("  c/v  %.4f -> %.4f" % [cv0, bas.cv])
	print("  r    %.5f -> %.5f" % [r0, bas.r_yil])
	_dogrula(bas.q > q0, "q yukseldi")
	_dogrula(bas.cv > cv0, "c/v yukseldi (q ile birlikte)")
	_dogrula(bas.r_yil < r0, "r DUSTU -- LTRPF")

	print("")
	print("------------------------------------------------------------------")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1
