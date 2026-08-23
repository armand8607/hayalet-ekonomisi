class_name RaporPaneli
extends PanelContainer

## Kampanya bitince acilan TARIHSEL SONUC RAPORU.
##
## ------------------------------------------------------------------------
## SKOR YOK, VE BU BIR TASARIM KARARI
## ------------------------------------------------------------------------
## §9.8: "ZAFER KOSULU YOKTUR. Kosu ufuk dolunca biter ve bir tarihsel sonuc
## raporu uretir. Devrim bir KAYIP DEGIL, oyuncunun elindeki politika setinin
## degismesidir."
##
## Dolayisiyla burada ne puan var, ne "kazandin", ne yildiz derecesi. Olan sey
## sayilir; yorumu okuyana kalir. Bir skor eklenseydi oyunun anlattigi sey
## degisirdi: kriz yonetilmesi gereken bir sinav olurdu, oysa oyun onun
## YAPISAL oldugunu soyluyor.
##
## HARITA USTUNE BINER, ayri bir ekran degildir (§5.5). Oyuncu raporu okurken
## yarattigi dunyayi gormeye devam eder -- sayilarin nereden geldigi
## gorunurlugunu kaybetmesin.

signal kapat_istendi
signal menuye_don

## Guncedeki tip -> raporda gorunecek ad. Tipler `Gunce`nin kendi kumesidir;
## burada yalnizca Turkce karsiligi durur.
const TESCIL_ADI := {
	"RESESYON": "Resesyon",
	"BUYUK BUNALIM": "Bunalım",
	"ASIRI URETIM": "Aşırı üretim krizi",
	"DOVIZ KRIZI": "Döviz krizi",
	"TEMERRUT": "Dış borç temerrüdü",
	"MORATORYUM": "Moratoryum",
	"SAVAS": "Savaşa giriş",
	"YENILGI": "Savaş yenilgisi",
	"DEVRIM": "Devrim",
	"KARSI-DEVRIM": "Karşı-devrim",
	"CAG": "Çağ geçişi",
	"KURUM": "Kurumsal rejim değişimi",
}

var _ic: VBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(560, 460)
	add_theme_stylebox_override("panel", Tema.panel_stili())

	var kok := VBoxContainer.new()
	kok.add_theme_constant_override("separation", 4)
	add_child(kok)

	var ust := HBoxContainer.new()
	kok.add_child(ust)
	var baslik := Label.new()
	baslik.text = "1836 – 2100   ·   tarihsel sonuç"
	baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baslik.add_theme_color_override("font_color", Tema.VURGU)
	ust.add_child(baslik)
	var kapat := Button.new()
	kapat.text = "×"
	kapat.tooltip_text = "Raporu kapat, dünyaya bak"
	kapat.pressed.connect(func() -> void: kapat_istendi.emit())
	ust.add_child(kapat)

	var kaydir := ScrollContainer.new()
	kaydir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kok.add_child(kaydir)
	_ic = VBoxContainer.new()
	_ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ic.add_theme_constant_override("separation", 3)
	kaydir.add_child(_ic)

	var don := Button.new()
	don.text = "Menüye dön"
	don.pressed.connect(func() -> void: menuye_don.emit())
	kok.add_child(don)


func goster(r: Dictionary) -> void:
	for c in _ic.get_children():
		c.queue_free()

	if r.has("ulke"):
		var u: Dictionary = r["ulke"]
		_bolum("%s — %s / %s, çağ %d" % [String(r["ad"]), String(u["rejim"]),
				String(u["kurum"]), int(u["cag"])])

		# LTRPF ZIRVEDEN OLCULUR. Kampanya basi bir gecici rejimdir (§6i);
		# "bastan sona" karsilastirmasi egilimi degil o artefakti olcerdi.
		var zirve := float(u["r_zirve"])
		var son := float(u["r_son"])
		_satir("Kâr oranı — zirve", "%s  (%d)"
				% [HaritaModu.bicimle(zirve, "oran3"), int(u["r_zirve_yil"])])
		_satir("Kâr oranı — 2100", "%s   (zirveden %%%.1f)"
				% [HaritaModu.bicimle(son, "oran3"),
						(son / maxf(zirve, 1e-9) - 1.0) * 100.0])
		_satir("Verimlilik q", HaritaModu.bicimle(float(u["q"]), "oran2"))
		_satir("Organik bileşim c/v", HaritaModu.bicimle(float(u["cv"]), "oran2"))
		_satir("Ücret payı", HaritaModu.bicimle(float(u["pay"]), "yuzde"))
		_satir("İşsizlik", HaritaModu.bicimle(float(u["issizlik"]), "yuzde"))
		_satir("Otomasyon payı", HaritaModu.bicimle(float(u["oto"]), "yuzde"))
		if int(u["devrim_yil"]) > 0:
			_satir("Devrim", str(int(u["devrim_yil"])), Tema.olay_rengi("DEVRIM"))

		# KARANLIK DEVLETIN DEFTERI. §4.6: bedeller GORUNUR metriklerdir.
		# Kol hic kullanilmadiysa bolum de gorunmez -- kullanmamak da bir
		# karardir ve o karar bos bir tabloyla odullendirilmemeli.
		if float(u["bolunme"]) > 0.01 or float(u["cezaevi"]) > 0.001:
			_bolum("Karanlık devletin defteri")
			_satir("Bölünme", HaritaModu.bicimle(float(u["bolunme"]), "oran2"))
			_satir("Cezaevi oranı",
					HaritaModu.bicimle(float(u["cezaevi"]), "yuzde"))
			_satir("Şehit stoku", HaritaModu.bicimle(float(u["sehit"]), "oran2"))
			_satir("Eğitim düzeyi",
					HaritaModu.bicimle(float(u["egitim"]), "oran2"))
			_satir("Örgütlenme", HaritaModu.bicimle(float(u["org"]), "yuzde"))

		_bolum("Bu ülkenin krizleri")
		_tescilleri_yaz(u["tescil"])

	var w: Dictionary = r["dunya"]
	_bolum("Dünya — %d ülke" % int(w["ulke_sayisi"]))
	_satir("Devrim yaşayan ülke", "%d" % int(w["devrim"]),
			Tema.olay_rengi("DEVRIM") if int(w["devrim"]) > 0 else Tema.METIN)
	_satir("2100'de sosyalist", "%d" % int(w["sosyalist"]))
	_satir("Toplam savaş", "%d" % int(w["savas"]))
	_satir("Blok", "%d  (en büyüğü %d ülke)"
			% [int(w["blok"]), int(w["en_buyuk_blok"])])

	_bolum("Dünyadaki bütün kriz tescilleri")
	_tescilleri_yaz(w["tescil"])


func _tescilleri_yaz(sayac: Dictionary) -> void:
	# SIRA SABIT: `TESCIL_ADI`nin sirasi. Sozluk sirasina birakilsaydi rapor
	# her kosuda baska sirada cikardi ve iki kosuyu yan yana okumak zorlasirdi.
	var yazildi := false
	for tip in TESCIL_ADI.keys():
		var n := int(sayac.get(tip, 0))
		if n <= 0:
			continue
		_satir(String(TESCIL_ADI[tip]), "%d" % n, Gunce.renk(String(tip)))
		yazildi = true
	if not yazildi:
		_satir("—", "kayda geçen kriz yok")


func _bolum(metin: String) -> void:
	var l := Label.new()
	l.text = "\n" + metin
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Tema.VURGU)
	_ic.add_child(l)


func _satir(ad: String, deger: String, renk: Color = Tema.METIN) -> void:
	var s := HBoxContainer.new()
	var a := Label.new()
	a.text = ad
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.add_theme_color_override("font_color", Tema.METIN_SOLUK)
	s.add_child(a)
	var b := Label.new()
	b.text = deger
	b.add_theme_color_override("font_color", renk)
	s.add_child(b)
	_ic.add_child(s)
