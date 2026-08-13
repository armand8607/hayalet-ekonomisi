class_name Crc32
extends RefCounted

## `zlib.crc32` ile birebir ayni CRC-32 (IEEE 802.3, polinom 0xEDB88320).
##
## BU BIR TESHIS ARACI DEGIL, MEKANIZMADIR. Motorda (frozen.md:4602 /
## hayalet_ekonomi_motoru_v43.py:2711) su satir var:
##
##     if (self.t + zlib.crc32(c.ad.encode("utf-8")) % P.ai_periyot) % P.ai_periyot:
##         return
##
## yani her ulkenin politika AI'sinin HANGI TURDA atesleyecegini ulke adinin
## crc32'si belirliyor. Atlanirsa butun politika zamanlamasi kayar.
##
## Kaynak yorumun kendi notu: burada once `hash(c.ad)` kullaniliyormus ve
## Python'un string hash'i PYTHONHASHSEED ile surece ozgu rastgelelestigi icin
## ayni tohum ayri sureclerde ayri sonuc uretiyormus (tohum 42 icin gecis
## 32/37/38, cokme 76/83/86). crc32 surecler arasi kararli oldugu icin
## secilmis. Godot'un `String.hash()`'i de ayni sebeple kullanilamaz.

const MASK32 := 0xFFFFFFFF

static var _tablo := PackedInt64Array()


static func _tabloyu_kur() -> void:
	if not _tablo.is_empty():
		return
	_tablo.resize(256)
	for i in range(256):
		var c := i
		for _bit in range(8):
			c = (0xEDB88320 ^ (c >> 1)) if (c & 1) else (c >> 1)
		_tablo[i] = c & MASK32


## Bir bayt dizisinin CRC-32'si.
static func of_bytes(baytlar: PackedByteArray) -> int:
	_tabloyu_kur()
	var crc := MASK32
	for b in baytlar:
		crc = (crc >> 8) ^ _tablo[(crc ^ b) & 0xFF]
	return (crc ^ MASK32) & MASK32


## Bir metnin UTF-8 kodlamasinin CRC-32'si. Motordaki
## `zlib.crc32(s.encode("utf-8"))` ifadesinin dogrudan karsiligi.
static func of_string(metin: String) -> int:
	return of_bytes(metin.to_utf8_buffer())
