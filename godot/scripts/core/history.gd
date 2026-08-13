class_name History
extends RefCounted

## Bir ulkenin tur-tur kaydi -- Python'daki `Country.tarih` listesinin karsiligi.
##
## SUTUN DEPOSU, SATIR DEPOSU DEGIL. Python tarafinda her tur ~60 anahtarli bir
## dict `tarih`e eklenir. Bir kampanyada bu 20 ulke x 1259 tur x ~60 alan
## = ~1.5 milyon deger eder. GDScript'te `Array[Dictionary]` olarak tutmak her
## degeri Variant kutusuna sokar ve hem bellegi hem de grafik cizimini
## gereksiz yere agirlastirir; gosterge paneli zaten "tek alanin zaman serisi"
## istiyor, "tek turun butun alanlari" degil.
##
## PackedFloat64Array secildi, Float32 DEGIL: parite karsilastirmasi Python'un
## binary64 degerleriyle yapiliyor; float32'ye dusurmek karsilastirmayi
## anlamsiz kilardi. Gosterge paneli isterse cizim aninda daraltabilir.
##
## Metin alanlari (rejim, kurum) id'ye cevrilip int sutununda tutulur --
## `rejim_adi()` ile geri okunur.

var _float_sutun: Dictionary = {}   ## alan adi -> PackedFloat64Array
var _int_sutun: Dictionary = {}     ## alan adi -> PackedInt32Array
var _metin_havuzu: PackedStringArray = PackedStringArray()
var _metin_indeksi: Dictionary = {} ## metin -> id
var _tur := 0


func tur_sayisi() -> int:
	return _tur


## Bir turu kaydeder. `float_alanlar` ve `int_alanlar` her cagrida ayni
## anahtarlari tasimalidir; eksik alan sessizce NAN olarak doldurulur ki
## sutunlar hizali kalsin (aksi halde zaman serisi kayar).
func kaydet(float_alanlar: Dictionary, int_alanlar: Dictionary = {}) -> void:
	for anahtar in float_alanlar:
		var sutun: PackedFloat64Array = _float_sutun.get(anahtar, PackedFloat64Array())
		while sutun.size() < _tur:
			sutun.append(NAN)
		sutun.append(float(float_alanlar[anahtar]))
		_float_sutun[anahtar] = sutun

	for anahtar in int_alanlar:
		var sutun: PackedInt32Array = _int_sutun.get(anahtar, PackedInt32Array())
		while sutun.size() < _tur:
			sutun.append(-1)
		var deger = int_alanlar[anahtar]
		sutun.append(_metin_id(deger) if deger is String else int(deger))
		_int_sutun[anahtar] = sutun

	_tur += 1
	_hizala()


func _hizala() -> void:
	for anahtar in _float_sutun:
		var s: PackedFloat64Array = _float_sutun[anahtar]
		while s.size() < _tur:
			s.append(NAN)
		_float_sutun[anahtar] = s
	for anahtar in _int_sutun:
		var s: PackedInt32Array = _int_sutun[anahtar]
		while s.size() < _tur:
			s.append(-1)
		_int_sutun[anahtar] = s


func _metin_id(metin: String) -> int:
	if _metin_indeksi.has(metin):
		return _metin_indeksi[metin]
	var id := _metin_havuzu.size()
	_metin_havuzu.append(metin)
	_metin_indeksi[metin] = id
	return id


## Bir alanin tam zaman serisi. Grafik katmani bunu dogrudan cizer.
func seri(alan: String) -> PackedFloat64Array:
	return _float_sutun.get(alan, PackedFloat64Array())


func int_seri(alan: String) -> PackedInt32Array:
	return _int_sutun.get(alan, PackedInt32Array())


## Bir int sutununda saklanan metni geri okur (rejim, kurum gibi).
func metin(alan: String, t: int) -> String:
	var s: PackedInt32Array = _int_sutun.get(alan, PackedInt32Array())
	if t < 0 or t >= s.size():
		return ""
	var id := s[t]
	return _metin_havuzu[id] if id >= 0 and id < _metin_havuzu.size() else ""


## Tek bir turu dict olarak geri verir -- parite dokumu ve olay incelemesi icin.
## Sicak yolda KULLANILMAZ; sutun deposunun butun amaci bunu gerektirmemektir.
func tur_kaydi(t: int) -> Dictionary:
	var out := {}
	for anahtar in _float_sutun:
		var s: PackedFloat64Array = _float_sutun[anahtar]
		if t >= 0 and t < s.size():
			out[anahtar] = s[t]
	for anahtar in _int_sutun:
		out[anahtar] = metin(anahtar, t)
	return out


func alanlar() -> PackedStringArray:
	var out := PackedStringArray()
	for anahtar in _float_sutun:
		out.append(anahtar)
	out.sort()
	return out
