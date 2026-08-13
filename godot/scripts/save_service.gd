extends Node

## Otoload 3 -- `user://` erisen TEK yer.
##
## Surumlu, atomik ve HICBIR KOSULDA OLUMCUL DEGIL: bozuk ya da gelecekten
## gelen bir kayit dosyasi oyunu acilmaz hale getirmemeli, varsayilana donmeli.
## Kaydin sekli degisirse SAVE_VERSION artirilir ve `_migrate` icine bir dal
## eklenir.

const SAVE_VERSION := 1
const YOL := "user://save.json"

var _veri: Dictionary = {}


func _ready() -> void:
	yukle()


func varsayilan() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"ayarlar": {"sesli": true, "dil": "tr"},
		# Kosu gecmisi: her tamamlanan kosunun tarihsel rapor ozeti. Bu oyunda
		# zafer/yenilgi yok (§9.8), dolayisiyla burada "en iyi skor" da yok --
		# yalnizca NE OLDUGUNUN kaydi tutulur.
		"kosular": [],
	}


func yukle() -> void:
	_veri = varsayilan()
	if not FileAccess.file_exists(YOL):
		return
	var f := FileAccess.open(YOL, FileAccess.READ)
	if f == null:
		push_warning("Kayit dosyasi acilamadi; varsayilan kullaniliyor.")
		return
	var ham := f.get_as_text()
	f.close()

	var ayrisan = JSON.parse_string(ham)
	if typeof(ayrisan) != TYPE_DICTIONARY:
		push_warning("Kayit dosyasi bozuk; varsayilan kullaniliyor.")
		return
	_veri = _migrate(ayrisan)


func _migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 0))
	if v > SAVE_VERSION:
		# Gelecekten gelen kayit: okumaya calismak veri kaybettirebilir.
		push_warning("Kayit surumu %d, bu yapi en fazla %d okuyor; varsayilana donuluyor."
				% [v, SAVE_VERSION])
		return varsayilan()
	# v == 0 -> 1 gibi gecisler buraya eklenecek.
	var temel := varsayilan()
	temel.merge(d, true)
	temel["version"] = SAVE_VERSION
	return temel


func kaydet() -> void:
	# Atomik: once gecici dosyaya yaz, sonra yerine tasi. Yazma sirasinda
	# kapanan bir oyun mevcut kaydi bozmasin.
	var gecici := YOL + ".tmp"
	var f := FileAccess.open(gecici, FileAccess.WRITE)
	if f == null:
		push_warning("Kayit yazilamadi: " + gecici)
		return
	f.store_string(JSON.stringify(_veri, "\t"))
	f.close()
	if DirAccess.rename_absolute(gecici, YOL) != OK:
		push_warning("Kayit yerine tasinamadi.")


func al(anahtar: String, varsayilan_deger = null):
	return _veri.get(anahtar, varsayilan_deger)


func ayarla(anahtar: String, deger) -> void:
	_veri[anahtar] = deger
