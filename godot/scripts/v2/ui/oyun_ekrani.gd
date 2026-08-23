class_name OyunEkrani
extends Control

## B7 -- Victoria duzeni. §5.5: "ANA EKRAN HARITA. Paneller USTUNE acilir."
##
## Harita tam ekrani kaplar ve arka katmandir; paneller onun uzerine biner,
## yan yana degil. Bu bir estetik tercih degil: oyunun konusu ulkenin DUNYA
## SISTEMINDEKI KONUMU (§0), ve harita kucultulup bir kosede gosterilseydi
## panellerin anlattigi sayilarin nereden geldigi gorunmezdi.
##
## ------------------------------------------------------------------------
## YENILEME YILLIK, KARE BASINA DEGIL
## ------------------------------------------------------------------------
## `HaritaGorunum.yenile()` renk araligini yeniden hesaplar ve
## `Harita.gorunur_baglar` cift taramasi yapar; tam kadroda 6328 cift eder.
## Her tik cagrilsaydi harita motordan daha pahaliya gelirdi. Yil siniri
## dogru esik: renkler ve baglar yil olceginde anlamli degisir, hafta
## olceginde degil. Ust bardaki takvim yine her karede tazelenir -- orasi
## bir metin, tarama degil.
##
## ------------------------------------------------------------------------
## HIZ: SANIYE BASINA TIK, KARE BASINA DEGIL
## ------------------------------------------------------------------------
## Tik maliyeti kadroyla buyur (B6: 113 ulkede 45.6 ms). Kare basina sabit
## sayida tik kosulsaydi buyuk dunyada oyun donar, kucuk dunyada takvim
## ucardi. Birikimli sayac saniyeye baglar; kare basina tik sayisi ayrica
## sinirlanir ki tek bir uzun kare oyunu kilitlemesin.

const HIZLAR := [0, 4, 12, 32]          ## saniyede tik
const HIZ_ADI := ["‖", "▶", "▶▶", "▶▶▶"]
const KARE_BASINA_EN_FAZLA := 4

signal menuye_don

var oyun: Oyun = null

var _harita: HaritaGorunum
var _ulke_paneli: UlkePaneli
var _politika_paneli: PolitikaPaneli
var _gunce_paneli: GuncePaneli

var _takvim: Label
var _bilgi: Label
var _ilerleme: ProgressBar
var _hiz_dugmeleri: Array[Button] = []

var _hiz := 0
var _sayac := 0.0
var _son_yil := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_harita = HaritaGorunum.new()
	_harita.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_harita.serit_acik = false          # ust bari bu ekran ciziyor
	_harita.ulke_secildi.connect(_ulke_secildi)
	add_child(_harita)

	_ust_bar_kur()
	_panelleri_kur()


func kur(p_oyun: Oyun) -> void:
	oyun = p_oyun
	_harita.kur(oyun.dunya)
	_ulke_paneli.kur(oyun)
	_politika_paneli.kur(oyun)
	_gunce_paneli.kur(oyun)
	# GOZLEMCI KIPINDE ULKE PANELI KAPALI ACILIR. Secili ulke yokken panel
	# on dokuz "veri yok" kutusu gosteriyordu -- dolu gorunen, hicbir sey
	# anlatmayan bir ekran. Oyuncu varsa kendi ulkesiyle acilir.
	_ulke_paneli.visible = oyun.oyuncu >= 0
	if oyun.oyuncu >= 0:
		_ulke_paneli.ulke_sec(oyun.oyuncu)
		var ki := Harita.indeks(oyun.dunya.adlar[oyun.oyuncu])
		if ki >= 0:
			_harita.secili = ki
	_son_yil = -1
	_bosluklari_guncelle()
	_yenile()


# ===========================================================================
# ZAMAN
# ===========================================================================

func _process(delta: float) -> void:
	_takvim.text = "%d" % oyun.takvim_yili() if oyun != null else ""
	if oyun == null or _hiz == 0 or oyun.bitti():
		return
	_sayac += delta * float(HIZLAR[_hiz])
	var n := mini(int(_sayac), KARE_BASINA_EN_FAZLA)
	if n <= 0:
		return
	_sayac -= float(n)
	oyun.ilerle(n)
	_ilerleme.value = oyun.ilerleme() * 100.0

	var yil := int(oyun.tik() / Oyun.YILDA_TIK)
	if yil != _son_yil:
		_son_yil = yil
		_yenile()
	if oyun.bitti():
		_hiz_ayarla(0)


## KAYDEDERKEN DURAKLATILIR. Serilestirme bir tik surer ve o sirada dunya
## ilerleseydi kayit ile ekran arasinda bir haftalik fark olusurdu -- kucuk
## ama "kaydettigim yer" iddiasini bozacak kadar.
func _kaydet() -> void:
	if oyun == null:
		return
	_hiz_ayarla(0)
	var basarili := Save.oturum_yaz(oyun.sozluge())
	_bilgi.text = ("Kaydedildi — %d" % oyun.takvim_yili() if basarili
			else "KAYIT YAZILAMADI")


func _hiz_ayarla(i: int) -> void:
	_hiz = clampi(i, 0, HIZLAR.size() - 1)
	_sayac = 0.0
	for k in range(_hiz_dugmeleri.size()):
		_hiz_dugmeleri[k].button_pressed = k == _hiz


func _unhandled_input(olay: InputEvent) -> void:
	if olay is InputEventKey and olay.pressed and not olay.echo:
		match (olay as InputEventKey).keycode:
			KEY_SPACE:
				_hiz_ayarla(0 if _hiz > 0 else 1)
				accept_event()
			KEY_EQUAL, KEY_KP_ADD:
				_hiz_ayarla(_hiz + 1)
				accept_event()
			KEY_MINUS, KEY_KP_SUBTRACT:
				_hiz_ayarla(_hiz - 1)
				accept_event()


# ===========================================================================
# KURULUM
# ===========================================================================

func _ust_bar_kur() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size.y = 38
	bar.offset_bottom = 38
	add_child(bar)

	var kenar := MarginContainer.new()
	for yan in ["margin_left", "margin_right"]:
		kenar.add_theme_constant_override(yan, 8)
	bar.add_child(kenar)
	var ic := HBoxContainer.new()
	ic.add_theme_constant_override("separation", 8)
	kenar.add_child(ic)

	_takvim = Label.new()
	_takvim.custom_minimum_size.x = 52
	_takvim.add_theme_color_override("font_color", Tema.VURGU)
	ic.add_child(_takvim)

	for k in range(HIZLAR.size()):
		var d := Button.new()
		d.text = HIZ_ADI[k]
		d.toggle_mode = true
		d.tooltip_text = ("duraklat" if k == 0
				else "saniyede %d hafta" % HIZLAR[k])
		d.pressed.connect(_hiz_ayarla.bind(k))
		ic.add_child(d)
		_hiz_dugmeleri.append(d)
	_hiz_dugmeleri[0].button_pressed = true

	_ilerleme = ProgressBar.new()
	_ilerleme.custom_minimum_size.x = 120
	_ilerleme.show_percentage = false
	ic.add_child(_ilerleme)

	_bilgi = Label.new()
	_bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bilgi.clip_text = true
	_bilgi.add_theme_color_override("font_color", Tema.METIN)
	ic.add_child(_bilgi)

	# Harita modlari. Dokuzu da `HaritaModu`dan okunur; ekran kendi listesini
	# tutmaz.
	var mod_secim := OptionButton.new()
	mod_secim.tooltip_text = "Harita modu"
	var kimlikler := HaritaModu.kimlikler()
	for k in range(kimlikler.size()):
		mod_secim.add_item(String(HaritaModu.mod(kimlikler[k])["ad"]), k)
	mod_secim.item_selected.connect(func(i: int) -> void:
		_harita.mod_sec(kimlikler[i]))
	ic.add_child(mod_secim)

	for o in [["Ülke", func() -> void: _panel_ac(_ulke_paneli)],
			["Politika", func() -> void: _panel_ac(_politika_paneli)],
			["Günce", func() -> void:
				_gunce_paneli.visible = not _gunce_paneli.visible
				_bosluklari_guncelle()],
			["Kaydet", func() -> void: _kaydet()],
			["Menü", func() -> void: menuye_don.emit()]]:
		var d := Button.new()
		d.text = String(o[0])
		d.pressed.connect(o[1] as Callable)
		ic.add_child(d)


func _panelleri_kur() -> void:
	# PANELLER HARITANIN USTUNE BINER (§5.5). Sag kenara yaslanirlar; harita
	# altlarinda devam eder, kirpilmaz -- kaydirip yakinlastirmak panel
	# acikken de calisir.
	_ulke_paneli = UlkePaneli.new()
	_ulke_paneli.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_ulke_paneli.offset_top = 40
	_ulke_paneli.offset_bottom = -160
	_ulke_paneli.offset_left = -504
	_ulke_paneli.kapat_istendi.connect(func() -> void:
		_ulke_paneli.visible = false
		_bosluklari_guncelle())
	add_child(_ulke_paneli)

	_politika_paneli = PolitikaPaneli.new()
	_politika_paneli.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_politika_paneli.offset_top = 40
	_politika_paneli.offset_bottom = -160
	_politika_paneli.offset_left = -424
	_politika_paneli.visible = false
	_politika_paneli.kapat_istendi.connect(func() -> void:
		_politika_paneli.visible = false
		_bosluklari_guncelle())
	add_child(_politika_paneli)

	_gunce_paneli = GuncePaneli.new()
	_gunce_paneli.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_gunce_paneli.offset_top = -156
	add_child(_gunce_paneli)


## Iki sag panel ayni yeri paylasir; biri acilinca digeri kapanir. Ust uste
## binmeleri ikisini de okunmaz yapardi.
func _panel_ac(panel: Control) -> void:
	var acik := not panel.visible
	_ulke_paneli.visible = false
	_politika_paneli.visible = false
	panel.visible = acik
	_bosluklari_guncelle()


## Haritanin kendi HUD ogelerini (efsane, bilgi kutusu) acik panellerin
## altindan cikarir. Panel gorunurlugu her degistiginde cagrilmali.
func _bosluklari_guncelle() -> void:
	_harita.alt_bosluk = (_gunce_paneli.size.y if _gunce_paneli.visible
			else 0.0)
	if _ulke_paneli.visible:
		_harita.sag_bosluk = _ulke_paneli.size.x
	elif _politika_paneli.visible:
		_harita.sag_bosluk = _politika_paneli.size.x
	else:
		_harita.sag_bosluk = 0.0
	_harita.bilgi_secili = not _ulke_paneli.visible
	_harita.queue_redraw()


## Belirli bir paneli acar. GORSEL KAPI ICIN: `--headless` `_draw()`
## kosturmadigi icin panellerin cizimini gormenin tek yolu ekran goruntusu,
## ve kapali bir panelin cizimi hic denenmez.
func panel_goster(ad: String) -> void:
	match ad:
		"ulke":
			_ulke_paneli.visible = true
			_politika_paneli.visible = false
		"politika":
			_politika_paneli.visible = true
			_ulke_paneli.visible = false
		"gunce":
			_gunce_paneli.visible = true
		"yok":
			_ulke_paneli.visible = false
			_politika_paneli.visible = false
			_gunce_paneli.visible = false
	_bosluklari_guncelle()


# ===========================================================================
func _ulke_secildi(kod: String) -> void:
	if oyun == null:
		return
	for i in range(oyun.dunya.adlar.size()):
		if oyun.dunya.adlar[i] == kod:
			_ulke_paneli.ulke_sec(i)
			_ulke_paneli.visible = true
			_politika_paneli.visible = false
			_bosluklari_guncelle()
			return
	# Cizili ama SIMULE EDILMEYEN ulke (156 cizili / 113 simule). Panel
	# bunu "veri yok" olarak gostermeli, sessizce eski ulkede kalmamali.
	_ulke_paneli.ulke_sec(-1)
	_ulke_paneli.visible = true
	_bosluklari_guncelle()


func _yenile() -> void:
	if oyun == null:
		return
	_harita.yenile()
	_ulke_paneli.yenile()
	_politika_paneli.esitle()
	_gunce_paneli.yenile()
	_ilerleme.value = oyun.ilerleme() * 100.0

	var d := oyun.oyuncu_durumu()
	if d == null:
		_bilgi.text = "Gözlemci — dünyayı dışarıdan izliyorsunuz"
		return
	# KISA TUTULUR. Uzun metin `clip_text` ile kelime ortasindan kesiliyordu
	# ("issi"); ayrinti zaten ulke panelinde duruyor.
	_bilgi.text = "%s · %s/%s · r %s · işsizlik %s" % [
			oyun.ad(oyun.oyuncu), d.rejim, d.kurum,
			HaritaModu.bicimle(d.r_yil, "oran3"),
			HaritaModu.bicimle(d.iss_duzeltilmis(), "yuzde")]
