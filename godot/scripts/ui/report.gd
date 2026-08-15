class_name Report
extends Control

## Koşu sonu ekranı.
##
## Ufka varmak AYAKTA KALMAKTIR -- bu oyunda başka bir bitiş yok. Rejimin el
## değiştirmesi koşuyu bitirmez, ne olduğunu anlatır. Ekran bu yüzden bir skor
## göstermez: motorun `tarihsel_rapor`'unu okunur hale getirir, o kadar.

signal menuye_don


func goster(rapor: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# TAM OPAK: yari saydam bir perdenin arkasindan sizan panel, raporu
	# okunmaz hale getiriyor ve arkada kalan sayilar hangi ekrana ait belli
	# olmuyor. Rapor kendi basina durmali.
	var perde := ColorRect.new()
	perde.color = Tema.ZEMIN
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(perde)

	var kaydir := ScrollContainer.new()
	kaydir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(kaydir)

	# TUZAK: `margin_*` MarginContainer'in tema sabitidir, ScrollContainer'in
	# DEGIL. Dogrudan ScrollContainer'a verilen override sessizce hicbir sey
	# yapmaz ve rapor sol kenara YAPISIK cikar. Headless kapilarin hicbiri
	# bunu yakalayamaz: `--headless` `_draw()` kosturmadigi icin bozuk
	# yerlesim butun testleri gecer, yalnizca ekran goruntusunde gorunur.
	var kenar := MarginContainer.new()
	kenar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for yan in ["margin_left", "margin_right"]:
		kenar.add_theme_constant_override(yan, 40)
	kaydir.add_child(kenar)

	var ic := VBoxContainer.new()
	ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic.add_theme_constant_override("separation", 10)
	kenar.add_child(ic)

	var bosluk := Control.new()
	bosluk.custom_minimum_size.y = 24
	ic.add_child(bosluk)

	var baslik := Label.new()
	baslik.text = "AYAKTA KALDIN"
	baslik.add_theme_font_size_override("font_size", 34)
	baslik.add_theme_color_override("font_color", Tema.VURGU)
	ic.add_child(baslik)

	var kopuslar: Array = rapor.get("kopuslar", [])
	var alt := Label.new()
	if kopuslar.is_empty():
		alt.text = "%s — rejimin baştan sona ayakta kaldı." % String(rapor.get("ulke", ""))
	else:
		alt.text = "%s — %d kez rejim el değiştirdi, ülke yine de sürdü." % [
				String(rapor.get("ulke", "")), kopuslar.size()]
	alt.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ic.add_child(alt)

	if not kopuslar.is_empty():
		ic.add_child(_baslik("Rejimin el değiştirdiği anlar"))
		for k in kopuslar:
			var s := Label.new()
			s.text = "  %.0f  —  %s  (%s → %s)" % [
					float(k["yil"]), String(k["aciklama"]),
					String(k["eski_rejim"]), String(k["yeni_rejim"])]
			s.add_theme_color_override("font_color", Tema.OLAY["DEVRIM"])
			ic.add_child(s)

	# --- Başlangıç / bitiş kesiti ---
	ic.add_child(_baslik("Başlangıç ve bitiş"))
	var bas: Dictionary = rapor.get("baslangic", {})
	var bit: Dictionary = rapor.get("bitis", {})
	var tablo := GridContainer.new()
	tablo.columns = 3
	tablo.add_theme_constant_override("h_separation", 28)
	ic.add_child(tablo)
	_satir(tablo, "", "başlangıç", "bitiş", true)
	_satir(tablo, "işsizlik", _yuzde(bas.get("issizlik")), _yuzde(bit.get("issizlik")))
	_satir(tablo, "ücret payı", _yuzde(bas.get("ucret_payi")), _yuzde(bit.get("ucret_payi")))
	_satir(tablo, "kâr oranı", _sayi(bas.get("kar_orani"), 5), _sayi(bit.get("kar_orani"), 5))
	_satir(tablo, "çağ", _sayi(bas.get("cag"), 1), _sayi(bit.get("cag"), 1))

	# --- Krizler ---
	ic.add_child(_baslik("Atlatılan krizler"))
	var kriz: Dictionary = rapor.get("kriz_sayilari", {})
	var kriz_tablo := GridContainer.new()
	kriz_tablo.columns = 2
	kriz_tablo.add_theme_constant_override("h_separation", 28)
	ic.add_child(kriz_tablo)
	for anahtar in ["resesyon", "buyuk_bunalim", "doviz_krizi", "temerrut",
			"moratoryum", "savas"]:
		_satir(kriz_tablo, anahtar.replace("_", " "), str(kriz.get(anahtar, 0)), "")

	# --- Kurumsal geçişler ---
	var gecisler: Array = rapor.get("kurum_gecisleri", [])
	if not gecisler.is_empty():
		ic.add_child(_baslik("Kurumsal geçişler"))
		for g in gecisler:
			var s := Label.new()
			var yil: float = float(rapor.get("baslangic_yili", 1760)) + float(g[0]) * Formulas.TUR_YIL
			s.text = "  %.0f  —  %s → %s" % [yil, String(g[1]), String(g[2])]
			s.add_theme_color_override("font_color", Tema.kurum_rengi(String(g[2])))
			ic.add_child(s)

	# --- Dönem dönem ---
	ic.add_child(_baslik("Dönem dönem"))
	var donem_tablo := GridContainer.new()
	donem_tablo.columns = 7
	donem_tablo.add_theme_constant_override("h_separation", 18)
	ic.add_child(donem_tablo)
	for b in ["tur", "rejim", "kurum", "işsizlik", "ücret payı", "kâr oranı", "otomasyon"]:
		var h := Label.new()
		h.text = b
		h.add_theme_color_override("font_color", Tema.METIN_SOLUK)
		donem_tablo.add_child(h)
	for d in rapor.get("donemler", []):
		for v in [
				"%d–%d" % [int(d["t0"]), int(d["t1"])],
				String(d["rejim"]), String(d["kurum"]),
				_yuzde(d["issizlik"]), _yuzde(d["ucret_payi"]),
				_sayi(d["kar_orani"], 5), _yuzde(d["otomasyon"])]:
			var h2 := Label.new()
			h2.text = str(v)
			donem_tablo.add_child(h2)

	var dugme := Button.new()
	dugme.text = "menüye dön"
	dugme.pressed.connect(func(): menuye_don.emit())
	ic.add_child(dugme)

	var son_bosluk := Control.new()
	son_bosluk.custom_minimum_size.y = 30
	ic.add_child(son_bosluk)


func _baslik(metin: String) -> Control:
	var l := Label.new()
	l.text = "\n" + metin
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Tema.METIN)
	return l


func _satir(izgara: GridContainer, ad: String, a: String, b: String,
		basliksa: bool = false) -> void:
	for metin in [ad, a, b]:
		if izgara.columns == 2 and metin == b:
			continue
		var l := Label.new()
		l.text = metin
		if basliksa or metin == ad:
			l.add_theme_color_override("font_color", Tema.METIN_SOLUK)
		izgara.add_child(l)


func _yuzde(v) -> String:
	if v == null or (v is float and is_nan(v)):
		return "—"
	return "%%%.1f" % (float(v) * 100.0)


func _sayi(v, basamak: int) -> String:
	if v == null or (v is float and is_nan(v)):
		return "—"
	return ("%%.%df" % basamak) % float(v)
