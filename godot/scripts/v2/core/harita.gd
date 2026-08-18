class_name Harita
extends RefCounted

## B5'IN HARITA MODELI -- geometri, izdusum, isabet testi, dunya kurulumu.
##
## CIZIM BURADA DEGIL. Bu sinif `RefCounted`tir ve hicbir sey cizmez;
## `_draw()` isi `ui/harita_gorunum.gd`indedir. Ayrim bir duzen tercihi degil
## TEST GEREGIDIR: deponun kurali "`--headless` hicbir sey cizmez, `_draw()`
## KOSMAZ", yani cizime baglanan her sey CI'da sinanamaz. Isabet testi,
## izdusum ve dunya kurulumu buradadir ve `--v2-harita` hepsini headless
## sinar.
##
## HARITA MOTORA DOKUNMAZ. Tek yonlu bir okuyucudur: `Dunya`dan ve
## `KrizDurumu`dan OKUR, hicbirine yazmaz. Katman takma/cikarma tartismasi
## (B2/B3/B4) burada YOKTUR, cunku takilacak bir sey yok -- harita bir
## gorunumdur, bir mekanizma degil.

# ---------------------------------------------------------------------------
# IZDUSUM -- MILLER SILINDIRIK
# ---------------------------------------------------------------------------
# Neden Mercator DEGIL: Mercator kutuplarda sonsuza gider ve Gronland'i
# Afrika buyuklugunde gosterir. Bu oyunda harita bir SIYASI okuma yuzeyidir
# (kim kime deger aktariyor); alan carpitmasi dogrudan yaniltir.
#
# Neden duz esdikdortgen (equirectangular) DEGIL: o da kutuplari asiri gerer
# ama asil sorun estetik degil -- yuksek enlemde ulkeler tanidik seklini
# kaybeder ve harita "okunmaz" hale gelir.
#
# Miller ikisinin arasindadir: kapali formu vardir (tablo gerekmez, Robinson
# gibi), kutuplari sonluda tutar ve sekilleri tanidik birakir.
#
#     y = 1.25 * asinh(tan(0.8 * enlem))
#
# PENCERE ASIMETRIKTIR: +84 / -58. Kirpma zorunlu (y kutupta sonsuza gider)
# ama SIMETRIK kirpmak icin bir sebep yok -- ve simetrik kirpinca ekranin
# alt beste biri bos kaliyordu, cunku Antarktika disarida (nufus yok) ve
# verideki en guney nokta -55.6 (Tierra del Fuego).
#
# Sinirlar VERIDEN secildi: kuzeyde Gronland'in ucu 83.56, guneyde Tierra
# del Fuego -55.63. Ikisine de birkac derece pay birakildi. Sonucta en/boy
# ~1.99, yani dunya haritasinin dogal orani.
const ENLEM_KUZEY := 84.0
const ENLEM_GUNEY := -58.0

## Pencerenin iki ucundaki Miller y'si -- normalizasyon boleni. Sabit olarak
## yazilmaz, ayni formulden HESAPLANIR: iki yerde yazilan bir sayi er gec
## ayrisir.
static var _y_kuzey: float = 0.0
static var _y_guney: float = 0.0

# ---------------------------------------------------------------------------
# BASLANGIC MERDIVENI
# ---------------------------------------------------------------------------
# `HaritaVerisi.konum` (merkez/yari/cevre) yalnizca BU tablodan bir basamak
# secer. Basamaklarin kendisi B1b'nin olculmus merdivenidir; burada yeni bir
# kalibrasyon YOKTUR ve olsaydi da yeri burasi olmazdi.
#
# NE OLMADIGI ONEMLI: bu tablo ulkelere buyukluk vermez (`L_etkin` hepsinde
# ayni). Tarihsel buyukluk (nufus, sermaye stoku) B6'nin isidir -- ve o
# yapilana kadar haritanin gosterdigi ayrisma YALNIZCA uretkenlik farkindan
# ve kaotik ayrismadan gelir, verilmis bir hiyerarsiden degil.
const MERDIVEN := {
	"merkez": [1.60, 0.42],
	"yari": [1.00, 0.30],
	"cevre": [0.65, 0.18],
}

## Ulke kaydi. `HaritaVerisi`den BIR KEZ cozulur ve paylasilir: 156 ulkenin
## 4490 noktasini her cagride yeniden ayristirmak, panelin her karesinde
## yapilacak bir is degil.
##
## Alanlar (uretilmis veriye ek olanlar):
##   `halkalar`  : Array[PackedVector2Array] -- IZDUSUM ALMIS, [0,1]^2 icinde
##   `derece`    : Array[PackedVector2Array] -- ham derece (isabet testi)
##   `ucgenler`  : Array[PackedInt32Array]   -- ucgenleme, bir kez
##   `kutu_d`    : Rect2 -- derece cinsinden sinir kutusu (isabet on elemesi)
##   `merkez_d`  : Vector2 -- etiket/bag noktasi, derece
static var _kayit: Array[Dictionary] = []
static var _kod_indeks: Dictionary = {}
## Isabet testi sirasi: KUCUK ULKE ONCE. Delikler tasinmadigi icin Lesotho
## Guney Afrika'nin, Vatikan Italya'nin icinde durur; buyuk ulke once
## sinanirsa kucugu hicbir zaman secilemez.
static var _isabet_sirasi: PackedInt32Array = PackedInt32Array()


# ---------------------------------------------------------------------------
# KAYIT
# ---------------------------------------------------------------------------
static func kayit() -> Array[Dictionary]:
	if _kayit.is_empty():
		_coz()
	return _kayit


## Kodla ulke indeksi; yoksa -1.
static func indeks(kod: String) -> int:
	if _kayit.is_empty():
		_coz()
	return int(_kod_indeks.get(kod, -1))


## Varsayilan simule dunyanin kodlari: `konum` alani dolu olanlar.
## Kalanlar CIZILIR ama simule EDILMEZ (bkz. ureticideki egemenlik notu).
static func simule_kodlar() -> PackedStringArray:
	var c := PackedStringArray()
	for u in kayit():
		if String(u["konum"]) != "":
			c.append(String(u["kod"]))
	return c


static func oynanabilir_kodlar() -> PackedStringArray:
	var c := PackedStringArray()
	for u in kayit():
		if bool(u["oynanabilir"]):
			c.append(String(u["kod"]))
	return c


static func _coz() -> void:
	_pencere()
	_kayit = []
	_kod_indeks = {}
	var olcek: float = HaritaVerisi.OLCEK
	var alanlar: Array = []
	for ham in HaritaVerisi.ULKELER:
		var derece: Array[PackedVector2Array] = []
		var halkalar: Array[PackedVector2Array] = []
		var ucgenler: Array[PackedInt32Array] = []
		for duz in ham["halkalar"]:
			var d := PackedVector2Array()
			var y := PackedVector2Array()
			d.resize(duz.size() / 2)
			y.resize(duz.size() / 2)
			for k in range(0, duz.size(), 2):
				var nokta := Vector2(float(duz[k]) / olcek, float(duz[k + 1]) / olcek)
				d[k / 2] = nokta
				y[k / 2] = yansit(nokta)
			derece.append(d)
			halkalar.append(y)
			# UCGENLEME IZDUSUM UZAYINDA YAPILIR, derecede degil. Miller
			# enlemi DOGRUSAL OLMAYAN bicimde gerer; derecede kesismeyen iki
			# kenar izdusumden sonra kesisebilir ve ucgenleme sessizce
			# bozulurdu. Cizim izdusum uzayindan sonra yalnizca AFIN
			# (kaydirma + olcek) donusum gorur, o da ucgenlemeyi bozmaz --
			# bu yuzden bir kez hesaplanip her yakinlastirmada kullanilir.
			ucgenler.append(Geometry2D.triangulate_polygon(_buyut(y)))
		var kutu := _kutu(derece)
		var kayit_satiri := {
			"kod": String(ham["kod"]),
			"ad": String(ham["ad"]),
			"ad_1836": String(ham["ad_1836"]),
			"kita": String(ham["kita"]),
			"egemen": bool(ham["egemen"]),
			"oynanabilir": bool(ham["oynanabilir"]),
			"konum": String(ham["konum"]),
			"alan": float(ham["alan"]),
			"kutu_d": kutu,
			"merkez_d": Vector2(float(ham["merkez"][0]) / olcek,
					float(ham["merkez"][1]) / olcek),
			"derece": derece,
			"halkalar": halkalar,
			"ucgenler": ucgenler,
		}
		_kod_indeks[kayit_satiri["kod"]] = _kayit.size()
		alanlar.append([float(ham["alan"]), _kayit.size()])
		_kayit.append(kayit_satiri)

	alanlar.sort_custom(func(a, b): return a[0] < b[0])
	_isabet_sirasi = PackedInt32Array()
	for a in alanlar:
		_isabet_sirasi.append(int(a[1]))


## UCGENLEME OLCEGI. `Geometry2D.triangulate_polygon` real_t (float32)
## calisir ve ic esikleri MUTLAKTIR. Birim uzayda ([0,1]^2) kucuk bir adanin
## alani ~2e-5'e duser; kulak kirpma o olcekte ucgenleri sessizce atlar.
##
## Olculdu: Endonezya'nin bes numarali halkasi 10 noktali, ucgenleme 8 ucgen
## (yani DOGRU SAYIDA) donduruyor ama kapladigi alan poligonun %35'i. Ayni
## halka 1000 kat buyutulunce sapma sifira iniyor.
##
## Buyutme AFINDIR, yani ucgenlemeyi bozmaz: indisler olcekten bagimsizdir
## ve cizim kendi donusumunu zaten uygular.
const UCGEN_OLCEK := 1000.0


static func _buyut(h: PackedVector2Array) -> PackedVector2Array:
	var c := PackedVector2Array()
	c.resize(h.size())
	for i in range(h.size()):
		c[i] = h[i] * UCGEN_OLCEK
	return c


static func _kutu(halkalar: Array[PackedVector2Array]) -> Rect2:
	var kutu := Rect2()
	var ilk := true
	for h in halkalar:
		for p in h:
			if ilk:
				kutu = Rect2(p, Vector2.ZERO)
				ilk = false
			else:
				kutu = kutu.expand(p)
	return kutu


# ---------------------------------------------------------------------------
# IZDUSUM
# ---------------------------------------------------------------------------
static func _pencere() -> void:
	if _y_kuzey == 0.0:
		_y_kuzey = _miller_y(ENLEM_KUZEY)
		_y_guney = _miller_y(ENLEM_GUNEY)


## Derece (boylam, enlem) -> [0,1]^2. Sol ust kose (-180, +84).
static func yansit(derece: Vector2) -> Vector2:
	_pencere()
	var y := _miller_y(clampf(derece.y, ENLEM_GUNEY, ENLEM_KUZEY))
	return Vector2(
			(clampf(derece.x, -180.0, 180.0) + 180.0) / 360.0,
			(_y_kuzey - y) / (_y_kuzey - _y_guney))


## [0,1]^2 -> derece. Isabet testi ekran noktasini BURADAN cevirir; ters
## donusum olmadan poligonlari her karede ekrana tasimak gerekirdi.
static func ters(birim: Vector2) -> Vector2:
	_pencere()
	var y := _y_kuzey - birim.y * (_y_kuzey - _y_guney)
	return Vector2(birim.x * 360.0 - 180.0, rad_to_deg(atan(sinh(y / 1.25)) / 0.8))


static func _miller_y(enlem_derece: float) -> float:
	return 1.25 * asinh(tan(0.8 * deg_to_rad(enlem_derece)))


## Haritanin EN/BOY orani. [0,1]^2'ye normalize edildigi icin cizim tarafi
## bunu bilmek zorunda: iki ekseni de birim kabul etmek dunyayi dikey olarak
## ezerdi. Boylam araligi TAU radyan, enlem araligi pencerenin iki ucu.
static func en_boy() -> float:
	_pencere()
	return TAU / (_y_kuzey - _y_guney)


# ---------------------------------------------------------------------------
# ISABET TESTI
# ---------------------------------------------------------------------------
## Derece noktasindaki ulkenin indeksi; hicbiri degilse -1.
##
## Sira KUCUK ULKEDEN BUYUGE (bkz. `_isabet_sirasi`). Kutu on elemesi
## olmadan 156 ulkenin 201 halkasi taranirdi; kutu ile aday sayisi tek
## haneye duser.
static func bul(derece: Vector2) -> int:
	if _kayit.is_empty():
		_coz()
	for i in _isabet_sirasi:
		var u := _kayit[i]
		var kutu: Rect2 = u["kutu_d"]
		if not kutu.has_point(derece):
			continue
		for h in u["derece"]:
			if halkada(derece, h):
				return i
	return -1


## Isin atma (even-odd). URETICIDEKI `icinde()` ILE AYNI ALGORITMA:
## etiket noktasinin poligonun icinde oldugu orada dogrulanir, burada
## sinanir. Ikisi ayrisirsa kapi ayrismayi yakalar.
##
## Halka KAPALIDIR ama son nokta tekrarlanmaz; dongü `j = n-1`den baslayarak
## kapanisi kendisi kurar.
static func halkada(p: Vector2, halka: PackedVector2Array) -> bool:
	var n := halka.size()
	if n < 3:
		return false
	var ic := false
	var j := n - 1
	for i in range(n):
		var a := halka[i]
		var b := halka[j]
		if (a.y > p.y) != (b.y > p.y):
			var kesim := (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x
			if p.x < kesim:
				ic = not ic
		j = i
	return ic


# ---------------------------------------------------------------------------
# DUNYA KURULUMU
# ---------------------------------------------------------------------------
## Haritadan bir `Dunya` kurar. Ulkeler dunyaya KOD ile girer ("TUR",
## "GBR"); gorunen ad `kayit()`ten okunur. Ad yerine kod kullanilmasinin
## sebebi tek: dunya katmani adlari anahtar olarak kullaniyor (`muttefik`,
## `savas`) ve gorunen adin degismesi (Osmanli -> Turkiye) o anahtarlari
## kirardi.
##
## `kodlar` bos verilirse `simule_kodlar()` kullanilir.
## `katmanlar` TAM YIGINI takar (uretim, nufus, mal, karanlik devlet).
## Varsayilani `true`, ve bu bilincli bir ayrim: test kosulari katmanlari
## ayri ayri takip etkilerini YALITIR (B2/B3'un deney tasarimi), OYUN ise
## yigini butun kosar. Harita oyunun dunyasini gosterir, bir deneyin degil --
## ve `bolunme` gibi modlar katman takili degilken tanimsiz kalirdi.
static func dunya_kur(kodlar: PackedStringArray = PackedStringArray(),
		tohum: int = 42, yil: float = 1836.0,
		savas_acik: bool = true, katmanlar: bool = true) -> Dunya:
	if kodlar.is_empty():
		kodlar = simule_kodlar()
	var w := Dunya.new()
	w.yil = yil
	for kod in kodlar:
		var i := indeks(kod)
		if i < 0:
			push_warning("Haritada olmayan kod: " + kod)
			continue
		var konum := String(_kayit[i]["konum"])
		var basamak: Array = MERDIVEN.get(konum, MERDIVEN["cevre"])
		var d := _ulke(basamak[0], basamak[1], yil)
		w.ekle(d, kod, tohum)
		if katmanlar:
			_katmanlari_tak(w.cekirdekler[w.cekirdekler.size() - 1], d)
	if savas_acik:
		w.savas = SavasKatmani.new(w.P, tohum + 7777)
	return w


## Dort katmani tek yerde takar. SIRA ONEMSIZ (katmanlar birbirinden
## bagimsizdir) ama `baslat` cagrilari cekirdegin `baslat`indan SONRA
## gelmeli: hepsi ulkenin kurulmus durumundan okuyarak baslar.
static func _katmanlari_tak(c: KrizCekirdegi, d: KrizDurumu) -> void:
	var m := UretimKatmani.new()
	m.baslat(d)
	c.mikro = m
	var np := NufusKatmani.new()
	np.baslat(d)
	c.nufus = np
	var mal := MalKatmani.new()
	mal.baslat(d)
	c.mal = mal
	var kd := KaranlikDevlet.new(c.P)
	# AI ULKELERI KENDI KARAR VERIR (§4.5). Oyuncunun ulkesi disinda
	# taktikleri kimse yazmazdi ve karanlik devlet butun dunyada olu
	# kalirdi -- B4'te olculdu, `otomatik` kolu calisiyor (en yuksek
	# tolerans 0.887). Oyuncu ulkesi secildiginde onun `otomatik`i
	# kapatilir; bu B7'nin isi.
	kd.otomatik = true
	kd.baslat(d)
	c.karanlik = kd


## `dunya_testi._ulke` ile AYNI kurulum. Kopyalanmis olmasi bilincli:
## harness'lar birbirinin ic islevini cagirmaz, ve bu deger `--v2-dunya`nin
## olctugu kurulumdur -- degistirilmesi gereken bir sey varsa ikisi birden
## degismeli, sessizce biri degil.
static func _ulke(q0: float, egitim: float, yil: float) -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = q0
	d.egitim = egitim
	d.yil = yil
	d.varlik = 0.5
	return d


# ---------------------------------------------------------------------------
# BAGLAR
# ---------------------------------------------------------------------------
# §6'nin B5 olcutu: "20+ ulke, dokuz mod, BAGLAR CIZILI". Bag, iki ulke
# arasindaki iliskidir ve dordu de dunya katmaninin KENDI durumundan okunur;
# harita hicbirini uretmez.
#
#   savas    : `d.savas` sozlugunun anahtarlari
#   ittifak  : `d.muttefik` dizisi
#   abluka   : `w.abluka` matrisi (cift uzerinde tanimli)
#   ticaret  : `w.cift_hacmi(i, j)` -- en buyuk N cift
#
# TICARET NEDEN KIRPILIR: n ulkede n(n-1)/2 cift vardir, 54 ulkede 1431.
# Hepsini cizmek haritayi spagettiye cevirir ve hicbir sey anlatmaz. En
# buyuk N cift ise dunya sisteminin omurgasini gosterir -- ve hangi ciftin
# "buyuk" oldugu kampanya boyunca DEGISIR, ki asil gorulmek istenen budur.
static func baglar(w: Dunya, en_fazla_ticaret: int = 40) -> Array[Dictionary]:
	var n := w.ulkeler.size()
	var ad_indeks := {}
	for i in range(n):
		ad_indeks[w.adlar[i]] = i

	var cikti: Array[Dictionary] = []
	var gorulen := {}

	for i in range(n):
		var d := w.ulkeler[i]
		for rakip in d.savas.keys():
			var j := int(ad_indeks.get(rakip, -1))
			if j < 0:
				continue
			var anahtar := "s%d-%d" % [mini(i, j), maxi(i, j)]
			if gorulen.has(anahtar):
				continue
			gorulen[anahtar] = true
			cikti.append({"i": mini(i, j), "j": maxi(i, j), "tip": "savas",
					"agirlik": 1.0})
		for mut in d.muttefik:
			var j2 := int(ad_indeks.get(mut, -1))
			if j2 < 0:
				continue
			var anahtar2 := "i%d-%d" % [mini(i, j2), maxi(i, j2)]
			if gorulen.has(anahtar2):
				continue
			gorulen[anahtar2] = true
			cikti.append({"i": mini(i, j2), "j": maxi(i, j2), "tip": "ittifak",
					"agirlik": 1.0})

	if w.abluka.size() == n * n:
		for i in range(n):
			for j in range(i + 1, n):
				var a: float = maxf(w.abluka[i * n + j], w.abluka[j * n + i])
				if a > 0.01:
					cikti.append({"i": i, "j": j, "tip": "abluka", "agirlik": a})

	# Ticaret: hacme gore en buyuk N cift, normalize edilmis agirlikla.
	var ciftler: Array = []
	for i in range(n):
		for j in range(i + 1, n):
			var h := w.cift_hacmi(i, j)
			if h > 0.0:
				ciftler.append([h, i, j])
	ciftler.sort_custom(func(a, b): return a[0] > b[0])
	var kac: int = mini(en_fazla_ticaret, ciftler.size())
	var en_buyuk: float = ciftler[0][0] if kac > 0 else 1.0
	for k in range(kac):
		cikti.append({"i": int(ciftler[k][1]), "j": int(ciftler[k][2]),
				"tip": "ticaret",
				"agirlik": ciftler[k][0] / maxf(en_buyuk, 1e-12)})
	return cikti


# ---------------------------------------------------------------------------
# CIZIM POLITIKASI
# ---------------------------------------------------------------------------
# `baglar()` iliskinin TAMAMINI dondurur; cizilecek olan ise bir SECIMDIR.
# Ikisini ayirmak zorunlu, cunku tam iliski cizilemez:
#
#   Olculdu (54 ulke, 1836-2100, tohum 42): kampanyanin sonunda 703 ittifak
#   bagi var. Sebep yapisal -- sosyalist pakt bir KLIKTIR: 38 sosyalist ulke
#   38*37/2 = 703 cift eder. Klik cizilirse harita spagettiye doner ve
#   "kim kiminle" sorusu tam da gorunmesi gereken yerde kaybolur.
#
# Politika tur bazinda:
#   savas    : hepsi -- nadir, ve en onemlisi
#   abluka   : en siddetli EN_FAZLA_ABLUKA tanesi (80 cizilince harita
#              okunmuyordu -- olculdu, 2035 yilinda 730 abluka cifti var)
#   ittifak  : KAPSAYAN YILDIZ -- her ulke yalnizca EN KUCUK indisli
#              muttefigine baglanir. Blok uyeligi gorunur, klik cizilmez;
#              n uyeli blok n-1 cizgi eder.
#   ticaret  : `baglar()` zaten en buyuk N cifti veriyor
#
# Politika BURADA, `RefCounted` icinde durur (cizimde degil) ki kapi onu
# headless sinayabilsin: cizime baglanan hicbir sey CI'da olculemez.
const EN_FAZLA_ABLUKA := 40


static func gorunur_baglar(w: Dunya, en_fazla_ticaret: int = 40) -> Array[Dictionary]:
	var hepsi := baglar(w, en_fazla_ticaret)
	var cikti: Array[Dictionary] = []
	var ablukalar: Array[Dictionary] = []
	var ilk_muttefik := {}          ## ulke -> en kucuk indisli muttefigi

	for b in hepsi:
		match String(b["tip"]):
			"abluka":
				ablukalar.append(b)
			"ittifak":
				var i := int(b["i"])
				var j := int(b["j"])
				# `baglar()` i<j sirali verdigi icin j'nin en kucuk
				# muttefigi i olabilir; iki yonu de kaydediyoruz.
				if not ilk_muttefik.has(j) or int(ilk_muttefik[j]) > i:
					ilk_muttefik[j] = i
				if not ilk_muttefik.has(i) or int(ilk_muttefik[i]) > j:
					ilk_muttefik[i] = j
			_:
				cikti.append(b)

	ablukalar.sort_custom(func(a, b): return float(a["agirlik"]) > float(b["agirlik"]))
	for k in range(mini(EN_FAZLA_ABLUKA, ablukalar.size())):
		cikti.append(ablukalar[k])

	var yildiz := {}
	for u in ilk_muttefik:
		var i := int(u)
		var j := int(ilk_muttefik[u])
		var anahtar := "%d-%d" % [mini(i, j), maxi(i, j)]
		if yildiz.has(anahtar):
			continue
		yildiz[anahtar] = true
		cikti.append({"i": mini(i, j), "j": maxi(i, j), "tip": "ittifak",
				"agirlik": 1.0})
	return cikti
