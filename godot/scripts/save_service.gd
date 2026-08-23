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


# ===========================================================================
# IKILI KAYIT (v2 oturumu, B7d)
# ===========================================================================
#
# AYRI DOSYA, ve JSON DEGIL. v2'nin oturum kaydi tam kadroda birkac megabayt
# tutar ve neredeyse tamami kayan nokta dizisidir; JSON'a yazilirsa her sayi
# ondalik metne cevrilir, dosya birkac katina cikar ve okumak yavaslar.
# `var_to_bytes` ayni veriyi ikili tutar.
#
# `save.json` ise KUCUK ve INSAN OKUR kalir -- ayarlar ve kosu ozetleri orada.
# Ikisini ayni dosyaya koymak kucuk olani buyugun rehinesi yapardi.
#
# Bu blok `user://`ye erisen TEK yer olma kuralini bozmaz, tersine korur:
# v2 dosya sistemine hic dokunmaz, yalnizca sozluk uretir.

const OTURUM_YOL := "user://v2_oturum.sav"


func oturum_var() -> bool:
	return FileAccess.file_exists(OTURUM_YOL)


## Atomik: once gecici dosyaya, sonra yerine. Yazarken kapanan bir oyun
## mevcut kaydi bozmasin.
func oturum_yaz(veri: Dictionary) -> bool:
	var gecici := OTURUM_YOL + ".tmp"
	var f := FileAccess.open(gecici, FileAccess.WRITE)
	if f == null:
		push_warning("Oturum kaydi yazilamadi: " + gecici)
		return false
	f.store_var(veri, true)
	f.close()
	if DirAccess.rename_absolute(gecici, OTURUM_YOL) != OK:
		push_warning("Oturum kaydi yerine tasinamadi.")
		return false
	return true


## Bos sozluk = kayit yok ya da okunamadi. HICBIR KOSULDA OLUMCUL DEGIL:
## bozuk bir kayit oyunu acilmaz yapmamali.
func oturum_oku() -> Dictionary:
	if not oturum_var():
		return {}
	var f := FileAccess.open(OTURUM_YOL, FileAccess.READ)
	if f == null:
		push_warning("Oturum kaydi acilamadi.")
		return {}
	var v: Variant = f.get_var(true)
	f.close()
	if typeof(v) != TYPE_DICTIONARY:
		push_warning("Oturum kaydi bozuk; yok sayiliyor.")
		return {}
	return v


func oturum_sil() -> void:
	if oturum_var():
		DirAccess.remove_absolute(OTURUM_YOL)


func al(anahtar: String, varsayilan_deger = null):
	return _veri.get(anahtar, varsayilan_deger)


func ayarla(anahtar: String, deger) -> void:
	_veri[anahtar] = deger
