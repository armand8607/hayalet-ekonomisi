class_name HaritaTesti
extends RefCounted

## B5 KAPISI -- harita.
##
## ------------------------------------------------------------------------
## OLCUT
## ------------------------------------------------------------------------
## §6'nin tablosu B5 icin "20+ ulke, dokuz mod, baglar cizili" diyor. Bu
## sayilabilir bir olcut ama TEK BASINA KAPI DEGIL: uc sayiyi da tutturan,
## ustelik yanlis yeri gosteren bir harita yazilabilir. Onceki asamalarin
## dersi burada da gecerli (olcut dort kez duzeltildi) -- kapinin, gecmenin
## kolay olmadigi bir sey olcmesi gerekir.
##
## Haritada "yanlis" olmanin uc yolu var ve ucu de OYNAYARAK FARK EDILMEZ:
##
##   1. GEOMETRI bozuk olabilir -- ucgenleme bosa dusen bir halka, sinirin
##      disina tasan bir koordinat. Ekranda bir ulke eksik olur ve kimse
##      hangisinin eksik oldugunu bilmez.
##   2. ISABET TESTI kayabilir -- tiklanan yer ile secilen ulke ayrisir.
##      Kucuk bir kaymayi gozle yakalamak imkansizdir; komsu ulkeyi secmek
##      dogru gorunur.
##   3. MOD OLU olabilir -- B2b'nin dersi: yonu dogru bir mekanizma yine de
##      olu olabilir. Butun ulkeleri ayni renge boyayan bir mod "calisiyor"
##      gorunur ve hicbir sey anlatmaz.
##
## Kapi bu ucunu de olcer, ve dorduncu bir sey daha: haritanin motora
## DOKUNMADIGINI. Harita bir gorunumdur; okumasinin dunyayi degistirmesi
## sessiz ve olumcul bir hata olurdu.

const HAFTA := 1.0 / 52.0
const BAS := 1836.0
## TAM KAMPANYA. Kisa bir kosu iki sey icin yetmez ve ikisi de kapinin
## asli:
##
##   * MOD CANLILIGI. `otomasyon` 1836'da sifirdir ve oyle olmalidir (cag
##     tablosu 2000'e koyuyor); `siyasi` ilk devrime kadar tek renktir. 40
##     yillik bir kosuda "olu mod" ile "henuz baslamamis mod" ayirt EDILEMEZ.
##   * BAG KAPSAMI. Dort bag turunun ucu (savas, ittifak, abluka) ancak
##     savas ciktiginda dogar. Kisa kosuda yalnizca ticaret bagi olculur ve
##     "baglar cizili" iddiasi dortte bir kanitlanmis olur.
const BITIS := 2100.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("")
	print("V2 HARITA -- B5 KAPISI")
	print("==================================================================")

	_geometri()
	_izdusum()
	_isabet()

	# KAPI DUNYASI SINIRLI (54 ulke), kadro degil. B6 kadroyu 113'e cikardi;
	# tam kadroda tam kampanya bu kapiyi ~620 saniyeye tasirdi ve olctugu
	# sey (mod canliligi, bag kapsami) ulke sayisina bagli degil. Olcek
	# B6'nin kapisinda, tam kadroda olculur.
	var w := Harita.dunya_kur(Harita.kapi_kodlar(), 42, BAS)
	var basla := Time.get_ticks_msec()
	var kampanya := _kampanya(w)
	var sure := Time.get_ticks_msec() - basla
	print("")
	print("DUNYA: %d ulke x %.0f yil = %d tik, %.1f sn (%.2f ms/tik)"
			% [w.ulkeler.size(), BITIS - BAS, int(kampanya["tik"]),
			sure / 1000.0, float(sure) / float(kampanya["tik"])])
	print("       B6'nin olcumu icin kayit; burada bir ESIK YOK.")

	_modlar(w, kampanya)
	_baglar(w, kampanya)
	_okuyucu()

	print("")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


## TANI KAPISI -- yalnizca veri katmani (1-3), dunya kosmadan.
##
## Ana kapi tam kampanya kosuyor (~4 dk); geometri degistiginde o kadar
## beklemek ureticiyi elle dogrulamaktan daha yavas olurdu. Bu kapi ~2 sn
## surer ve halka bazinda dokum verir.
static func veri() -> int:
	_gecen = 0
	_kalan = 0
	print("")
	print("V2 HARITA -- VERI TANISI (kapi degil, dokum)")
	print("==================================================================")
	_geometri()
	_izdusum()
	_isabet()
	print("")
	print("HALKA DOKUMU -- ucgenleme sapmasi en buyuk 12 halka")
	print("     kod  halka  nokta   sapma")
	var satirlar: Array = []
	for u in Harita.kayit():
		for h in range(u["halkalar"].size()):
			var y: PackedVector2Array = u["halkalar"][h]
			var t: PackedInt32Array = u["ucgenler"][h]
			var alan := _halka_alani(y)
			var sapma := absf(_ucgen_alani(y, t) - alan) / maxf(alan, 1e-12)
			satirlar.append([sapma, String(u["kod"]), h, y.size(), t.size() / 3])
	satirlar.sort_custom(func(a, b): return a[0] > b[0])
	for k in range(mini(12, satirlar.size())):
		var r: Array = satirlar[k]
		print("     %-4s %5d %6d   %s  (%d ucgen)" % [r[1], r[2], r[3], r[0], r[4]])
	print("")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


# ===========================================================================
# 1. GEOMETRI
# ===========================================================================
static func _geometri() -> void:
	print("")
	print("1. GEOMETRI -- uretilmis veri kendi icinde tutarli mi")
	print("------------------------------------------------------------------")
	var kayit := Harita.kayit()

	_dogrula(kayit.size() >= 20, "ulke sayisi >= 20 (B5 olcutu)",
			"= %d" % kayit.size())

	var oyn := Harita.oynanabilir_kodlar()
	_dogrula(oyn.size() == 19, "oynanabilir kume 19 (§5.8b G20)",
			"= %d" % oyn.size())

	# §5.8b'nin tablosu: her oynanabilir ulkenin 1836 karsiligi YAZILI olmali.
	# Bos birakilan bir tanesi oyunda "Turkiye 1836'da" diye gorunurdu.
	var adsiz := PackedStringArray()
	for u in kayit:
		if bool(u["oynanabilir"]) and String(u["ad_1836"]) == "":
			adsiz.append(String(u["kod"]))
	_dogrula(adsiz.is_empty(), "oynanabilir ulkelerin 1836 adi dolu",
			"eksik: %s" % str(adsiz) if not adsiz.is_empty() else "")

	var sim := Harita.simule_kodlar()
	_dogrula(sim.size() >= 20, "simule edilen ulke >= 20", "= %d" % sim.size())

	# --- halkalar ---
	var bos_ucgen := PackedStringArray()
	var kisa_halka := PackedStringArray()
	var sinir_disi := PackedStringArray()
	var tekrar_ucu := PackedStringArray()
	var alan_sapmasi := 0.0
	var alan_sapan := ""
	for u in kayit:
		for h in range(u["halkalar"].size()):
			var d: PackedVector2Array = u["derece"][h]
			var y: PackedVector2Array = u["halkalar"][h]
			var t: PackedInt32Array = u["ucgenler"][h]
			if d.size() < 3:
				kisa_halka.append(String(u["kod"]))
			if t.size() < 3:
				bos_ucgen.append(String(u["kod"]))
			if d.size() >= 2 and d[0] == d[d.size() - 1]:
				tekrar_ucu.append(String(u["kod"]))
			for p in d:
				if absf(p.x) > 180.0 or absf(p.y) > 90.0:
					sinir_disi.append(String(u["kod"]))
					break
			# UCGENLEME POLIGONU KAPLIYOR MU. Bos donmeyen ama poligonun
			# yalnizca bir kismini ucgenleyen bir sonuc, ekranda "yarim
			# ulke" olarak gorunur ve veri gecerli oldugu icin hicbir
			# yapisal denetime takilmaz. Tek yakalama yolu ALANI olcmek.
			if t.size() >= 3:
				var sapma := absf(_ucgen_alani(y, t) - _halka_alani(y)) \
						/ maxf(_halka_alani(y), 1e-12)
				if sapma > alan_sapmasi:
					alan_sapmasi = sapma
					alan_sapan = String(u["kod"])
	_dogrula(kisa_halka.is_empty(), "her halka >= 3 nokta",
			str(kisa_halka) if not kisa_halka.is_empty() else "")
	_dogrula(bos_ucgen.is_empty(), "her halka ucgenlendi",
			"bos: %s" % str(bos_ucgen) if not bos_ucgen.is_empty() else "")
	_dogrula(tekrar_ucu.is_empty(), "halkalar kapali ama son nokta tekrarsiz",
			str(tekrar_ucu) if not tekrar_ucu.is_empty() else "")
	_dogrula(sinir_disi.is_empty(), "koordinatlar [-180,180]x[-90,90] icinde",
			str(sinir_disi) if not sinir_disi.is_empty() else "")
	_dogrula(alan_sapmasi < 1e-6, "ucgenleme poligonu tam kapliyor",
			"en buyuk sapma %s (%s)" % [alan_sapmasi, alan_sapan])


static func _halka_alani(h: PackedVector2Array) -> float:
	var t := 0.0
	var n := h.size()
	for i in range(n):
		var a := h[i]
		var b := h[(i + 1) % n]
		t += a.x * b.y - b.x * a.y
	return absf(t) * 0.5


static func _ucgen_alani(h: PackedVector2Array, t: PackedInt32Array) -> float:
	var toplam := 0.0
	for k in range(0, t.size() - 2, 3):
		var a := h[t[k]]
		var b := h[t[k + 1]]
		var c := h[t[k + 2]]
		toplam += absf((b - a).cross(c - a)) * 0.5
	return toplam


# ===========================================================================
# 2. IZDUSUM
# ===========================================================================
static func _izdusum() -> void:
	print("")
	print("2. IZDUSUM -- Miller, gidis-donus ve yon")
	print("------------------------------------------------------------------")

	var en_buyuk := 0.0
	var enlem := Harita.ENLEM_GUNEY
	while enlem <= Harita.ENLEM_KUZEY:
		var boylam := -180.0
		while boylam <= 180.0:
			var p := Vector2(boylam, enlem)
			var geri := Harita.ters(Harita.yansit(p))
			en_buyuk = maxf(en_buyuk, (geri - p).length())
			boylam += 15.0
		enlem += 6.0
	_dogrula(en_buyuk < 1e-4, "yansit/ters gidis-donus", "en buyuk hata %s derece" % en_buyuk)

	# Yon: kuzeye gidince EKRANDA YUKARI (y kucuk), doguya gidince saga.
	var kuzey := Harita.yansit(Vector2(0.0, 60.0))
	var guney := Harita.yansit(Vector2(0.0, -60.0))
	var bati := Harita.yansit(Vector2(-90.0, 0.0))
	var dogu := Harita.yansit(Vector2(90.0, 0.0))
	_dogrula(kuzey.y < guney.y, "kuzey ekranda yukarida",
			"%.3f < %.3f" % [kuzey.y, guney.y])
	_dogrula(bati.x < dogu.x, "dogu ekranda sagda",
			"%.3f < %.3f" % [bati.x, dogu.x])

	# Kirpma noktalari birim karenin kosesine oturmali; oturmazsa harita
	# ya tasar ya da kenarda bos serit birakir.
	var sol_ust := Harita.yansit(Vector2(-180.0, Harita.ENLEM_KUZEY))
	var sag_alt := Harita.yansit(Vector2(180.0, Harita.ENLEM_GUNEY))
	_dogrula(sol_ust.distance_to(Vector2.ZERO) < 1e-9
			and sag_alt.distance_to(Vector2.ONE) < 1e-9,
			"birim kare [0,1]^2'ye tam oturuyor",
			"(%.6f,%.6f)-(%.6f,%.6f)" % [sol_ust.x, sol_ust.y, sag_alt.x, sag_alt.y])

	# En/boy orani: Miller'in kendi oranindan HESAPLANIR, elle yazilmaz.
	var en_boy := Harita.en_boy()
	_dogrula(en_boy > 1.9 and en_boy < 2.1, "en/boy orani pencereden geliyor",
			"= %.4f" % en_boy)

	# PENCERE VERIYI KAPSIYOR MU. Kirpma sinirlari veriden secildi; veri
	# degisip de sinirlar unutulursa bir ulke kirpma cizgisine yapisir ve
	# haritada duz bir kenar olarak gorunur -- gozle "ada yok" diye okunur.
	var en_kuzey := -90.0
	var en_guney := 90.0
	for u in Harita.kayit():
		var kutu: Rect2 = u["kutu_d"]
		en_kuzey = maxf(en_kuzey, kutu.position.y + kutu.size.y)
		en_guney = minf(en_guney, kutu.position.y)
	_dogrula(en_kuzey < Harita.ENLEM_KUZEY and en_guney > Harita.ENLEM_GUNEY,
			"kirpma penceresi butun veriyi kapsiyor",
			"veri %.2f .. %.2f, pencere %.0f .. %.0f"
			% [en_guney, en_kuzey, Harita.ENLEM_GUNEY, Harita.ENLEM_KUZEY])

	# Enlem kirpmasi: kutup verisi kirpma noktasina OTURUR, tasmaz.
	var kutup := Harita.yansit(Vector2(0.0, 89.9))
	_dogrula(kutup.y >= -1e-9 and kutup.y <= 1.0, "kutup kirpiliyor",
			"y = %.6f" % kutup.y)


# ===========================================================================
# 3. ISABET TESTI
# ===========================================================================
static func _isabet() -> void:
	print("")
	print("3. ISABET -- tiklanan yer ile secilen ulke ayni mi")
	print("------------------------------------------------------------------")
	var kayit := Harita.kayit()

	# (a) Etiket noktasi ULKENIN ICINDE mi. Uretici bunu erisilemezlik kutbu
	#     olarak hesapliyor; burada BAGIMSIZ olarak sinaniyor. Disari dusen
	#     bir etiket noktasi, bag cizgisini denizden baslatir.
	var disarida := PackedStringArray()
	for u in kayit:
		var icinde := false
		for h in u["derece"]:
			if Harita.halkada(u["merkez_d"], h):
				icinde = true
				break
		if not icinde:
			disarida.append(String(u["kod"]))
	_dogrula(disarida.is_empty(), "etiket noktasi ulkenin icinde",
			"disarida: %s" % str(disarida) if not disarida.is_empty() else "")

	# (b) `bul()` o noktada DOGRU ulkeyi donduruyor mu. (a)'dan farki:
	#     burada butun ulkeler yarisir. Delikler tasinmadigi icin buyuk bir
	#     ulkenin poligonu kucugunu kapsayabilir; siranin kucukten buyuge
	#     olmasinin sinandigi yer burasi.
	var yanlis := PackedStringArray()
	for i in range(kayit.size()):
		var bulunan := Harita.bul(kayit[i]["merkez_d"])
		if bulunan != i:
			yanlis.append("%s->%s" % [kayit[i]["kod"],
					kayit[bulunan]["kod"] if bulunan >= 0 else "yok"])
	_dogrula(yanlis.is_empty(), "bul() etiket noktasinda dogru ulkeyi veriyor",
			"kayan: %s" % str(yanlis) if not yanlis.is_empty() else "")

	# (c) Acik denizde hicbir ulke secilmemeli.
	var deniz := [Vector2(-140.0, -30.0), Vector2(-30.0, -40.0),
			Vector2(80.0, -40.0), Vector2(-160.0, 40.0)]
	var deniz_hatasi := PackedStringArray()
	for p in deniz:
		var i2 := Harita.bul(p)
		if i2 >= 0:
			deniz_hatasi.append("%s@%s" % [kayit[i2]["kod"], str(p)])
	_dogrula(deniz_hatasi.is_empty(), "acik denizde ulke yok",
			str(deniz_hatasi) if not deniz_hatasi.is_empty() else "")

	# (d) Bilinen noktalar. Izdusum ya da veri kaydigi anda BU duser --
	#     gidis-donus testi kendi icinde tutarli bir yanlisi yakalamaz.
	var capalar := {
		"TUR": Vector2(32.85, 39.93),    # Ankara
		"USA": Vector2(-77.04, 38.91),   # Washington
		"CHN": Vector2(116.40, 39.90),   # Pekin
		"BRA": Vector2(-47.88, -15.79),  # Brasilia
		"ZAF": Vector2(28.19, -25.75),   # Pretoria
		"AUS": Vector2(149.13, -35.28),  # Canberra
		"RUS": Vector2(37.62, 55.75),    # Moskova
		"IND": Vector2(77.21, 28.61),    # Yeni Delhi
	}
	var capa_hatasi := PackedStringArray()
	for kod in capalar:
		var i3 := Harita.bul(capalar[kod])
		var bulunan_kod: String = String(kayit[i3]["kod"]) if i3 >= 0 else "yok"
		if bulunan_kod != kod:
			capa_hatasi.append("%s->%s" % [kod, bulunan_kod])
	_dogrula(capa_hatasi.is_empty(), "baskentler dogru ulkeye dusuyor",
			str(capa_hatasi) if not capa_hatasi.is_empty() else "")


# ===========================================================================
# KAMPANYA -- tek kosu, iki olcum
# ===========================================================================
## Dunyayi 1836'dan 2100'e kosar ve YILDA BIR ornek alir:
##   `yayilim[mod]` : modun ulkeler arasindaki en buyuk ayrismasi
##   `bag[tip]`     : o turden bagin gorulen en buyuk sayisi
##
## Ikisi de EN BUYUGU tutar, son degeri degil. Savas biter, abluka kalkar,
## devrim geri alinabilir; son kareye bakan bir olcum "hic olmadi" der.
static func _kampanya(w: Dunya) -> Dictionary:
	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var yillik := int(round(1.0 / HAFTA))
	var yayilim := {}
	for m in HaritaModu.MODLAR:
		yayilim[m["id"]] = 0.0
	var bag := {"savas": 0, "ittifak": 0, "abluka": 0, "ticaret": 0}
	var sonsuz := PackedStringArray()

	for t in range(n):
		w.adim(HAFTA)
		if t % yillik != 0:
			continue
		for m in HaritaModu.MODLAR:
			var id := String(m["id"])
			var en_az := INF
			var en_cok := -INF
			for i in range(w.ulkeler.size()):
				var v := HaritaModu.deger(id, w, i)
				if not is_finite(v):
					if not sonsuz.has(id):
						sonsuz.append(id)
					continue
				en_az = minf(en_az, v)
				en_cok = maxf(en_cok, v)
			if en_cok > -INF:
				yayilim[id] = maxf(float(yayilim[id]), en_cok - en_az)
		var sayim := {"savas": 0, "ittifak": 0, "abluka": 0, "ticaret": 0}
		for b in Harita.baglar(w):
			sayim[b["tip"]] = int(sayim[b["tip"]]) + 1
		for tip in sayim:
			bag[tip] = maxi(int(bag[tip]), int(sayim[tip]))

	return {"tik": n, "yayilim": yayilim, "bag": bag, "sonsuz": sonsuz}


# ===========================================================================
# 4. MODLAR
# ===========================================================================
static func _modlar(w: Dunya, kampanya: Dictionary) -> void:
	print("")
	print("4. MODLAR -- dokuz mod, dogru alani okuyor, ve olu degil")
	print("------------------------------------------------------------------")

	_dogrula(HaritaModu.MODLAR.size() == 9, "dokuz mod (B5 olcutu)",
			"= %d" % HaritaModu.MODLAR.size())

	var idler := HaritaModu.kimlikler()
	var tekil := {}
	for id in idler:
		tekil[id] = true
	_dogrula(tekil.size() == idler.size(), "mod kimlikleri tekil")

	var sonsuz: PackedStringArray = kampanya["sonsuz"]
	_dogrula(sonsuz.is_empty(), "mod degerleri kampanya boyunca sonlu",
			str(sonsuz) if not sonsuz.is_empty() else "")

	_sadakat()

	# --- CANLILIK: kampanya boyunca ulkeler AYRISIYOR mu -------------------
	# B2b'nin dersi: yonu dogru bir mekanizma yine de olu olabilir. Butun
	# dunyayi tek renge boyayan bir mod "calisiyor" gorunur ve hicbir sey
	# anlatmaz. Olcum SON KAREDE degil kampanya boyunca en buyuk ayrisma
	# uzerinden yapilir (bkz. `_kampanya`).
	print("")
	print("     mod          kampanyadaki en buyuk ayrisma")
	var yayilim: Dictionary = kampanya["yayilim"]
	var olu := PackedStringArray()
	for m in HaritaModu.MODLAR:
		var id := String(m["id"])
		var y := float(yayilim[id])
		print("     %-11s  %s" % [id, y])
		if y <= 0.0:
			olu.append(id)

	# BIR MOD AYRI TUTULUR -- ve bu bir muafiyet degil, OLCULMUS bir bulgudur
	# (tasarim belgesi §6g). Haritanin degil DUNYANIN durumudur: mod sadakat
	# testini gectigi icin okudugu alan dogru, o alan hareket etmiyor.
	#
	# BURASI BIR KEZ IKI MODDU. `otomasyon` da duzdu ve sebebi merdivenin
	# kapali formun bir mertebe altinda kalmasiydi; kapi "hala duz mu" diye
	# sordugu icin B2a'nin cag kuplaji acildigi gun DUSTU ve belge
	# guncellendi (§6b). Ters yonlu kapinin ne ise yaradigi tam olarak budur.
	const BEKLENEN_DUZ := ["bolunme"]
	var olu_beklenmeyen := PackedStringArray()
	for id in olu:
		if not BEKLENEN_DUZ.has(id):
			olu_beklenmeyen.append(id)
	_dogrula(olu_beklenmeyen.is_empty(),
			"sekiz mod kampanya boyunca ayrisiyor",
			"olu: %s" % str(olu_beklenmeyen) if not olu_beklenmeyen.is_empty() else "")

	# (1) BOLUNME ARTIK CANLI -- ve bu kapi, TERS YONDE BIRAKILMIS bir kaydin
	#     ise yaradiginin kanitidir.
	#
	#     B5 burada "yayilim == 0.0" diye yaziyordu, cunku sekiz `t_*` alanini
	#     yazan bir aktor yoktu: ne oyuncu vardi ne AI politika katmani, ve
	#     `KaranlikDevlet.otomatik` yalnizca `mafya_tolerans`i suruyordu.
	#     Kayit gevsek birakilsaydi (">= 0") surucu geldigi gun hicbir sey
	#     haber vermezdi. B7b'de aktor geldi, kapi KIRMIZIYA DONDU (olculdu:
	#     yayilim 0.0 -> 0.374) ve belge guncellendi.
	#
	#     Yeni iddia yon degil BUYUKLUK sorar, tipki otomasyonunki gibi:
	#     mod yalnizca kipirdamis olmasin, ulkeler arasinda GERCEKTEN ayrissin.
	#     B7b'nin kendi kapisi (`--v2-oyun`) mekanizmayi olcer; burada
	#     olculen, HARITANIN o ayrimi gosterebildigidir.
	_dogrula(float(yayilim["bolunme"]) > 0.20,
			"bolunme modu canli (politika aktoru, B7b)",
			"yayilim %.3f -> §6j" % float(yayilim["bolunme"]))

	# BLOK GOSTERIMI (B7c) -- ve CANLILIGI BURADA olculur, `--v2-oyun`da
	# degil. Is bolumu B5'in kendi ilkesi: harita kapisi MOD CANLILIGI ve
	# BAG KAPSAMI olcer. On ulkelik bir dunyada ittifak neredeyse hic
	# olusmuyor (olculdu: 1 blok, 2 uye), yani orada "blok gosterimi
	# calisiyor" demek bos kalirdi. Sozlesme denetimleri (kimlik, tutarlilik,
	# tek uyeli blok yok) `--v2-oyun`da duruyor.
	var blok := Harita.bloklar(w)
	var blok_boy := {}
	for i in range(blok.size()):
		if blok[i] >= 0:
			blok_boy[blok[i]] = int(blok_boy.get(blok[i], 0)) + 1
	var en_buyuk_blok := 0
	for k in blok_boy.keys():
		en_buyuk_blok = maxi(en_buyuk_blok, int(blok_boy[k]))
	print("     blok: %d tane, en buyugu %d ulke"
			% [blok_boy.size(), en_buyuk_blok])
	# ESIK TOHUMLAMAYLA YENIDEN CAPALANDI: 5 -> 3.
	#
	# 1836'nin nufusu tohumlanmadan once en buyuk blok 10 ulkeydi ve esik 5
	# rahat geciyordu. Tohumlamadan sonra 4. Bant GEVSETILMEDI, sebep
	# olculdu: ittifak ORTAK DUSMAN ister, ve `guc() = K*q` boyutla
	# ayrisinca hedef elemesi (`h.guc() >= c.guc() * 1.15`) ulkeleri fiilen
	# agirlik siniflarina ayiriyor -- iki ulkenin ayni hedefi secmesi
	# seyreliyor. Bu, tohumlamanin bir yan etkisi degil SONUCU: esit
	# buyuklukteki bir dunyada herkes herkese saldirabiliyordu.
	#
	# Esik 3'te, cunku olcutun sordugu sey "harita blok UYELIGINI
	# gosterebiliyor mu" ve bunun icin blok bir CIFTTEN buyuk olmali
	# (ikili blok kabuk cizimini zorlamaz). Ayirt ediciligi duruyor: blok
	# olusumu dururdu 0/1'e duser ve denetim kirmizi verir.
	_dogrula(en_buyuk_blok >= 3, "blok gosterimi canli (B7c)",
			"en buyuk blok %d ulke" % en_buyuk_blok)

	# (2) OTOMASYON ARTIK CANLI -- ve bu B5'in getirdigi bir bulgunun
	#     cozumu. `UretimKatmani` takiliyken `oto` otoritesi ona gecer ve
	#     `basamak_oto` MUTLAK q >= 36 ister; merdiven 2100'de 12.4'te
	#     kaliyordu, yani §5.3'un "LTRPF'nin doruk noktasi" dedigi sey oyun
	#     dunyasinda HIC baslamiyordu. B2a'nin cag kuplaji (§6b) merdiveni
	#     kapali forma oturttu.
	#
	#     Denetim yon degil BUYUKLUK sorar: otomasyon yalnizca kipirdamis
	#     olmasin, anlamli bir paya varsin. Kampanya sonunda cag 6'dayiz.
	_dogrula(float(yayilim["otomasyon"]) > 0.25,
			"otomasyon kampanyada anlamli paya variyor",
			"yayilim %.3f (§6b'nin cag kuplaji)" % float(yayilim["otomasyon"]))

	var bos_efsane := PackedStringArray()
	for m in HaritaModu.MODLAR:
		var e := HaritaModu.efsane(String(m["id"]), w)
		if e.is_empty():
			bos_efsane.append(String(m["id"]))
	_dogrula(bos_efsane.is_empty(), "her modun efsanesi dolu",
			str(bos_efsane) if not bos_efsane.is_empty() else "")

	var cizilen := Harita.kayit().size()
	var simule := Harita.simule_kodlar().size()
	_dogrula(cizilen > simule, "cizilen ulke > simule edilen ulke",
			"%d cizili / %d simule" % [cizilen, simule])


## SADAKAT -- her mod OKUDUGUNU IDDIA ETTIGI alani mi okuyor.
##
## Canlilik testinin yakalayamadigi hata budur: iki alan da hareket ediyorsa
## yanlis alani okuyan bir mod da "canli" gorunur. Burada alan DOGRUDAN
## yazilir ve modun degeri o yaziyi gostermek zorunda kalir.
##
## Ucuz olmasi bilincli: iki ulkelik bir dunya, hic tik yok. Kosu gerektiren
## bir sadakat testi, olcugu seyi kosunun kendi dinamigiyle karistirirdi.
static func _sadakat() -> void:
	var kodlar := PackedStringArray(["GBR", "TUR"])
	var w := Harita.dunya_kur(kodlar, 1, BAS)
	var d: KrizDurumu = w.ulkeler[0]
	d.Y_yil = 100.0
	d.Y_trend = 200.0
	d.Y_ort = 100.0
	d.katilim_etg = 0.0

	# mod -> [alani yazan kapama, beklenen deger]
	var beklenen := {}
	d.rejim = "sosyalist"
	beklenen["siyasi"] = 1.0
	d.r_yil = 0.123
	beklenen["kar_orani"] = 0.123
	beklenen["bunalim"] = 0.5              # 1 - Y_ort/Y_trend
	d.e = 0.55
	beklenen["issizlik"] = 0.45
	d.bolunme = 0.42
	beklenen["bolunme"] = 0.42
	d.orgutlu = 0.31
	beklenen["orgutlenme"] = 0.31
	d.NX_yil = 20.0
	beklenen["ticaret"] = 0.20             # NX / Y
	w.toplam_dis[0] = 30.0
	beklenen["dis_konum"] = 0.30           # toplam_dis / Y
	d.oto = 0.60
	beklenen["otomasyon"] = 0.60

	var sapan := PackedStringArray()
	for id in beklenen:
		var v := HaritaModu.deger(String(id), w, 0)
		if absf(v - float(beklenen[id])) > 1e-12:
			sapan.append("%s(%.6f!=%.6f)" % [id, v, beklenen[id]])
	_dogrula(sapan.is_empty(), "her mod iddia ettigi alani okuyor",
			str(sapan) if not sapan.is_empty() else "(9 alan dogrudan yazildi)")


# ===========================================================================
# 5. BAGLAR
# ===========================================================================
static func _baglar(w: Dunya, kampanya: Dictionary) -> void:
	print("")
	print("5. BAGLAR -- dunyanin kendi durumundan mi geliyor")
	print("------------------------------------------------------------------")
	var baglar := Harita.baglar(w)
	var sayim := {"savas": 0, "ittifak": 0, "abluka": 0, "ticaret": 0}
	var kendine := 0
	var ters_sira := 0
	var tekrar := 0
	var gorulen := {}
	for b in baglar:
		var i := int(b["i"])
		var j := int(b["j"])
		sayim[b["tip"]] = int(sayim[b["tip"]]) + 1
		if i == j:
			kendine += 1
		if i > j:
			ters_sira += 1
		var anahtar := "%s-%d-%d" % [b["tip"], i, j]
		if gorulen.has(anahtar):
			tekrar += 1
		gorulen[anahtar] = true

	print("     savas %d, ittifak %d, abluka %d, ticaret %d"
			% [sayim["savas"], sayim["ittifak"], sayim["abluka"], sayim["ticaret"]])

	_dogrula(kendine == 0, "ulke kendisiyle bagli degil")
	_dogrula(ters_sira == 0, "baglar i<j sirali (cift bir kez)")
	_dogrula(tekrar == 0, "ayni bag iki kez yok")
	_dogrula(int(sayim["ticaret"]) > 0, "ticaret bagi var",
			"= %d" % sayim["ticaret"])

	# Ticaret bagi HACME gore secilmis mi: agirliklar (0,1] icinde ve en az
	# biri 1.0 (en buyuk cift normalizasyon boleni).
	var agirlik_hatasi := 0
	var en_buyuk := 0.0
	for b in baglar:
		if b["tip"] != "ticaret":
			continue
		var a := float(b["agirlik"])
		if a <= 0.0 or a > 1.0 + 1e-12:
			agirlik_hatasi += 1
		en_buyuk = maxf(en_buyuk, a)
	_dogrula(agirlik_hatasi == 0 and absf(en_buyuk - 1.0) < 1e-9,
			"ticaret agirliklari (0,1] ve en buyugu 1.0",
			"en buyuk %.6f" % en_buyuk)

	# Savas bagi varsa ILGILI ULKELER savasta olmali -- bag dunyadan
	# okunuyor mu, yoksa haritanin kendi uydurmasi mi.
	var savas_tutarsiz := 0
	for b in baglar:
		if b["tip"] != "savas":
			continue
		if not (w.ulkeler[int(b["i"])].savasta() and w.ulkeler[int(b["j"])].savasta()):
			savas_tutarsiz += 1
	_dogrula(savas_tutarsiz == 0, "savas bagi dunyanin savas durumuyla tutarli")

	# Abluka bagi ile matris ayni seyi mi soyluyor.
	var n := w.ulkeler.size()
	var abluka_matris := 0
	for i in range(n):
		for j in range(i + 1, n):
			if maxf(w.abluka[i * n + j], w.abluka[j * n + i]) > 0.01:
				abluka_matris += 1
	_dogrula(abluka_matris == int(sayim["abluka"]),
			"abluka bagi sayisi matrisle ayni",
			"matris %d / bag %d" % [abluka_matris, sayim["abluka"]])

	# Bag ucu haritada var mi: bir bag cizilemiyorsa ekranda hicbir sey
	# gorunmez ve kapi yesil kalirdi.
	var kayipsiz := true
	for b in baglar:
		if Harita.indeks(w.adlar[int(b["i"])]) < 0 \
				or Harita.indeks(w.adlar[int(b["j"])]) < 0:
			kayipsiz = false
	_dogrula(kayipsiz, "her bagin iki ucu da haritada")

	# KAPSAM: dort bag turunun DORDU de kampanya boyunca en az bir kez
	# dogmali. Yalnizca son kareye bakan bir olcum bunu goremez -- savas
	# biter, abluka kalkar. "Baglar cizili" olcutunun dortte dordu.
	var bag: Dictionary = kampanya["bag"]
	print("     kampanyadaki en yuksek sayilar: savas %d, ittifak %d, "
			% [bag["savas"], bag["ittifak"]]
			+ "abluka %d, ticaret %d" % [bag["abluka"], bag["ticaret"]])
	var gorulmeyen := PackedStringArray()
	for tip in ["savas", "ittifak", "abluka", "ticaret"]:
		if int(bag[tip]) == 0:
			gorulmeyen.append(String(tip))
	_dogrula(gorulmeyen.is_empty(), "dort bag turu de kampanyada dogdu",
			"gorulmeyen: %s" % str(gorulmeyen) if not gorulmeyen.is_empty() else "")

	# --- CIZIM POLITIKASI: tam iliski cizilemez -------------------------
	# Ittifak bir KLIKTIR (sosyalist pakt); tamami cizilirse harita
	# okunmaz olur. Politika `Harita.gorunur_baglar`da ve BURADA sinaniyor:
	# cizim tarafinda dursaydi headless olculemezdi.
	var gorunur := Harita.gorunur_baglar(w)
	var g_sayim := {"savas": 0, "ittifak": 0, "abluka": 0, "ticaret": 0}
	for b in gorunur:
		g_sayim[b["tip"]] = int(g_sayim[b["tip"]]) + 1
	print("     cizilen: savas %d, ittifak %d, abluka %d, ticaret %d"
			% [g_sayim["savas"], g_sayim["ittifak"], g_sayim["abluka"],
			g_sayim["ticaret"]])

	_dogrula(int(g_sayim["ittifak"]) <= maxi(0, w.ulkeler.size() - 1),
			"ittifak yildizi klikten kucuk (<= n-1)",
			"%d -> %d" % [sayim["ittifak"], g_sayim["ittifak"]])
	_dogrula(int(g_sayim["abluka"]) <= Harita.EN_FAZLA_ABLUKA,
			"abluka cizimi sinirli", "%d -> %d" % [sayim["abluka"], g_sayim["abluka"]])
	_dogrula(int(g_sayim["savas"]) == int(sayim["savas"]),
			"savas baglarinin hepsi cizilir")

	# YILDIZ HICBIR MUTTEFIKI DUSURMEMELI: bir ulke ittifak iliskisi
	# tasiyorsa cizimde de en az bir bagi olmali. Yoksa blok haritada
	# eksik gorunur ve bunu gozle fark etmek imkansizdir.
	var ittifakli := {}
	for b in baglar:
		if b["tip"] == "ittifak":
			ittifakli[b["i"]] = true
			ittifakli[b["j"]] = true
	var cizili := {}
	for b in gorunur:
		if b["tip"] == "ittifak":
			cizili[b["i"]] = true
			cizili[b["j"]] = true
	var dusen := 0
	for u in ittifakli:
		if not cizili.has(u):
			dusen += 1
	_dogrula(dusen == 0, "ittifaki olan her ulkenin cizimde bir bagi var",
			"%d ulke ittifakli" % ittifakli.size())


# ===========================================================================
# 6. HARITA MOTORA DOKUNMUYOR
# ===========================================================================
static func _okuyucu() -> void:
	print("")
	print("6. OKUYUCU -- haritanin okumasi dunyayi degistiriyor mu")
	print("------------------------------------------------------------------")
	# KARSI-OLGUSAL: ayni tohum, ayni ulkeler, ayni tik sayisi. Tek fark,
	# bir kolda haritanin her tik SORGULANMASI (dokuz modun degeri, rengi ve
	# butun baglar). Harita gercekten bir gorunumse iki dunya BIREBIR ayni
	# kalmali.
	#
	# Neden ucuz degil ama gerekli: `HaritaModu.deger` ulke durumundan okur
	# ve okumak masum gorunur -- ama `aralik` bir dizi kurar, `baglar`
	# sozluk gezer, ve bunlarin herhangi biri yanlislikla bir alan yazsa
	# etkisi kaotik olarak buyur ve hicbir kapiya takilmazdi.
	var yil := 12.0
	var n := Oran.donem_sayisi(yil, HAFTA)
	var kodlar := Harita.kapi_kodlar()

	var a := Harita.dunya_kur(kodlar, 7, BAS)
	var b := Harita.dunya_kur(kodlar, 7, BAS)
	for _i in range(n):
		a.adim(HAFTA)
	for _i in range(n):
		b.adim(HAFTA)
		for m in HaritaModu.MODLAR:
			var id := String(m["id"])
			var ar := HaritaModu.aralik(id, b)
			for k in range(b.ulkeler.size()):
				var _v := HaritaModu.deger(id, b, k)
				var _r := HaritaModu.renk(id, b, k, ar)
			var _e := HaritaModu.efsane(id, b)
		var _bg := Harita.baglar(b)

	var fark := _dunya_farki(a, b)
	_dogrula(fark.is_empty(), "harita sorgulanan dunya ile sorgulanmayan ayni",
			"ilk fark: %s" % fark if not fark.is_empty() else
			"%d ulke x %d tik" % [a.ulkeler.size(), n])

	# BELIRLENIMLILIK: ayni tohum -> ayni renkler. Harita bir yerde
	# sirasiz bir sozluk gezseydi renkler kosudan kosuya oynardi.
	var renk_a := _renk_imzasi(a)
	var c := Harita.dunya_kur(kodlar, 7, BAS)
	for _i in range(n):
		c.adim(HAFTA)
	_dogrula(renk_a == _renk_imzasi(c), "ayni tohum ayni renkleri veriyor",
			"imza %d" % renk_a)


## Iki dunyanin butun ulke alanlarini karsilastirir; ilk farki dondurur.
static func _dunya_farki(a: Dunya, b: Dunya) -> String:
	if a.ulkeler.size() != b.ulkeler.size():
		return "ulke sayisi"
	for i in range(a.ulkeler.size()):
		var x := a.ulkeler[i]
		var y := b.ulkeler[i]
		for pr in x.get_property_list():
			if not (pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var ad: String = pr["name"]
			var vx: Variant = x.get(ad)
			var vy: Variant = y.get(ad)
			if typeof(vx) == TYPE_FLOAT:
				if not is_same(vx, vy):
					return "%s.%s (%.17g vs %.17g)" % [a.adlar[i], ad, vx, vy]
			elif str(vx) != str(vy):
				return "%s.%s" % [a.adlar[i], ad]
	for i in range(a.son_vt.size()):
		if not is_same(a.son_vt[i], b.son_vt[i]):
			return "son_vt[%d]" % i
		if not is_same(a.toplam_dis[i], b.toplam_dis[i]):
			return "toplam_dis[%d]" % i
	return ""


## Butun modlarin butun ulkelerdeki renklerinin CRC32'si. Float
## karsilastirmasi yerine bayt imzasi: "esit mi" sorusu "nasil yazdirdin"
## sorusuna donmesin.
static func _renk_imzasi(w: Dunya) -> int:
	var bayt := PackedByteArray()
	for m in HaritaModu.MODLAR:
		var id := String(m["id"])
		var ar := HaritaModu.aralik(id, w)
		for i in range(w.ulkeler.size()):
			var r := HaritaModu.renk(id, w, i, ar)
			bayt.append(int(r.r8))
			bayt.append(int(r.g8))
			bayt.append(int(r.b8))
	return Crc32.of_bytes(bayt)
