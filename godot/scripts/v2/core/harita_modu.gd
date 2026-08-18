class_name HaritaModu
extends RefCounted

## B5'IN DOKUZ HARITA MODU.
##
## Bir mod, dunyanin TEK BIR sorusudur: "kim daha karli", "kim boluk",
## "kim kime deger veriyor". Victoria'nin harita modlarindan farki, dokuzunun
## da motorun KENDI degiskenleri olmasi -- hicbiri gosterim icin ayrica
## hesaplanmaz, hicbiri turetilmis bir "skor" degildir.
##
## ------------------------------------------------------------------------
## OLCEK VERIDEN GELIR, SABIT ARALIKTAN DEGIL
## ------------------------------------------------------------------------
## `Chart`in dersi burada da gecerli: kar orani 0.15'ten 0.04'e inerken sabit
## [0,1] ekseninde butun dunya tek renk olur ve oyunun anlattigi asil sey --
## DUSME EGILIMI -- kaybolur. Her mod araligini o anki dunyadan alir.
##
## Bunun bedeli var ve bilincli: renkler kampanya boyunca YENIDEN OLCEKLENIR,
## yani "dun kirmizi bugun sari" mutlak bir iyilesme demek degildir. Efsane
## (`efsane()`) bu yuzden her zaman SAYIYI da yazar.
##
## ------------------------------------------------------------------------
## AYRISAN MODLARDA MERKEZ SIFIR YA DA MEDYANDIR
## ------------------------------------------------------------------------
## Dis ticaret ve dis konum icin anlamli esik SIFIRDIR (veren mi alan mi).
## Kar orani icin sifir anlamsizdir -- hepsi pozitiftir; anlamli soru
## "dunyaya gore nerede" oldugu icin merkez MEDYANDIR.

## Ayrisan modun iki ucu ve merkezi.
const AZ := Color("4a90d9")        ## merkezin altinda (mavi)
const ORTA := Color("2c3346")      ## merkez
const COK := Color("e8c25a")       ## merkezin ustunde (kehribar)

## Sirali modun tabani. Ust ucu her modun kendi rengidir: dokuz modun
## dokuzu da ayni rampayi kullansaydi mod degistirmek FARK EDILMEZDI.
const TABAN := Color("222839")

## Simule edilmeyen ulke. Cizilir ama veri tasimaz (bkz. `Harita`).
##
## NOTR GRI, ve bu bilincli: butun mod rampalari mavi-kehribar-kirmizi
## ekseninde durdugu icin renksiz bir gri hicbir modun degeriyle
## karistirilamaz. Ilk denemede mavimsi bir koyu ton secilmisti ve ayrisan
## modun MERKEZ rengiyle (ORTA) neredeyse ayni cikiyordu -- yani "veri yok"
## ile "tam ortada" ekranda ayni goruntuydu.
const VERI_YOK := Color("242424")

const MODLAR: Array[Dictionary] = [
	{"id": "siyasi", "ad": "Siyasi", "tip": "kategorik", "merkez": "",
	 "bicim": "", "renk": "",
	 "aciklama": "Rejim ve kurumsal düzen. Devrim haritada bir renk değişimidir."},
	{"id": "kar_orani", "ad": "Kâr oranı", "tip": "ayrisan", "merkez": "medyan",
	 "bicim": "oran3", "renk": "",
	 "aciklama": "Yıllık kâr oranı, dünya medyanına göre. Motorun ekseni budur."},
	{"id": "bunalim", "ad": "Bunalım", "tip": "sirali", "merkez": "",
	 "bicim": "yuzde", "renk": "e0553b",
	 "aciklama": "Hasılanın trendin ne kadar altında olduğu -- bunalımın derinliği."},
	{"id": "issizlik", "ad": "İşsizlik", "tip": "sirali", "merkez": "",
	 "bicim": "yuzde", "renk": "e07b39",
	 "aciklama": "Yedek sanayi ordusu. Ücret payının pazarlık gücünü bu belirler."},
	{"id": "bolunme", "ad": "Bölünme", "tip": "sirali", "merkez": "",
	 "bicim": "oran2", "renk": "b5474a",
	 "aciklama": "Emekçi sınıfın kendi içine bölünmüşlüğü -- karanlık devletin ürünü."},
	{"id": "orgutlenme", "ad": "Örgütlenme", "tip": "sirali", "merkez": "",
	 "bicim": "oran2", "renk": "5cb87a",
	 "aciklama": "Sendika ve parti: bölünmenin karşısındaki hareket."},
	{"id": "ticaret", "ad": "Dış ticaret", "tip": "ayrisan", "merkez": "sifir",
	 "bicim": "yuzde", "renk": "",
	 "aciklama": "Net ihracat / hasıla. Toplamı sıfırdır: birinin fazlası ötekinin açığı."},
	{"id": "dis_konum", "ad": "Dış konum", "tip": "ayrisan", "merkez": "sifir",
	 "bicim": "kat", "renk": "",
	 "aciklama": "Dört dış kanalın BİRİKMİŞ toplamı / yıllık hasıla (kat). Emperyalizmin imzası."},
	{"id": "otomasyon", "ad": "Otomasyon", "tip": "sirali", "merkez": "",
	 "bicim": "oran2", "renk": "6ea8d9",
	 "aciklama": "Canlı emeğin yerini alan pay. LTRPF'nin doruk noktası, koşulu değil."},
]


static func mod(id: String) -> Dictionary:
	for m in MODLAR:
		if m["id"] == id:
			return m
	return MODLAR[0]


static func kimlikler() -> PackedStringArray:
	var c := PackedStringArray()
	for m in MODLAR:
		c.append(String(m["id"]))
	return c


# ---------------------------------------------------------------------------
# DEGER
# ---------------------------------------------------------------------------
## Modun ulke icin okudugu sayi. HICBIRI TURETILMIS BIR SKOR DEGILDIR:
## hepsi motorun kendi alanidir ya da motorun kendi kullandigi ifadedir.
static func deger(id: String, w: Dunya, i: int) -> float:
	var d: KrizDurumu = w.ulkeler[i]
	match id:
		"siyasi":
			return 1.0 if d.rejim == "sosyalist" else 0.0
		"kar_orani":
			return d.r_yil
		"bunalim":
			# `_kriz_tescili`nin KENDI ifadesi: derinlik = 1 - Y_ort/Y_trend.
			# Ayrica hesaplanmaz, ayni iki alandan okunur -- yoksa harita
			# motorun bunalim tanimindan sessizce ayrisirdi.
			return clampf(1.0 - d.Y_ort / maxf(d.Y_trend, 1e-9), 0.0, 1.0)
		"issizlik":
			return d.iss_duzeltilmis()
		"bolunme":
			return d.bolunme
		"orgutlenme":
			return d.orgutlu
		"ticaret":
			return d.NX_yil / maxf(d.Y_yil, 1e-9)
		"dis_konum":
			return w.dis_konum(i)
		"otomasyon":
			return d.oto
	return 0.0


## Modun bu dunyadaki araligi: [alt, ust, merkez].
##
## Merkez ayrisan modlarda renk donum noktasidir; sirali modlarda kullanilmaz
## ama yine de dondurulur ki cagiran taraf iki ayri fonksiyon cagirmasin.
static func aralik(id: String, w: Dunya) -> Vector3:
	var m := mod(id)
	var n := w.ulkeler.size()
	if n == 0:
		return Vector3(0.0, 1.0, 0.0)
	var degerler := PackedFloat64Array()
	for i in range(n):
		degerler.append(deger(id, w, i))
	var alt: float = degerler[0]
	var ust: float = degerler[0]
	for v in degerler:
		alt = minf(alt, v)
		ust = maxf(ust, v)
	var merkez := 0.0
	match String(m["merkez"]):
		"sifir":
			merkez = 0.0
			# Ayrisan olcek SIMETRIK olmali: eksi ve arti ucu ayri
			# olceklenirse "sifira ne kadar yakin" sorusu iki tarafta
			# farkli anlama gelir.
			var uc: float = maxf(absf(alt), absf(ust))
			alt = -uc
			ust = uc
		"medyan":
			merkez = _medyan(degerler)
		_:
			merkez = alt
	return Vector3(alt, ust, merkez)


static func _medyan(a: PackedFloat64Array) -> float:
	var s := a.duplicate()
	s.sort()
	var n := s.size()
	if n == 0:
		return 0.0
	if n % 2 == 1:
		return s[n / 2]
	return 0.5 * (s[n / 2 - 1] + s[n / 2])


# ---------------------------------------------------------------------------
# RENK
# ---------------------------------------------------------------------------
## Ulkenin bu moddaki rengi. `simule` false ise ulke haritada CIZILIR ama
## veri tasimaz -- rengi tek ve notrdur.
static func renk(id: String, w: Dunya, i: int, ar: Vector3) -> Color:
	var m := mod(id)
	var d: KrizDurumu = w.ulkeler[i]
	if String(m["tip"]) == "kategorik":
		# Siyasi mod REJIMI temel alir, kurumu doygunlukla anlatir: iki
		# eksen tek renkte toplanmazsa harita iki kez okunmak zorunda kalir.
		var taban := Tema.rejim_rengi(d.rejim)
		if d.rejim == "kapitalist":
			taban = taban.lerp(Tema.kurum_rengi(d.kurum), 0.45)
		if d.parti_iktidari:
			taban = taban.lerp(Tema.REJIM["sosyalist"], 0.30)
		return taban
	var v := deger(id, w, i)
	if String(m["tip"]) == "ayrisan":
		var merkez := ar.z
		if v >= merkez:
			var t := _oran(v - merkez, ar.y - merkez)
			return ORTA.lerp(COK, t)
		var t2 := _oran(merkez - v, merkez - ar.x)
		return ORTA.lerp(AZ, t2)
	var ust_renk := Color(String(m["renk"]))
	return TABAN.lerp(ust_renk, _oran(v - ar.x, ar.y - ar.x))


static func _oran(pay: float, payda: float) -> float:
	if payda <= 1e-12:
		return 0.0
	return clampf(pay / payda, 0.0, 1.0)


# ---------------------------------------------------------------------------
# EFSANE
# ---------------------------------------------------------------------------
## Ekranin altina cizilecek renk skalasi: [{renk, etiket}].
##
## SAYIYI HER ZAMAN YAZAR. Olcek veriden geldigi icin renk tek basina
## anlamsizdir; "kirmizi" bir kampanyada %8 issizlik, otekinde %30 olabilir.
static func efsane(id: String, w: Dunya) -> Array[Dictionary]:
	var m := mod(id)
	if String(m["tip"]) == "kategorik":
		return [
			{"renk": Tema.REJIM["kapitalist"].lerp(Tema.KURUM["liberal"], 0.45),
			 "etiket": "liberal"},
			{"renk": Tema.REJIM["kapitalist"].lerp(Tema.KURUM["duzenli"], 0.45),
			 "etiket": "düzenli"},
			{"renk": Tema.REJIM["kapitalist"].lerp(Tema.KURUM["neoliberal"], 0.45),
			 "etiket": "neoliberal"},
			{"renk": Tema.REJIM["sosyalist"], "etiket": "sosyalist"},
		]
	var ar := aralik(id, w)
	var cikti: Array[Dictionary] = []
	var adim := 4
	for k in range(adim + 1):
		var t := float(k) / float(adim)
		var v: float = ar.x + (ar.y - ar.x) * t
		cikti.append({"renk": _skala_rengi(m, ar, v), "etiket": bicimle(v, String(m["bicim"]))})
	return cikti


static func _skala_rengi(m: Dictionary, ar: Vector3, v: float) -> Color:
	if String(m["tip"]) == "ayrisan":
		if v >= ar.z:
			return ORTA.lerp(COK, _oran(v - ar.z, ar.y - ar.z))
		return ORTA.lerp(AZ, _oran(ar.z - v, ar.z - ar.x))
	return TABAN.lerp(Color(String(m["renk"])), _oran(v - ar.x, ar.y - ar.x))


static func bicimle(v: float, bicim: String) -> String:
	match bicim:
		"yuzde":
			return "%%%.1f" % (v * 100.0)
		"oran3":
			return "%.3f" % v
		"oran2":
			return "%.2f" % v
		"kat":
			# Birikmis bir stok ile YILLIK bir akimin orani. Yuzde olarak
			# yazilinca "%963" cikiyor ve okunmuyor; dogru okuma "9.6 kat".
			return "%.1f kat" % v
	return "%.2f" % v
