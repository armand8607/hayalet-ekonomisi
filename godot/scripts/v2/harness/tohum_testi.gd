class_name TohumTesti
extends RefCounted

## 1836 EKONOMIK TOHUMLAMASININ KAPISI.
##
## `TohumVerisi` URETILMIS bir dosyadir ve uretici agdan okur; bu kapi
## kaynaga DEGIL veriye bakar -- `gen_harita.py`/`--v2-harita` ile ayni is
## bolumu. Denetimler yapisaldir: tablo tutarli mi, tohum motora ULASIYOR
## mu, ve normalizasyonu seciren kisit hala saglaniyor mu.
##
## NEDEN "ULASIYOR MU" AYRI BIR DENETIM: deponun kendi dersi. Karanlik
## devletin `uyusturucu_orani`si cekirdekte okunuyor ama hicbir sey
## tarafindan yazilmiyordu ve 198 yil 0.0'da olu durdu. Bir tablonun var
## olmasi surdugu anlamina gelmez.

const HAFTA := 1.0 / 52.0
const BAS := 1836.0

## Maddison'in KENDI dunya toplami, 1820. Tohumun capasi -- kurulusta
## hedeflenmedi, denetlenir.
const DUNYA_1820 := 1033538000.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("=".repeat(74))
	print("TOHUMLAMA -- 1836'nin nufusu (Maddison), %d toprak" % TohumVerisi.NUFUS.size())
	print("=".repeat(74))
	_tablo()
	_normalizasyon()
	_miras()
	_capa()
	_motora_ulasiyor_mu()
	print("")
	print("-".repeat(74))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


# ---------------------------------------------------------------------------
# TABLO
# ---------------------------------------------------------------------------

static func _tablo() -> void:
	print("")
	print("TABLO")
	var kodlar := Harita.simule_kodlar()
	var eksik: Array[String] = []
	for kod in kodlar:
		if not TohumVerisi.NUFUS.has(kod) and not (kod in TohumVerisi.TOHUMSUZ):
			eksik.append(kod)
	_dogrula(eksik.is_empty(),
			"her simule toprak ya tohumlu ya kayitli tohumsuz",
			"" if eksik.is_empty() else "eksik: %s" % str(eksik))

	# ILERI YONLU: tabloda haritada OLMAYAN bir kod olmamali, yoksa uretici
	# ile harita sessizce ayrisir.
	var fazla: Array[String] = []
	for kod in TohumVerisi.NUFUS:
		if Harita.indeks(kod) < 0:
			fazla.append(kod)
	_dogrula(fazla.is_empty(), "tabloda haritada olmayan kod yok",
			"" if fazla.is_empty() else str(fazla))

	# TERS YONLU DENETIM (B5'in birakip da ise yarayan kaydi gibi):
	# tohumsuzlar SAYILIR. Bir kaynak onlari kapsadigi gun bu duser ve
	# belge guncellenir -- gevsek birakilsaydi kimse haber vermezdi.
	_dogrula(TohumVerisi.TOHUMSUZ.size() == 2
			and "PNG" in TohumVerisi.TOHUMSUZ and "SOM" in TohumVerisi.TOHUMSUZ,
			"tohumsuz kume tam olarak {PNG, SOM}",
			str(TohumVerisi.TOHUMSUZ))

	var kaynaksiz: Array[String] = []
	for kod in TohumVerisi.NUFUS:
		if not TohumVerisi.KAYNAK.has(kod) or String(TohumVerisi.KAYNAK[kod]).is_empty():
			kaynaksiz.append(kod)
	_dogrula(kaynaksiz.is_empty(), "her tohumun kaydi var (nereden geldigi)",
			"" if kaynaksiz.is_empty() else str(kaynaksiz))

	var eksi := 0
	for kod in TohumVerisi.NUFUS:
		if float(TohumVerisi.NUFUS[kod]) <= 0.0:
			eksi += 1
	_dogrula(eksi == 0, "hicbir nufus sifir ya da negatif degil")


# ---------------------------------------------------------------------------
# NORMALIZASYON
# ---------------------------------------------------------------------------

static func _normalizasyon() -> void:
	print("")
	print("NORMALIZASYON")
	var L := PackedFloat64Array()
	for kod in TohumVerisi.NUFUS:
		L.append(TohumVerisi.l_etkin(kod))
	var s := Array(L)
	s.sort()
	var n := s.size()
	var med: float = s[n / 2] if n % 2 == 1 else 0.5 * (s[n / 2 - 1] + s[n / 2])
	_dogrula(absf(med - TohumVerisi.MEDYAN_L) < 1e-6,
			"medyan ulke motorun kalibre edildigi %.1f'da" % TohumVerisi.MEDYAN_L,
			"medyan = %.4f" % med)

	# BU DENETIM NORMALIZASYON KARARINI TUTAR. `savas.gd::_yikim` nufus
	# kaybini `maxf(1.0, ...)` ile tabanlar; taban ALTINDA baslayan bir ulke
	# savasta nufus kaybedemez, yani sessizce dokunulmaz olur. Ortalamaya
	# gore normalize edilseydi DORT ulke oraya duserdi -- olculdu.
	var en_kucuk: float = s[0]
	_dogrula(en_kucuk > 1.0,
			"en kucuk ulke `savas.gd`in 1.0 nufus tabaninin ustunde",
			"en kucuk L_etkin = %.3f" % en_kucuk)

	print("     L_etkin araligi: %.2f .. %.0f  (oran %.0f)"
			% [s[0], s[n - 1], s[n - 1] / maxf(s[0], 1e-9)])


# ---------------------------------------------------------------------------
# MIRAS
# ---------------------------------------------------------------------------

static func _miras() -> void:
	print("")
	print("MIRAS -- 1836'da ayri devlet olmayan topraklar")
	# Kaynak dizgisi "<butun> <nasil>, pay <p>" bicimindedir. Paylar
	# butun basina toplanir ve 1'i ASMAMALI: asarsa bolusturme bir topragi
	# iki kez saymis demektir.
	var toplam := {}
	var sayi := 0
	for kod in TohumVerisi.KAYNAK:
		var s := String(TohumVerisi.KAYNAK[kod])
		var i := s.find(", pay ")
		if i < 0:
			continue
		sayi += 1
		var butun := s.substr(0, s.find(" ara ")) if s.contains(" ara ") else s.substr(0, i)
		var p := float(s.substr(i + 6))
		toplam[butun] = float(toplam.get(butun, 0.0)) + p
		_dogrula(p > 0.0 and p <= 1.0, "%s payi (0,1] araliginda" % kod,
				"pay = %.4f" % p)
	_dogrula(sayi >= 30, "bolusturulen toprak sayisi beklenen mertebede",
			"%d toprak" % sayi)
	for butun in toplam:
		var t: float = toplam[butun]
		_dogrula(t <= 1.0 + 1e-6, "'%s' paylari 1'i asmiyor" % butun,
				"toplam = %.4f" % t)


# ---------------------------------------------------------------------------
# CAPA
# ---------------------------------------------------------------------------

static func _capa() -> void:
	print("")
	print("CAPA -- dunya toplami")
	var toplam := 0.0
	for kod in TohumVerisi.NUFUS:
		toplam += float(TohumVerisi.NUFUS[kod])
	# 113 toprağin 1836 toplami, Maddison'in KENDI dunya 1820 rakamiyla
	# karsilastirilir. 16 yil sonrasi oldugu icin BUYUK olmali, ama dunyanin
	# o donemki buyume hiziyla (yilda ~%0.5) sinirli. Bant: [1.0, 1.3].
	#
	# Bu bir kalibrasyon DEGIL, bagimsiz bir capadir: kurulusta hicbir yerde
	# dunya toplami hedeflenmedi, tek tek topraklardan cikti.
	var oran := toplam / DUNYA_1820
	_dogrula(oran >= 1.0 and oran <= 1.3,
			"1836 toplami Maddison'in dunya 1820'siyle tutarli",
			"%.0f / %.0f = %.3f" % [toplam, DUNYA_1820, oran])


# ---------------------------------------------------------------------------
# MOTORA ULASIYOR MU
# ---------------------------------------------------------------------------

static func _motora_ulasiyor_mu() -> void:
	print("")
	print("MOTORA ULASIYOR MU")
	var kodlar := Harita.kapi_kodlar(54)
	var w := Harita.dunya_kur(kodlar, 42, BAS)

	# 1. Kurulan dunyanin `L_etkin`i tabloyla BIREBIR ayni mi.
	var sapan := 0
	for i in range(w.ulkeler.size()):
		var beklenen := TohumVerisi.l_etkin(w.adlar[i])
		if absf(w.ulkeler[i].L_etkin - beklenen) > 1e-9:
			sapan += 1
	_dogrula(sapan == 0, "kurulan dunyanin L_etkin'i tabloyla ayni",
			"sapan: %d" % sapan)

	# 2. Kesit GERCEKTEN ayrisik mi. Tohumdan onceki dunyada bu oran tam
	#    1.00'di; denetim onun geri gelmesini yakalar.
	var en_kucuk := INF
	var en_buyuk := -INF
	for d in w.ulkeler:
		en_kucuk = minf(en_kucuk, d.L_etkin)
		en_buyuk = maxf(en_buyuk, d.L_etkin)
	_dogrula(en_buyuk / en_kucuk > 100.0,
			"kesit ayrisik (tohum oncesi bu oran 1.00'di)",
			"L_max/L_min = %.0f" % (en_buyuk / en_kucuk))

	# 3. `K` TOHUMU TAKIP ETTI MI. Cekirdek `baslat()`inde K'yi L'den
	#    turetir; tohumlanmis bir dunyada K/L ulkeler arasinda YALNIZCA
	#    merdivenin `q`suyla degismeli, buyuklukle DEGIL. Bu, "yalnizca
	#    L_etkin tohumlamak yeter" iddiasinin kendisidir.
	var oranlar := {}
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		var anahtar := "%.4f" % d.q
		var kl := d.K / maxf(d.L_etkin, 1e-12)
		if oranlar.has(anahtar):
			oranlar[anahtar][0] = minf(oranlar[anahtar][0], kl)
			oranlar[anahtar][1] = maxf(oranlar[anahtar][1], kl)
		else:
			oranlar[anahtar] = [kl, kl]
	var en_kotu := 0.0
	for anahtar in oranlar:
		var a: Array = oranlar[anahtar]
		en_kotu = maxf(en_kotu, a[1] / maxf(a[0], 1e-12) - 1.0)
	# BICIM `%f`, `%e` DEGIL: GDScript'in `%` bicimlendiricisi bilimsel
	# gosterimi desteklemez ve "unsupported format character" ile duser --
	# denetim gecerken satirin kendisi hata basar.
	_dogrula(en_kotu < 1e-9,
			"K/L ayni merdiven basamaginda buyukten kucuge AYNI",
			"en buyuk bagil sapma = %.12f" % en_kotu)

	# 4. Hasila tohumu takip ediyor mu: t=0'da Y kesiti L kesitiyle ayni
	#    mertebede olmali. Adim atilmadan once `Y_yil` `baslat()`ta yazilir.
	var y_kucuk := INF
	var y_buyuk := -INF
	for d in w.ulkeler:
		y_kucuk = minf(y_kucuk, d.Y_yil)
		y_buyuk = maxf(y_buyuk, d.Y_yil)
	var y_oran := y_buyuk / maxf(y_kucuk, 1e-12)
	var l_oran := en_buyuk / en_kucuk
	_dogrula(y_oran > 0.5 * l_oran and y_oran < 2.0 * l_oran,
			"t=0'da Y kesiti L kesitiyle ayni mertebede",
			"Y_max/min = %.0f, L_max/min = %.0f" % [y_oran, l_oran])
