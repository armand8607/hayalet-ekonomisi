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
	print("  %-10s %8s %10s %12s %14s"
			% ["ulke", "q", "c/v", "VT/Y", "birikmis VT"])
	var alan := -1
	var veren := -1
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		print("  %-10s %8.3f %10.3f %12.5f %14.1f"
				% [w.adlar[i], d.q, d.cv, w.son_vt[i] / maxf(d.Y_yil, 1e-9),
				w.toplam_vt[i]])
		if alan < 0 or w.toplam_vt[i] > w.toplam_vt[alan]:
			alan = i
		if veren < 0 or w.toplam_vt[i] < w.toplam_vt[veren]:
			veren = i
	print("  en cok ALAN  : %s" % w.adlar[alan])
	print("  en cok VEREN : %s" % w.adlar[veren])
	_dogrula(w.ulkeler[alan].cv > w.ulkeler[veren].cv,
			"alanin organik bilesimi verenden yuksek",
			"(%.3f > %.3f)" % [w.ulkeler[alan].cv, w.ulkeler[veren].cv])

	# -----------------------------------------------------------------
	# 4. B1b OLCUTU  --  TOHUM TARAMASI
	# -----------------------------------------------------------------
	#
	# TEK TOHUMLA KARAR VERILMEZ. Cekirdek kaotiktir; belge de bunu soyluyor
	# (§10: "devrim sayisi tohuma duyarli, en az uc tohum gerekir") ve
	# `tarih_testi` zaten medyanla hukum veriyor. Ayni usul burada da gecerli.
	#
	# TUR AYRIMI KORUNUR. "Kriz yogunlugu" uc ayri seyi topluyor ve teorinin
	# iddiasi hepsinde ayni degil: deger girisi GERCEKLESME sorununu hafifletir
	# (asiri uretim) ve krizin DERINLESMESINI onler (bunalim). Resesyon icin
	# boyle bir iddia yok -- yuksek organik bilesim kendi basina daha sik
	# karlilik sikismasi uretir. Toplami tek sayiya indirmek bu ayrimi yok
	# eder, o yuzden uc tur AYRI raporlanir.
	print("")
	print("--- 4. B1b olcutu: alanda kriz yogunlugu verenden DUSUK mu ---")
	print("  (belge §6: 'emperyalizmin motordaki imzasi budur ve tek ulkede")
	print("   tanimsizdir' -- bu kosuda tanimli)")
	print("")
	print("  %6s %-10s %12s %8s %9s %8s %11s"
			% ["tohum", "konum", "birikmis VT", "asiri", "resesyon", "bunalim", "toplam/100y"])
	var sure := BITIS - BAS
	var alan_asiri := PackedFloat64Array()
	var veren_asiri := PackedFloat64Array()
	var alan_bunalim := PackedFloat64Array()
	var veren_bunalim := PackedFloat64Array()
	var alan_toplam := PackedFloat64Array()
	var veren_toplam := PackedFloat64Array()

	for tohum in [1, 2, 3, 4, 5, 6]:
		var wt := _dunya_kur(tohum)
		_kos(wt, sure)
		var a := 0
		var v := 0
		for i in range(wt.ulkeler.size()):
			if wt.toplam_vt[i] > wt.toplam_vt[a]:
				a = i
			if wt.toplam_vt[i] < wt.toplam_vt[v]:
				v = i
		for par in [[a, "ALAN"], [v, "VEREN"]]:
			var i: int = par[0]
			var d := wt.ulkeler[i]
			var kap := (d.devrim_yil - BAS) if d.devrim_yil > 0.0 else sure
			kap = maxf(kap, 1.0)
			var au := d.asiri_uretim_krizleri.size() * 100.0 / kap
			var bn := d.bunalimlar.size() * 100.0 / kap
			var tp := wt.kriz_sayisi(i) * 100.0 / kap
			if par[1] == "ALAN":
				alan_asiri.append(au)
				alan_bunalim.append(bn)
				alan_toplam.append(tp)
			else:
				veren_asiri.append(au)
				veren_bunalim.append(bn)
				veren_toplam.append(tp)
			print("  %6d %-10s %12.1f %8d %9d %8d %11.1f"
					% [tohum, "%s (%s)" % [par[1], wt.adlar[i]], wt.toplam_vt[i],
					d.asiri_uretim_krizleri.size(), d.resesyonlar.size(),
					d.bunalimlar.size(), tp])

	print("")
	print("  MEDYAN (6 tohum, /100 kapitalist yil)")
	print("  %-22s %10s %10s" % ["", "ALAN", "VEREN"])
	print("  %-22s %10.1f %10.1f"
			% ["asiri uretim", _medyan(alan_asiri), _medyan(veren_asiri)])
	print("  %-22s %10.1f %10.1f"
			% ["bunalim", _medyan(alan_bunalim), _medyan(veren_bunalim)])
	print("  %-22s %10.1f %10.1f"
			% ["TOPLAM", _medyan(alan_toplam), _medyan(veren_toplam)])
	print("")

	# Teorinin iki ayri iddiasi, ayri ayri sinaniyor:
	_dogrula(_medyan(alan_asiri) < _medyan(veren_asiri),
			"deger girisi GERCEKLESME sorununu hafifletiyor (asiri uretim)",
			"(%.1f < %.1f)" % [_medyan(alan_asiri), _medyan(veren_asiri)])
	_dogrula(_medyan(alan_bunalim) < _medyan(veren_bunalim),
			"deger girisi krizin DERINLESMESINI onluyor (bunalim)",
			"(%.1f < %.1f)" % [_medyan(alan_bunalim), _medyan(veren_bunalim)])
	# Belgenin §6'da yazdigi kapinin harfi harfine hali.
	_dogrula(_medyan(alan_toplam) < _medyan(veren_toplam),
			"belge §6 olcutu: ALAN'da toplam kriz yogunlugu daha dusuk",
			"(%.1f < %.1f)" % [_medyan(alan_toplam), _medyan(veren_toplam)])

	print("")
	print("------------------------------------------------------------------")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1
