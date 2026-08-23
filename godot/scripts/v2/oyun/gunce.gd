class_name Gunce
extends RefCounted

## B7 -- gunce. §0'in "olay sistemi yoktur, kriz TESCILI vardir" kurali.
##
## ------------------------------------------------------------------------
## BU SINIF HICBIR SEY URETMEZ
## ------------------------------------------------------------------------
## Gunceye dusen her satir, cekirdegin ZATEN kaydettigi bir esik gecisidir.
## Burada ne bir olay tablosu var, ne bir cekilis, ne de "sirada ne olsa
## guzel olur" karari. Yapilan tek is, cekirdegin kendi kayit dizilerini her
## tik OKUYUP hangilerinin uzadigini bulmaktir.
##
## Bu ayrim kozmetik degil: bir olay tablosu eklenseydi oyunun anlattigi sey
## ("krizler yazilmaz, dayatilir") ekranda YALAN olurdu, ve bunu oynayarak
## fark etmek imkansizdi -- ekranda ikisi de ayni gorunur.
##
## KAPI BUNU SAYARAK SINAR: `--v2-oyun` her tipin sayacini cekirdegin kayit
## dizisinin UZUNLUGUYLA karsilastirir. Gunce bir olay uydurursa sayac
## sismis, bir tescili kacirirsa eksik kalmis olur.
##
## ------------------------------------------------------------------------
## SAYAC SINIRSIZ, LISTE SINIRLI
## ------------------------------------------------------------------------
## Tam kadroda bir kampanya on binlerce tescil uretir. Panel zaten yalnizca
## sonunu gosterir, ama KAPI toplami bilmek zorunda. Bu yuzden iki ayri sey
## tutulur: `sayac` sinirsiz ve tam, `girdiler` sondan sinirli.

## Liste bu boyu asinca bastan bir yigin atilir. Tek tek `pop_front()`
## yapilmaz: O(n) kopyalama her girdide tekrarlanirdi.
const EN_FAZLA := 8000
const ATILAN := 1024

## RESESYON disindaki butun tipler `Tema.OLAY`da zaten var; degerleri burada
## TEKRARLAMAK iki tablonun sessizce ayrismasi demekti. Yalnizca eksik olan
## tanimlanir, gerisi `Tema`ya sorulur.
const EK_RENK := {
	"RESESYON": Color("c9973f"),
}

## Tek girdi: {"yil": float, "ulke": int, "tip": String, "mesaj": String}
var girdiler: Array[Dictionary] = []

## tip -> toplam. Sinirsiz; kapinin saydigi sey budur.
var sayac: Dictionary = {}

# Ulke basina son gorulen kayit boylari / degerleri.
var _n_asiri: PackedInt32Array = PackedInt32Array()
var _n_res: PackedInt32Array = PackedInt32Array()
var _n_bun: PackedInt32Array = PackedInt32Array()
var _n_tem: PackedInt32Array = PackedInt32Array()
var _n_mor: PackedInt32Array = PackedInt32Array()
var _n_fx: PackedInt32Array = PackedInt32Array()
var _n_savas: PackedInt32Array = PackedInt32Array()
## Ulke basina o an savasilan rakiplerin kodlari. Sayac degil KUME tutulur:
## "savasa girdi" satirinin KIME KARSI oldugunu ancak fark alarak bilebiliriz.
var _rakipler: Array[Dictionary] = []
var _n_yenilgi: PackedInt32Array = PackedInt32Array()
var _rejim: PackedStringArray = PackedStringArray()
var _kurum: PackedStringArray = PackedStringArray()
var _era: PackedInt32Array = PackedInt32Array()

var _adlar: PackedStringArray = PackedStringArray()


static func renk(tip: String) -> Color:
	if EK_RENK.has(tip):
		return EK_RENK[tip]
	return Tema.olay_rengi(tip)


## Baslangic durumunu esas alir. CAGRILMASI ZORUNLU: cagrilmazsa ilk tikte
## butun mevcut kayitlar "yeni olmus gibi" gunceye dokulur.
func kur(w: Dunya) -> void:
	var n := w.ulkeler.size()
	girdiler = []
	sayac = {}
	_adlar = w.adlar.duplicate()
	_n_asiri.resize(n)
	_n_res.resize(n)
	_n_bun.resize(n)
	_n_tem.resize(n)
	_n_mor.resize(n)
	_n_fx.resize(n)
	_n_savas.resize(n)
	_n_yenilgi.resize(n)
	_rakipler = []
	_rakipler.resize(n)
	_era.resize(n)
	_rejim.resize(n)
	_kurum.resize(n)
	for i in range(n):
		var d := w.ulkeler[i]
		_n_asiri[i] = d.asiri_uretim_krizleri.size()
		_n_res[i] = d.resesyonlar.size()
		_n_bun[i] = d.bunalimlar.size()
		_n_tem[i] = d.temerrutler.size()
		_n_mor[i] = d.moratoryumlar.size()
		_n_fx[i] = d.fx_krizleri.size()
		_n_savas[i] = d.savas_toplam
		_n_yenilgi[i] = d.yenilgi_sayisi
		_rakipler[i] = d.savas.duplicate()
		_era[i] = d.era
		_rejim[i] = d.rejim
		_kurum[i] = d.kurum


## Bir tikin tescillerini toplar. SALT OKUR.
func topla(w: Dunya) -> void:
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		var ad := _ad(i, w.yil)

		var n := d.asiri_uretim_krizleri.size()
		while _n_asiri[i] < n:
			var k: Array = d.asiri_uretim_krizleri[_n_asiri[i]]
			_ekle(w.yil, i, "ASIRI URETIM",
					"%s: asiri uretim krizi -- talep acigi %%%.1f"
					% [ad, float(k[1]) * 100.0])
			_n_asiri[i] += 1

		n = d.resesyonlar.size()
		while _n_res[i] < n:
			var k: Array = d.resesyonlar[_n_res[i]]
			_ekle(w.yil, i, "RESESYON",
					"%s: resesyon -- buyume %%%.1f" % [ad, float(k[1]) * 100.0])
			_n_res[i] += 1

		n = d.bunalimlar.size()
		while _n_bun[i] < n:
			var k: Array = d.bunalimlar[_n_bun[i]]
			_ekle(w.yil, i, "BUYUK BUNALIM",
					"%s: BUNALIM -- derinlik %%%.1f" % [ad, float(k[1]) * 100.0])
			_n_bun[i] += 1

		n = d.temerrutler.size()
		while _n_tem[i] < n:
			# `temerrutler` YIL degil `q` kaydeder (cekirdegin kendi secimi);
			# gunce takvimi tescilin GORULDUGU tikten alir.
			_ekle(w.yil, i, "TEMERRUT", "%s: dis borc temerrudu" % ad)
			_n_tem[i] += 1

		n = d.moratoryumlar.size()
		while _n_mor[i] < n:
			_ekle(w.yil, i, "MORATORYUM", "%s: borc moratoryumu ilan etti" % ad)
			_n_mor[i] += 1

		n = d.fx_krizleri.size()
		while _n_fx[i] < n:
			_ekle(w.yil, i, "DOVIZ KRIZI", "%s: doviz krizi -- rezerv tukendi" % ad)
			_n_fx[i] += 1

		# SAVAS SATIRI RAKIBI ADLANDIRIR. Ilk yazimda yalnizca `savas_toplam`
		# sayaci okunuyordu ve gunce "Turkiye savasa girdi" satirini ayni yil
		# UC KEZ tekrarliyordu -- ucu de dogruydu, ama hicbiri kime karsi
		# oldugunu soylemiyordu. Rakip kumesi zaten `d.savas`ta duruyor;
		# eksik olan onu okumakti.
		if _n_savas[i] != d.savas_toplam or d.savas.size() != _rakipler[i].size():
			for kod in d.savas.keys():
				if not _rakipler[i].has(kod):
					_ekle(w.yil, i, "SAVAS", "%s, %s ile savasa girdi"
							% [ad, Harita.gorunen_ad(String(kod), w.yil)])
			_n_savas[i] = d.savas_toplam
			_rakipler[i] = d.savas.duplicate()

		while _n_yenilgi[i] < d.yenilgi_sayisi:
			_ekle(w.yil, i, "YENILGI", "%s savasi kaybetti" % ad)
			_n_yenilgi[i] += 1

		if d.era != _era[i]:
			_ekle(w.yil, i, "CAG", "%s: cag %d -> %d" % [ad, _era[i], d.era])
			_era[i] = d.era

		if d.kurum != _kurum[i]:
			_ekle(w.yil, i, "KURUM",
					"%s: kurumsal rejim %s -> %s" % [ad, _kurum[i], d.kurum])
			_kurum[i] = d.kurum

		if d.rejim != _rejim[i]:
			# YON ONEMLI. Ayni alanin iki yonu iki AYRI olaydir: biri
			# devrim, digeri karsi-devrim. Tek "rejim degisti" satiri
			# oyunun anlattigi seyi silerdi.
			if d.rejim == "sosyalist":
				_ekle(w.yil, i, "DEVRIM", "%s: SOSYALIST DEVRIM" % ad)
			else:
				_ekle(w.yil, i, "KARSI-DEVRIM",
						"%s: karsi-devrim -- kapitalizm restore edildi" % ad)
			_rejim[i] = d.rejim


## GUNCE ADI TESCIL ANINDAKI ADDIR, bugunku ad degil. 1890'da Osmanli'nin
## bunalimi gunceye "Osmanli Imparatorlugu" diye duser ve 1923'ten sonra da
## oyle kalir -- satir yazildigi anda dondurulur, cunku gunce bir kayittir.
func _ad(i: int, yil: float) -> String:
	if i < 0 or i >= _adlar.size():
		return "?"
	return Harita.gorunen_ad(_adlar[i], yil)


func _ekle(yil: float, ulke: int, tip: String, mesaj: String) -> void:
	sayac[tip] = int(sayac.get(tip, 0)) + 1
	girdiler.append({"yil": yil, "ulke": ulke, "tip": tip, "mesaj": mesaj})
	if girdiler.size() > EN_FAZLA:
		girdiler = girdiler.slice(ATILAN)


## Son `n` girdi, istege bagli olarak tek ulkeye suzulmus. Panel bunu okur.
func son(n: int = 60, ulke: int = -1) -> Array[Dictionary]:
	var c: Array[Dictionary] = []
	for k in range(girdiler.size() - 1, -1, -1):
		if ulke >= 0 and int(girdiler[k]["ulke"]) != ulke:
			continue
		c.append(girdiler[k])
		if c.size() >= n:
			break
	c.reverse()
	return c
