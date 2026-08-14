class_name Chart
extends Control

## Tek bir metriğin zaman serisi. Saf `_draw()`, sıfır asset.
##
## Panelin ekseni belgenin 12 çekirdek metriğidir; hangi metriği çizeceğini
## `Sim.CEKIRDEK_METRIKLER` söyler, bu sınıf kendi listesini tutmaz.
##
## Grafik ÖLÇEĞİNİ kendi verisinden alır (min/max), sabit bir aralıktan değil:
## kâr oranı 0.04'ten 0.003'e inerken sabit [0,1] ekseninde düz çizgi görünür
## ve oyunun anlattığı asıl şey -- düşme EĞİLİMİ -- kaybolur.

var metrik: Dictionary = {}
var ulke_ad := ""

## Rejimin el değiştirdiği turlar. Dikey çizgi olarak işaretlenir: oyunun
## "ayakta kalma" çerçevesinde en anlamlı an bunlar.
var kopus_turlari: PackedInt32Array = PackedInt32Array()

var _seri := PackedFloat64Array()


func kur(p_metrik: Dictionary, p_ulke: String = "") -> void:
	metrik = p_metrik
	ulke_ad = p_ulke
	custom_minimum_size = Vector2(210, 104)
	tooltip_text = String(metrik.get("ad", ""))


func yenile(kopuslar: Array = []) -> void:
	_seri = Sim.seri(String(metrik.get("anahtar", "")), ulke_ad)
	kopus_turlari = PackedInt32Array()
	for k in kopuslar:
		kopus_turlari.append(int(k["tur"]))
	queue_redraw()


func _draw() -> void:
	var yazi := get_theme_default_font()
	var boy := get_theme_default_font_size()
	var r := Rect2(Vector2.ZERO, size)

	draw_rect(r, Tema.PANEL)
	draw_rect(r, Tema.CIZGI, false, 1.0)

	var ad := String(metrik.get("ad", ""))
	draw_string(yazi, Vector2(8, 15), ad, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16, boy - 1, Tema.METIN_SOLUK)

	if _seri.is_empty():
		draw_string(yazi, Vector2(8, size.y / 2), "veri yok",
				HORIZONTAL_ALIGNMENT_LEFT, -1, boy, Tema.METIN_SOLUK)
		return

	var son := _seri[_seri.size() - 1]
	var bicim := String(metrik.get("bicim", "oran"))
	draw_string(yazi, Vector2(8, 35), Sim.bicimle(son, bicim),
			HORIZONTAL_ALIGNMENT_LEFT, -1, boy + 5, Tema.METIN)

	# Çizim alanı. Sağda min/max etiketleri için yer ayrılır: onlar sola
	# hizalı yazılırsa büyük değerin üstüne biner.
	var etiket_gen := 52.0
	var alan := Rect2(8, 44, size.x - 16 - etiket_gen, size.y - 52)
	if alan.size.y <= 4 or alan.size.x <= 4 or _seri.size() < 2:
		return

	var alt := INF
	var ust := -INF
	for v in _seri:
		if is_nan(v):
			continue
		alt = minf(alt, v)
		ust = maxf(ust, v)
	if not is_finite(alt) or not is_finite(ust):
		return

	# SABİT SERİ (otomasyon çağ 5'e kadar tam sıfır, canlı emek payı tam 1.0):
	# yapay bir aralık uydurmak "%-100 … %200" gibi anlamsız bir eksen üretir.
	# Doğrusu, çizgiyi ortada düz göstermek ve tek değeri yazmaktır.
	var sabit := absf(ust - alt) < 1e-12
	if sabit:
		var oy := alan.position.y + alan.size.y * 0.5
		draw_line(Vector2(alan.position.x, oy), Vector2(alan.end.x, oy),
				Tema.VURGU * Color(1, 1, 1, 0.7), 1.5)
		draw_string(yazi, Vector2(alan.end.x + 4, oy + 4),
				Sim.bicimle(alt, bicim), HORIZONTAL_ALIGNMENT_LEFT, etiket_gen - 4,
				boy - 3, Tema.METIN_SOLUK)
		return

	# Ufuk boyunca sabit yatay ölçek: koşu ilerledikçe çizgi soldan sağa dolar,
	# her turda yeniden gerilmez. Yoksa grafik "hareket ediyor" gibi görünür.
	var ufuk := maxi(Sim.ufuk, _seri.size())

	# Sıfır çizgisi (varsa) -- kâr oranının işaret değiştirmesi görünür olmalı.
	if alt < 0.0 and ust > 0.0:
		var sy := alan.position.y + alan.size.y * (1.0 - (0.0 - alt) / (ust - alt))
		draw_line(Vector2(alan.position.x, sy),
				Vector2(alan.end.x, sy), Tema.CIZGI, 1.0)

	for t in kopus_turlari:
		var kx := alan.position.x + alan.size.x * (float(t) / float(ufuk))
		draw_line(Vector2(kx, alan.position.y), Vector2(kx, alan.end.y),
				Tema.OLAY["DEVRIM"] * Color(1, 1, 1, 0.5), 1.0)

	var noktalar := PackedVector2Array()
	for i in range(_seri.size()):
		var v: float = _seri[i]
		if is_nan(v):
			continue
		noktalar.append(Vector2(
				alan.position.x + alan.size.x * (float(i) / float(ufuk)),
				alan.position.y + alan.size.y * (1.0 - (v - alt) / (ust - alt))))
	if noktalar.size() >= 2:
		draw_polyline(noktalar, Tema.VURGU, 1.5, true)

	# Min/max SAĞDA: solda büyük değerin altına yazılırsa üst üste biner.
	draw_string(yazi, Vector2(alan.end.x + 4, alan.position.y + 8),
			Sim.bicimle(ust, bicim), HORIZONTAL_ALIGNMENT_LEFT, etiket_gen - 4,
			boy - 3, Tema.METIN_SOLUK)
	draw_string(yazi, Vector2(alan.end.x + 4, alan.end.y),
			Sim.bicimle(alt, bicim), HORIZONTAL_ALIGNMENT_LEFT, etiket_gen - 4,
			boy - 3, Tema.METIN_SOLUK)
