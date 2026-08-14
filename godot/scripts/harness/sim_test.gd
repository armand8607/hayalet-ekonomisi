class_name SimTest
extends RefCounted

## `Sim` otoload'unun headless duman testi.
##
## Bu katmanda kâhinle karşılaştırılacak bir şey yok -- `Sim` motorda olmayan
## bir kavram, oyun katmanının kendi sözleşmesi. Ölçüt şu: arayüz bu API'ye
## dayandığında yanlış bir şey görmeyecek mi?
##
## Özellikle POLİTİKA GECİKMESİ sınanıyor. Motorda bir politika ilanı 8 tur
## sonra yürürlüğe girer ve yerleşme hızı rejime göre değişir; arayüz bunu
## "düğmeye bastım, sayı değişmedi, demek ki bozuk" diye göstermemeli.

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s" % ad)
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("SIM KATMANI DUMAN TESTI")
	print("=".repeat(66))

	_kosu_kurulumu()
	_politika_gecikmesi()
	_senaryo_odalari()
	_ufuk_ve_rapor()

	print("-".repeat(66))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


static func _kosu_kurulumu() -> void:
	print("\n--- kosu kurulumu ---")
	Sim.kosu_baslat("", 42, "Turkiye")
	_dogrula(Sim.motor != null, "motor kuruldu")
	_dogrula(Sim.tur() == 0, "tur 0'da basliyor", "tur=%d" % Sim.tur())
	_dogrula(Sim.ufuk == 1259, "kampanya ufku 1259", "ufuk=%d" % Sim.ufuk)
	_dogrula(absf(Sim.yil() - 1760.0) < 0.001, "yil 1760", "yil=%.1f" % Sim.yil())
	_dogrula(Sim.ulke_adlari().size() == 20, "20 ulke")

	# Oyuncunun ulkesi politika AI'sinden MUAF olmali; aksi halde oyuncunun
	# her ilani birkac tur sonra AI tarafindan eziliyor.
	var muaf_sayisi := 0
	for c in Sim.motor.D:
		if c.ai_muaf:
			muaf_sayisi += 1
	_dogrula(muaf_sayisi == 1 and Sim.ulke().ai_muaf,
			"yalnizca oyuncunun ulkesi ai_muaf", "muaf=%d" % muaf_sayisi)

	Sim.ilerle(10)
	_dogrula(Sim.tur() == 10, "10 tur ilerledi", "tur=%d" % Sim.tur())
	_dogrula(Sim.ulke().tarih.tur_sayisi() == 10, "tarih 10 kayit tutuyor")
	_dogrula(not is_nan(Sim.metrik("r")), "kar orani okunabiliyor")
	_dogrula(not is_nan(Sim.metrik("e")), "issizlik okunabiliyor")

	# `e` kayitta istihdam; ekranda issizlik gosterilmeli.
	var e_ham := Sim.ulke().tarih.deger("e", 9)
	_dogrula(absf(Sim.metrik("e") - (1.0 - e_ham)) < 1e-12,
			"issizlik cevrilmis olarak donuyor")
	_dogrula(Sim.seri("r").size() == 10, "seri 10 uzunlugunda")


static func _politika_gecikmesi() -> void:
	print("\n--- politika gecikmesi (ILAN, anlik degisiklik degil) ---")
	Sim.kosu_baslat("", 42, "Turkiye")
	var c := Sim.ulke()
	var gecikme: int = Sim.motor.P.pol_gecikme

	Sim.temel_gelir_ilan(0.10)
	var bekleyen := Sim.bekleyen_politikalar()
	_dogrula(bekleyen.size() == 1, "ilan kuyruga girdi", "n=%d" % bekleyen.size())
	_dogrula(int(bekleyen[0]["kalan"]) == gecikme,
			"gecikme %d tur" % gecikme, "kalan=%d" % int(bekleyen[0]["kalan"]))
	_dogrula(absf(c.etg_hedef) < 1e-12, "hedef HENUZ degismedi", "etg_hedef=%f" % c.etg_hedef)

	# KUYRUK TURUN BASINDA BOSALIR, sonunda degil. t=0'da ilan edilen politika
	# etkin_t=8 alir; `politika_kuyrugu_isle` her adimin BASINDA `t >= etkin_t`
	# diye bakar ve `t` adimin SONUNDA artar. Yani k'inci adim t=k-1 ile baslar
	# ve kosul ancak k=9'da saglanir: 8 adim sonra HENUZ degil, 9 adim sonra evet.
	Sim.ilerle(gecikme)
	_dogrula(absf(c.etg_hedef) < 1e-12,
			"%d adim sonra hedef hala degismedi (kuyruk adim basinda bakar)" % gecikme,
			"etg_hedef=%f" % c.etg_hedef)

	Sim.ilerle(1)
	_dogrula(absf(c.etg_hedef - 0.10) < 1e-12,
			"%d. adimda hedef yururlukte" % (gecikme + 1), "etg_hedef=%f" % c.etg_hedef)
	_dogrula(Sim.bekleyen_politikalar().is_empty(), "kuyruk bosaldi")

	# Fiili ETG hedefe YAVAS yakinsar; bir turda ziplamaz.
	var etg_once := c.etg
	Sim.ilerle(20)
	_dogrula(c.etg > etg_once, "fiili ETG yerlesmeye basladi",
			"%f -> %f" % [etg_once, c.etg])
	_dogrula(c.etg < c.etg_hedef, "fiili ETG hedefe henuz varmadi",
			"etg=%f hedef=%f" % [c.etg, c.etg_hedef])


static func _senaryo_odalari() -> void:
	print("\n--- senaryo odalari ---")
	for ad in Sim.SENARYOLAR:
		if ad == "":
			continue
		Sim.kosu_baslat(ad, 42, "Turkiye")
		var meta: Dictionary = Sim.SENARYOLAR[ad]
		var yil_dogru := absf(Sim.yil() - float(meta["yil"])) < 0.001
		# Senaryo yuklemesi gunluge SENARYO satiri birakir.
		var senaryo_olayi := false
		for o in Sim.olaylar(10):
			if o["tip"] == "SENARYO":
				senaryo_olayi = true
		Sim.ilerle(5)
		_dogrula(yil_dogru and senaryo_olayi and Sim.tur() == 5,
				"%s kuruldu (yil %d)" % [ad, int(meta["yil"])],
				"yil=%.0f olay=%s tur=%d" % [Sim.yil(), senaryo_olayi, Sim.tur()])

	# socialist_siege gercekten sosyalist ulke ile basliyor mu?
	Sim.kosu_baslat("socialist_siege", 42, "Turkiye")
	var sos := 0
	for c in Sim.motor.D:
		if c.rejim == "sosyalist":
			sos += 1
	_dogrula(sos == 3, "socialist_siege 3 sosyalist ulkeyle basliyor", "n=%d" % sos)


static func _ufuk_ve_rapor() -> void:
	print("\n--- ufuk ve tarihsel rapor ---")
	# Kisa ufuk: bu oyunda zafer/yenilgi yok, kosu ufuk dolunca biter.
	Sim.kosu_baslat("", 7, "ABD", 30)
	# GDScript lambda'lari DEGERE gore yakalar: `func(r): rapor = r` disaridaki
	# degiskeni degistirmez. Sozluk referans tipi oldugu icin icini doldurmak
	# calisir.
	var kutu := {}
	Sim.kosu_bitti.connect(func(r): kutu["rapor"] = r, CONNECT_ONE_SHOT)

	Sim.ilerle(29)
	_dogrula(not Sim.bitti(), "29. turda kosu surüyor")
	Sim.ilerle(1)
	_dogrula(Sim.bitti(), "30. turda kosu bitti")
	var rapor: Dictionary = kutu.get("rapor", {})
	_dogrula(not rapor.is_empty(), "kosu_bitti sinyali raporla yayildi")
	_dogrula(rapor.get("ulke", "") == "ABD", "rapor oyuncunun ulkesi icin",
			"ulke=%s" % rapor.get("ulke", ""))
	_dogrula(rapor.has("donemler") and rapor.has("olaylar") and rapor.has("kriz_sayilari"),
			"rapor donem/olay/kriz bolumlerini tasiyor")

	# Ufuk dolduktan sonra ilerlememeli.
	var t_son := Sim.tur()
	Sim.ilerle(10)
	_dogrula(Sim.tur() == t_son, "ufuk sonrasi ilerlemiyor", "tur=%d" % Sim.tur())
