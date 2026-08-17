class_name SavasTesti
extends RefCounted

## B4 KAPISI -- savas bir kriz cikisi olarak.
##
## ------------------------------------------------------------------------
## OLCUT BASTAN TANIMLI, VE AYIRT EDIYOR
## ------------------------------------------------------------------------
## §6'nin asama tablosu B4 icin tek cumle yaziyor:
##
##   > **Savas sonrasi kar orani YUKARI, nufus ASAGI.**
##
## Bu, B1b/B2a/B2b/B2c'nin aksine bastan ayirt eden bir olcuttur -- savas
## katmani olmadan kurulamaz bile, cunku "savas sonrasi" diye bir an yoktur.
## Dort kez olcut duzeltmek zorunda kalmadik.
##
## Ama tek basina yeterli DEGIL, ve sebebi §3.2'nin kendi cumlesinde:
##
##   > Savas sermayeyi imha eder, sermayenin imhasi kar oranini YUKSELTIR.
##
## Yani olcut bir MEKANIZMA iddiasidir, bir sonuc gozlemi degil. `r = s/K`
## oldugu icin `K`yi yeterince yikan HERHANGI bir sey kar oranini yukseltir;
## testin isi bunun savas yikimindan geldigini gostermektir. Bu yuzden
## muhasebe zinciri ayri ayri olculur: yikim -> K duser -> r yukselir.
##
## ------------------------------------------------------------------------
## DORT KADEME
## ------------------------------------------------------------------------
##   1. OZDESLIK -- katman takili degilken dunya ZERRE degismez
##   2. MUHASEBE -- §3.2: savastan sonra r yukari, nufus asagi (ANA OLCUT)
##   3. KANAL    -- §3.1: savas krizden DOGUYOR mu (kar sikismasi -> ilan)
##   4. CANLILIK -- savaslar basliyor VE bitiyor, sayilari bantta, birim
##      tuzagina dusulmemis (haftalik ile aylik ayni savas yogunlugu)

const HAFTA := 1.0 / 52.0
const AY := 1.0 / 12.0
const BAS := 1825.0
const SURE := 198.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


static func _ulke(q0: float, egitim: float) -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = q0
	d.egitim = egitim
	d.yil = BAS
	d.varlik = 0.5
	return d


## `--v2-dunya` ile AYNI dunya. Ayni kurulumda olcmek zorunlu: kalibrasyon
## KARAR VERILEN kurulumda yapilir, yoksa sabit tasinmaz (B2a'nin dersi).
static func _dunya_kur(tohum: int = 42, savas_acik: bool = true,
		saldirganlik: float = 0.35) -> Dunya:
	var w := Dunya.new()
	w.yil = BAS
	w.ekle(_ulke(1.60, 0.42), "Yuksek", tohum)
	w.ekle(_ulke(1.30, 0.36), "Orta-ust", tohum)
	w.ekle(_ulke(1.00, 0.30), "Orta", tohum)
	w.ekle(_ulke(0.80, 0.24), "Orta-alt", tohum)
	w.ekle(_ulke(0.65, 0.18), "Dusuk", tohum)
	for d in w.ulkeler:
		d.saldirganlik = saldirganlik
	if savas_acik:
		w.savas = SavasKatmani.new(w.P, tohum + 7777)
	return w


## SAVAS EPIZODU. Her savasin baslangicini, bitisini ve iki yanindaki
## pencereleri kaydeder -- olcut "savas SONRASI" dedigi icin epizot bazli
## olculmeli, kampanya ortalamasiyla degil.
##
## Kampanya ortalamasi burada YANILTICI olurdu: savas hem yikar (K asagi, r
## yukari) hem de talep tabani kurar (u yukari, r yukari). Ortalama ikisini
## ayni kefeye koyar; olcut ise savasin BITTIGI andan sonrasini soruyor.
class Epizot:
	var ulke: int
	var bas_yil: float
	var bit_yil: float
	var r_once: float
	var r_sonra: float
	var L_once: float
	var L_sonra: float
	var K_once: float
	var K_dip: float


static func _kos(w: Dunya, donem_yil: float, pencere_yil: float = 12.0) -> Array:
	var n := Oran.donem_sayisi(SURE, donem_yil)
	var pencere := Oran.donem_sayisi(pencere_yil, donem_yil)
	var ulke_n := w.ulkeler.size()

	# Halka tampon: her ulke icin son `pencere` donemin r ve L'si.
	var r_iz: Array = []
	var L_iz: Array = []
	for i in range(ulke_n):
		r_iz.append(PackedFloat64Array())
		L_iz.append(PackedFloat64Array())

	var acik: Array = []          # suren epizotlar (ulke -> Epizot)
	var bekleyen: Array = []      # bitmis, `sonra` penceresi dolmayi bekleyen
	var epizotlar: Array = []
	var onceki_savasta: Array = []
	for i in range(ulke_n):
		acik.append(null)
		onceki_savasta.append(false)

	for t in range(n):
		w.adim(donem_yil)
		for i in range(ulke_n):
			var d := w.ulkeler[i]
			var iz: PackedFloat64Array = r_iz[i]
			iz.append(d.r_yil)
			if iz.size() > pencere:
				iz = iz.slice(iz.size() - pencere)
			r_iz[i] = iz
			var Liz: PackedFloat64Array = L_iz[i]
			Liz.append(d.L_etkin)
			if Liz.size() > pencere:
				Liz = Liz.slice(Liz.size() - pencere)
			L_iz[i] = Liz

			var simdi := d.savasta()
			if simdi and not onceki_savasta[i]:
				# SAVAS BASLADI -- oncesini dondur.
				var e := Epizot.new()
				e.ulke = i
				e.bas_yil = d.yil
				e.r_once = _ort(r_iz[i])
				e.L_once = d.L_etkin
				e.K_once = d.K
				e.K_dip = d.K
				acik[i] = e
			elif simdi and acik[i] != null:
				var ea: Epizot = acik[i]
				ea.K_dip = minf(ea.K_dip, d.K)
			elif (not simdi) and onceki_savasta[i] and acik[i] != null:
				# SAVAS BITTI -- sonrasi icin bekleme listesine.
				var eb: Epizot = acik[i]
				eb.bit_yil = d.yil
				bekleyen.append({"e": eb, "kalan": pencere,
						"r_top": 0.0, "say": 0})
				acik[i] = null
			onceki_savasta[i] = simdi

		# Bekleyen epizotlarin `sonra` penceresini doldur.
		var kalanlar: Array = []
		for b in bekleyen:
			var e2: Epizot = b["e"]
			b["r_top"] = float(b["r_top"]) + w.ulkeler[e2.ulke].r_yil
			b["say"] = int(b["say"]) + 1
			b["kalan"] = int(b["kalan"]) - 1
			if int(b["kalan"]) <= 0:
				e2.r_sonra = float(b["r_top"]) / maxf(float(b["say"]), 1.0)
				e2.L_sonra = w.ulkeler[e2.ulke].L_etkin
				epizotlar.append(e2)
			else:
				kalanlar.append(b)
		bekleyen = kalanlar

	return epizotlar


static func _ort(x: PackedFloat64Array) -> float:
	if x.is_empty():
		return 0.0
	var t := 0.0
	for v in x:
		t += v
	return t / float(x.size())


# ===========================================================================
# 1. OZDESLIK
# ===========================================================================

static func _ozdeslik() -> void:
	print("\n--- 1. OZDESLIK (katman takili degilken dunya zerre degismez) ---")
	var w1 := _dunya_kur(42, false)
	var w2 := _dunya_kur(42, false)
	var n := Oran.donem_sayisi(SURE, HAFTA)
	for _i in range(n):
		w1.adim(HAFTA)
		w2.adim(HAFTA)
	var ayni := true
	for i in range(w1.ulkeler.size()):
		for alan in ["K", "q", "pay", "r_yil", "L_etkin", "Omega"]:
			if float(w1.ulkeler[i].get(alan)) != float(w2.ulkeler[i].get(alan)):
				ayni = false
	_dogrula(ayni, "(a) savas katmani yokken dunya belirlenimli",
			"(5 ulke x 6 alan, IEEE754)")

	var savassiz := 0
	for d in w1.ulkeler:
		savassiz += d.savas_toplam
	_dogrula(savassiz == 0, "(b) katman takili degilken HIC savas olmuyor",
			"(%d donem)" % savassiz)


# ===========================================================================
# 2. MUHASEBE  --  §3.2, B4'un ilan edilmis olcutu
# ===========================================================================

static func _muhasebe() -> void:
	print("\n--- 2. MUHASEBE (§3.2 -- ANA OLCUT) ---")

	# UC TOHUM. Deponun kendi kurali: "devrim sayisi tohuma duyarli, en az uc
	# tohum gerekir" (§10). Savas ondan da ayrik bir olay, dolayisiyla tek
	# tohumda iki epizot bir olcum degil bir anekdottur.
	var epizotlar: Array = []
	var dunyalar: Array = []
	for tohum in [42, 101, 202]:
		var w := _dunya_kur(tohum, true)
		epizotlar.append_array(_kos(w, HAFTA))
		dunyalar.append(w)

	_dogrula(epizotlar.size() >= 3,
			"olcut tanimli: en az uc tamamlanmis savas epizodu var (3 tohum)",
			"(%d epizot)" % epizotlar.size())
	if epizotlar.is_empty():
		return

	var r_artan := 0
	var L_azalan := 0
	var dr_top := 0.0
	var dL_top := 0.0
	for e in epizotlar:
		var ep: Epizot = e
		if ep.r_sonra > ep.r_once:
			r_artan += 1
		if ep.L_sonra < ep.L_once:
			L_azalan += 1
		dr_top += ep.r_sonra - ep.r_once
		dL_top += (ep.L_sonra - ep.L_once) / maxf(ep.L_once, 1e-9)
	var m := float(epizotlar.size())

	# ANA OLCUT, IKI YARISI.
	_dogrula(dr_top / m > 0.0,
			"KAR ORANI savastan sonra YUKARI (§3.2)",
			"(ort %+.5f, %d/%d epizotta artiyor)" % [dr_top / m, r_artan, int(m)])
	_dogrula(dL_top / m < 0.0,
			"NUFUS savastan sonra ASAGI",
			"(ort %+.2f%%, %d/%d epizotta azaliyor)" % [
				dL_top / m * 100.0, L_azalan, int(m)])

	# NUFUS KAYBI TARIHSEL BANTTA MI. Yon yeter demek degil: ilk kalibrasyonda
	# savaslar 15.3 yil suruyordu ve epizot basina kayip %31.8'e cikiyordu --
	# yonu DOGRU, buyuklugu tarihin iki katindan fazla. 1. Dunya Savasi'nda
	# Fransa ~%4, 2. Dunya Savasi'nda SSCB ~%13 kaybetti.
	_dogrula(absf(dL_top / m) < 0.20,
			"    ...ve kayip TARIHSEL bantta (buyuk savaslarda %4-13)",
			"(ort %.1f%%)" % absf(dL_top / m * 100.0))

	# MUHASEBE ZINCIRI -- KARSI-OLGUSAL OLCULUR.
	#
	# Ilk yazimda "savas icinde K dip < K bas" diye olculdu ve KALDI: 0/2
	# epizot. Sebep olcumun yanlis kurulmasiydi, mekanizmanin yoklugu degil --
	# `K` savas sirasinda da birikimle buyuyor, yani yikim GERCEK ama net
	# duzey yine de yukselebiliyor. Dogru soru "K dustu mu" degil, "SAVAS
	# OLMASAYDI K ne olurdu" -- yani karsi-olgusal.
	var K_savasli := 0.0
	var K_barisci := 0.0
	var yikim_top := 0.0
	for tohum2 in [42, 101, 202]:
		var wa := _dunya_kur(tohum2, true)
		var wb := _dunya_kur(tohum2, false)
		var n := Oran.donem_sayisi(SURE, HAFTA)
		for _i in range(n):
			wa.adim(HAFTA)
			wb.adim(HAFTA)
		for i in range(wa.ulkeler.size()):
			K_savasli += wa.ulkeler[i].K
			K_barisci += wb.ulkeler[i].K
			yikim_top += wa.ulkeler[i].savas_yikimi
	_dogrula(K_savasli < K_barisci,
			"    ...zincirin ilk halkasi: savas SERMAYE STOKUNU kucultuyor",
			"(savasli %.0f < barisci %.0f, kumulatif yikim %.0f)" % [
				K_savasli, K_barisci, yikim_top])

	var toplam_yikim := 0.0
	var toplam_nufus := 0.0
	for w2 in dunyalar:
		for d in (w2 as Dunya).ulkeler:
			toplam_yikim += d.savas_yikimi
			toplam_nufus += d.savas_nufus_kaybi
	_dogrula(toplam_yikim > 0.0 and toplam_nufus > 0.0,
			"    ...muhasebe iki tarafli: sermaye VE nufus sayiliyor",
			"(K %.0f, L %.1f)" % [toplam_yikim, toplam_nufus])


# ===========================================================================
# 3. KANAL  --  §3.1: savas krizden DOGUYOR mu
# ===========================================================================

static func _kanal() -> void:
	print("\n--- 3. KANAL (§3.1 -- savas bir kriz cikisi mi) ---")

	# SALDIRGANLIK KARSI-OLGUSALI. Savas ilani `saldirganlik` ile CARPILDIGI
	# icin sifirda hicbir ilan olmamali -- kolun gercekten o kol oldugunun
	# en dogrudan kaniti.
	var w0 := _dunya_kur(42, true, 0.0)
	var e0 := _kos(w0, HAFTA)
	var w1 := _dunya_kur(42, true, 0.35)
	var e1 := _kos(w1, HAFTA)
	_dogrula(w0.savas.ilan_sayisi == 0 and w1.savas.ilan_sayisi > 0,
			"saldirganlik 0 iken HIC savas yok, 0.35'te var",
			"(%d -> %d ilan)" % [w0.savas.ilan_sayisi, w1.savas.ilan_sayisi])

	# KAR SIKISMASI KANALI. §3.1: "dusen kar orani -> sermaye ihraci /
	# emperyalistler arasi savas". Motorda `sikisma = (sv_r_ref - r)/sv_r_ref`,
	# yani savas olasiligi kar oranININ FONKSIYONUDUR.
	#
	# Olcum: savas ILAN EDEN ulkelerin ilan anindaki kar orani, ilan
	# etmeyenlerin ayni andaki kar oranindan DUSUK olmali.
	# ES-ZAMANLI KARSILASTIRMA, KAMPANYA ORTALAMASI DEGIL.
	#
	# Ilk yazimda ilan anindaki kar orani KAMPANYA GENELI ortalamayla
	# karsilastirildi ve siklik 5'e cikarilinca test dondu: ilan edenlerin
	# orani DAHA YUKSEK cikti (0.0937 vs 0.0711). Mekanizma bozulmadi,
	# olcum trendi iceriyordu -- `r` kampanya boyunca 0.10'dan 0.04'e
	# duser ve ilanlar erken yillarda kumelenir, yani "ilan eden" orneklemi
	# otomatik olarak ERKEN yillardan geliyordu.
	#
	# Dogru soru: ilan eden ulkenin kar orani, O ANDA digerlerinin altinda mi.
	# Ayni ailenin ucuncu hatasi (mutlak NX yerine NX/Y, ham l_etkin yerine
	# carpan): duzey karsilastirmasi trendi olcer, mekanizmayi degil.
	var w2 := _dunya_kur(42, true)
	var fark_top := 0.0
	var ilan_say := 0
	var n := Oran.donem_sayisi(SURE, HAFTA)
	var onceki: Array = []
	for i in range(w2.ulkeler.size()):
		onceki.append(false)
	for _t in range(n):
		# Tikten ONCEKI kar oranlari -- ilan karari onlara bakiyor.
		var r_simdi: PackedFloat64Array = PackedFloat64Array()
		for d in w2.ulkeler:
			r_simdi.append(d.r_yil)
		w2.adim(HAFTA)
		for i in range(w2.ulkeler.size()):
			var simdi := w2.ulkeler[i].savasta()
			if simdi and not onceki[i]:
				# O ANIN kesitindeki ortalama -- ilan eden haric.
				var top := 0.0
				var say := 0
				for j in range(w2.ulkeler.size()):
					if j != i:
						top += r_simdi[j]
						say += 1
				fark_top += r_simdi[i] - top / maxf(float(say), 1.0)
				ilan_say += 1
			onceki[i] = simdi
	var ort_fark := fark_top / maxf(float(ilan_say), 1.0)
	_dogrula(ilan_say > 0 and ort_fark < 0.0,
			"SAVASA GIRENIN kar orani, O ANDA digerlerinin altinda (§3.1)",
			"(es-zamanli fark %+.5f, %d ilan)" % [ort_fark, ilan_say])

	# SAVAS ASIRI URETIMI EMER. §3.1'in "asiri uretim -> yeni pazar, gerekirse
	# zorla" satiri: savas ekonomisi kapasiteyi sogurdugu icin gerceklesme
	# krizi savasta ATESLENEMEZ. v4.4'un kendi kanali (`D_talep >= Y_pot*0.95`).
	var savasta_acik := 0.0
	var savasta_say := 0
	var barista_acik := 0.0
	var barista_say := 0
	var w3 := _dunya_kur(42, true)
	for _t2 in range(n):
		w3.adim(HAFTA)
		for d in w3.ulkeler:
			if d.savasta():
				savasta_acik += d.talep_acigi
				savasta_say += 1
			else:
				barista_acik += d.talep_acigi
				barista_say += 1
	var s_ort := savasta_acik / maxf(float(savasta_say), 1.0)
	var b_ort := barista_acik / maxf(float(barista_say), 1.0)
	_dogrula(savasta_say > 0 and s_ort < b_ort,
			"SAVAS asiri uretimi EMIYOR (talep acigi savasta daha kucuk)",
			"(savasta %.4f, baris %.4f)" % [s_ort, b_ort])


# ===========================================================================
# 4. CANLILIK  --  ve birim tuzagi
# ===========================================================================

static func _canlilik() -> void:
	print("\n--- 4. CANLILIK ---")
	var w := _dunya_kur(42, true)
	var epizotlar := _kos(w, HAFTA)
	var toplam_donem := 0
	var suren := 0
	for d in w.ulkeler:
		toplam_donem += d.savas_toplam
		if d.savasta():
			suren += 1
	var savas_pay := float(toplam_donem) / (float(w.ulkeler.size())
			* float(Oran.donem_sayisi(SURE, HAFTA)))

	_dogrula(w.savas.ilan_sayisi > 0, "savaslar BASLIYOR",
			"(%d ilan)" % w.savas.ilan_sayisi)
	_dogrula(epizotlar.size() > 0, "savaslar BITIYOR (sayac gercekten doluyor)",
			"(%d tamamlanmis epizot)" % epizotlar.size())
	# BANT: ulke basina zamanin makul bir payi. Ust sinir onemli -- `fx_baski`
	# tuzaginda oldugu gibi bir kapi "surekli savas" uretebilir ve yon
	# denetimleriyle yesil verirdi.
	_dogrula(savas_pay > 0.01 and savas_pay < 0.45,
			"savas yogunlugu bantta (surekli savas DEGIL, hic yok da degil)",
			"(zamanin %%%.1f'i)" % (savas_pay * 100.0))

	# BIRIM TUZAGI. `sv_min_sure`/`sv_max_sure` TUR cinsindendir; haftalik
	# donguye oldugu gibi kopyalansaydi savaslar 14 kat kisa surer ve
	# haftalik kol aylik koldan cok farkli bir yogunluk verirdi. Bu denetim
	# `--v2-olcek`in savas icin karsiligi.
	var wa := _dunya_kur(42, true)
	var na := Oran.donem_sayisi(SURE, AY)
	for _i in range(na):
		wa.adim(AY)
	var aylik_donem := 0
	for d in wa.ulkeler:
		aylik_donem += d.savas_toplam
	var aylik_pay := float(aylik_donem) / (float(wa.ulkeler.size()) * float(na))
	_dogrula(absf(aylik_pay - savas_pay) < 0.20,
			"BIRIM TUZAGI: haftalik ile aylik ayni savas yogunlugu",
			"(haftalik %%%.1f, aylik %%%.1f)" % [
				savas_pay * 100.0, aylik_pay * 100.0])

	# Savas suresi bandi -- tarihsel olcek: buyuk savaslar 1-7 yil.
	var sure_top := 0.0
	for e in epizotlar:
		var ep: Epizot = e
		sure_top += ep.bit_yil - ep.bas_yil
	var ort_sure := sure_top / maxf(float(epizotlar.size()), 1.0)
	_dogrula(ort_sure > 1.0 and ort_sure < 25.0,
			"savas suresi makul bantta",
			"(ort %.1f yil)" % ort_sure)


# ===========================================================================
# 5. KARANLIK DEVLETIN BEDELI -- COK ULKELI DUNYADA (B3'ten devredilen olcum)
# ===========================================================================

## B3'te olculdu ve bir denge acigi cikti: tek ulkeli kosuda karanlik devlet
## devrimi onluyor VE kar oranini yukseltiyor, tek bedeli hasila. Zafer kosulu
## olmadigi icin oyuncunun hasilayi umursamasi icin sebep yoktu -- yani kol
## neredeyse BEDAVAYDI.
##
## Karar kayda gecti: "once olcelim, sonra karar". Beklenti, bedelin cok
## ulkeli dunyada dogmasiydi -- uretkenligini yiyen ulke pazar kaybeder,
## savasi kaybeder. B4 o dunyayi kurdugu icin olcum artik yapilabilir.
##
## KAPI DEGIL KAYIT: bu bir yon testi degil, karari besleyecek olcumdur.
static func _karanlik_bedeli() -> void:
	print("\n--- 5. KARANLIK DEVLETIN BEDELI (cok ulkeli, B3'ten devredildi) ---")
	var sonuc: Array = []
	for karanlik in [false, true]:
		var w := _dunya_kur(42, true)
		if karanlik:
			# YALNIZCA "Orta" ulkesi karanlik devlete sarilir. Karsilastirma
			# ayni dunyada, ayni tohumda, tek ulke degisecek sekilde kurulur.
			var kd := KaranlikDevlet.new(w.cekirdekler[2].P)
			kd.baslat(w.ulkeler[2])
			w.cekirdekler[2].karanlik = kd
			var d2 := w.ulkeler[2]
			d2.t_uyusturucu = 1.0
			d2.t_cemaat = 1.0
			d2.t_mistisizm = 1.0
			d2.t_milliyetcilik = 1.0
			d2.t_cinsiyet = 1.0
			d2.t_sendika_baskisi = 1.0
			d2.t_tutuklama = 1.0
			d2.t_paramiliter = 1.0
		var n := Oran.donem_sayisi(SURE, HAFTA)
		var r_top := 0.0
		var nx_y_top := 0.0
		var abluka_top := 0.0
		for _i in range(n):
			w.adim(HAFTA)
			r_top += w.ulkeler[2].r_yil
			nx_y_top += w.ulkeler[2].NX_yil / maxf(w.ulkeler[2].Y_yil, 1e-9)
			var un := w.ulkeler.size()
			for j in range(un):
				if j != 2 and w.abluka.size() == un * un:
					abluka_top += w.abluka[2 * un + j] / float(un - 1)
		var d := w.ulkeler[2]
		sonuc.append({
			"r": r_top / float(n), "q": d.q, "K": d.K,
			"devrim": d.devrim_yil,
			# NX MUTLAK DEGIL HASILAYA ORANLI. Karanlik devlete sarilan ulke
			# 13 kat kuculdugu icin MUTLAK dis akimlari da kuculur -- ilk
			# olcumde `birikmis NX` daha az negatif cikti ve bu "dis konumu
			# duzeldi" gibi okunabilirdi. Duzelen bir sey yok, ekonomi kuculdu.
			"nx_y": nx_y_top / float(n), "dis": w.toplam_dis[2],
			"yenilgi": d.yenilgi_sayisi, "savas": d.savas_toplam,
			"abluka": abluka_top / float(n),
		})
	var a: Dictionary = sonuc[0]
	var b: Dictionary = sonuc[1]
	print("  Olculen ulke: 'Orta'. Sekiz taktik tam kapasite.")
	print("  %-22s %12s %12s" % ["", "karanliksiz", "karanlik"])
	for alan in [["ort kar orani", "r"], ["uretkenlik q", "q"],
			["sermaye K", "K"], ["ort NX/Y", "nx_y"],
			["bilesik dis konum", "dis"], ["ort abluka", "abluka"],
			["devrim yili", "devrim"],
			["yenilgi sayisi", "yenilgi"], ["savasta donem", "savas"]]:
		print("  %-22s %12.4f %12.4f" % [alan[0], float(a[alan[1]]),
				float(b[alan[1]])])
	print("\n  NOT: bu bir kapi degil KAYITTIR. B3'un denge sorusu bu tabloya")
	print("  bakarak karara baglanir (bkz. tasarim belgesi §6e).")


# ===========================================================================
# 6. ABLUKA, AMBARGO VE ITTIFAK  --  §3.3
# ===========================================================================

static func _abluka_ittifak() -> void:
	print("\n--- 6. ABLUKA, AMBARGO, ITTIFAK (§3.3) ---")

	var w := _dunya_kur(42, true)
	var n := Oran.donem_sayisi(SURE, HAFTA)
	var abluka_gorulen := 0.0
	var savas_ciftinde := 0.0
	var savas_cift_say := 0
	var korunum_en_kotu := 0.0
	var ittifak_gorulen := 0
	for _i in range(n):
		w.adim(HAFTA)
		var un := w.ulkeler.size()
		# KORUNUM: abluka acikken de `sum(NX) == 0` ozdesligi durmali.
		# Ciftte tanimli olmasinin sebebi buydu; tek tarafli yazilsaydi
		# burada kirilirdi (v4.4'un L blogu %57 hata veriyordu).
		var nx_top := 0.0
		var nx_mutlak := 0.0
		for d in w.ulkeler:
			nx_top += d.NX_yil
			nx_mutlak += absf(d.NX_yil)
		if nx_mutlak > 1e-9:
			korunum_en_kotu = maxf(korunum_en_kotu, absf(nx_top) / nx_mutlak)
		for a in range(un):
			if not w.ulkeler[a].muttefik.is_empty():
				ittifak_gorulen += 1
			for b in range(a + 1, un):
				if w.abluka.size() != un * un:
					continue
				var k := w.abluka[a * un + b]
				abluka_gorulen = maxf(abluka_gorulen, k)
				if w.ulkeler[a].savas.has(w.adlar[b]):
					savas_ciftinde += k
					savas_cift_say += 1

	_dogrula(korunum_en_kotu < 1e-9,
			"KORUNUM: abluka acikken de sum(NX) == 0 (cift uzerinde tanimli)",
			"(en kotu bagil hata %.3e)" % korunum_en_kotu)
	_dogrula(abluka_gorulen > 0.0, "abluka/ambargo FIILEN uygulaniyor",
			"(en yuksek kesinti %.2f)" % abluka_gorulen)
	if savas_cift_say > 0:
		_dogrula(savas_ciftinde / float(savas_cift_say) > 0.5,
				"    ...ve savasan cift birbiriyle ticaret yapmiyor",
				"(ort kesinti %.2f)" % (savas_ciftinde / float(savas_cift_say)))

	# ABLUKA GERCEKTEN TICARETI KESIYOR MU.
	#
	# DUNYA TOPLAMINA BAKILMAZ, ve bu bir kez yanlis olculdu: abluka acikken
	# dunya hacmi DAHA BUYUK cikti (6.29M vs 5.71M). Mekanizma tersine
	# donmedi -- abluka edilen ulkenin mallari satilamayinca `talep_acigi`
	# buyuyor, `_itki` onu KALAN ciftlere daha sert asiyor, ve 198 yillik iki
	# yorunge zaten kaotik olarak ayrisiyor. Dunya toplami mekanizmayi degil
	# yorunge farkini olcer.
	#
	# Dogru olcu ABLUKA EDILEN CIFTIN kendi hacmi: kesinti oradadir.
	var wc := _dunya_kur(42, true)
	var engelli_hacim := 0.0
	var engelli_say := 0
	var serbest_hacim := 0.0
	var serbest_say := 0
	for _i in range(n):
		wc.adim(HAFTA)
		var un := wc.ulkeler.size()
		if wc.abluka.size() != un * un:
			continue
		for a in range(un):
			for b in range(a + 1, un):
				var h := wc.cift_hacmi(a, b)
				if wc.abluka[a * un + b] > 0.5:
					engelli_hacim += h
					engelli_say += 1
				else:
					serbest_hacim += h
					serbest_say += 1
	var e_ort := engelli_hacim / maxf(float(engelli_say), 1.0)
	var s_ort := serbest_hacim / maxf(float(serbest_say), 1.0)
	_dogrula(engelli_say > 0 and e_ort < s_ort,
			"ABLUKA edilen ciftin ticareti KESILIYOR",
			"(engelli cift %.1f < serbest cift %.1f, %d gozlem)" % [
				e_ort, s_ort, engelli_say])

	_dogrula(ittifak_gorulen > 0, "ITTIFAKLAR kuruluyor (§3.3)",
			"(%d ulke-donem muttefikli)" % ittifak_gorulen)


# ===========================================================================
# 7. ENDOJEN KARANLIK DEVLET  --  §4.5
# ===========================================================================

## §4.5: "Yapay zeka yonetimindeki ulkeler bu kollari kendi krizlerine gore
## kullanir -- yani dunyada baska ulkelerin fasizme kayisini DISARIDAN
## izlersin." B3'te `otomatik` bayragi yazildi ama hicbir kapi calistirmadi;
## dunya artik var, dolayisiyla sinanabilir.
static func _endojen_karanlik() -> void:
	print("\n--- 7. ENDOJEN KARANLIK DEVLET (§4.5) ---")
	var w := _dunya_kur(42, true)
	for i in range(w.ulkeler.size()):
		var kd := KaranlikDevlet.new(w.cekirdekler[i].P)
		kd.otomatik = true
		kd.baslat(w.ulkeler[i])
		w.cekirdekler[i].karanlik = kd
	var n := Oran.donem_sayisi(SURE, HAFTA)
	var tol_zirve := 0.0
	var uo_zirve := 0.0
	for _i in range(n):
		w.adim(HAFTA)
		for d in w.ulkeler:
			tol_zirve = maxf(tol_zirve, d.mafya_tolerans)
			uo_zirve = maxf(uo_zirve, d.uyusturucu_orani)
	_dogrula(tol_zirve > 0.05,
			"AI ulkeleri karanlik araca KENDILIGINDEN sariliyor",
			"(en yuksek tolerans %.3f)" % tol_zirve)
	_dogrula(uo_zirve > 0.0,
			"    ...ve endojen kol gercek bir cikti uretiyor",
			"(en yuksek uyusturucu orani %.4f)" % uo_zirve)


# ===========================================================================
# GIRIS
# ===========================================================================

static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("\nV2 SAVAS -- BIR KRIZ CIKISI OLARAK (B4)")
	print("==================================================================")
	print("  pencere : %.0f-%.0f, haftalik, 5 ulke" % [BAS, BAS + SURE])

	_ozdeslik()
	_muhasebe()
	_kanal()
	_canlilik()
	_abluka_ittifak()
	_endojen_karanlik()
	_karanlik_bedeli()

	print("------------------------------------------------------------------")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


## SIKLIK TARAMASI -- tani, kapi degil.
##
## SURE tarihsel capaya cekildi ama SIKLIK cekilmedi ve bu bir eksikti:
## olcut yon ve bant soruyor, sikligi sormuyordu. B2b'nin dersinin bir
## kuzeni burada duruyor olabilirdi -- "yonu dogru, mekanizma seyrek".
##
## TARIHSEL CAPA. 1816-2007 arasi devletlerarasi savas kaydinda buyuk gucler
## zamanlarinin kabaca %5-15'ini savasta gecirir; bir ulke yuzyilda 1-4 kez
## savasa girer. Ust sinir onemli: "surekli savas" da tarihsel degildir.
static func tarama() -> int:
	print("\nV2 SAVAS -- SIKLIK KALIBRASYONU (tani)")
	print("==================================================================")
	print("  Capa: buyuk gucler zamanin %5-15'ini savasta gecirir,")
	print("        ulke basina yuzyilda 1-4 savas.")
	print("  --- (a) siklik carpani (5 ulke) ---")
	print("  siklik  zaman_pay  savas/ulke-yuzyil  ort_sure")
	for sik in [1.0, 4.0, 10.0]:
		_tarama_satiri(5, float(sik), "  %6.1f" % float(sik))

	# HIPOTEZ: baglayici kisit OLASILIK DEGIL HEDEF BULUNABILIRLIGI.
	# Hedef secimi `guc < 1.15*guc` istiyor; bes ulkeli ve ayrismis bir
	# dunyada zayif ulkenin saldiracagi kimse yok, guclu ulke de savasa
	# girince kilitleniyor. Oyleyse ULKE SAYISI sikligi olasiliktan daha
	# cok belirlemeli. Tarihsel capa (yuzyilda 1-4 savas) zaten 50+ devletli
	# bir dunyadan geliyor.
	print("\n  --- (b) ulke sayisi (siklik = 1.0) ---")
	print("  ulke    zaman_pay  savas/ulke-yuzyil  ort_sure")
	for un in [5, 10, 20]:
		_tarama_satiri(un, 1.0, "  %4d  " % un)

	# SECIM 20 ULKEDE YAPILIR, 5'te DEGIL. Kalibrasyon KARAR VERILEN
	# kurulumda yapilir; oyunun hedefi ~100 ulkedir (B6), test dunyasi degil.
	# 5 ulkelik kola gore ayarlanmis bir sabit olcek buyudukce savasi
	# salgina cevirirdi.
	print("\n  --- (c) 20 ulkede siklik secimi ---")
	print("  siklik  zaman_pay  savas/ulke-yuzyil  ort_sure")
	for sik2 in [1.0, 2.0, 3.0, 5.0]:
		_tarama_satiri(20, float(sik2), "  %6.1f" % float(sik2))
	print("\n  NOT: bu bir kapi degil TANIDIR. Secim tasarim belgesine yazilir.")
	return 0


## Tarama satiri. `ulke_n` verildiginde dunya o kadar ulkeyle kurulur --
## uretkenlikleri ayni araliga yayilir, yani ayrisma yapisi korunur.
static func _tarama_satiri(ulke_n: int, siklik: float, on_ek: String) -> void:
	var donem_top := 0
	var epizot_top := 0
	var sure_top := 0.0
	for tohum in [42, 101, 202]:
		var w := Dunya.new()
		w.yil = BAS
		for i in range(ulke_n):
			var t := float(i) / maxf(float(ulke_n - 1), 1.0)
			w.ekle(_ulke(1.60 - 0.95 * t, 0.42 - 0.24 * t),
					"U%d" % i, tohum)
		for d in w.ulkeler:
			d.saldirganlik = 0.35
		w.savas = SavasKatmani.new(w.P, tohum + 7777)
		w.savas.P.savas_siklik = siklik
		var eps := _kos(w, HAFTA)
		for d in w.ulkeler:
			donem_top += d.savas_toplam
		epizot_top += eps.size()
		for e in eps:
			sure_top += (e as Epizot).bit_yil - (e as Epizot).bas_yil
	var ulke_donem := 3 * ulke_n * Oran.donem_sayisi(SURE, HAFTA)
	var ulke_yuzyil := 3.0 * float(ulke_n) * SURE / 100.0
	print("%s %10.3f %18.2f %9.1f" % [on_ek,
			float(donem_top) / float(ulke_donem),
			float(epizot_top) / ulke_yuzyil,
			sure_top / maxf(float(epizot_top), 1.0)])
