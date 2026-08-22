extends Node

## Giris noktasi ve arguman kapisi.
##
## `--` sonrasi verilen her sey `OS.get_cmdline_user_args()` ile buraya ulasir.
## Normal bir oyun oturumunda bunlarin HICBIRI atesleyemez; yalnizca
## dogrulama kosulari kullanir:
##
##   Godot.exe --headless --path godot res://scenes/Main.tscn --quit-after 2 -- --self-test
##   Godot.exe --headless --path godot res://scenes/Main.tscn --quit-after 2 -- --dump-rng
##
## TUZAK: `--headless` hicbir sey cizmez, yani `_draw()` KOSMAZ. Gosterge
## panelinin cizimini sinamak icin bayrak dusurulmeli.
##
## TUZAK: `class_name` tasiyan yeni bir script headless kosuda gorunmez;
## Godot global siniflari `.godot/global_script_class_cache.cfg` uzerinden
## cozer ve onu yalnizca editorun taramasi kurar. "Identifier ... not declared"
## hatasi alinirsa bir kez:
##   Godot.exe --headless --path godot --import

func _ready() -> void:
	var argumanlar := OS.get_cmdline_user_args()

	if argumanlar.is_empty():
		_oyunu_baslat()
		return

	var cikis := 0
	for a in argumanlar:
		match a:
			"--self-test":
				cikis = Parity.self_test()
			"--sim-test":
				cikis = SimTest.kos()
			"--v2-tarih":
				# v2 cekirdeginin 1825-2023 tarihsel kayda karsi sinanmasi.
				cikis = TarihTesti.kos()
			"--v2-olcek":
				# v2 kriz cekirdeginin olcek degismezligi. v4.4'e DOKUNMAZ.
				cikis = OlcekTesti.kos()
			"--v2-dunya":
				# Dunya katmani: deger akisi korunuyor mu, ve esitsiz
				# mubadelenin kriz yogunlugundaki imzasi olculebiliyor mu.
				cikis = DunyaTesti.kos()
			"--v2-uretim":
				# Mikro uretim katmani (B2a): toplama ozdesligi ve §2.4'un
				# tuzagi -- bina defterinde karli gorunen yukseltme toplam
				# kar oranini dusuruyor mu.
				cikis = UretimTesti.kos()
			"--v2-mal-tarama":
				# Yigin kisma ve erime kalibrasyonu. Tani kapisi.
				cikis = MalTesti.tarama()
			"--v2-mal":
				# Mal piyasasi (B2c): satilamayan urun bir AKIM mi STOK mu --
				# ve stok asiri uretim krizine SURE kazandiriyor mu.
				cikis = MalTesti.kos()
			"--v2-savas-tarama":
				# Savas SIKLIGININ tarihsel capaya karsi kalibrasyonu.
				# Tani kapisi.
				cikis = SavasTesti.tarama()
			_ when a.begins_with("--v2-savas-siklik="):
				# --v2-savas-siklik=DEGER[:ulke] -- kalibrasyon tek noktasi.
				var sa := a.get_slice("=", 1)
				cikis = BasarimTesti.savas_noktasi(
						float(sa.get_slice(":", 0)),
						int(sa.get_slice(":", 1)) if sa.contains(":") else -1)
			"--v2-b6":
				# B6: tam kadro (~100 ulke) -- olcek altinda korunum, maliyet
				# bicimi ve B4'un savas capasinin yeniden okunmasi.
				cikis = BasarimTesti.kos()
			"--v2-olcek-tarama":
				# B6: tik maliyeti ulke sayisiyla nasil buyuyor. Tani kapisi.
				cikis = BasarimTesti.tarama()
			"--v2-harita-veri":
				# Harita veri katmani tanisi: geometri + izdusum + isabet,
				# dunya kosmadan. Ana kapi kampanya kosar, bu kosmaz.
				cikis = HaritaTesti.veri()
			"--v2-harita":
				# Harita (B5): geometri, izdusum, isabet testi, dokuz mod,
				# baglar -- ve haritanin motora DOKUNMADIGI.
				cikis = HaritaTesti.kos()
			"--v2-oyun":
				# Oyun kabugu (B7): oturum, gecmis, gunce ve oyuncu kollari.
				# En sert kademesi kabugun motoru DEGISTIRMEDIGI.
				cikis = OyunTesti.kos()
			"--v2-aktor-tarama":
				# B7b kalibrasyonu: olcek x tavan. Tani kapisi.
				cikis = OyunTesti.aktor_tarama()
			_ when a.begins_with("--v2-aktor-iz"):
				# --v2-aktor-iz[=YIL[:ulke]] -- politika aktoru ne yapiyor.
				# Tani kapisi; aktorlu ve aktorsuz kollar yan yana.
				var ai := a.get_slice("=", 1) if a.contains("=") else ""
				cikis = OyunTesti.aktor_iz(
						int(ai.get_slice(":", 0)) if ai != "" else 200,
						int(ai.get_slice(":", 1)) if ai.count(":") >= 1 else 12)
			_ when a.begins_with("--v2-oyun-iz"):
				# --v2-oyun-iz[=YIL] -- oyuncunun ana grafiginin kampanya boyu
				# bicimi. Tani kapisi.
				var oi := a.get_slice("=", 1) if a.contains("=") else ""
				cikis = OyunTesti.iz(int(oi) if oi != "" else 230)
			"--v2-savas":
				# Savas bir kriz cikisi olarak (B4): §3.2'nin muhasebesi --
				# savastan sonra kar orani yukari, nufus asagi. Ayrica B3'ten
				# devredilen olcum: karanlik devletin bedeli cok ulkeli
				# dunyada doguyor mu.
				cikis = SavasTesti.kos()
			"--v2-bolunme-tarama":
				# Bolunme kanallarinin siddeti ve karsi hareketin agirligi.
				# Tani kapisi.
				cikis = BolunmeTesti.tarama()
			"--v2-bolunme":
				# Karanlik devlet (B3): riza ve zor aygitlari, `bolunme`, ve
				# karsisindaki sendika/parti. Uc kademe -- katman takili
				# degilken cekirdek zerre degismiyor mu, §7'nin alti yon
				# iddiasi tutuyor mu, ve mekanizma CANLI mi (yonu dogru bir
				# mekanizma yine de olu olabilir).
				cikis = BolunmeTesti.kos()
			"--v2-nufus-tarama":
				# Yedek ordu etkisinin kalibrasyonu. Tani kapisi.
				cikis = NufusTesti.tarama()
			"--v2-nufus":
				# Sinif kohortlari (B2b): nufus korunumu, bilesim kanali ve
				# yedek sanayi ordusu -- ucret payi pazarlanan bir skaler mi,
				# yoksa bilesim x duzey mi.
				cikis = NufusTesti.kos()
			"--v2-uretim-tarama":
				# Yukseltme maliyetinin kalibrasyonu. Tani kapisi.
				cikis = UretimTesti.tarama()
			"--v2-uretim-iz":
				# Mikro kol ile kapali form yan yana -- devrimin neden erkene
				# kaydigini aramak icin. Tani kapisi.
				cikis = UretimTesti.iz()
			"--v2-tarih-mikro":
				# Ayni tarihsel olcut, IKI mikro katman da TAKILI. B2'nin
				# kendi olcutu: toplamlar mikro katmanlardan gelirken tarihsel
				# kayit hala tutuyor mu.
				TarihTesti.mikro_acik = true
				TarihTesti.nufus_acik = true
				cikis = TarihTesti.kos()
				TarihTesti.mikro_acik = false
				TarihTesti.nufus_acik = false
			"--v2-dunya-ayrim":
				# Dis konum gradyanindaki duzluk gercek mi, temerrut
				# sikliginin eseri mi. 36 kampanya; ayri kapi.
				cikis = DunyaTesti.ayrim_taramasi()
			"--v2-dunya-siddet":
				# Transferin agirligi ne kadar olmali ki kural gurultuden
				# ciksin. Tani kapisi; ana testin dort kati surer.
				cikis = DunyaTesti.siddet_taramasi()
			_ when a.begins_with("--v2-iz"):
				# --v2-iz[=YIL[:baslangic[:donem_yil]]] -- cekirdegin teshis izi.
				# donem_yil verilirse o olcekte kosar (olcek ayrismasi avi).
				var z := a.get_slice("=", 1) if a.contains("=") else ""
				OlcekTesti.iz(
						float(z.get_slice(":", 0)) if z != "" else 100.0,
						float(z.get_slice(":", 2)) if z.count(":") >= 2 else OlcekTesti.HAFTA,
						float(z.get_slice(":", 1)) if z.count(":") >= 1 else 1836.0)
			"--dump-rng":
				Parity.dump_rng(42)
			"--dump-crc32":
				Parity.dump_crc32()
			"--dump-params":
				Parity.dump_params()
			"--dump-formulas":
				Parity.dump_formulas()
			"--dump-libm":
				Parity.dump_libm()
			"--dump-agg":
				Parity.dump_agg(42)
			"--dump-init":
				Parity.dump_init(42)
			_ when a.begins_with("--dump-turn="):
				# --dump-turn=TUR[:senaryo]
				var targ := a.get_slice("=", 1)
				Parity.dump_turn(int(targ.get_slice(":", 0)), 42,
						targ.get_slice(":", 1) if targ.contains(":") else "")
			_ when a.begins_with("--dump-scenario="):
				Parity.dump_scenario(a.get_slice("=", 1), 42)
			_ when a.begins_with("--yon-testleri"):
				# --yon-testleri[=N[:bas[:yalnizca]]]
				var y := a.get_slice("=", 1) if a.contains("=") else ""
				cikis = Mekanizma.kos(
						int(y.get_slice(":", 0)) if y != "" else 6,
						int(y.get_slice(":", 1)) if y.count(":") >= 1 else 1,
						y.get_slice(":", 2) if y.count(":") >= 2 else "")
			_ when a.begins_with("--dump-report="):
				# --dump-report=TUR[:senaryo]
				var arg := a.get_slice("=", 1)
				Parity.dump_report(int(arg.get_slice(":", 0)), 42,
						arg.get_slice(":", 1) if arg.contains(":") else "")
			_ when a.begins_with("--kabul="):
				Parity.kabul(int(a.get_slice("=", 1)))
			_ when a.begins_with("--oyna"):
				# --oyna[=senaryo[:tohum[:ulke[:tur]]]] -- menuyu atlar.
				# Cizim testi icin: `--headless` `_draw()` KOSTURMAZ, bu kapi
				# bayraksiz calistirilmalidir.
				var o := a.get_slice("=", 1) if a.contains("=") else ""
				_dogrudan_oyna(
						o.get_slice(":", 0) if o != "" else "",
						int(o.get_slice(":", 1)) if o.count(":") >= 1 else 42,
						o.get_slice(":", 2) if o.count(":") >= 2 else "Turkiye",
						int(o.get_slice(":", 3)) if o.count(":") >= 3 else 0)
				_ss_kontrol(argumanlar)
				return
			_ when a.begins_with("--v2-harita-goster"):
				# --v2-harita-goster[=YIL[:tohum[:mod]]] -- haritayi CIZER.
				# `--ss=` ile birlikte kullanilir; `--headless` cizmez.
				var hg := a.get_slice("=", 1) if a.contains("=") else ""
				_haritayi_goster(
						float(hg.get_slice(":", 0)) if hg != "" else 40.0,
						int(hg.get_slice(":", 1)) if hg.count(":") >= 1 else 42,
						hg.get_slice(":", 2) if hg.count(":") >= 2 else "siyasi")
				_ss_kontrol(argumanlar)
				return
			_ when a.begins_with("--v2-oyna"):
				# --v2-oyna[=KOD[:tohum[:yil[:kadro[:panel]]]]] -- OYUN EKRANI.
				# `panel`: ulke | politika | gunce | yok -- gorsel kapi
				# kapali bir panelin cizimini deneyemez.
				# `kadro` verilirse dunya o kadar ulkeyle kurulur; ekran
				# goruntusu icin tam kadro (113 ulke) gereksiz pahalidir.
				# `--headless` `_draw()` KOSTURMAZ; bu kapi bayraksiz ya da
				# `xvfb-run` altinda kosulmalidir.
				var vo := a.get_slice("=", 1) if a.contains("=") else ""
				_v2_oyna(
						vo.get_slice(":", 0) if vo != "" else "",
						int(vo.get_slice(":", 1)) if vo.count(":") >= 1 else 42,
						int(vo.get_slice(":", 2)) if vo.count(":") >= 2 else 0,
						int(vo.get_slice(":", 3)) if vo.count(":") >= 3 else 0,
						vo.get_slice(":", 4) if vo.count(":") >= 4 else "")
				_ss_kontrol(argumanlar)
				return
			"--v2-menu":
				_v2_menuyu_ac()
				_ss_kontrol(argumanlar)
				return
			"--menu":
				_menuyu_ac()
				_ss_kontrol(argumanlar)
				return
			_ when a.begins_with("--ss="):
				pass   # `--oyna` / `--menu` ile birlikte kullanilir
			_:
				push_warning("Bilinmeyen arguman: " + a)
	get_tree().quit(cikis)


## OYUN ACILDIGINDA v2 GELIR (B7 bitince yapilan devir).
##
## B7a'da varsayilan bilerek v4.4'te birakilmisti: Pages'e ve APK'ya cikan
## surum yarim bir kabuk olmamaliydi. B7 uc parcasiyla kapandi (kabuk, politika
## aktoru, sunum) ve devir artik yapilabilir.
##
## v4.4 KALDIRILMADI, bayraga tasindi: `--menu` eski menuyu, `--oyna` eski
## paneli acar. Dondurulmus motor ve onun oyun katmani hala kosulabilir
## durumda -- `--kabul`, `--yon-testleri` ve `--sim-test` onlara bagli.
func _oyunu_baslat() -> void:
	_v2_menuyu_ac()


## Menuyu atlayip dogrudan panele girer; `tur` verilirse o kadar ilerletir.
func _dogrudan_oyna(senaryo: String, tohum: int, ulke: String, tur: int) -> void:
	_kosuyu_baslat(senaryo, tohum, ulke)
	if tur > 0:
		Sim.ilerle(tur)


## Haritayi kurar, `yil` kadar ilerletir ve cizer. B5'in GORSEL kapisi:
## `--headless` `_draw()` KOSTURMAZ, yani bozuk bir harita butun headless
## kapilardan gecer. Ekrani gormenin tek yolu budur.
func _haritayi_goster(yil: float, tohum: int, mod: String) -> void:
	_ekrani_temizle()
	var hafta := 1.0 / 52.0
	var w := Harita.dunya_kur(PackedStringArray(), tohum, 1836.0)
	for _i in range(Oran.donem_sayisi(yil, hafta)):
		w.adim(hafta)
	var g := HaritaGorunum.new()
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.mod_id = mod
	add_child(g)
	g.kur(w)


## v2'nin kampanya kurulum ekrani (B7).
func _v2_menuyu_ac() -> void:
	_ekrani_temizle()
	var m := OyunMenusu.new()
	m.kosu_istendi.connect(func(kod: String, tohum: int) -> void:
		_v2_oyna(kod, tohum, 0, 0))
	add_child(m)


## v2 oyun ekranini kurar ve istege bagli olarak `yil` kadar ilerletir.
##
## `kur()` add_child'DAN SONRA cagrilir: ekran alt dugumlerini `_ready`de
## kurar, once cagrilsaydi harita ve paneller henuz yok olurdu.
func _v2_oyna(kod: String, tohum: int, yil: int, kadro: int,
		panel: String = "") -> void:
	_ekrani_temizle()
	var o := Oyun.new()
	var kodlar := PackedStringArray()
	if kadro > 0:
		# OYUNCUNUN ULKESI KADROYA ZORLA EKLENIR. `kapi_kodlar` sabit bir alt
		# kumedir ve TUR'u icermiyordu; gorsel kapi sessizce GOZLEMCI kipine
		# dusuyor, butun kollar kapali cikiyordu -- yani panelin asil sinanmak
		# istenen hali hic cizilmiyordu.
		kodlar = Harita.kapi_kodlar(kadro)
		if kod != "" and not kodlar.has(kod):
			kodlar.append(kod)
	o.kur(kod, tohum, kodlar)
	if yil > 0:
		o.ilerle(yil * Oyun.YILDA_TIK)
	var e := OyunEkrani.new()
	e.menuye_don.connect(_v2_menuyu_ac)
	add_child(e)
	e.kur(o)
	if panel != "":
		e.panel_goster(panel)


## Ekran goruntusu alir ve cikar. Paneli GERCEKTEN gormenin tek yolu budur:
## `--headless` hicbir sey cizmez, yani bozuk bir `_draw()` sessizce gecer.
func _ss_kontrol(argumanlar: PackedStringArray) -> void:
	for a in argumanlar:
		if a.begins_with("--ss="):
			_ekran_goruntusu(a.get_slice("=", 1))
			return


func _ekran_goruntusu(yol: String) -> void:
	# Birkac kare beklenir: Container'lar duzeni ERTELENMIS olarak hesaplar,
	# ilk karede cekilen goruntude her sey ust uste biner ya da kutu tam
	# yuksekligine daha ulasmamis olur.
	for _i in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var hata := img.save_png(yol)
	if hata != OK:
		push_error("Ekran goruntusu yazilamadi: %s (%d)" % [yol, hata])
	else:
		print("ekran goruntusu: %s" % yol)
	get_tree().quit(0)


func _menuyu_ac() -> void:
	_ekrani_temizle()
	var menu := Menu.new()
	menu.kosu_istendi.connect(_kosuyu_baslat)
	add_child(menu)


func _kosuyu_baslat(senaryo: String, tohum: int, ulke: String) -> void:
	Sim.kosu_baslat(senaryo, tohum, ulke)
	_ekrani_temizle()
	var panel := Dashboard.new()
	panel.menuye_don.connect(_menuyu_ac)
	add_child(panel)


func _ekrani_temizle() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
