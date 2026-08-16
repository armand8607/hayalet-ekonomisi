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
	print("  %8s %10s %14s %14s %10s %10s"
			% ["siddet", "|VT|/Y", "ALAN medyan", "VEREN medyan", "ALAN 6'da", "VEREN 6'da"])
	var sure := BITIS - BAS
	for siddet in [0.05, 0.10, 0.20, 0.40, 0.80]:
		var alan_d := PackedFloat64Array()
		var veren_d := PackedFloat64Array()
		var agirlik := 0.0
		var alan_dogru := 0
		var veren_dogru := 0
		for tohum in [1, 2, 3, 4, 5, 6]:
			var acik := _dunya_kur(tohum)
			acik.siddet = siddet
			_kos(acik, sure)
			var kapali := _dunya_kur(tohum)
			kapali.siddet = 0.0
			_kos(kapali, sure)
			agirlik += acik.vt_agirligi()
			var a := 0
			var v := 0
			for i in range(acik.ulkeler.size()):
				if acik.toplam_vt[i] > acik.toplam_vt[a]:
					a = i
				if acik.toplam_vt[i] < acik.toplam_vt[v]:
					v = i
			var da := (_bunalim_yogunlugu(acik, a, sure)
					- _bunalim_yogunlugu(kapali, a, sure))
			var dv := (_bunalim_yogunlugu(acik, v, sure)
					- _bunalim_yogunlugu(kapali, v, sure))
			alan_d.append(da)
			veren_d.append(dv)
			if da < 0.0:
				alan_dogru += 1
			if dv > 0.0:
				veren_dogru += 1
		print("  %8.2f %10.4f %14.2f %14.2f %10s %10s"
				% [siddet, agirlik / 6.0, _medyan(alan_d), _medyan(veren_d),
				"%d/6" % alan_dogru, "%d/6" % veren_dogru])
	print("")
	print("  (v4.4 varsayilan dunyada |VT|/Y ~ 0.01-0.03 uretiyordu)")
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
		for i in range(acik.ulkeler.size()):
			ulke_delta[i].append(_bunalim_yogunlugu(acik, i, sure)
					- _bunalim_yogunlugu(kapali, i, sure))

	var m_alan := _medyan(alan_delta)
	var m_veren := _medyan(veren_delta)
	print("")
	print("  MEDYAN DEGISIM (6 tohum, bunalim/100 kapitalist yil)")
	print("    ALAN  : %+.2f" % m_alan)
	print("    VEREN : %+.2f" % m_veren)
	print("")
	_dogrula(m_alan < 0.0, "ALAN'da bunalim yogunlugu AZALIYOR",
			"(%+.2f)" % m_alan)
	_dogrula(m_veren > 0.0, "VEREN'de bunalim yogunlugu ARTIYOR",
			"(%+.2f)" % m_veren)

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
	# Teorinin iddiasi: transfer krizi YOK ETMEZ, tasir. Dunya toplami
	# alanin kazancindan cok daha az degismeli -- yoksa transfer bir
	# cikis degil, bir kriz makinesi ya da kriz sonduruculugudur.
	_dogrula(absf(ma_b - mk_b) < absf(m_alan),
			"transfer krizi YOK ETMIYOR, TASIYOR (dunya neti alanin kazancindan kucuk)",
			"(|%+.2f| < |%+.2f|)" % [ma_b - mk_b, m_alan])

	print("")
	print("------------------------------------------------------------------")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1
