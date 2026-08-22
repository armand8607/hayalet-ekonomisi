class_name HaritaGorunum
extends Control

## B5'IN HARITASI -- ana ekran (§5.5), sifir asset.
##
## Cizilen her sey `_draw()` icinde uretilir; tek veri kaynagi uretilmis
## poligon tablosudur (§5.1'in gevsettigi kural). Ne doku var, ne yazi tipi
## dosyasi, ne SVG.
##
## ------------------------------------------------------------------------
## UCGENLEME NEDEN BURADA DEGIL
## ------------------------------------------------------------------------
## Ulke sinirlari ICBUKEYDIR (Norvec, Vietnam, Sili). `draw_colored_polygon`
## icbukeyde guvenilir degildir; dogru yol poligonu ucgenlemek. Ucgenleme
## `Harita`da BIR KEZ yapilir ve burada yalnizca AFIN donusum uygulanir --
## kaydirma ve yakinlastirma ucgenlemeyi bozmaz, dolayisiyla her karede
## yeniden ucgenlemek saf israf olurdu.
##
## `RenderingServer.canvas_item_add_triangle_array` kullanilmasinin sebebi de
## bu: ulke basina TEK cizim cagrisi. Ucgen basina `draw_colored_polygon`
## cagirmak 156 ulkede ~4500 cagri ederdi.
##
## ------------------------------------------------------------------------
## BAGLAR
## ------------------------------------------------------------------------
## Dort tur bag cizilir ve dordu de `Dunya`nin durumundan gelir: savas,
## ittifak, abluka, ticaret (bkz. `Harita.baglar`). Cizgiler ulkelerin
## ETIKET NOKTASINDAN cikar -- agirlik merkezinden degil, cunku o denize
## dusebilir (bkz. ureticideki `etiket_noktasi`).

signal ulke_secildi(kod: String)
signal mod_degisti(mod_id: String)

const OKYANUS := Color("0d1017")
const SINIR := Color("0d1017")
const SINIR_SECILI := Color("e8c25a")
const SINIR_USTUNDE := Color("d6dbe6")

const BAG_RENK := {
	"savas": Color("d9534f"),
	"ittifak": Color("5cb87a"),
	"abluka": Color("d98d4a"),
	"ticaret": Color("4a90d9"),
}

## Etiket yazilacak en kucuk ulke alani (derece^2). Bunun altindakiler
## yalnizca yakinlastirinca ad alir; yoksa Avrupa okunamaz bir yazi
## yumagina doner.
const ETIKET_ALAN := 260.0

var dunya: Dunya = null
## Haritanin KENDI ust seridi (mod adi + yil). Oyun kabugu (B7) kendi, daha
## genis ust barini cizdigi icin onu kapatir; `--v2-harita-goster` ve kapilar
## icin ACIK kalir, yoksa B5'in gorsel kapisi bilgisini kaybederdi.
var serit_acik: bool = true

## PANELLERIN KAPLADIGI KENARLAR. Harita tam ekrandir ve paneller USTUNE
## biner (§5.5); haritanin KENDI cizdikleri (efsane, bilgi kutusu) o
## panellerin altinda kalmamali. Olculdu: gunce paneli acikken efsane
## yarisina kadar orluyordu ve rejim renkleri okunmuyordu.
##
## Harita GEOMETRISI bilerek kaydirilmaz -- yalnizca HUD ogeleri. Dunyayi
## panel acilinca kaydirmak, ulkelerin ekrandaki yerini panel durumuna bagli
## hale getirirdi.
var alt_bosluk: float = 0.0
var sag_bosluk: float = 0.0

## Haritanin bilgi kutusu SECILI ulke icin de cizilsin mi. Ulke paneli
## acikken ayni bilgiyi iki yerde gostermek demektir ve kutu ust barin
## uzerine biniyordu; panel aciksa yalnizca IMLEC ALTINDAKI ulke gosterilir.
var bilgi_secili: bool = true
var mod_id: String = "siyasi"
## Secili ulkenin KAYIT indeksi (dunya indeksi degil), -1 = yok.
var secili: int = -1

var _ustunde: int = -1
var _zum: float = 1.0
var _kaydirma := Vector2.ZERO          ## [0,1] birim uzayda sol ust kose
var _suruklu := false
var _kod_dunya := {}                   ## kod -> dunya indeksi
var _aralik := Vector3.ZERO
var _baglar: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


## Haritayi bir dunyaya baglar. Dunya olmadan da cizilir (butun ulkeler
## "veri yok" rengiyle) -- menu arka plani icin bu gerekli.
func kur(w: Dunya) -> void:
	dunya = w
	_kod_dunya = {}
	if w != null:
		for i in range(w.adlar.size()):
			_kod_dunya[w.adlar[i]] = i
	yenile()


## Dunya ilerledikten sonra cagrilir: renk araligi ve baglar yeniden okunur.
func yenile() -> void:
	if dunya != null:
		_aralik = HaritaModu.aralik(mod_id, dunya)
		_baglar = Harita.gorunur_baglar(dunya)
	queue_redraw()


func mod_sec(id: String) -> void:
	if id == mod_id:
		return
	mod_id = id
	mod_degisti.emit(id)
	yenile()


# ---------------------------------------------------------------------------
# DONUSUM
# ---------------------------------------------------------------------------
# Birim uzay ([0,1]^2, Miller izdusumu) -> ekran. Tek yerde tanimli olmasi
# zorunlu: cizim, isabet testi ve etiketler ayni donusumu kullanmazsa
# tiklanan yer ile gorunen yer ayrisir.
# OLCEK IKI BILESENLIDIR, VE BU ZORUNLU. `Harita.yansit` iki ekseni de
# AYRI AYRI [0,1]'e normalize eder; en/boy orani o normalizasyonda kaybolur
# ve burada geri verilmek zorundadir. Tek bir sayiyla olceklenirse dunya
# dikeyde 1.57 kat gerilir -- olculdu: Brezilya'nin etiketi 489 piksel
# yerine 768'e dustu, guney yarikure ekranin altindan tasti. Ekranda "biraz
# uzun" gorunen bir dunya ile dogru olan arasindaki farki gozle ayirmak
# zordur; bu yuzden yazili durur.
func _olcek() -> Vector2:
	var oran := 1.0 / Harita.en_boy()
	var k := minf(size.x, size.y / oran) * _zum
	return Vector2(k, k * oran)


func _kose() -> Vector2:
	var k := _olcek()
	return (size - k) * 0.5 - _kaydirma * k


func _ekrana(birim: Vector2) -> Vector2:
	return _kose() + birim * _olcek()


func _birime(ekran: Vector2) -> Vector2:
	return (ekran - _kose()) / _olcek()


# ---------------------------------------------------------------------------
# CIZIM
# ---------------------------------------------------------------------------
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OKYANUS)

	var kayit := Harita.kayit()
	var k := _olcek()
	var kose := _kose()

	for i in range(kayit.size()):
		var u := kayit[i]
		var renk := _ulke_rengi(u)
		for h in range(u["halkalar"].size()):
			var birim: PackedVector2Array = u["halkalar"][h]
			var ucgen: PackedInt32Array = u["ucgenler"][h]
			var ekran := PackedVector2Array()
			ekran.resize(birim.size())
			for n in range(birim.size()):
				ekran[n] = kose + birim[n] * k
			if ucgen.size() >= 3:
				var renkler := PackedColorArray()
				renkler.resize(ekran.size())
				renkler.fill(renk)
				RenderingServer.canvas_item_add_triangle_array(
						get_canvas_item(), ucgen, ekran, renkler)
			# Sinir: halka kapali ama son nokta tekrarlanmiyor, elle kapaniyor.
			var kapali := ekran.duplicate()
			kapali.append(ekran[0])
			draw_polyline(kapali, SINIR, 1.0, true)

	_baglari_ciz()
	_cerceve_ciz(secili, SINIR_SECILI, 2.0)
	_cerceve_ciz(_ustunde, SINIR_USTUNDE, 1.0)
	_etiketleri_ciz()
	_hud_ciz()


func _ulke_rengi(u: Dictionary) -> Color:
	if dunya == null:
		return HaritaModu.VERI_YOK
	var di := int(_kod_dunya.get(u["kod"], -1))
	if di < 0:
		return HaritaModu.VERI_YOK
	return HaritaModu.renk(mod_id, dunya, di, _aralik)


func _cerceve_ciz(i: int, renk: Color, kalinlik: float) -> void:
	if i < 0:
		return
	var u := Harita.kayit()[i]
	var k := _olcek()
	var kose := _kose()
	for birim in u["halkalar"]:
		var ekran := PackedVector2Array()
		for n in birim:
			ekran.append(kose + n * k)
		ekran.append(ekran[0])
		draw_polyline(ekran, renk, kalinlik, true)


func _baglari_ciz() -> void:
	if dunya == null:
		return
	for b in _baglar:
		var a := _dunya_merkezi(int(b["i"]))
		var c := _dunya_merkezi(int(b["j"]))
		if a == Vector2.INF or c == Vector2.INF:
			continue
		var tip := String(b["tip"])
		var renk: Color = BAG_RENK[tip]
		var kalinlik := 1.0
		match tip:
			"ticaret":
				# Ticaret bagi en KALABALIK olan; agirligiyla soluklasir ki
				# omurga gorunsun, spagetti gorunmesin.
				renk.a = 0.15 + 0.45 * float(b["agirlik"])
				kalinlik = 1.0 + 2.0 * float(b["agirlik"])
			"savas":
				kalinlik = 2.5
			"abluka":
				renk.a = 0.25 + 0.35 * float(b["agirlik"])
				kalinlik = 1.5
			"ittifak":
				renk.a = 0.45
				kalinlik = 1.5
		draw_line(a, c, renk, kalinlik, true)


## Dunya indeksinden ekran noktasi. Haritada karsiligi yoksa `Vector2.INF`.
func _dunya_merkezi(di: int) -> Vector2:
	if dunya == null or di < 0 or di >= dunya.adlar.size():
		return Vector2.INF
	var ki := Harita.indeks(dunya.adlar[di])
	if ki < 0:
		return Vector2.INF
	return _ekrana(Harita.yansit(Harita.kayit()[ki]["merkez_d"]))


func _etiketleri_ciz() -> void:
	var yazi := get_theme_default_font()
	var boy := get_theme_default_font_size()
	for i in range(Harita.kayit().size()):
		var u := Harita.kayit()[i]
		var alan: float = u["alan"]
		# Yakinlastikca esik duser: uzakta yalnizca kitalar okunur, yakinda
		# her ulke. Esigi sabit tutmak iki ucu da bozardi.
		if alan * _zum * _zum < ETIKET_ALAN and i != secili and i != _ustunde:
			continue
		var p := _ekrana(Harita.yansit(u["merkez_d"]))
		if p.x < -60.0 or p.y < 0.0 or p.x > size.x + 60.0 or p.y > size.y:
			continue
		var ad := _gorunen_ad(u)
		var g := yazi.get_string_size(ad, HORIZONTAL_ALIGNMENT_LEFT, -1, boy - 2)
		var renk: Color = Tema.METIN if bool(u["oynanabilir"]) else Tema.METIN_SOLUK
		# Golge: harita rengi acik oldugunda duz yazi kayboluyor.
		draw_string(yazi, p - Vector2(g.x * 0.5 - 1.0, -1.0), ad,
				HORIZONTAL_ALIGNMENT_LEFT, -1, boy - 2, OKYANUS)
		draw_string(yazi, p - Vector2(g.x * 0.5, 0.0), ad,
				HORIZONTAL_ALIGNMENT_LEFT, -1, boy - 2, renk)


## Kampanya 1836'da basladigi icin oynanabilir ulkeler TARIHSEL adiyla
## gorunur (§5.8b). Ad degisiminin takvimi B7'nin isi; simdilik kayittaki
## tarihsel ad varsa o yazilir.
func _gorunen_ad(u: Dictionary) -> String:
	var t := String(u["ad_1836"])
	return t if t != "" else String(u["ad"])


func _hud_ciz() -> void:
	var yazi := get_theme_default_font()
	var boy := get_theme_default_font_size()
	var m := HaritaModu.mod(mod_id)

	# --- ust serit: mod adi + yil ---
	if serit_acik:
		var serit := Rect2(0.0, 0.0, size.x, 28.0)
		draw_rect(serit, Tema.PANEL)
		draw_line(Vector2(0.0, 28.0), Vector2(size.x, 28.0), Tema.CIZGI, 1.0)
		draw_string(yazi, Vector2(Tema.KENAR, 19.0), String(m["ad"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, boy, Tema.METIN)
		draw_string(yazi, Vector2(Tema.KENAR + 120.0, 19.0),
				String(m["aciklama"]), HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 320.0, boy - 2, Tema.METIN_SOLUK)
		if dunya != null:
			# Birikmis kayan nokta hatasi yil sinirinda bir yil geri gosterir
			# (1836.9999... -> 1836); epsilon toleransi onu yutar.
			draw_string(yazi, Vector2(size.x - 90.0, 19.0),
					"%d" % floori(dunya.yil + 1e-6),
					HORIZONTAL_ALIGNMENT_LEFT, -1, boy, Tema.VURGU)

	_efsane_ciz()
	_secili_ciz()


func _efsane_ciz() -> void:
	if dunya == null:
		return
	var yazi := get_theme_default_font()
	var boy := get_theme_default_font_size()
	var girdiler := HaritaModu.efsane(mod_id, dunya)
	var kutu_en := 132.0
	var kutu_boy := 16.0
	var x := Tema.KENAR
	var y := size.y - kutu_boy - Tema.KENAR - alt_bosluk
	draw_rect(Rect2(x - 4.0, y - 4.0,
			kutu_en * girdiler.size() + 8.0, kutu_boy + 8.0), Tema.PANEL)
	for g in girdiler:
		draw_rect(Rect2(x, y, 16.0, kutu_boy), g["renk"])
		draw_rect(Rect2(x, y, 16.0, kutu_boy), Tema.CIZGI, false, 1.0)
		draw_string(yazi, Vector2(x + 20.0, y + kutu_boy - 4.0),
				String(g["etiket"]), HORIZONTAL_ALIGNMENT_LEFT, kutu_en - 22.0,
				boy - 3, Tema.METIN_SOLUK)
		x += kutu_en


func _secili_ciz() -> void:
	var i := (secili if secili >= 0 else _ustunde) if bilgi_secili else _ustunde
	if i < 0:
		return
	var u := Harita.kayit()[i]
	var yazi := get_theme_default_font()
	var boy := get_theme_default_font_size()
	var satirlar: Array[String] = []
	satirlar.append(_gorunen_ad(u))
	if String(u["ad_1836"]) != "":
		satirlar.append(String(u["ad"]))
	satirlar.append(String(u["kita"]))

	var di := int(_kod_dunya.get(u["kod"], -1))
	if dunya != null and di >= 0:
		var d: KrizDurumu = dunya.ulkeler[di]
		var m := HaritaModu.mod(mod_id)
		satirlar.append("%s: %s" % [String(m["ad"]),
				HaritaModu.bicimle(HaritaModu.deger(mod_id, dunya, di),
						String(m["bicim"]))])
		satirlar.append("rejim: %s / %s" % [d.rejim, d.kurum])
		satirlar.append("kâr oranı: %.3f   işsizlik: %%%.1f"
				% [d.r_yil, d.iss_duzeltilmis() * 100.0])
		if d.savasta():
			satirlar.append("SAVAŞTA: " + ", ".join(_savas_adlari(d)))
	elif dunya != null:
		satirlar.append("simüle edilmiyor")

	var g := 0.0
	for s in satirlar:
		g = maxf(g, yazi.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1,
				boy - 2).x)
	var kutu := Rect2(size.x - g - 24.0 - sag_bosluk, 38.0, g + 16.0,
			satirlar.size() * 16.0 + 12.0)
	draw_rect(kutu, Tema.PANEL)
	draw_rect(kutu, Tema.CIZGI, false, 1.0)
	var y := kutu.position.y + 16.0
	for k in range(satirlar.size()):
		draw_string(yazi, Vector2(kutu.position.x + 8.0, y), satirlar[k],
				HORIZONTAL_ALIGNMENT_LEFT, kutu.size.x - 16.0, boy - 2,
				Tema.METIN if k == 0 else Tema.METIN_SOLUK)
		y += 16.0


func _savas_adlari(d: KrizDurumu) -> PackedStringArray:
	var c := PackedStringArray()
	for kod in d.savas.keys():
		var i := Harita.indeks(String(kod))
		c.append(_gorunen_ad(Harita.kayit()[i]) if i >= 0 else String(kod))
	return c


# ---------------------------------------------------------------------------
# GIRDI
# ---------------------------------------------------------------------------
func _gui_input(olay: InputEvent) -> void:
	if olay is InputEventMouseMotion:
		if _suruklu:
			_kaydirma -= olay.relative / _olcek()
			queue_redraw()
		else:
			var yeni := Harita.bul(Harita.ters(_birime(olay.position)))
			if yeni != _ustunde:
				_ustunde = yeni
				queue_redraw()
	elif olay is InputEventMouseButton:
		if olay.button_index == MOUSE_BUTTON_LEFT:
			_suruklu = olay.pressed
			if not olay.pressed:
				_sec(Harita.bul(Harita.ters(_birime(olay.position))))
		elif olay.button_index == MOUSE_BUTTON_WHEEL_UP and olay.pressed:
			_yakinlas(1.12, olay.position)
		elif olay.button_index == MOUSE_BUTTON_WHEEL_DOWN and olay.pressed:
			_yakinlas(1.0 / 1.12, olay.position)


func _sec(i: int) -> void:
	secili = i
	queue_redraw()
	if i >= 0:
		ulke_secildi.emit(String(Harita.kayit()[i]["kod"]))


## Imlecin ALTINDAKI noktayi sabit tutarak yakinlastirir. Merkeze gore
## yakinlastirmak haritayi kullanilmaz yapar: kullanici baktigi yeri
## kaybeder.
func _yakinlas(carpan: float, imlec: Vector2) -> void:
	var once := _birime(imlec)
	_zum = clampf(_zum * carpan, 1.0, 12.0)
	var sonra := _birime(imlec)
	_kaydirma += once - sonra
	queue_redraw()
