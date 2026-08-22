class_name OyunMenusu
extends Control

## Kampanya kurulum ekrani.
##
## SENARYO SECIMI YOK, ve bu bir eksiklik degil. v4.4'un senaryo odalari
## (`turkey_2001`, `golden_age_1950`...) donmus bir dunyayi belli bir yildan
## baslatiyordu; v2'nin tek kampanyasi 1836-2100'dur (§5.3) ve her sey onun
## icinde endojen olarak dogar. Secilecek tek sey OZNEDIR: hangi ulke.
##
## ZORLUK AYARI DA YOK (§0). Zorluk, sectigin ulkenin dunya sistemindeki
## KONUMUDUR -- cevre olmak zaten zordur, cunku deger transferi onu surekli
## bosaltir. Bu yuzden listede her ulkenin konumu yazar: secim ekraninin
## anlatmasi gereken sey budur, bir yildiz derecesi degil.

signal kosu_istendi(kod: String, tohum: int)

const KONUM_ADI := {
	"merkez": "merkez",
	"yari": "yarı-çevre",
	"cevre": "çevre",
}

var _liste: ItemList
var _tohum: SpinBox
var _aciklama: Label
var _kodlar: PackedStringArray = PackedStringArray()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Arka planda harita. `HaritaGorunum` dunya olmadan da cizer (butun
	# ulkeler "veri yok" renginde) -- tam olarak bunun icin oyle yazilmisti.
	var arka := HaritaGorunum.new()
	arka.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arka.serit_acik = false
	arka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arka)
	arka.kur(null)

	var kutu := PanelContainer.new()
	kutu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	kutu.custom_minimum_size = Vector2(560, 460)
	kutu.offset_left = -280
	kutu.offset_right = 280
	kutu.offset_top = -230
	kutu.offset_bottom = 230
	add_child(kutu)

	var kenar := MarginContainer.new()
	for yan in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		kenar.add_theme_constant_override(yan, 12)
	kutu.add_child(kenar)

	var kok := VBoxContainer.new()
	kok.add_theme_constant_override("separation", 6)
	kenar.add_child(kok)

	var baslik := Label.new()
	baslik.text = "Hayalet Ekonomisi — 1836-2100"
	baslik.add_theme_color_override("font_color", Tema.VURGU)
	kok.add_child(baslik)

	var alt := Label.new()
	alt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alt.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	alt.text = ("Krizler yazılmaz, dayatılır. Zorluk ayarı yoktur: zorluk, "
			+ "seçtiğiniz ülkenin dünya sistemindeki konumudur.")
	kok.add_child(alt)

	_liste = ItemList.new()
	_liste.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_liste.item_selected.connect(_secildi)
	kok.add_child(_liste)

	_aciklama = Label.new()
	_aciklama.custom_minimum_size.y = 34
	_aciklama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aciklama.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	kok.add_child(_aciklama)

	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 8)
	kok.add_child(satir)
	var te := Label.new()
	te.text = "Tohum"
	te.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	satir.add_child(te)
	_tohum = SpinBox.new()
	_tohum.min_value = 0
	_tohum.max_value = 999999
	_tohum.value = 42
	_tohum.tooltip_text = ("Tohum krizlerin ZAMANLAMASINI değiştirir, "
			+ "kaçınılmazlığını değil.")
	satir.add_child(_tohum)

	var basla := Button.new()
	basla.text = "Başla"
	basla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basla.pressed.connect(_basla)
	satir.add_child(basla)

	_doldur()


func _doldur() -> void:
	_kodlar = PackedStringArray()
	# GOZLEMCI once: dunyayi once disaridan izlemek, oynamadan once
	# mekanizmalari gormenin en ucuz yolu.
	_liste.add_item("Gözlemci — dünyayı dışarıdan izle")
	_kodlar.append("")

	for kod in Harita.oynanabilir_kodlar():
		var i := Harita.indeks(kod)
		if i < 0:
			continue
		var u := Harita.kayit()[i]
		var ad_1836 := String(u["ad_1836"])
		var ad := String(u["ad"])
		var etiket := ad_1836 if ad_1836 != "" else ad
		if ad_1836 != "" and ad_1836 != ad:
			etiket += "  (%s)" % ad
		etiket += "   —   " + String(KONUM_ADI.get(String(u["konum"]),
				String(u["konum"])))
		_liste.add_item(etiket)
		_kodlar.append(kod)

	_liste.select(0)
	_secildi(0)


func _secildi(i: int) -> void:
	if i <= 0:
		_aciklama.text = ("Hiçbir ülkenin kollarını tutmazsınız; bütün dünya "
				+ "yapay zekâ yönetiminde işler.")
		return
	var ki := Harita.indeks(_kodlar[i])
	if ki < 0:
		_aciklama.text = ""
		return
	var u := Harita.kayit()[ki]
	match String(u["konum"]):
		"merkez":
			_aciklama.text = ("Merkez: değer transferi size doğru akar. "
					+ "Kriziniz kendi birikiminizden gelir, dışarıdan değil.")
		"yari":
			_aciklama.text = ("Yarı-çevre: iki yönden de basınç. Yukarı "
					+ "tırmanmak da aşağı düşmek de mümkün.")
		_:
			_aciklama.text = ("Çevre: değer transferi sizi sürekli boşaltır. "
					+ "Oyunun en zor konumu — ve zorluk ayarı bu.")


func _basla() -> void:
	var i := _liste.get_selected_items()
	var k := i[0] if not i.is_empty() else 0
	kosu_istendi.emit(_kodlar[k], int(_tohum.value))
