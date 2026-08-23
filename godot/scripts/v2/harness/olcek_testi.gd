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

## Yakinsama referansi: uretim olceginin (haftalik) dort kati incesi.
const REFERANS := 1.0 / 208.0

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


## `yil` kadar kosar ve YORUNGE ORTALAMALARINI dondurur.
##
## Kaotik bir motorda uc nokta karsilastirilamaz (asagida 2a'nin gerekcesi),
## ama zaman ortalamalari cekicinin ozellikleridir ve olcekten bagimsiz
## olmalidir. Ortalamalar donem SAYISIYLA degil donem UZUNLUGUYLA agirliklanir,
## yoksa haftalik kosu yalnizca daha sik ornekledigi icin farkli cikardi.
static func _kos_ort(donem_yil: float, yil: float) -> Dictionary:
	var d := _baslangic()
	var cekirdek := KrizCekirdegi.new()
	cekirdek.baslat(d)
	var n := Oran.donem_sayisi(yil, donem_yil)
	var r_top := 0.0
	var e_top := 0.0
	var agirlik := 0.0
	for _i in range(n):
		cekirdek.adim(d, donem_yil)
		r_top += d.r_yil * donem_yil
		e_top += d.e * donem_yil
		agirlik += donem_yil
	return {
		"d": d,
		"r_ort": r_top / maxf(agirlik, 1e-9),
		"e_ort": e_top / maxf(agirlik, 1e-9),
		# K'nin ortalama yillik buyume hizi -- uc nokta degil, egim.
		"g_ort": log(maxf(d.K, 1e-9) / 320.0) / maxf(agirlik, 1e-9),
	}


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
	print("  (canli = canli_pay: satinalma gucunun hasilaya orani. Uretim")
	print("   kapasitesi ile TUKETIM kapasitesi arasindaki makas budur.)")
	print("%6s %3s %8s %6s %6s %6s %6s %6s %6s %6s %6s %7s %6s"
			% ["yil", "cag", "Y_pot", "C/Yp", "I/Yp", "D/Yp", "K/Y", "canli",
				"pay_I", "acik", "satI", "satII", "e"])
	# --- MINSKY TANISI ---
	# Patlama IKI kosulun AYNI ANDA ve kesintisiz saglanmasini ister:
	#   (1) varlik/Y > minsky_esik      -- balon yeterince buyuk mu
	#   (2) varlik_beklenti < i_spec    -- beklenti donmus mu
	# Hangisinin bagladigini bilmeden esik mi kanal mi sorusu cevaplanamaz,
	# o yuzden ikisi AYRI sayilir.
	var v_max := 0.0
	var esik_yil := 0.0
	var bekl_yil := 0.0
	var ikisi_yil := 0.0
	var ardisik := 0.0
	var ardisik_max := 0.0
	var bekl_min := INF
	var bekl_max := -INF
	# Minsky'nin KENDI olcutu: borc taahhutleri nakit akisini asiyor mu.
	var ponzi_max := 0.0
	var ponzi_top := 0.0
	var borc_y_max := 0.0
	var ponzi_yil := 0.0
	var i_min_yil := 0.0
	var i_pol_max := 0.0
	var i_pol_top := 0.0
	var pi_top := 0.0
	var gereken := float(KrizParam.sure_donem(
			Oran.yillik_sure(cekirdek.P.v44.minsky_sure, Oran.V44_TUR_YIL),
			donem_yil)) * donem_yil

	for i in range(n):
		cekirdek.adim(d, donem_yil)

		var v := d.varlik / maxf(d.Y_yil, 1e-9)
		var k1 := v > cekirdek.P.v44.minsky_esik
		var k2 := d.varlik_beklenti < d.i_spec_yil

		var servis := (d.i_yil + cekirdek.P.v44.borc_faizi_marj) * d.borc
		var ponzi := servis / maxf(d.s_yil, 1e-9)
		ponzi_max = maxf(ponzi_max, ponzi)
		ponzi_top += ponzi * donem_yil
		borc_y_max = maxf(borc_y_max, d.borc / maxf(d.Y_yil, 1e-9))
		if ponzi > 1.0:
			ponzi_yil += donem_yil
		i_pol_max = maxf(i_pol_max, d.i_pol_yil)
		i_pol_top += d.i_pol_yil * donem_yil
		pi_top += d.pi_inf * donem_yil
		if d.i_pol_yil <= cekirdek.P.v44.i_min + 1e-9:
			i_min_yil += donem_yil
		v_max = maxf(v_max, v)
		bekl_min = minf(bekl_min, d.varlik_beklenti)
		bekl_max = maxf(bekl_max, d.varlik_beklenti)
		if k1:
			esik_yil += donem_yil
		if k2:
			bekl_yil += donem_yil
		if k1 and k2:
			ikisi_yil += donem_yil
			ardisik += donem_yil
			ardisik_max = maxf(ardisik_max, ardisik)
		else:
			ardisik = 0.0

		if i % adim_basi == 0 or i == n - 1:
			var yp := maxf(d.Y_pot_yil, 1e-9)
			print("%6.0f %3d %8.1f %6.3f %6.3f %6.3f %6.2f %6.3f %6.3f %6.3f %6.3f %7.4f %6.3f"
					% [d.yil, d.era, d.Y_pot_yil, d.C_yil / yp, d.I_yil / yp,
						d.D_yil / yp, d.K / maxf(d.Y_yil, 1e-9), d.canli_pay,
						d.pay_I, d.talep_acigi,
						d.satilamayan_I / maxf(d.Y_pot_yil, 1e-9),
						d.satilamayan_II / maxf(d.Y_pot_yil, 1e-9), d.e])
	print("  krizler: asiri_uretim=%d resesyon=%d bunalim=%d delev=%d rejim=%s"
			% [d.asiri_uretim_krizleri.size(), d.resesyonlar.size(),
				d.bunalimlar.size(), d.delev, d.rejim])
	# --- KRIZ TAKVIMI ---
	# Sayilar krizlerin ZAMANDA NASIL DAGILDIGINI soylemez. Tesciller ayri
	# ayri mi yayiliyor, yoksa patlamalar halinde mi kumeleniyor?
	print("")
	print("  --- KRIZ TAKVIMI (tescil yillari) ---")
	print("    DEVRIM: %s   (sonrasinda asiri uretim tescili KAPANIR)"
			% ("%d" % int(d.devrim_yil) if d.devrim_yil > 0.0 else "olmadi"))
	for c in [["asiri uretim", d.asiri_uretim_krizleri],
			["resesyon    ", d.resesyonlar],
			["bunalim     ", d.bunalimlar]]:
		var satir := ""
		for kayit in c[1]:
			satir += "%d " % int(kayit[0])
		print("    %s: %s" % [c[0], satir if satir != "" else "(yok)"])
	# Butun tesciller tek eksende: aralarindaki bosluklarin dagilimi.
	var hepsi: Array[float] = []
	for liste in [d.asiri_uretim_krizleri, d.resesyonlar, d.bunalimlar]:
		for kayit in liste:
			hepsi.append(float(kayit[0]))
	hepsi.sort()
	if hepsi.size() > 1:
		var bosluk := ""
		var yakin := 0
		for i in range(1, hepsi.size()):
			var g := hepsi[i] - hepsi[i - 1]
			bosluk += "%.0f " % g
			if g <= 2.0:
				yakin += 1
		print("    tescil araliklari: %s" % bosluk)
		print("    2 yildan yakin arayla gelen: %d / %d"
				% [yakin, hepsi.size() - 1])

	print("")
	print("  --- MINSKY TANISI (%d yil icinde) ---" % int(yil))
	print("    balon tepesi         : varlik/Y = %.3f   (esik %.2f) -> %s"
			% [v_max, cekirdek.P.v44.minsky_esik,
				"ASILDI" if v_max > cekirdek.P.v44.minsky_esik else "HIC ASILMADI"])
	print("    (1) esik ustunde     : %.1f yil" % esik_yil)
	print("    (2) beklenti donmus  : %.1f yil" % bekl_yil)
	print("    (1) VE (2) birlikte  : %.1f yil" % ikisi_yil)
	print("    en uzun KESINTISIZ   : %.2f yil   (gereken %.2f) -> %s"
			% [ardisik_max, gereken, "YETER" if ardisik_max >= gereken else "YETMEZ"])
	print("    varlik_beklenti araligi: [%.4f, %.4f]" % [bekl_min, bekl_max])
	print("    --- borc tarafi (tetikleyicinin BAKMADIGI) ---")
	print("    borc/Y tepesi        : %.3f" % borc_y_max)
	print("    borc_servisi/s tepesi: %.3f   ortalama %.3f"
			% [ponzi_max, ponzi_top / maxf(yil, 1e-9)])
	print("    servis > arti deger  : %.1f yil  (Ponzi bolgesi)" % ponzi_yil)
	print("    --- faiz (borc yukunun ON KOSULU) ---")
	print("    politika faizi       : tepe %.4f  ortalama %.4f  (taban %.4f)"
			% [i_pol_max, i_pol_top / maxf(yil, 1e-9), cekirdek.P.v44.i_min])
	print("    TABANDA gecen sure   : %.1f yil  (%.0f%%)"
			% [i_min_yil, 100.0 * i_min_yil / maxf(yil, 1e-9)])
	print("    ortalama enflasyon   : %.4f  (hedef %.4f)"
			% [pi_top / maxf(yil, 1e-9), cekirdek.P.v44.pi_hedef])


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

	# -- 2a. UC NOKTA DEGIL, CEKICI ORTALAMALARI -----------------------------
	#
	# Once sabit bantlar vardi ("haftalik <-> aylik K farki < %5"). O bantlar
	# motor DUZ bir yorunge izlerken kalibre edilmisti; cevrim dogunca hepsi
	# birden kirildi. Yerine YAKINSAMA sinamasi kondu -- "donem kisaldikca
	# hata kuculmeli" -- ve o da kaldi. Sebebi olculdu ve onemlidir:
	#
	#   pencere   yillik   v4.4turu    aylik  haftalik      (1/208'e hata)
	#    30 yil   0.0860     0.1054   0.0971    0.0245
	#    60 yil   0.2647     0.0083   0.2614    0.0594
	#    90 yil   0.0399     0.1216   0.0391    0.0472
	#
	# Hata donem uzunluguyla ILISKISIZ. 60 yilda kaba v4.4 turu %0.8 ile
	# neredeyse tam isabet ederken cok daha ince aylik adim %26 sapiyor.
	# Bu yakinsama basarisizligi degil, DUYARLI BAGIMLILIKTIR: cevrim
	# dogduktan sonra motor kaotiktir, uc nokta K'si cekiciden alinmis bir
	# ORNEKTIR ve donem uzunlugundaki en kucuk degisiklik fazi kaydirir.
	#
	# v4.4 ayni duvara carpmis ve ayni sonuca varmisti (CLAUDE.md): "Motor
	# kaotik oldugu icin tek bir ulp yuzlerce tur sonra yuzlerce alana
	# yayilir... kabul olcutu katman 4 ve 5'tir, 3b degil." Yani yorunge
	# esitligi birakilir, olcut YON ve BANT olur.
	#
	# Bu testin ISI hala tam olarak yapilabilir. Amaci "14 katlik tuzagi"
	# yakalamaktir: tur basina tanimli bir parametrenin cevrilmeden
	# kopyalanmasi. Boyle bir hata ORTALAMALARI kat kat kaydirir -- kaosun
	# birkac yuzdelik saciliminin yaninda devasa kalir. O yuzden karsilastirma
	# uc noktadan ZAMAN ORTALAMALARINA tasindi: ortalama kar orani, ortalama
	# istihdam ve K'nin ortalama buyume hizi. Bunlar cekicinin ozellikleridir,
	# fazina bagli degildir.
	print("")
	print("--- 2a. cekici ortalamalari (uc nokta degil; 90 yil) ---")
	var merdiven := [["yillik", YIL], ["v4.4 turu", V44_TUR], ["aylik", AY],
			["haftalik", HAFTA]]
	var ortalamalar: Array[Dictionary] = []
	print("  %-12s %8s %10s %10s %10s" % ["", "donem", "r_ort", "e_ort", "g_ort"])
	for c in merdiven:
		var o := _kos_ort(float(c[1]), 90.0)
		ortalamalar.append(o)
		print("  %-12s %8.4f %10.5f %10.4f %10.5f"
				% [c[0], float(c[1]), o["r_ort"], o["e_ort"], o["g_ort"]])

	# Referans en ince olcek. Bant kaosun sacilimini kaldiracak kadar genis,
	# ama bir birim hatasinin (14 kat) yanindan bile gecemeyecek kadar dar.
	var ref_o := ortalamalar[3]
	for i in range(3):
		var o := ortalamalar[i]
		var ad: String = merdiven[i][0]
		_dogrula(_bagil(o["r_ort"], ref_o["r_ort"]) < 0.20,
				"ortalama kar orani: haftalik <-> %s" % ad,
				"(bagil fark %.3f)" % _bagil(o["r_ort"], ref_o["r_ort"]))
		_dogrula(_bagil(o["e_ort"], ref_o["e_ort"]) < 0.20,
				"ortalama istihdam: haftalik <-> %s" % ad,
				"(bagil fark %.3f)" % _bagil(o["e_ort"], ref_o["e_ort"]))
		_dogrula(_bagil(o["g_ort"], ref_o["g_ort"]) < 0.20,
				"K'nin ortalama buyume hizi: haftalik <-> %s" % ad,
				"(bagil fark %.3f)" % _bagil(o["g_ort"], ref_o["g_ort"]))

	# -- 2c. REJIM AYRISMASI (catallanma, integrasyon hatasi DEGIL) ----------
	# Tam pencerede (100 yil) olculur: yakinsama testi bilerek catallanma
	# oncesinde durur, dolayisiyla rejim ayrismasini ancak burasi yakalar.
	# Yillik adim disaridadir -- devrim esigi (`pr_sure_yil`) bir yildan
	# kisadir ve yillik ornekleme onu cozemez; 2b de ayni gerekceyle yillik
	# adimi kriz sayaclarinin disinda birakir.
	print("")
	print("--- 2c. rejim tutarliligi (tam pencere) ---")
	print("  rejimler: haftalik=%s aylik=%s tur=%s yillik=%s"
			% [hafta.rejim, ay.rejim, tur.rejim, yillik.rejim])
	_dogrula(hafta.rejim == ay.rejim and hafta.rejim == tur.rejim,
			"ince olcekler ayni rejimde bitiyor",
			"(%s / %s / %s)" % [hafta.rejim, ay.rejim, tur.rejim])

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
	# BANT SAYIYLA OLCEKLENIR. Mutlak +-2 idi ve motor 0-2 kriz uretirken
	# konmustu; simdi 10-14 uretiyor, orada +-2 kaosun kendi sacilimindan
	# dardir (haftalik 14, aylik 12, tur 11, yillik 10). Testin isi bir birim
	# hatasini yakalamaktir: 14 katlik bir kayma sayimi mertebe olarak
	# degistirir, %25'lik bir bandin yanindan bile gecemez.
	for c in [["aylik", ay], ["v4.4 turu", tur]]:
		var s: KrizDurumu = c[1]
		var f_res := absi(s.resesyonlar.size() - hafta.resesyonlar.size())
		var f_bun := absi(s.bunalimlar.size() - hafta.bunalimlar.size())
		var bant_res := maxi(2, int(round(0.25 * float(hafta.resesyonlar.size()))))
		_dogrula(f_res <= bant_res, "resesyon sayisi: haftalik <-> %s" % c[0],
				"(%d vs %d, bant %d)" % [hafta.resesyonlar.size(),
					s.resesyonlar.size(), bant_res])
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
