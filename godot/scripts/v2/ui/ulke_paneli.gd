class_name UlkePaneli
extends PanelContainer

## Secili ulkenin paneli -- §5.5'in "12 cekirdek metrik grafigi panele
## tasinir, SILINMEZ" cumlesinin karsiligi.
##
## LISTEYI KENDI TUTMAZ: metrikler `Oyun.CEKIRDEK_METRIKLER`den okunur.
## Panelin kendi listesi olsaydi motor tarafinda bir metrik degisince ekran
## sessizce eski adi gostermeye devam ederdi.
##
## Karanlik devletin bedelleri AYNI PANELDE, ayni bicimde gosterilir (§4.6):
## cezaevi orani ve egitim cokusu gizli carpanlar degil, kar orani kadar
## gorunur metriklerdir. Ayri bir "istatistik" ekranina surulseydi temsil
## ilkesi kagitta kalirdi.

const SUTUN := 2

signal kapat_istendi

var _oyun: Oyun = null
var _ulke: int = -1

var _baslik: Label
var _durum: Label
var _izgara: GridContainer
var _grafikler: Array[ZamanGrafigi] = []


func _ready() -> void:
	custom_minimum_size.x = 500
	add_theme_stylebox_override("panel", Tema.panel_stili())
	var kok := VBoxContainer.new()
	kok.add_theme_constant_override("separation", 4)
	add_child(kok)

	var ust := HBoxContainer.new()
	kok.add_child(ust)
	_baslik = Label.new()
	_baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_baslik.add_theme_color_override("font_color", Tema.METIN)
	ust.add_child(_baslik)
	var kapat := Button.new()
	kapat.text = "×"
	kapat.tooltip_text = "Paneli kapat"
	kapat.pressed.connect(func() -> void: kapat_istendi.emit())
	ust.add_child(kapat)

	_durum = Label.new()
	_durum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_durum.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	kok.add_child(_durum)

	var kaydir := ScrollContainer.new()
	kaydir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kok.add_child(kaydir)

	_izgara = GridContainer.new()
	_izgara.columns = SUTUN
	_izgara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_izgara.add_theme_constant_override("h_separation", 4)
	_izgara.add_theme_constant_override("v_separation", 4)
	kaydir.add_child(_izgara)


func kur(oyun: Oyun) -> void:
	_oyun = oyun
	for g in _grafikler:
		g.queue_free()
	_grafikler = []
	for m in _metrikler():
		var g := ZamanGrafigi.new()
		g.kur(m)
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_izgara.add_child(g)
		_grafikler.append(g)


## Cekirdek 12 + karanlik devletin bedelleri + `q`. Sira anlamlidir: oyuncu
## once kendi ekonomisini, sonra odedigi bedeli gorur.
static func _metrikler() -> Array[Dictionary]:
	var c: Array[Dictionary] = []
	c.append_array(Oyun.CEKIRDEK_METRIKLER)
	c.append_array(Oyun.EK_METRIKLER)
	c.append_array(Oyun.KARANLIK_METRIKLER)
	return c


func ulke_sec(i: int) -> void:
	_ulke = i
	yenile()


func yenile() -> void:
	if _oyun == null or _oyun.dunya == null:
		return
	if _ulke < 0 or _ulke >= _oyun.dunya.ulkeler.size():
		# IZGARA GIZLENIR, bosaltilmaz. Bos kutulari cizmek paneli DOLU
		# gosterir ve hicbir sey anlatmaz -- on dokuz "veri yok" karesi
		# olculdu, ekranin yarisini kaplamisti.
		_baslik.text = "Ülke seçilmedi"
		_durum.text = ("Haritadan bir ülke seçin. Çizili 156 ülkenin hepsi "
				+ "simüle edilmez; gri olanların ekonomisi yoktur.")
		_izgara.visible = false
		return
	_izgara.visible = true

	var d := _oyun.dunya.ulkeler[_ulke]
	var oyuncu_mu := _ulke == _oyun.oyuncu
	_baslik.text = "%s%s" % [_oyun.ad(_ulke), "  (siz)" if oyuncu_mu else ""]
	_baslik.add_theme_color_override("font_color",
			Tema.VURGU if oyuncu_mu else Tema.METIN)

	var satir := "%s / %s   ·   çağ %d   ·   kâr oranı %s   ·   işsizlik %s" % [
			d.rejim, d.kurum, d.era,
			HaritaModu.bicimle(d.r_yil, "oran3"),
			HaritaModu.bicimle(d.iss_duzeltilmis(), "yuzde")]
	if d.savasta():
		satir += "\nSAVAŞTA: " + ", ".join(_savas_adlari(d))
	if d.devrim_yil > 0.0:
		satir += "\nDevrim: %d" % int(d.devrim_yil)
	_durum.text = satir

	var isaretler := _isaretler()
	var yillar := _oyun.gecmis.yillar
	for k in range(_grafikler.size()):
		var anahtar := String(_grafikler[k].metrik["anahtar"])
		_grafikler[k].yenile(_oyun.gecmis.seri(anahtar, _ulke), yillar,
				isaretler)


## Grafiklerin arkasina cizilen dikey cizgiler: bu ulkenin kriz tescilleri.
## Egriyi guncenin yanina koymak yerine UZERINE koymak, "hangi kriz hangi
## kirilmaya denk geldi" sorusunu tek bakista cevaplatir.
func _isaretler() -> Array[Dictionary]:
	var c: Array[Dictionary] = []
	for g in _oyun.gunce.girdiler:
		if int(g["ulke"]) != _ulke:
			continue
		var tip := String(g["tip"])
		if tip == "RESESYON" or tip == "ASIRI URETIM":
			continue     # cok sik; grafik taranir
		c.append({"yil": float(g["yil"]), "renk": Gunce.renk(tip)})
	return c


func _savas_adlari(d: KrizDurumu) -> PackedStringArray:
	var c := PackedStringArray()
	for kod in d.savas.keys():
		var i := Harita.indeks(String(kod))
		c.append(String(Harita.kayit()[i]["ad"]) if i >= 0 else String(kod))
	return c
