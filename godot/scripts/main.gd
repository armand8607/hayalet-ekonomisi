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
			_:
				push_warning("Bilinmeyen arguman: " + a)
	get_tree().quit(cikis)


func _oyunu_baslat() -> void:
	# Gosterge paneli bu turun kapsaminda degil; iskele yerinde duruyor.
	print("Hayalet Ekonomisi — motor %s" % Formulas.SURUM)
	print("Gösterge paneli henüz bağlanmadı (GhostEngine portu bekliyor).")
