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
# KATMAN 3a -- DUNYA KURULUMU. Motor portunun ilk kontrol noktasi.
#
# Burasi gectiginde su dordu birden kanitlanmis olur: Country'nin 138 alani,
# dunya tohum tablosu, cag_ata'nin goreli-konum aritmetigi ve init_simulation'in
# olcekleme zinciri. step() yazilmadan once bunlarin dogru olmasi sart --
# yanlis bir baslangic durumu her turu bozar ve hatayi step() icinde aratir.
# ---------------------------------------------------------------------------

## Sayisal degerler DAIMA f64 olarak basilir, int/float ayrimi yapilmadan.
## Neden: Python'da `L_max` kurulusta int 110, birkac tur sonra float 110.37.
## Tipe gore bicimlendirmek, deger ayni olsa bile sahte fark uretirdi.
static func _deger(v) -> String:
	match typeof(v):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool " + ("1" if v else "0")
		TYPE_INT, TYPE_FLOAT:
			return "num " + f64(float(v))
		TYPE_STRING, TYPE_STRING_NAME:
			return "str " + String(v)
		TYPE_DICTIONARY:
			var anahtarlar := (v as Dictionary).keys()
			anahtarlar.sort()
			var parcalar := PackedStringArray()
			for k in anahtarlar:
				parcalar.append("%s=%s" % [k, _skaler(v[k])])
			return "dict " + " ".join(parcalar)
		TYPE_ARRAY:
			var ogeler := PackedStringArray()
			for x in v:
				ogeler.append(_skaler(x))
			return "array " + " ".join(ogeler)
	return "??? " + str(v)


## Ic ice yapilarin ogeleri. `pol_kuyruk` gibi alanlar sozluk icinde dizi
## tasiyor [deger, etkinlesme_turu]; sayisal olmayan ogeler metin basilir.
static func _skaler(x) -> String:
	match typeof(x):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "1" if x else "0"
		TYPE_INT, TYPE_FLOAT:
			return f64(float(x))
		TYPE_ARRAY:
			var p := PackedStringArray()
			for y in x:
				p.append(_skaler(y))
			return "(" + ",".join(p) + ")"
		TYPE_DICTIONARY:
			var anahtarlar := (x as Dictionary).keys()
			anahtarlar.sort()
			var p2 := PackedStringArray()
			for k in anahtarlar:
				p2.append("%s:%s" % [k, _skaler(x[k])])
			return "{" + ",".join(p2) + "}"
	return String(x)


static func _dump_dunya(e: GhostEngine) -> void:
	yaz("motor K_olcek num %s" % f64(e.K_olcek))
	yaz("motor K_carpani num %s" % f64(e.K_carpani))
	yaz("motor hedef_istihdam num %s" % f64(e.hedef_istihdam))
	yaz("motor t num %s" % f64(float(e.t)))
	yaz("motor dunya_devrimi bool %s" % ("1" if e.dunya_devrimi else "0"))
	yaz("motor dd_sayac num %s" % f64(float(e.dd_sayac)))
	yaz("motor pakt_uyumu num %s" % f64(e.pakt_uyumu))
	yaz("motor kap_kriz_payi num %s" % f64(e.kap_kriz_payi))
	yaz("motor log_sayisi num %s" % f64(float(e.log.size())))

	for c in e.D:
		var adlar := PackedStringArray()
		for p in c.get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				adlar.append(p.name)
		adlar.sort()
		for ad in adlar:
			if ad == "tarih":
				continue   # History nesnesi; ayri dokumleniyor
			var v = c.get(ad)
			if ad == "muttefik":
				# Python'da bu bir `set`; GDScript'te Set yok. Uyeligi
				# karsilastirmak icin siralanir -- SIRA parite olcutu degildir,
				# olamaz da: Python set yinelemesi dizgi hash'ine baglidir.
				v = (v as Array).duplicate()
				v.sort()
			yaz("ulke %s %s %s" % [c.ad, ad, _deger(v)])


static func dump_init(tohum: int = 42) -> void:
	var e := GhostEngine.new(tohum)
	yaz("# init tohum=%d ulke=%d" % [tohum, e.D.size()])
	_dump_dunya(e)


# ---------------------------------------------------------------------------
# KATMAN 3b -- TUR-TUR IZ. Portun asil sinavi.
#
# N tur kosturur ve butun dunya durumunu doker. Ilk sapan alan hatanin hangi
# blokta oldugunu dogrudan soyler; compare_dump.py goreli farki da basar.
# ---------------------------------------------------------------------------
static func dump_turn(tur: int, tohum: int = 42) -> void:
	var e := GhostEngine.new(tohum)
	for _i in range(tur):
		e.step()
	yaz("# turn tur=%d tohum=%d" % [tur, tohum])
	_dump_dunya(e)

	# Son turun tarih kaydi: step()'in butun ara degiskenlerini gorunur kilar.
	for c in e.D:
		var alanlar := c.tarih.alanlar()
		for ad in alanlar:
			var s := c.tarih.seri(ad)
			if s.size() > 0:
				yaz("tarih %s %s num %s" % [c.ad, ad, f64(s[s.size() - 1])])
		yaz("tarih %s rej str %s" % [c.ad, c.tarih.metin("rej", c.tarih.tur_sayisi() - 1)])
		yaz("tarih %s kurum str %s" % [c.ad, c.tarih.metin("kurum", c.tarih.tur_sayisi() - 1)])

	# Olay gunlugu: tip ve mesaj birebir esitse kriz siniflandirmasi da dogrudur.
	for kayit in e.log:
		yaz("log %d %s %s" % [int(kayit[0]), String(kayit[1]), String(kayit[2])])


# ---------------------------------------------------------------------------
# TANI -- libm mutabakati. exp/log/pow CPython ile Godot arasinda son bitte
# ayrisiyor mu? 36 noktalik formul izgarasi uyusmasi bunu KANITLAMAZ; burada
# genis ve deterministik bir izgara taranir.
# ---------------------------------------------------------------------------
static func dump_libm() -> void:
	yaz("# libm")
	# Deterministik izgara: MT19937'den cekilir, iki tarafta da ayni sayilar.
	var r := PyRandom.new(12345)
	for i in range(4000):
		var x := (r.random() - 0.5) * 40.0
		yaz("exp %d %s %s" % [i, f64(x), f64(exp(x))])
	for i in range(2000):
		var x := r.random() * 200.0 + 1e-9
		yaz("log %d %s %s" % [i, f64(x), f64(log(x))])
	for i in range(2000):
		var b := r.random() * 20.0 + 0.01
		var e2 := (r.random() - 0.5) * 6.0
		yaz("pow %d %s %s %s" % [i, f64(b), f64(e2), f64(pow(b, e2))])


# ---------------------------------------------------------------------------
# TANI -- step() icindeki dunya toplamlari.
#
# Float toplamasi BIRLESMELI DEGILDIR: ayni sayilari baska sirada toplamak
# son bitte farkli sonuc verir. VT_net ve goc_net bu toplamlara bolundugu icin
# bir ulp'lik sapma dogrudan oraya yansiyor. Bu dokum, sapmanin toplamda mi
# yoksa formulde mi oldugunu ayirir.
# ---------------------------------------------------------------------------
static func dump_agg(tohum: int = 42) -> void:
	var e := GhostEngine.new(tohum)
	yaz("# agg tohum=%d" % tohum)

	var Yv := {}
	for c in e.D:
		Yv[c.ad] = minf(c.K / e.kappa_v(Formulas.organik_bilesim(c.q) * c.deger_carpani, c.q),
				c.q * c.l_etkin())
	for c in e.D:
		yaz("Yv %s %s" % [c.ad, f64(float(Yv[c.ad]))])

	var top := 0.0
	for c in e.D:
		top += float(Yv[c.ad])
	yaz("top %s" % f64(top))

	var ort_cv := 0.0
	var ort_sv := 0.0
	var ort_q := 0.0
	for c in e.D:
		ort_cv += Formulas.organik_bilesim(c.q) * c.deger_carpani * float(Yv[c.ad])
		ort_sv += (1.0 / maxf(c.pay, 0.05) - 1.0) * float(Yv[c.ad])
		ort_q += c.q * float(Yv[c.ad])
	yaz("ort_cv_ham %s" % f64(ort_cv))
	yaz("ort_sv_ham %s" % f64(ort_sv))
	yaz("ort_q_ham %s" % f64(ort_q))
	yaz("ort_cv %s" % f64(ort_cv / top))
	yaz("ort_sv %s" % f64(ort_sv / top))
	yaz("ort_q %s" % f64(ort_q / top))

	var cek := {}
	for c in e.D:
		cek[c.ad] = c.pay * c.q * c.e
	var sc := 0.0
	for c in e.D:
		sc += float(cek[c.ad])
	yaz("cek_toplam %s" % f64(sc))
	yaz("ort_cek %s" % f64(sc / float(e.D.size())))
	var tot_L := 0.0
	for c in e.D:
		tot_L += c.L_max
	yaz("tot_L %s" % f64(tot_L))


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
