class_name Dashboard
extends Control

## Oyunun asıl ekranı: 12 çekirdek metrik, ülke listesi, politika paneli,
## olay günlüğü.
##
## Belgenin §44 kararı korunuyor: SİS YOK. Bütün sayılar kesin, gizlenen bilgi
## yok. Tek istisna oyuncunun kararı olan POLİTİKA GECİKMESİDİR -- ilan edilen
## değer panelde hemen görünür, motorda ise 8 tur sonra yürürlüğe girer ve
## rejime göre yavaş yerleşir. Oyuncu geri sayım görmez; etkiyi grafiklerde
## zamanla görür.
##
## Bu yüzden politika denetimleri motorun ANLIK durumunu değil, oyuncunun
## İLAN ETTİĞİ hedefi gösterir. Aksi halde kaydırıcı bırakıldığı yerden geri
## sıçrar ve "bozuk" görünür.

signal menuye_don

const GRAFIK_SUTUN := 3

var _grafikler: Array[Chart] = []
var _ulke_listesi: ItemList
var _olay_gunlugu: RichTextLabel
var _ust_bilgi: Label
var _ilerleme: ProgressBar
var _durum: Label

var _etg_kaydirici: HSlider
var _etg_etiket: Label
var _fin_kaydirici: HSlider
var _fin_etiket: Label
var _plan_secim: OptionButton
var _kurum_secim: OptionButton
var _kurum_dugme: Button
var _kurum_not: Label
var _mafya_endojen: CheckBox
var _mafya_kaydirici: HSlider

var _secili_ulke := ""
var _oto := false
var _oto_sayac := 0.0
var _oto_araligi := 0.25


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arayuzu_kur()
	_secili_ulke = Sim.oyuncu

	Sim.tur_ilerledi.connect(_tur_ilerledi)
	Sim.olay_eklendi.connect(_olay_eklendi)
	Sim.rejim_degisti.connect(_rejim_degisti)
	Sim.kosu_bitti.connect(_kosu_bitti)

	_ulkeleri_doldur()
	_politikayi_esitle()
	_yenile()


func _process(delta: float) -> void:
	if not _oto or Sim.bitti():
		return
	_oto_sayac += delta
	if _oto_sayac >= _oto_araligi:
		_oto_sayac = 0.0
		Sim.ilerle(1)


# ===========================================================================
# KURULUM
# ===========================================================================

func _arayuzu_kur() -> void:
	var zemin := ColorRect.new()
	zemin.color = Tema.ZEMIN
	zemin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	zemin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zemin)

	var kok := VBoxContainer.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_theme_constant_override("separation", 6)
	add_child(kok)

	kok.add_child(_ust_bar_kur())

	var orta := HBoxContainer.new()
	orta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	orta.add_theme_constant_override("separation", 6)
	kok.add_child(orta)

	orta.add_child(_ulke_paneli_kur())
	orta.add_child(_grafik_izgarasi_kur())
	orta.add_child(_politika_paneli_kur())

	kok.add_child(_gunluk_kur())


func _ust_bar_kur() -> Control:
	var kutu := PanelContainer.new()
	kutu.custom_minimum_size.y = 46
	var kenar := MarginContainer.new()
	for yan in ["margin_left", "margin_right"]:
		kenar.add_theme_constant_override(yan, 8)
	kutu.add_child(kenar)
	var ic := HBoxContainer.new()
	ic.add_theme_constant_override("separation", 10)
	kenar.add_child(ic)

	# Bilgi metni ESNEK olan taraftir: kirpilirsa okunur kalir, ama dugmeler
	# tasarsa tiklanamaz hale gelir.
	_ust_bilgi = Label.new()
	_ust_bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ust_bilgi.size_flags_stretch_ratio = 2.0
	_ust_bilgi.clip_text = true
	_ust_bilgi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic.add_child(_ust_bilgi)

	_ilerleme = ProgressBar.new()
	_ilerleme.custom_minimum_size = Vector2(120, 0)
	_ilerleme.show_percentage = false
	_ilerleme.max_value = 1.0
	ic.add_child(_ilerleme)

	var d1 := Button.new()
	d1.text = "+1 tur"
	d1.pressed.connect(func(): Sim.ilerle(1))
	ic.add_child(d1)

	var d10 := Button.new()
	d10.text = "+10"
	d10.pressed.connect(func(): Sim.ilerle(10))
	ic.add_child(d10)

	var oto := CheckBox.new()
	oto.text = "otomatik"
	oto.toggled.connect(func(a): _oto = a)
	ic.add_child(oto)

	var hiz := OptionButton.new()
	for etiket in ["yavaş", "normal", "hızlı"]:
		hiz.add_item(etiket)
	hiz.selected = 1
	hiz.item_selected.connect(func(i): _oto_araligi = [0.6, 0.25, 0.05][i])
	ic.add_child(hiz)

	var geri := Button.new()
	geri.text = "menü"
	geri.pressed.connect(func(): menuye_don.emit())
	ic.add_child(geri)

	return kutu


func _ulke_paneli_kur() -> Control:
	var kutu := PanelContainer.new()
	kutu.custom_minimum_size.x = 172
	var ic := VBoxContainer.new()
	kutu.add_child(ic)

	var baslik := Label.new()
	baslik.text = "Ülkeler"
	baslik.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ic.add_child(baslik)

	_ulke_listesi = ItemList.new()
	_ulke_listesi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ulke_listesi.item_selected.connect(_ulke_secildi)
	ic.add_child(_ulke_listesi)

	_durum = Label.new()
	_durum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_durum.add_theme_font_size_override("font_size", 11)
	ic.add_child(_durum)

	return kutu


func _grafik_izgarasi_kur() -> Control:
	# ScrollContainer KULLANILMIYOR: cocuklarini asgari boyutlarina sikistirir,
	# grafikler dikeyde yayilmaz ve altta bos bir serit kalir. 12 grafik 3x4
	# olarak hedef cozunurluge zaten siglyor.
	var izgara := GridContainer.new()
	izgara.columns = GRAFIK_SUTUN
	izgara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izgara.size_flags_vertical = Control.SIZE_EXPAND_FILL
	izgara.add_theme_constant_override("h_separation", 6)
	izgara.add_theme_constant_override("v_separation", 6)

	for m in Sim.CEKIRDEK_METRIKLER:
		var g := Chart.new()
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.size_flags_vertical = Control.SIZE_EXPAND_FILL
		izgara.add_child(g)
		g.kur(m)
		_grafikler.append(g)

	return izgara


func _politika_paneli_kur() -> Control:
	var kutu := PanelContainer.new()
	kutu.custom_minimum_size.x = 272
	var ic := VBoxContainer.new()
	ic.add_theme_constant_override("separation", 8)
	kutu.add_child(ic)

	var baslik := Label.new()
	baslik.text = "Politika"
	baslik.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ic.add_child(baslik)

	var not_etiket := Label.new()
	not_etiket.text = "Kararlar yürürlüğe girmesi zaman alır; etkiyi grafiklerde göreceksin."
	not_etiket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	not_etiket.add_theme_font_size_override("font_size", 10)
	not_etiket.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ic.add_child(not_etiket)

	# --- Temel gelir ---
	_etg_etiket = Label.new()
	ic.add_child(_etg_etiket)
	_etg_kaydirici = HSlider.new()
	_etg_kaydirici.min_value = 0.0
	_etg_kaydirici.max_value = 0.40
	_etg_kaydirici.step = 0.01
	_etg_kaydirici.value_changed.connect(func(v):
		_etg_etiket.text = "Temel gelir hedefi: %%%.0f" % (v * 100.0)
		Sim.temel_gelir_ilan(v))
	ic.add_child(_etg_kaydirici)

	# --- ETG finansmanı ---
	_fin_etiket = Label.new()
	ic.add_child(_fin_etiket)
	_fin_kaydirici = HSlider.new()
	_fin_kaydirici.min_value = 0.0
	_fin_kaydirici.max_value = 1.0
	_fin_kaydirici.step = 0.05
	_fin_kaydirici.value_changed.connect(func(v):
		_fin_etiket.text = "Finansman: sermayeden %%%.0f" % (v * 100.0)
		Sim.etg_finansman_ilan(v))
	ic.add_child(_fin_kaydirici)

	ic.add_child(HSeparator.new())

	# --- Plan profili (yalnızca planlı ekonomide) ---
	var plan_etiket := Label.new()
	plan_etiket.text = "Plan profili"
	ic.add_child(plan_etiket)
	_plan_secim = OptionButton.new()
	for p in ["dengeli", "sanayilesmeci", "tuketimci"]:
		_plan_secim.add_item(p)
	_plan_secim.item_selected.connect(func(i):
		Sim.plan_profili_ilan(_plan_secim.get_item_text(i)))
	ic.add_child(_plan_secim)

	ic.add_child(HSeparator.new())

	# --- Kurumsal inşa: siyasi sermaye harcayan TEK kol ---
	var kurum_etiket := Label.new()
	kurum_etiket.text = "Kurumsal inşa"
	ic.add_child(kurum_etiket)
	_kurum_secim = OptionButton.new()
	for k in ["duzenli", "neoliberal", "liberal"]:
		_kurum_secim.add_item(k)
	ic.add_child(_kurum_secim)
	_kurum_dugme = Button.new()
	_kurum_dugme.text = "inşa et"
	_kurum_dugme.pressed.connect(func():
		Sim.kurumsal_insa_ilan(_kurum_secim.get_item_text(_kurum_secim.selected)))
	ic.add_child(_kurum_dugme)
	_kurum_not = Label.new()
	_kurum_not.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kurum_not.add_theme_font_size_override("font_size", 10)
	_kurum_not.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	ic.add_child(_kurum_not)

	ic.add_child(HSeparator.new())

	# --- Karanlık devlet ---
	_mafya_endojen = CheckBox.new()
	_mafya_endojen.text = "mafya politikası: devlet karar versin"
	_mafya_endojen.button_pressed = true
	_mafya_endojen.toggled.connect(func(a):
		_mafya_kaydirici.editable = not a
		Sim.mafya_kilidi_ayarla(null if a else _mafya_kaydirici.value))
	ic.add_child(_mafya_endojen)
	_mafya_kaydirici = HSlider.new()
	_mafya_kaydirici.min_value = 0.0
	_mafya_kaydirici.max_value = 1.0
	_mafya_kaydirici.step = 0.05
	_mafya_kaydirici.editable = false
	_mafya_kaydirici.value_changed.connect(func(v):
		if not _mafya_endojen.button_pressed:
			Sim.mafya_kilidi_ayarla(v))
	ic.add_child(_mafya_kaydirici)

	return kutu


func _gunluk_kur() -> Control:
	var kutu := PanelContainer.new()
	kutu.custom_minimum_size.y = 116
	_olay_gunlugu = RichTextLabel.new()
	_olay_gunlugu.bbcode_enabled = true
	_olay_gunlugu.scroll_following = true
	kutu.add_child(_olay_gunlugu)
	return kutu


# ===========================================================================
# GÜNCELLEME
# ===========================================================================

func _ulkeleri_doldur() -> void:
	_ulke_listesi.clear()
	var i := 0
	for ad in Sim.ulke_adlari():
		var c := Sim.ulke(ad)
		_ulke_listesi.add_item(ad + ("  ◆" if ad == Sim.oyuncu else ""))
		_ulke_listesi.set_item_custom_fg_color(i, Tema.rejim_rengi(c.rejim))
		if ad == _secili_ulke:
			_ulke_listesi.select(i)
		i += 1


func _ulke_secildi(indeks: int) -> void:
	var adlar := Sim.ulke_adlari()
	if indeks < 0 or indeks >= adlar.size():
		return
	_secili_ulke = adlar[indeks]
	for g in _grafikler:
		g.ulke_ad = _secili_ulke
	_yenile()


func _tur_ilerledi(_t: int) -> void:
	_yenile()


func _yenile() -> void:
	var c := Sim.ulke(_secili_ulke)
	if c == null:
		return

	_ust_bilgi.text = "%s  ·  %d. yıl (%.0f)  ·  tur %d/%d  ·  oynadığın ülke: %s" % [
			String(Sim.SENARYOLAR[Sim.senaryo]["ad"]), int(Sim.yil() - Sim.baslangic_yili) + 1,
			Sim.yil(), Sim.tur(), Sim.ufuk, Sim.oyuncu]
	_ilerleme.value = Sim.ilerleme()

	var kopus_notu := ""
	if not Sim.kopuslar.is_empty():
		kopus_notu = "\nrejim %d kez el değiştirdi" % Sim.kopuslar.size()
	_durum.text = "%s\n%s / %s\nçağ %d — %s%s" % [
			c.ad, c.rejim, c.kurum, c.era,
			String(Tables.ERAS[c.era]["name"]), kopus_notu]
	_durum.add_theme_color_override("font_color", Tema.rejim_rengi(c.rejim))

	# Ülke listesi rejim renkleri değişmiş olabilir (devrim, restorasyon).
	var i := 0
	for ad in Sim.ulke_adlari():
		_ulke_listesi.set_item_custom_fg_color(i, Tema.rejim_rengi(Sim.ulke(ad).rejim))
		i += 1

	for g in _grafikler:
		g.yenile(Sim.kopuslar)

	# Plan kolu yalnızca planlı ekonomide anlamlı; ETG orada zaten kapanır.
	var oyuncu_c := Sim.ulke()
	var sosyalist := oyuncu_c != null and oyuncu_c.rejim == "sosyalist"
	_plan_secim.disabled = not sosyalist
	_etg_kaydirici.editable = not sosyalist
	_fin_kaydirici.editable = not sosyalist

	var durum := Sim.kurumsal_insa_durumu()
	_kurum_dugme.disabled = not bool(durum.get("mumkun", false))
	_kurum_not.text = ("hazır — siyasi sermaye harcanacak"
			if durum.get("mumkun", false) else String(durum.get("sebep", "")))


func _olay_eklendi(tur: int, tip: String, mesaj: String) -> void:
	var renk := Tema.olay_rengi(tip)
	var yil := Sim.baslangic_yili + tur * Formulas.TUR_YIL
	_olay_gunlugu.append_text("[color=#%s][%.0f] %s[/color] — %s\n" % [
			renk.to_html(false), yil, tip, mesaj])


func _rejim_degisti(kesinti: Dictionary) -> void:
	# Oyunun "düşme" kavramı budur: elindeki rejim el değiştirdi. Koşu BİTMEZ.
	_olay_gunlugu.append_text("[color=#%s][b]— %s (%.0f) —[/b][/color]\n" % [
			Tema.OLAY["DEVRIM"].to_html(false),
			String(kesinti["aciklama"]), float(kesinti["yil"])])
	_politikayi_esitle()


func _kosu_bitti(rapor: Dictionary) -> void:
	_oto = false
	var ekran := Report.new()
	add_child(ekran)
	ekran.goster(rapor)
	ekran.menuye_don.connect(func(): menuye_don.emit())


## Denetimleri motorun fiili durumuyla eşitler. Yalnızca koşu başında ve rejim
## değişince çağrılır -- her turda çağrılsa oyuncunun bıraktığı kaydırıcı
## motorun henüz yerleşmemiş değerine geri sıçrardı.
func _politikayi_esitle() -> void:
	var c := Sim.ulke()
	if c == null:
		return
	_etg_kaydirici.set_value_no_signal(c.etg_hedef)
	_etg_etiket.text = "Temel gelir hedefi: %%%.0f" % (c.etg_hedef * 100.0)
	_fin_kaydirici.set_value_no_signal(c.etg_sermaye_payi)
	_fin_etiket.text = "Finansman: sermayeden %%%.0f" % (c.etg_sermaye_payi * 100.0)
