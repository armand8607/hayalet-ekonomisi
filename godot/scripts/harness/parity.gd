class_name Parity
extends RefCounted

## PARITE DOKUMLERI -- portun dogrulanmasinin omurgasi.
##
## Her rutin, Python tarafinda `python/tools/dump_trace.py` icindeki esdegeri
## ile SATIR SATIR ayni cikti uretmelidir. Karsilastirma `tools/compare_dump.py`
## ile yapilir.
##
## FLOAT'LAR ONDALIK DEGIL IEEE754 BIT DESENI OLARAK BASILIR. Ondalik
## bicimlendirme (`%.17g` vb.) iki dilde ayni yuvarlamayi garanti etmez ve
## "esit mi degil mi" sorusunu bicimlendirme sorusuna cevirir; bit deseni
## bu belirsizligi tamamen ortadan kaldirir.

## Bir double'in little-endian IEEE754 bit deseni (16 haneli hex).
## Python karsiligi: struct.pack('<d', x).hex()
static func f64(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.hex_encode()


static func yaz(s: String) -> void:
	print(s)


# ---------------------------------------------------------------------------
# KATMAN 1 -- RNG akisi. SERT KAPI: birebir esit olmali.
# ---------------------------------------------------------------------------
static func dump_rng(tohum: int = 42) -> void:
	yaz("# rng tohum=%d" % tohum)

	var r := PyRandom.new(tohum)
	for i in range(10000):
		yaz("random %d %s" % [i, f64(r.random())])

	# randint ve choice AYRI bir ornekten cekilir: Python tarafinda da oyle,
	# yoksa akis konumu kayar ve karsilastirma anlamsizlasir.
	var r2 := PyRandom.new(tohum)
	for i in range(1000):
		yaz("randint %d %d" % [i, r2.randint(0, 99)])

	var r3 := PyRandom.new(tohum)
	var dizi := []
	for i in range(20):
		dizi.append(i * 7)
	for i in range(1000):
		yaz("choice %d %d" % [i, r3.choice(dizi)])

	# getrandbits: _randbelow'un dogrudan tabani.
	var r4 := PyRandom.new(tohum)
	for k in [1, 2, 3, 7, 8, 15, 16, 31, 32]:
		for i in range(50):
			yaz("getrandbits %d %d %d" % [k, i, r4.getrandbits(k)])


# ---------------------------------------------------------------------------
# KATMAN 2 -- crc32. Politika AI'sinin zamanlamasini belirledigi icin
# mekanizmanin parcasi (bkz. crc32.gd).
# ---------------------------------------------------------------------------
static func dump_crc32() -> void:
	var p := Params.make()
	yaz("# crc32 ai_periyot=%d" % p.ai_periyot)
	for satir in Tables.ULKELER:
		var ad := String(satir[0])
		var c := Crc32.of_string(ad)
		yaz("crc32 %s %d %d" % [ad, c, c % p.ai_periyot])
	# Kenar durumlar: bos metin, ascii disi, uzun metin.
	for ad in ["", "a", "abc", "Türkiye", "Çin", "0123456789"]:
		yaz("crc32x %s %d" % [ad, Crc32.of_string(ad)])


# ---------------------------------------------------------------------------
# KATMAN 2 -- 355 kalibrasyon sabiti. Uretim adiminin sadakatini kanitlar.
# ---------------------------------------------------------------------------
static func dump_params() -> void:
	var p := Params.make()
	var adlar := p.alanlar_sirali()
	yaz("# params alan_sayisi=%d karma=%s" % [adlar.size(), ParamSet.BEKLENEN_KARMA])
	for ad in adlar:
		var v = p.get(ad)
		match typeof(v):
			TYPE_BOOL:
				yaz("param %s bool %s" % [ad, "1" if v else "0"])
			TYPE_INT:
				yaz("param %s int %d" % [ad, v])
			TYPE_FLOAT:
				yaz("param %s float %s" % [ad, f64(v)])
			TYPE_STRING:
				yaz("param %s str %s" % [ad, v])
			TYPE_ARRAY:
				var parcalar := PackedStringArray()
				for x in v:
					parcalar.append(f64(float(x)))
				yaz("param %s array %s" % [ad, " ".join(parcalar)])
			_:
				yaz("param %s ??? %s" % [ad, str(v)])


# ---------------------------------------------------------------------------
# KATMAN 2 -- saf fonksiyonlar sabit bir girdi izgarasinda.
# BURADA AYRISMA BEKLENIYOR: exp/log/pow libm'e gider ve CPython ile Godot son
# ulp'de ayrilabilir. Amac "sifir fark" degil, farkin BUYUKLUGUNU olcmek --
# katman 3'un tolerans esikleri bu olcume dayanacak.
# ---------------------------------------------------------------------------
static func dump_formulas() -> void:
	yaz("# formulas TUR_YIL=%s KAMPANYA_TURU=%d" % [f64(Formulas.TUR_YIL), Formulas.KAMPANYA_TURU])
	yaz("# kampanya_turu_dogru=%s" % ("1" if Formulas.kampanya_turu_dogru() else "0"))

	var qlar := [1e-6, 0.001, 0.1, 0.5, 0.9, 1.0, 2.6, 5.2, 10.5, 21.0, 42.0,
			60.0, 100.0, 158.3281, 200.0, 500.0]
	for q in qlar:
		yaz("organik_bilesim %s %s" % [f64(q), f64(Formulas.organik_bilesim(q))])

	for x in [-0.05, -0.001, 0.0, 0.0045, 0.008, 0.0205, 0.16, 0.42, 1.0]:
		yaz("yillik %s %s" % [f64(x), f64(Formulas.yillik(x))])

	for x in [-100.0, -60.0, -10.0, -1.0, -0.5, 0.0, 0.5, 1.0, 10.0, 60.0, 100.0]:
		yaz("sg %s %s" % [f64(x), f64(Formulas.sg(x))])

	# cv capalari: ERAS'tan turetiliyor, ayri yazilmiyor.
	for c in Tables.cv_capalari():
		yaz("cv_capa %s %s" % [f64(float(c[0])), f64(float(c[1]))])


# ---------------------------------------------------------------------------
# Veri katmani ic tutarliligi (Python gerektirmez).
# ---------------------------------------------------------------------------
static func self_test() -> int:
	var sonuc: Dictionary = Params.dogrula()
	yaz("=== veri katmani dogrulamasi ===")
	yaz("  ParamSet alan sayisi : %d" % Params.make().alanlar_sirali().size())
	yaz("  parametre karmasi    : %s" % ParamSet.BEKLENEN_KARMA)
	yaz("  cag / kurum / ulke   : %d / %d / %d"
			% [Tables.ERAS.size(), Tables.KURUMLAR.size(), Tables.ULKELER.size()])
	yaz("  KAMPANYA_TURU        : %d (turetim dogru: %s)"
			% [Formulas.KAMPANYA_TURU, Formulas.kampanya_turu_dogru()])
	yaz("  organik_bilesim(1.0) : %.12f" % Formulas.organik_bilesim(1.0))
	yaz("  organik_bilesim(42.0): %.12f" % Formulas.organik_bilesim(42.0))
	yaz("  sg(0.0)              : %.12f" % Formulas.sg(0.0))

	if sonuc["gecti"]:
		yaz("SONUC: GECTI")
		return 0
	for h in sonuc["hatalar"]:
		yaz("  HATA: " + str(h))
	yaz("SONUC: KALDI")
	return 1
