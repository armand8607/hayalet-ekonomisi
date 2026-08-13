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
			"--dump-rng":
				Parity.dump_rng(42)
			"--dump-crc32":
				Parity.dump_crc32()
			"--dump-params":
				Parity.dump_params()
			"--dump-formulas":
				Parity.dump_formulas()
			"--dump-init":
				Parity.dump_init(42)
			_:
				push_warning("Bilinmeyen arguman: " + a)
	get_tree().quit(cikis)


func _oyunu_baslat() -> void:
	# Gosterge paneli bu turun kapsaminda degil; iskele yerinde duruyor.
	print("Hayalet Ekonomisi — motor %s" % Formulas.SURUM)
	print("Gösterge paneli henüz bağlanmadı (GhostEngine portu bekliyor).")
