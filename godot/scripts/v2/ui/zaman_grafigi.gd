class_name ZamanGrafigi
extends Control

## Tek bir metrigin zaman serisi. Saf `_draw()`, sifir asset.
##
## v4.4 tarafindaki `Chart`in v2 karsiligi. KOPYALANMADI, yeniden yazildi:
## `Chart` verisini `Sim`den ceker (otoload), bu ise veriyi DISARIDAN alir.
## v2'nin hicbir otoloadu yok ve bir grafigin kuresel duruma bagli olmasi
## paneli test edilemez yapardi.
##
## OLCEK KENDI VERISINDEN GELIR, sabit bir araliktan degil. Kar orani 0.38'den
## 0.03'e inerken sabit [0,1] ekseninde neredeyse duz bir cizgi gorunur ve
## oyunun anlattigi asil sey -- DUSME EGILIMI -- ekranda kaybolur.

const YUKSEKLIK := 96.0
const GENISLIK := 232.0

## Cizim alaninin kenar paylari. Sagda min/max etiketi icin yer birakilir.
const UST := 42.0
const ALT := 14.0
const SOL := 8.0
const SAG := 46.0

var metrik: Dictionary = {}

var _seri := PackedFloat64Array()
var _yillar := PackedFloat64Array()
## Dikey isaretler: [{"yil": float, "renk": Color}]. Kriz tescilleri.
var _isaretler: Array[Dictionary] = []


func kur(p_metrik: Dictionary) -> void:
	metrik = p_metrik
	custom_minimum_size = Vector2(GENISLIK, YUKSEKLIK)
	tooltip_text = String(metrik.get("ad", ""))


func yenile(seri: PackedFloat64Array, yillar: PackedFloat64Array,
		isaretler: Array[Dictionary] = []) -> void:
	_seri = seri
	_yillar = yillar
	_isaretler = isaretler
	queue_redraw()


func _draw() -> void:
	var yazi := get_theme_default_font()
	var boy := get_theme_default_font_size()
	draw_rect(Rect2(Vector2.ZERO, size), Tema.PANEL)
	draw_rect(Rect2(Vector2.ZERO, size), Tema.CIZGI, false, 1.0)

	draw_string(yazi, Vector2(SOL, 15.0), String(metrik.get("ad", "")),
			HORIZONTAL_ALIGNMENT_LEFT, size.x - SOL - 4.0, boy - 1,
			Tema.METIN_SOLUK)

	if _seri.size() < 2:
		draw_string(yazi, Vector2(SOL, size.y * 0.5), "veri yok",
				HORIZONTAL_ALIGNMENT_LEFT, -1, boy, Tema.METIN_SOLUK)
		return

	var bicim := String(metrik.get("bicim", "oran2"))
	draw_string(yazi, Vector2(SOL, 35.0),
			HaritaModu.bicimle(_seri[_seri.size() - 1], bicim),
			HORIZONTAL_ALIGNMENT_LEFT, -1, boy + 4, Tema.METIN)

	var enk := INF
	var enb := -INF
	for v in _seri:
		enk = minf(enk, v)
		enb = maxf(enb, v)
	# Duz seri: sifira bolmemek icin yapay bir aralik acilir ve cizgi ortaya
	# oturur. "Duz" bilgi verici bir cikti oldugu icin gizlenmez.
	if enb - enk <= 0.0:
		enk -= 0.5
		enb += 0.5

	var alan := Rect2(SOL, UST, size.x - SOL - SAG, size.y - UST - ALT)
	if alan.size.x <= 1.0 or alan.size.y <= 1.0:
		return

	# --- dikey isaretler: kriz tescilleri ---
	# Grafigin ARKASINA cizilir; egri ustte kalmali.
	if _yillar.size() >= 2:
		var y0: float = _yillar[0]
		var y1: float = _yillar[_yillar.size() - 1]
		if y1 > y0:
			for m in _isaretler:
				var t := (float(m["yil"]) - y0) / (y1 - y0)
				if t < 0.0 or t > 1.0:
					continue
				var x := alan.position.x + t * alan.size.x
				var renk: Color = m["renk"]
				renk.a = 0.35
				draw_line(Vector2(x, alan.position.y),
						Vector2(x, alan.end.y), renk, 1.0)

	# --- egri ---
	var noktalar := PackedVector2Array()
	noktalar.resize(_seri.size())
	var n := float(_seri.size() - 1)
	for k in range(_seri.size()):
		var t := float(k) / n
		var d := (_seri[k] - enk) / (enb - enk)
		noktalar[k] = Vector2(alan.position.x + t * alan.size.x,
				alan.end.y - d * alan.size.y)
	draw_polyline(noktalar, Tema.VURGU, 1.0, true)

	# --- min / max etiketleri ---
	# Sagda, cizim alaninin DISINDA: egrinin uzerine yazilirsa ikisi de
	# okunmaz olur.
	var x_et := alan.end.x + 4.0
	draw_string(yazi, Vector2(x_et, alan.position.y + 8.0),
			HaritaModu.bicimle(enb, bicim), HORIZONTAL_ALIGNMENT_LEFT,
			SAG - 6.0, boy - 3, Tema.METIN_SOLUK)
	draw_string(yazi, Vector2(x_et, alan.end.y),
			HaritaModu.bicimle(enk, bicim), HORIZONTAL_ALIGNMENT_LEFT,
			SAG - 6.0, boy - 3, Tema.METIN_SOLUK)
