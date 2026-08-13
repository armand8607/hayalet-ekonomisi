class_name History
extends RefCounted

## Bir ulkenin tur-tur kaydi -- Python'daki `Country.tarih` listesinin karsiligi.
##
## DUZ (row-major) DEPO. Python tarafinda her tur ~66 anahtarli bir dict
## `tarih`e ekleniyor; bir kampanyada bu 20 ulke x 1259 tur x 66 alan
## ~= 1.7 milyon deger eder.
##
## NEDEN SOZLUK ICINDE SUTUN TUTULMUYOR: GDScript'te paketli diziler
## KOPYALA-YAZ'dir. `var s = sozluk[k]` referansi ikiye cikarir, `s.append(x)`
## o anda TUM diziyi kopyalar, `sozluk[k] = s` kopyayi geri yazar. Yani her
## ekleme O(n)'dir ve toplam maliyet O(n^2)'ye cikar -- olculdu: kampanya basina
## ~29 sn'nin buyuk kismi buradan geliyordu.
##
## Cozum: tek bir `PackedFloat64Array` DOGRUDAN uye olarak tutulur (referans
## sayisi 1, ekleme yerinde ve amortize sabit) ve alanlar satir icinde sabit
## ofsetlerle dizilir. Satir uzunlugu ilk kayitta belirlenir.
##
## Float64 secildi, Float32 DEGIL: parite karsilastirmasi Python'un binary64
## degerleriyle yapiliyor.

var _alan_idx: Dictionary = {}          ## alan adi -> satir ici ofset
var _alan_sirasi: PackedStringArray = PackedStringArray()
var _genislik := 0                      ## satir basina float alan sayisi
var _duz := PackedFloat64Array()        ## row-major: [tur * _genislik + ofset]

var _int_idx: Dictionary = {}
var _int_sirasi: PackedStringArray = PackedStringArray()
var _int_genislik := 0
var _int_duz := PackedInt32Array()

var _metin_havuzu: PackedStringArray = PackedStringArray()
var _metin_indeksi: Dictionary = {}
var _tur := 0


func tur_sayisi() -> int:
	return _tur


## Bir turu kaydeder.
##
## Satir semasi ILK CAGRIDA sabitlenir. Sonraki cagrilarda yeni bir alan
## gorulurse sema genisletilir ve gecmis satirlar NAN ile doldurulur; motor
## her tur ayni sozluk sabitini yazdigi icin bu yol pratikte hic calismaz,
## ama sessiz kayma yerine dogru davranis uretir.
func kaydet(float_alanlar: Dictionary, int_alanlar: Dictionary = {}) -> void:
	if _genislik == 0:
		for anahtar in float_alanlar:
			_alan_idx[anahtar] = _alan_sirasi.size()
			_alan_sirasi.append(anahtar)
		_genislik = _alan_sirasi.size()
	elif float_alanlar.size() != _genislik:
		_semayi_genislet(float_alanlar)
	else:
		for anahtar in float_alanlar:
			if not _alan_idx.has(anahtar):
				_semayi_genislet(float_alanlar)
				break

	var taban := _tur * _genislik
	_duz.resize(taban + _genislik)
	for i in range(_genislik):
		_duz[taban + i] = NAN
	for anahtar in float_alanlar:
		_duz[taban + int(_alan_idx[anahtar])] = float(float_alanlar[anahtar])

	if not int_alanlar.is_empty():
		if _int_genislik == 0:
			for anahtar in int_alanlar:
				_int_idx[anahtar] = _int_sirasi.size()
				_int_sirasi.append(anahtar)
			_int_genislik = _int_sirasi.size()
		var itaban := _tur * _int_genislik
		_int_duz.resize(itaban + _int_genislik)
		for i in range(_int_genislik):
			_int_duz[itaban + i] = -1
		for anahtar in int_alanlar:
			if not _int_idx.has(anahtar):
				continue
			var deger = int_alanlar[anahtar]
			_int_duz[itaban + int(_int_idx[anahtar])] = (
					_metin_id(deger) if deger is String else int(deger))

	_tur += 1


func _semayi_genislet(float_alanlar: Dictionary) -> void:
	var yeni: PackedStringArray = _alan_sirasi.duplicate()
	for anahtar in float_alanlar:
		if not _alan_idx.has(anahtar):
			yeni.append(anahtar)
	if yeni.size() == _genislik:
		return
	var eski_genislik := _genislik
	var eski := _duz
	_alan_sirasi = yeni
	_alan_idx.clear()
	for i in range(yeni.size()):
		_alan_idx[yeni[i]] = i
	_genislik = yeni.size()
	_duz = PackedFloat64Array()
	_duz.resize(_tur * _genislik)
	for t in range(_tur):
		for i in range(_genislik):
			_duz[t * _genislik + i] = (eski[t * eski_genislik + i]
					if i < eski_genislik else NAN)


func _metin_id(metin: String) -> int:
	if _metin_indeksi.has(metin):
		return _metin_indeksi[metin]
	var id := _metin_havuzu.size()
	_metin_havuzu.append(metin)
	_metin_indeksi[metin] = id
	return id


## Tek bir degerin O(1) okunmasi. SICAK YOL BUNU KULLANIR: `kurumsal_gecis_isle`
## ve bunalim tipi siniflandirmasi her tur son 45-60 turluk pencereyi tariyor;
## orada `seri()` cagirmak turu O(n) yapip toplami O(n^2)'ye cikarirdi.
func deger(alan: String, t: int) -> float:
	if t < 0 or t >= _tur or not _alan_idx.has(alan):
		return NAN
	return _duz[t * _genislik + int(_alan_idx[alan])]


## Bir alanin tam zaman serisi. Grafik ve rapor katmani icindir (soguk yol):
## duz depodan adimlayarak yeni bir dizi kurar.
func seri(alan: String) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	if not _alan_idx.has(alan):
		return out
	var ofset := int(_alan_idx[alan])
	out.resize(_tur)
	for t in range(_tur):
		out[t] = _duz[t * _genislik + ofset]
	return out


## Bir int sutununda saklanan metni geri okur (rejim, kurum gibi).
func metin(alan: String, t: int) -> String:
	if t < 0 or t >= _tur or not _int_idx.has(alan) or _int_genislik == 0:
		return ""
	var id := _int_duz[t * _int_genislik + int(_int_idx[alan])]
	return _metin_havuzu[id] if id >= 0 and id < _metin_havuzu.size() else ""


## Tek bir turu dict olarak geri verir -- parite dokumu ve olay incelemesi icin.
## Sicak yolda KULLANILMAZ.
func tur_kaydi(t: int) -> Dictionary:
	var out := {}
	if t < 0 or t >= _tur:
		return out
	for anahtar in _alan_sirasi:
		out[anahtar] = _duz[t * _genislik + int(_alan_idx[anahtar])]
	for anahtar in _int_sirasi:
		out[anahtar] = metin(anahtar, t)
	return out


func alanlar() -> PackedStringArray:
	var out := _alan_sirasi.duplicate()
	out.sort()
	return out
