class_name PolitikaPaneli
extends PanelContainer

## Oyuncunun kollari.
##
## ------------------------------------------------------------------------
## §4.6'NIN TEMSIL ILKESI BU PANELDE YASAR
## ------------------------------------------------------------------------
## Sekiz taktik "etkinlik", "guvenlik" ya da "istikrar" kolu diye sunulmaz.
## Her satirda UC sey birden yazar: taktigin kendisi, hangi aygita ait oldugu
## (riza / zor), ve BEDELI KIMIN ODEDIGI. Metinler `Oyun.TAKTIKLER`den gelir,
## o da `KaranlikDevlet`in kendi tablosundan turetilmistir -- yani ekranda
## yazan bedel ile motorda isleyen kanal AYNI KAYNAKTAN gelir ve ayrisamaz.
##
## Bedeller ayrica SAYILIR: panelin altindaki olcerler `riza_kolu`,
## `zor_kolu`, `bolunme` ve `karsi_hareket`i canli gosterir. Bunlar gizli
## carpanlar degil, kar orani kadar gorunur metriklerdir -- ve grafikleri
## ulke panelinde, cekirdek metriklerle ayni izgarada durur.
##
## KARSI HAREKET DEKOR DEGIL (§4.4). Panelin en altinda kendi olcerini tasir:
## karanlik devlet iter, sendika ve parti ceker, ve oyuncu bu yarisi canli
## gorur.

signal kapat_istendi

var _oyun: Oyun = null

var _kaydiricilar: Dictionary = {}     ## alan/anahtar -> HSlider
var _etiketler: Dictionary = {}        ## alan/anahtar -> Label
var _olcerler: Dictionary = {}         ## anahtar -> Label
var _uyari: Label


func _ready() -> void:
	custom_minimum_size.x = 420
	add_theme_stylebox_override("panel", Tema.panel_stili())
	var kok := VBoxContainer.new()
	kok.add_theme_constant_override("separation", 4)
	add_child(kok)

	var ust := HBoxContainer.new()
	kok.add_child(ust)
	var baslik := Label.new()
	baslik.text = "Politika"
	baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baslik.add_theme_color_override("font_color", Tema.METIN)
	ust.add_child(baslik)
	var kapat := Button.new()
	kapat.text = "×"
	kapat.pressed.connect(func() -> void: kapat_istendi.emit())
	ust.add_child(kapat)

	var kaydir := ScrollContainer.new()
	kaydir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kok.add_child(kaydir)

	var ic := VBoxContainer.new()
	ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic.add_theme_constant_override("separation", 6)
	kaydir.add_child(ic)

	# --- ekonomi ---
	ic.add_child(_bolum("Birikim"))
	_kol(ic, "yukseltme_payi", "Üretim yöntemi yükseltmesine ayrılan yatırım",
			0.0, 1.0, 0.05,
			"Merdiveni tırmanmak q'yu yükseltir → c/v yükselir → kâr oranı DÜŞER. "
			+ "Oyunun merkezî tuzağı budur ve kaçınılamaz (§2.4).")
	_kol(ic, "etg", "Temel gelir hedefi (hasılanın payı)", 0.0, 0.40, 0.01,
			"Yalnızca kapitalist rejimde tanımlıdır; planlı ekonomide ücret "
			+ "zaten planla belirlenir.")
	_kol(ic, "aciklik", "Dışa açıklık", 0.0, 2.0, 0.05,
			"Açıklık hem pazar hem değer transferi kanalıdır. Çevre için iki "
			+ "ucu keskin: ihracat da buradan gelir, sızıntı da.")
	_kol(ic, "saldirganlik", "Saldırganlık", 0.0, 1.0, 0.05,
			"Savaş bir kriz çıkışıdır — en şiddetlisi (§3.2).")

	# --- karanlik devlet ---
	ic.add_child(_bolum("Karanlık devlet"))
	_uyari = Label.new()
	_uyari.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_uyari.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	_uyari.text = ("Bunlar bir yönetim tekniği değil, sınıf egemenliğinin "
			+ "araçlarıdır. Her birinin mağduru adlandırılmış, bedeli "
			+ "sayılmıştır. Kullanmamak da bir karardır.")
	ic.add_child(_uyari)

	for t in Oyun.TAKTIKLER:
		_kol(ic, String(t["alan"]),
				"[%s]  %s" % [String(t["aygit"]), String(t["ad"])],
				0.0, 1.0, 0.05, "Bedeli: " + String(t["bedel"]))

	# --- bedeller, canli ---
	ic.add_child(_bolum("Bedeller"))
	for o in [["riza_kolu", "Rıza aygıtı"], ["zor_kolu", "Zor aygıtı"],
			["bolunme", "Bölünme"], ["karsi_hareket", "Karşı hareket"],
			["cezaevi_orani", "Cezaevi oranı"], ["sehit", "Şehit stoku"]]:
		var satir := HBoxContainer.new()
		var ad := Label.new()
		ad.text = String(o[1])
		ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ad.add_theme_color_override("font_color", Tema.METIN_SOLUK)
		satir.add_child(ad)
		var deger := Label.new()
		deger.add_theme_color_override("font_color", Tema.METIN)
		satir.add_child(deger)
		_olcerler[String(o[0])] = deger
		ic.add_child(satir)


func _bolum(metin: String) -> Control:
	var l := Label.new()
	l.text = metin
	l.add_theme_color_override("font_color", Tema.VURGU)
	return l


func _kol(ana: Control, anahtar: String, ad: String, en_az: float,
		en_cok: float, adim: float, aciklama: String) -> void:
	var kutu := VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 0)

	var ust := HBoxContainer.new()
	var etiket := Label.new()
	etiket.text = ad
	etiket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiket.add_theme_color_override("font_color", Tema.METIN)
	ust.add_child(etiket)
	var deger := Label.new()
	deger.custom_minimum_size.x = 46
	deger.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deger.add_theme_color_override("font_color", Tema.VURGU)
	ust.add_child(deger)
	kutu.add_child(ust)

	var kaydirici := HSlider.new()
	kaydirici.min_value = en_az
	kaydirici.max_value = en_cok
	kaydirici.step = adim
	kaydirici.value_changed.connect(func(v: float) -> void: _degisti(anahtar, v))
	kutu.add_child(kaydirici)

	# BEDEL HER ZAMAN GORUNUR, tooltip'e saklanmaz. Ustune gelinmedikce
	# okunmayan bir bedel, sayilmis sayilmaz (§4.6).
	var alt := Label.new()
	alt.text = aciklama
	alt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alt.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	kutu.add_child(alt)

	_kaydiricilar[anahtar] = kaydirici
	_etiketler[anahtar] = deger
	ana.add_child(kutu)


func kur(oyun: Oyun) -> void:
	_oyun = oyun
	var oynanir := oyun != null and oyun.oyuncu >= 0
	for k in _kaydiricilar.keys():
		(_kaydiricilar[k] as HSlider).editable = oynanir
	esitle()


## Kaydiricilari motorun DURUMUNA esitler. Cagrilmasi zorunlu: kaydirici
## kendi degerini tutar ve motor onu (rejim degisimi, sosyalist devrim)
## sifirlayabilir; esitlenmezse ekran motorun soylemedigi bir sey soyler.
func esitle() -> void:
	if _oyun == null:
		return
	var d := _oyun.oyuncu_durumu()
	_yaz("yukseltme_payi", _oyun.yukseltme_payi())
	_yaz("etg", _oyun.etg_hedefi())
	_yaz("aciklik", _oyun.aciklik())
	_yaz("saldirganlik", _oyun.saldirganlik())
	for t in Oyun.TAKTIKLER:
		_yaz(String(t["alan"]), _oyun.taktik_degeri(String(t["alan"])))
	if d != null:
		# ETG SOSYALIST REJIMDE TANIMSIZ, ve bu gizlenmez: cekirdek alani her
		# tik sifirlar, dolayisiyla kaydiriciyi acik birakmak oyuncuya
		# olmayan bir kol gostermek olurdu.
		var kap := d.rejim == "kapitalist"
		(_kaydiricilar["etg"] as HSlider).editable = kap
		(_etiketler["etg"] as Label).text = (
				(_etiketler["etg"] as Label).text if kap else "—")
	yenile()


func _yaz(anahtar: String, deger: float) -> void:
	if not _kaydiricilar.has(anahtar):
		return
	var k := _kaydiricilar[anahtar] as HSlider
	k.set_block_signals(true)
	k.value = deger
	k.set_block_signals(false)
	(_etiketler[anahtar] as Label).text = "%.2f" % deger


func _degisti(anahtar: String, v: float) -> void:
	if _oyun == null:
		return
	match anahtar:
		"yukseltme_payi":
			_oyun.yukseltme_payi_ayarla(v)
		"etg":
			_oyun.etg_ayarla(v)
		"aciklik":
			_oyun.aciklik_ayarla(v)
		"saldirganlik":
			_oyun.saldirganlik_ayarla(v)
		_:
			_oyun.taktik_ayarla(anahtar, v)
	(_etiketler[anahtar] as Label).text = "%.2f" % v


## Canli bedel olcerleri. Her tik cagrilir.
func yenile() -> void:
	var d: KrizDurumu = _oyun.oyuncu_durumu() if _oyun != null else null
	for anahtar in _olcerler.keys():
		var l := _olcerler[anahtar] as Label
		if d == null:
			l.text = "—"
			continue
		var v := float(d.get(anahtar))
		l.text = HaritaModu.bicimle(v,
				"yuzde" if anahtar == "cezaevi_orani" else "oran2")
