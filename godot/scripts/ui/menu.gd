class_name Menu
extends Control

## Açılış ekranı: senaryo, ülke, tohum.
##
## Tohum görünür bırakıldı çünkü motor DETERMİNİSTİKTİR: aynı tohum aynı
## tarihi üretir. Bir koşuyu tekrar oynayıp farklı politika denemek bu oyunda
## anlamlı bir şey; gizlemek onu imkânsız kılardı.

signal kosu_istendi(senaryo: String, tohum: int, ulke: String)

var _senaryo_secim: OptionButton
var _ulke_secim: OptionButton
var _tohum: SpinBox
var _aciklama: Label

## Ülke listesini motoru kurmadan gösterebilmek için tohum tablosundan okunur.
var _senaryo_anahtarlari: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var zemin := ColorRect.new()
	zemin.color = Tema.ZEMIN
	zemin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(zemin)

	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(orta)

	var ic := VBoxContainer.new()
	ic.custom_minimum_size.x = 460
	ic.add_theme_constant_override("separation", 10)
	orta.add_child(ic)

	var baslik := Label.new()
	baslik.text = "HAYALET EKONOMİSİ"
	baslik.add_theme_font_size_override("font_size", 34)
	baslik.add_theme_color_override("font_color", Tema.VURGU)
	ic.add_child(baslik)

	var alt := Label.new()
	alt.text = ("Krizlere, ambargolara ve savaşlara rağmen ayakta kal.\n"
			+ "Motor: %s" % Formulas.SURUM)
	alt.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ic.add_child(alt)

	ic.add_child(HSeparator.new())

	ic.add_child(_etiket("Senaryo"))
	_senaryo_secim = OptionButton.new()
	for anahtar in Sim.SENARYOLAR:
		_senaryo_anahtarlari.append(anahtar)
		_senaryo_secim.add_item(String(Sim.SENARYOLAR[anahtar]["ad"]))
	_senaryo_secim.item_selected.connect(_senaryo_degisti)
	ic.add_child(_senaryo_secim)

	_aciklama = Label.new()
	_aciklama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aciklama.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	_aciklama.add_theme_font_size_override("font_size", 11)
	ic.add_child(_aciklama)

	ic.add_child(_etiket("Oynayacağın ülke"))
	_ulke_secim = OptionButton.new()
	for satir in Tables.ULKELER:
		_ulke_secim.add_item(String(satir[0]))
	# Türkiye varsayılan: motorun ampirik katsayıları onun etrafında kurulmuş.
	for i in range(Tables.ULKELER.size()):
		if String(Tables.ULKELER[i][0]) == "Turkiye":
			_ulke_secim.selected = i
	ic.add_child(_ulke_secim)

	ic.add_child(_etiket("Tohum (aynı tohum aynı tarihi üretir)"))
	_tohum = SpinBox.new()
	_tohum.min_value = 0
	_tohum.max_value = 999999
	_tohum.value = 42
	ic.add_child(_tohum)

	ic.add_child(HSeparator.new())

	var basla := Button.new()
	basla.text = "BAŞLA"
	basla.custom_minimum_size.y = 40
	basla.pressed.connect(func(): kosu_istendi.emit(
			String(_senaryo_anahtarlari[_senaryo_secim.selected]),
			int(_tohum.value),
			_ulke_secim.get_item_text(_ulke_secim.selected)))
	ic.add_child(basla)

	var gecmis: Array = Save.al("kosular", [])
	if not gecmis.is_empty():
		var g := Label.new()
		var son: Dictionary = gecmis[gecmis.size() - 1]
		g.text = "son koşu: %s / %s — %d tur, %s" % [
				String(son.get("senaryo", "kampanya")), String(son.get("ulke", "")),
				int(son.get("tur", 0)),
				"rejim korundu" if son.get("rejim_korundu", false)
						else "%d kopuş" % int(son.get("kopus_sayisi", 0))]
		g.add_theme_color_override("font_color", Tema.CIZGI)
		g.add_theme_font_size_override("font_size", 11)
		ic.add_child(g)

	_senaryo_degisti(0)


func _etiket(metin: String) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	return l


func _senaryo_degisti(indeks: int) -> void:
	var anahtar: String = String(_senaryo_anahtarlari[indeks])
	var meta: Dictionary = Sim.SENARYOLAR[anahtar]
	_aciklama.text = "%s\n%d yılında başlar, %d tur (~%d yıl) sürer." % [
			String(meta["aciklama"]), int(meta["yil"]), int(meta["ufuk"]),
			int(int(meta["ufuk"]) * Formulas.TUR_YIL)]
