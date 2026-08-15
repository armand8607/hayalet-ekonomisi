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
			"--v2-olcek":
				# v2 kriz cekirdeginin olcek degismezligi. v4.4'e DOKUNMAZ.
				cikis = OlcekTesti.kos()
			_ when a.begins_with("--v2-iz"):
				# --v2-iz[=YIL[:baslangic_yili]] -- cekirdegin teshis izi.
				var z := a.get_slice("=", 1) if a.contains("=") else ""
				OlcekTesti.iz(
						float(z.get_slice(":", 0)) if z != "" else 100.0,
						OlcekTesti.HAFTA,
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
			"--menu":
				_menuyu_ac()
				_ss_kontrol(argumanlar)
				return
			_ when a.begins_with("--ss="):
				pass   # `--oyna` / `--menu` ile birlikte kullanilir
			_:
				push_warning("Bilinmeyen arguman: " + a)
	get_tree().quit(cikis)


func _oyunu_baslat() -> void:
	_menuyu_ac()


## Menuyu atlayip dogrudan panele girer; `tur` verilirse o kadar ilerletir.
func _dogrudan_oyna(senaryo: String, tohum: int, ulke: String, tur: int) -> void:
	_kosuyu_baslat(senaryo, tohum, ulke)
	if tur > 0:
		Sim.ilerle(tur)


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
