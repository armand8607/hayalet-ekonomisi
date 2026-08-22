class_name GuncePaneli
extends PanelContainer

## Gunce -- §0'in "olay sistemi yoktur, kriz TESCILI vardir" kuralinin
## ekrandaki yuzu.
##
## Buradaki her satir cekirdegin kendi kayit dizisinden gelir (`Gunce`).
## Panelin uydurdugu, sirasini degistirdigi ya da "dramatik olsun diye"
## sectigi bir sey yoktur; suzgec disinda yaptigi tek is renklendirmektir.
##
## SUZGEC ONEMLI. Tam kadroda bir yil onlarca tescil uretir ve hepsi tek
## akista aksaydi oyuncunun KENDI ulkesinin krizi gorunmez olurdu. Varsayilan
## bu yuzden "yalnizca benim ulkem"dir; dunya akisi bir dugme uzaktadir.

const EN_FAZLA_SATIR := 200

var _oyun: Oyun = null
var _yalniz_oyuncu := true
var _metin: RichTextLabel
var _dugme: Button
var _son_boy := -1


func _ready() -> void:
	custom_minimum_size.y = 150
	add_theme_stylebox_override("panel", Tema.panel_stili())
	# Kenar payi: metin panelin kenarina yapisinca en ustteki satir kesik
	# gorunuyordu ve kaydirma artifakti gibi degil, bozuk gibi okunuyordu.
	var kenar := MarginContainer.new()
	for yan in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		kenar.add_theme_constant_override(yan, 6)
	add_child(kenar)
	var kok := VBoxContainer.new()
	kok.add_theme_constant_override("separation", 2)
	kenar.add_child(kok)

	var ust := HBoxContainer.new()
	kok.add_child(ust)
	var baslik := Label.new()
	baslik.text = "Günce"
	baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baslik.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ust.add_child(baslik)

	_dugme = Button.new()
	_dugme.toggle_mode = true
	_dugme.button_pressed = true
	_dugme.text = "yalnızca ülkem"
	_dugme.tooltip_text = "Kapatılırsa bütün dünyanın tescilleri akar"
	_dugme.toggled.connect(func(basili: bool) -> void:
		_yalniz_oyuncu = basili
		_dugme.text = "yalnızca ülkem" if basili else "bütün dünya"
		_son_boy = -1
		yenile())
	ust.add_child(_dugme)

	_metin = RichTextLabel.new()
	_metin.bbcode_enabled = true
	_metin.scroll_following = true
	_metin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kok.add_child(_metin)


func kur(oyun: Oyun) -> void:
	_oyun = oyun
	_son_boy = -1
	# Oyuncu yoksa "yalnizca ulkem" suzgeci bos ekran demektir; gozlemci
	# kipinde dunya akisi varsayilan olur.
	if oyun != null and oyun.oyuncu < 0:
		_yalniz_oyuncu = false
		_dugme.button_pressed = false
		_dugme.text = "bütün dünya"
		_dugme.disabled = true
	yenile()


func yenile() -> void:
	if _oyun == null or _oyun.gunce == null:
		return
	# Gunce her tik yoklaniyor ama nadiren buyuyor; degismediyse BBCode'u
	# yeniden kurmak bosuna is (tam kadroda her karede yuzlerce satir).
	var boy := _oyun.gunce.girdiler.size()
	if boy == _son_boy:
		return
	_son_boy = boy

	var suzgec := _oyun.oyuncu if _yalniz_oyuncu else -1
	var girdiler := _oyun.gunce.son(EN_FAZLA_SATIR, suzgec)
	var satirlar := PackedStringArray()
	for g in girdiler:
		var renk: Color = Gunce.renk(String(g["tip"]))
		satirlar.append("[color=#%s]%4d[/color]  %s" % [
				renk.to_html(false), int(g["yil"]), String(g["mesaj"])])
	_metin.text = "\n".join(satirlar)
