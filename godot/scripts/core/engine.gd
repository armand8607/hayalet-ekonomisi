class_name GhostEngine
extends RefCounted

## Hayalet Ekonomisi motoru -- Python `GhostEconomyEngine` sinifinin portu.
##
## PORT KURALI: davranis degistirilmez. Belge "v4.4 OZELLIK ACISINDAN
## DONDURULDU" diyor; burada bulunan her tuhaflik AYNEN tasinir. Bir sey yanlis
## gorunuyorsa duzeltilmez, raporlanir -- kalibrasyonun tamami o tuhafliklarin
## uzerine oturuyor.
##
## DURUM: dunya kurulumu (dunya_kur / cag_ata / init_simulation) tasindi ve
## parite ile dogrulandi. `step()` govdesi (A-T bloklari) HENUZ TASINMADI.
##
## Otoload DEGILDIR: Monte Carlo ve parite kosulari ayni anda onlarca bagimsiz
## ornek calistirir.

var P: ParamSet
var tohum: int
var baslangic_yili: int
var dunya_devrimi := false
var dd_sayac := 0
var pakt_uyumu := 0.0
var kap_kriz_payi := 0.0

## Senaryonun tarihsel baslangic istihdami. `init_simulation` K'yi bu hedefe
## gore olcekler. Issizlik bu modelde YAVAS BIRIKEN bir stoktur ve 120 turluk
## oyun ufkunda kurumsal farklardan TURETILEMEZ -- senaryo odalarinin isi
## zaten budur: baslangic durumu turetilmez, kurulur.
var hedef_istihdam: float

## Senaryonun sermaye/emek bollugu carpani. Baslangic issizlik SEVIYESINI kuran
## degisken budur (ampirik olarak kalibre edilir, bkz. belge bolum 8).
var K_carpani := 1.0
var K_olcek := 1.0
var _K_carpani_override = null

var D: Array[Country] = []
var log: Array = []
var t := 0
var rng: PyRandom


func _init(p_tohum: int = 42) -> void:
	P = Params.make()
	tohum = p_tohum
	baslangic_yili = Formulas.BASLANGIC_YILI
	hedef_istihdam = P.e0
	D = dunya_kur()
	log = []
	t = 0
	rng = PyRandom.new(tohum)
	# VARSAYILAN dunyada da cag ile q tutarli kilinir. Aksi halde q, cag 6'nin
	# tavanina kadar ~200 KAT buyur, emek arzi neredeyse sabit kalir ve
	# kapitalist ulkelerde %60-70 teknolojik issizlik cikardi.
	cag_ata(Formulas.P_BASLANGIC_CAGI)
	init_simulation()


## Simulasyonun o andaki takvim yili.
func yil() -> float:
	return baslangic_yili + t * Formulas.TUR_YIL


## G20 ulkelerini ve Turkiye'yi ampirik deger katsayilariyla baslatir.
func dunya_kur() -> Array[Country]:
	var out: Array[Country] = []
	for satir in Tables.ULKELER:
		out.append(Country.new(
			String(satir[0]), String(satir[1]),
			float(satir[2]), float(satir[3]), float(satir[4]),
			float(satir[5]), float(satir[6]), float(satir[7]), float(satir[8])))
	return out


## Ulkeleri bir caga tasir ve q'yu O CAGLA TUTARLI hale getirir.
##
## Ulkenin dunya icindeki GORELI verimlilik konumu korunur, mutlak seviye ise
## hedef cagin [q_esik, bir sonraki cagin q_esik'i] araligina tasinir -- boylece
## hicbir ulke atandigi turda hemen bir sonraki caga sicramaz ve merkez-cevre
## farki kaybolmaz.
##
## DIKKAT: qmin/qmax daima BUTUN dunyadan alinir, `ulkeler` altkumesinden degil.
func cag_ata(era: int, ulkeler: Array[Country] = []) -> void:
	var hedefler: Array[Country] = D if ulkeler.is_empty() else ulkeler
	var qmin := INF
	var qmax := -INF
	for c in D:
		qmin = minf(qmin, c.q)
		qmax = maxf(qmax, c.q)

	var alt: float = maxf(float(Tables.ERAS[era]["q_esik"]), 0.5)
	var ust: float = (float(Tables.ERAS[era + 1]["q_esik"]) if era < 6
			else float(Tables.ERAS[6]["q_tavan"]))

	for c in hedefler:
		var konum := (c.q - qmin) / maxf(qmax - qmin, 1e-9)
		c.era = era
		c.q = alt + (ust - alt) * (0.10 + 0.55 * konum)


## Marxian KODEY: sabit sermayenin ucuzlamasi DOYUMLUDUR.
##
## Payda doyumlu olmasa karsi-egilim egilimi tamamen yutar ve kar orani
## YUKSELIRDI. Marx'in kendi cercevesi: ucuzlama egilimi geciktirir, tersine
## ceviremez.
func kappa_v(cv: float, q: float) -> float:
	var L := maxf(0.0, log(maxf(q, 0.05) / 0.5))
	var ucuz := P.ucuzlama_max * L / (L + P.ucuzlama_h)
	return P.kv0 * pow(cv, P.kv_us) / (1.0 + ucuz)


## Sabit sermayenin ucuzlama duzeyi [0, ucuzlama_max).
## `ito` icin ayrica gerekli: makine ucuzladikca emegi ikame esigi duser.
func ucuzlama_orani(q: float) -> float:
	var L := maxf(0.0, log(maxf(q, 0.05) / 0.5))
	return P.ucuzlama_max * L / (L + P.ucuzlama_h)


## Kuresel olcegi istihdam ve kapasite hedefine baglar.
##
## Toplama SIRASI onemlidir: Python soldan saga topluyor ve float toplamasi
## birlesmeli degildir. D sirasi korunmali.
func init_simulation() -> void:
	var hedef_terimler := []
	var K_terimler := []
	for c in D:
		hedef_terimler.append(kappa_v(Formulas.organik_bilesim(c.q), c.q) * c.q * c.L_max
				* hedef_istihdam / P.u_normal)
		K_terimler.append(c.K)
	var hedef := Formulas.py_sum(hedef_terimler)

	var mevcut := Formulas.py_sum(K_terimler)
	if mevcut == 0.0:
		mevcut = 1.0
	K_olcek = hedef / mevcut

	if _K_carpani_override != null:
		K_carpani = _K_carpani_override

	for c in D:
		c.K *= K_olcek * K_carpani
		var kv := kappa_v(Formulas.organik_bilesim(c.q), c.q)
		c.Y = minf(c.K / kv, c.q * c.L_max) * P.u_normal
		c.Y_zirve = c.Y
		c.norm = P.tuketim_normu
		c.FX = P.fx_baslangic * c.Y
		c.Y_ort = c.Y
		c.Y_trend = c.Y


const KRIZ_ONCELIK := ["DEVRIM", "RESTORASYON", "BUYUK_BUNALIM", "DEVLET_COKUSU",
		"MORATORYUM", "FX_KRIZI", "MINSKY", "BORC_KRIZI",
		"PLAN_KITLIGI", "ASIRI_URETIM", "RESESYON"]


# ===========================================================================
# SENARYO ODALARI
# ===========================================================================

## Tarihsel/kurgusal bir baslangic durumunu yukler.
##
## YUKLEME SIRASI YUK TASIR ve kaynakta bir kez yanlisti:
##   1) YAPISAL ayarlar   -> cag, kurum, rejim, hegemonya, ittifak
##   2) init_simulation() -> K olcegi, Y, FX, norm YENIDEN kurulur
##   3) ORANSAL ayarlar   -> FX/Y, borc/Y, Omega, org, pay, kemer ...
## Oransal ayarlar 2. adimdan once yapilirsa `init_simulation` icindeki
## `c.FX = fx_baslangic*c.Y` satiri onlari sessizce eziyor: turkey_2001'in ana
## oncülü olan "rezerv tukenmis" (FX = 0.02*Y) hic yuklenmiyordu.
##
## `K_carpani` senaryonun BASLANGIC ISSIZLIGINI kuran degiskendir. Issizlik bu
## modelde yavas biriken bir stoktur ve 120 turluk oyun ufkunda kurumsal
## farklardan turetilemez; senaryo odalarinin isi zaten budur -- baslangic
## durumu turetilmez, KURULUR.
func load_scenario(isim: String, p_K_carpani = null) -> void:
	_log("SENARYO", "SENARYO ODASI YÜKLENDİ: %s" % isim.to_upper())
	# Kaynakta burada ayrica `random.seed(self.tohum)` var; o MODUL DUZEYI
	# jeneratoru tohumluyor ve motorda hicbir yerde okunmuyor (tarandi).
	# Islevsel olan tek satir bu:
	rng = PyRandom.new(tohum)
	_K_carpani_override = p_K_carpani

	match isim:
		"turkey_2001":
			# Türkiye 2001 krizi ve neoliberal gecis
			hedef_istihdam = 0.885      # kriz oncesi yuksek issizlik
			K_carpani = 0.50
			cag_ata(4)
			for c in D:
				c.kurum = "neoliberal"
				if c.ad == "ABD":
					c.hegemon = true
			init_simulation()
			for c in D:
				if c.ad == "Turkiye":
					c.dis_borc = 1.35       # limit sinirinda
					c.kamu_borc = 1.15      # kemer sikma sinirinda
					c.FX = 0.02 * c.Y       # rezerv tukenmis
					c.kemer = 40            # agir IMF butce kisiti aktif
					c.Omega = 0.45          # yuksek halk ofkesi
					c.org = 0.12            # orgutluluk zayif
					c.pay = 0.339           # ucret payi ezik
					c.baski_egilimi = 0.70  # polis gucu baskisi yuksek
				elif c.ad == "ABD":
					c.FX = 0.80 * c.Y

		"golden_age_1950":
			# Altin cag refah devleti (1945-1975)
			hedef_istihdam = 0.975      # tam istihdam taahhudu
			K_carpani = 1.70
			cag_ata(2)
			for c in D:
				c.kurum = "duzenli"
			init_simulation()
			for c in D:
				c.org = 0.72                # guclu isci sendikalari
				c.pay = 0.58                # emegin yuksek payi
				c.e = 0.97                  # tam istihdam
				c.e_norm = 0.96
				c.borc = 0.05 * c.Y         # dusuk hanehalki borcu
				c.varlik = 0.02 * c.Y       # sifira yakin spekulatif finans
				c.kamu_borc = 0.25
				c.PC = 1.0                  # yuksek demokratik mesruiyet

		"neoliberal_1995":
			# Neoliberal kuresellesme ve finansallasma (1995-2020)
			hedef_istihdam = 0.905      # yedek sanayi ordusu disiplin araci
			K_carpani = 0.45
			cag_ata(4)
			for c in D:
				c.kurum = "neoliberal"
			init_simulation()
			for c in D:
				c.org = 0.15                # sendikalar ezilmis
				c.pay = 0.38                # dusuk ucret payi
				c.borc = 0.60 * c.Y         # borcla gudumlenen tuketim
				c.varlik = 0.80 * c.Y       # spekulatif balonlar birikiyor
				c.PC = 0.85

		"socialist_siege":
			# Kusatilmis planli ekonomi (alternatif gelecek)
			hedef_istihdam = 0.935
			K_carpani = 1.30
			cag_ata(5)
			for c in D:
				c.kurum = "duzenli"
				if c.ad == "Rusya" or c.ad == "Cin" or c.ad == "Turkiye":
					c.rejim = "sosyalist"
					# Senaryo baslangici bir DEVRIM DEGILDIR. Onceden `devrim_t = 0`
					# atanip hem devrim sayisi sisiyor hem de ulke askeri mudahale
					# penceresine (0 < t-devrim_t <= 40) giriyordu.
					c.baslangic_rejimi_t = 0
				elif c.ad == "ABD" or c.ad == "Ingiltere" or c.ad == "Almanya":
					c.saldirganlik = 0.95   # emperyalist mudahale zirvede
					if not c.muttefik.has("ABD"):
						c.muttefik.append("ABD")
					if not c.muttefik.has("Ingiltere"):
						c.muttefik.append("Ingiltere")
			init_simulation()
			for c in D:
				if c.rejim == "sosyalist":
					c.pay = 0.65
					c.borc = 0.0
					c.varlik = 0.0
					c.PKE = 0.75

		_:
			push_error("Bilinmeyen senaryo: " + isim)


func _kur(c: Country, alan: String) -> float:
	return float(Tables.KURUMLAR[c.kurum][alan])


func _log(tip: String, mesaj: String) -> void:
	log.append([t, tip, mesaj])


# ===========================================================================
# YARDIMCILAR
# ===========================================================================

## Yerlesme hizi carpani: rejim/kurum ne kadar hizli hareket edebilir.
## Neoliberal devlet hizli (merkezilesmis yurutme), duzenli yavas (mutabakat).
func politika_hizi(c: Country) -> float:
	if c.rejim == "sosyalist":
		return P.pol_hiz_sosyalist
	match c.kurum:
		"liberal": return P.pol_hiz_liberal
		"duzenli": return P.pol_hiz_duzenli
		"neoliberal": return P.pol_hiz_neoliberal
	return 1.0


## Bir politikayi ILAN eder; etkisi `pol_gecikme` tur sonra baslar.
## Butun oyuncu API'si buradan gecer -- anlik durum degisikligi YOKTUR.
func politika_ilan(c: Country, ad: String, deger, gecikme = null) -> void:
	var g: int = P.pol_gecikme if gecikme == null else int(gecikme)
	c.pol_kuyruk[ad] = [deger, t + maxi(0, g)]


## Ilan edilmis politikalari gecikme dolunca yururluge koyar.
func politika_kuyrugu_isle(c: Country) -> void:
	if c.pol_kuyruk.is_empty():
		return
	for ad in c.pol_kuyruk.keys():
		var girdi: Array = c.pol_kuyruk[ad]
		if t >= int(girdi[1]):
			var deger = girdi[0]
			match ad:
				"etg": c.etg_hedef = float(deger)
				"etg_finansman": c.etg_sermaye_payi = float(deger)
				"plan": c.plan_hedef = deger
				"kurum_insa": c.kurum_insa_hedef = deger
				"kredi": c.kredi_durusu = float(deger)
				"yatirim": c.yatirim_durusu = float(deger)
				"ticaret": c.ticaret_durusu = float(deger)
			c.pol_kuyruk.erase(ad)


## Kriz birikimi ve sendikal orgutluluge gore kurumsal rejim gecisleri.
##
## Duzenli -> neoliberal donusumun kosulu "uretken sermaye finansal getiriyi
## yenemiyor"dur; dolayisiyla olcut i_reel DEGIL i_spec'tir.
func kurumsal_gecis_isle(c: Country) -> void:
	if c.rejim != "kapitalist" or t - c.kurum_t < P.kg_min_sure:
		return
	var son_bunalim := -9999
	if not c.bunalimlar.is_empty():
		son_bunalim = int(c.bunalimlar[-1][0])
	var taze_bunalim := (t - son_bunalim) >= 0 and (t - son_bunalim) <= P.kg_bunalim_penceresi

	var n := c.tarih.tur_sayisi()
	var bas := maxi(0, n - 60)
	var rli := 0.0
	if n > bas:
		var rs := c.tarih.seri("r")
		var isp := c.tarih.seri("i_spec")
		var say := 0
		for i in range(bas, n):
			if rs[i] < isp[i]:
				say += 1
		rli = float(say) / float(maxi(n - bas, 1))

	var derin := 0.0
	if not c.bunalimlar.is_empty():
		derin = float(c.bunalimlar[-1][2])
	var zorlayici := taze_bunalim and (c.Omega >= P.kg_omega_esigi or derin >= P.kg_derin_bunalim)

	var yeni := ""
	match c.kurum:
		"liberal":
			if taze_bunalim and (c.org >= P.kg_org_esigi or zorlayici):
				yeni = "duzenli"
		"duzenli":
			if rli >= P.kg_kar_esigi or c.stagflasyon >= P.kg_stagf_esigi:
				yeni = "neoliberal"
		"neoliberal":
			if taze_bunalim and (c.org >= P.kg_geri_donus_org or zorlayici):
				yeni = "duzenli"

	if yeni != "" and rng.random() < P.kg_olasilik:
		c.kurum_gecmis.append([t, c.kurum, yeni])
		_log("KURUM", "%s: Kurumsal rejim %s -> %s olarak değişti." % [c.ad, c.kurum, yeni])
		c.kurum = yeni
		c.kurum_t = t


## Devlet, huzursuzlugu esik altinda tutmak icin gereken ETG'yi arar.
## Mali fren gercektir: kamu borcu freni asarsa ETG artirilamaz -- "gereken"
## ile "finanse edilebilir" ayrisir; testin olcmek istedigi sey bu ayrismadir.
func can_simidi_isle(c: Country) -> void:
	if not P.cs_acik or c.rejim != "kapitalist":
		return
	var finanse_edilebilir := c.kamu_borc < P.cs_borc_freni
	if c.Omega > P.cs_omega_hedef and finanse_edilebilir:
		c.etg_hedef = minf(P.cs_tavan, c.etg_hedef + P.cs_adim)
		c.cs_kisit = 0
	elif c.Omega > P.cs_omega_hedef:
		c.cs_kisit = 1          # gerekiyor ama finanse edilemiyor
	else:
		c.etg_hedef = maxf(0.0, c.etg_hedef - P.cs_adim * 0.5)
		c.cs_kisit = 0


## Rakip ulkenin kurumsal rejimine gore politika secimi.
## Oyuncunun kullandigi API'nin AYNISINI kullanir; dogrudan sonuc degistirmez.
func politika_ai_isle(c: Country) -> void:
	if not P.ai_acik or c.ai_muaf:
		return
	if P.cs_acik and c.rejim == "kapitalist":
		return   # can simidi modu ETG'yi devralir
	# crc32 TESHIS DEGIL MEKANIZMADIR: her ulkenin AI'si hangi turda atesler,
	# onu bu belirler. Onceden `hash(c.ad)` kullaniliyordu ve PYTHONHASHSEED
	# yuzunden ayni tohum ayri sureclerde ayri sonuc uretiyordu.
	if (t + Crc32.of_string(c.ad) % P.ai_periyot) % P.ai_periyot:
		return

	var iss := 1.0 - c.e
	var sikinti := (iss > P.ai_iss_esigi) or (c.Omega > P.ai_omega_esigi)

	if c.rejim == "sosyalist":
		if c.kitlik > P.ai_kitlik_esigi or c.Omega > P.ai_omega_esigi:
			set_plan_profili("tuketimci", c.ad)
		elif c.savasta() or c.ambargo:
			set_plan_profili("sanayilesmeci", c.ad)
		else:
			set_plan_profili("dengeli", c.ad)
		return

	# Ek politika kollari: kredi, yatirim, dis ticaret.
	var kredi_hedef := 1.0
	var yat_hedef := 0.0
	var tic_hedef := 0.0
	match c.kurum:
		"neoliberal":
			kredi_hedef = 1.0 + (P.ai_kredi_bant if sikinti else 0.15)
			yat_hedef = -P.ai_yatirim_adim * 4
			tic_hedef = P.ai_ticaret_bant
		"duzenli":
			kredi_hedef = 1.0 - (0.20 if sikinti else P.ai_kredi_bant * 0.6)
			yat_hedef = P.ai_yatirim_adim * 4
			tic_hedef = -P.ai_ticaret_bant * 0.5
		"liberal":
			kredi_hedef = 1.0
			yat_hedef = 0.0
			tic_hedef = P.ai_ticaret_bant * 0.5

	for girdi in [["kredi", kredi_hedef, P.ai_kredi_adim],
			["yatirim", yat_hedef, P.ai_yatirim_adim],
			["ticaret", tic_hedef, P.ai_ticaret_adim]]:
		var ad: String = girdi[0]
		var hedef: float = girdi[1]
		var adim: float = girdi[2]
		var mevcut := 0.0
		match ad:
			"kredi": mevcut = c.kredi_durusu
			"yatirim": mevcut = c.yatirim_durusu
			"ticaret": mevcut = c.ticaret_durusu
		politika_ilan(c, ad, mevcut + maxf(-adim, minf(adim, hedef - mevcut)))

	if c.kurum == "duzenli":
		# Bolusumcu yatistirma: sikinti varsa temel geliri yukseltir.
		var hedef := c.etg_hedef + (P.ai_etg_adim if sikinti else -P.ai_etg_adim)
		if c.kamu_borc > P.kamu_borc_limiti:
			hedef -= P.ai_etg_adim
		c.etg_hedef = maxf(0.0, minf(P.ai_etg_tavan_duzenli, hedef))
	elif c.kurum == "neoliberal":
		# Karliligi korur: bolusumu sikar, ETG'yi asgaride tutar.
		var hedef := c.etg_hedef - P.ai_etg_adim
		if c.Omega > P.ai_omega_esigi + 0.2:
			hedef = c.etg_hedef + P.ai_etg_adim   # yalnizca patlama esiginde
		c.etg_hedef = maxf(0.0, minf(P.ai_etg_tavan_neoliberal, hedef))
		# AI liberal rejim INSA ETMEZ (Clarke): neoliberal devlet mudahale
		# aygitini sokmez, piyasa disiplinini dayatmak icin yeniden yapilandirir.
		# Liberal insa yalnizca OYUNCUYA acik bir siyasi projedir.
	else:
		c.etg_hedef = 0.0


## Yalniz kalmis sosyalist ekonominin iki yolu (restorasyon / Cin yolu).
func izolasyon_sapmasi_isle(c: Country) -> void:
	if c.rejim != "sosyalist":
		c.izo_sayac = 0
		return
	var blok := 0
	for x in D:
		if x.rejim == "sosyalist":
			blok += 1
	var yalniz := blok <= P.izo_blok_esigi
	var baski_altinda := c.abluka != 0 or c.ambargo or c.savasta()
	if yalniz and baski_altinda and c.kitlik > P.izo_kitlik_esigi:
		c.izo_sayac += 1
	else:
		c.izo_sayac = maxi(0, c.izo_sayac - 1)
	if c.izo_sayac < P.izo_sure:
		return

	c.izo_sayac = 0
	c.restorasyon_t = t
	c.rejim = "kapitalist"
	c.kitlik = 0.0
	c.plan_hedef = null
	if c.baski_egilimi >= P.izo_baski_esigi:
		# (b) Cin yolu: parti iktidarda kalir, ekonomi kapitalistlesir.
		c.parti_iktidari = true
		c.kurum = "neoliberal"
		_log("PIYASA SOS.", "%s: parti iktidari korudu ama kapitalist birikime kapilari acti (piyasa sosyalizmi)." % c.ad)
	else:
		# (a) Restorasyon: kitlik rejimi dusurdu.
		c.parti_iktidari = false
		c.kurum = "liberal"
		c.Omega = minf(1.0, c.Omega + 0.20)
		_log("RESTORASYON", "%s: kusatma ve kitlik altinda sosyalist rejim cokti, kapitalizm restore edildi." % c.ad)


## Dunya devrimi: enternasyonal dayanisma + kapitalizmin genel krizi.
## Hasila sarti YOKTUR. Tetiklendiginde abluka, ambargo ve deger transferi
## KALICI olarak sona erer.
func dunya_devrimi_isle() -> void:
	var sos: Array[Country] = []
	var piyasa: Array[Country] = []
	var kap: Array[Country] = []
	for c in D:
		if c.rejim == "sosyalist":
			sos.append(c)
		if c.parti_iktidari:
			piyasa.append(c)
		if c.rejim == "kapitalist" and not c.parti_iktidari:
			kap.append(c)

	var pakt_var := sos.size() >= P.dd_pakt_esigi
	var ittifakta := 0
	for c in sos:
		if c.pakt_durusu != "rekabet":
			ittifakta += 1
	pakt_uyumu = float(ittifakta) / float(maxi(sos.size() + piyasa.size(), 1))
	var dayanisma := pakt_var and pakt_uyumu >= P.dd_uyum_esigi

	var krizde_say := 0
	for c in kap:
		if (c.Omega > P.dd_omega_esigi or c.bun_ici > 0
				or (c.delev > 0 and (1.0 - c.e) > P.dd_iss_esigi)):
			krizde_say += 1
	kap_kriz_payi = (float(krizde_say) / float(kap.size())) if not kap.is_empty() else 0.0
	var genel_kriz := kap_kriz_payi >= P.dd_kriz_esigi

	if dayanisma and genel_kriz:
		dd_sayac += 1
	else:
		dd_sayac = maxi(0, dd_sayac - 1)

	if dd_sayac >= P.dd_sure and not dunya_devrimi:
		dunya_devrimi = true
		_log("DUNYA DEVRIMI", "Sosyalist pakt (%d ulke, uyum %%%.0f) ile kapitalizmin genel krizi (%%%.0f) ortusdu. Abluka ve deger transferi sona erdi."
				% [sos.size(), pakt_uyumu * 100, kap_kriz_payi * 100])
	if dunya_devrimi:
		for c in D:
			c.abluka = 0
			c.ambargo = false
			c.VT_net = 0.0


## Kasitli kurumsal insa (Polanyi: "laissez-faire planlandi").
## Endojen gecisten farkli olarak bu bir SIYASI PROJEDIR: yuksek siyasi sermaye
## gerektirir, onu tuketir. Liberal rejime ulasmanin TEK yolu budur.
func kurumsal_insa_isle(c: Country) -> void:
	var hedef = c.kurum_insa_hedef
	if hedef == null or hedef == c.kurum or c.rejim != "kapitalist":
		return
	if t - c.kurum_insa_t < P.ki_min_sure:
		return
	if c.PC < P.ki_pc_esigi:
		return
	c.PC = maxf(0.0, c.PC - P.ki_pc_maliyet)
	c.kurum_gecmis.append([t, c.kurum, hedef])
	_log("KURUM", "%s: %s -> %s rejimi siyasi proje olarak İNŞA EDİLDİ." % [c.ad, c.kurum, hedef])
	c.kurum = hedef
	c.kurum_t = t
	c.kurum_insa_t = t
	c.kurum_insa_hedef = null


## Sosyalist plan profilini belirler. Paylar RAKIP kullanimlardir: biri artarsa
## digeri azalir. Bir POLITIKA HEDEFIDIR, anlik durum degisikligi degil.
func set_plan_profili(profil, ulke = null) -> void:
	var p: Dictionary = (Tables.PLAN_PROFILLERI[profil] if profil is String else profil)
	var top_terimler := []
	for k in p:
		top_terimler.append(maxf(0.0, float(p[k])))
	var top := Formulas.py_sum(top_terimler)
	if top == 0.0:
		top = 1.0
	var norm := {}
	for k in p:
		norm[k] = maxf(0.0, float(p[k])) / top
	for c in D:
		if ulke == null or c.ad == ulke:
			politika_ilan(c, "plan", norm.duplicate())


func set_pakt_durusu(durus: String, ulke = null) -> void:
	assert(durus == "ittifak" or durus == "rekabet")
	for c in D:
		if ulke == null or c.ad == ulke:
			c.pakt_durusu = durus


func set_etg_finansman(sermaye_payi: float, ulke = null) -> void:
	for c in D:
		if ulke == null or c.ad == ulke:
			politika_ilan(c, "etg_finansman", maxf(0.0, minf(1.0, sermaye_payi)))


func set_kurumsal_insa(kurum: String, ulke = null) -> void:
	assert(Tables.KURUMLAR.has(kurum))
	for c in D:
		if ulke == null or c.ad == ulke:
			politika_ilan(c, "kurum_insa", kurum)


## ETG politikasini belirler (hasila orani olarak hedef).
## Sosyalist rejimde yok sayilir: planli ekonomide ucret zaten planla belirlenir.
func set_temel_gelir(oran: float, ulke = null) -> void:
	for c in D:
		if ulke == null or c.ad == ulke:
			politika_ilan(c, "etg", maxf(0.0, minf(0.40, oran)))


## Bir ulkeyi oyuncuya devreder: politika AI'si ona dokunmaz.
func oyuncu_ulkesi(ad: String) -> void:
	for c in D:
		c.ai_muaf = (c.ad == ad)


## Iki ulke arasinda savas baslatir.
func ilan(a: Country, b: Country, sebep: String) -> void:
	var sure := rng.randint(P.sv_min_sure, P.sv_max_sure)
	a.savas[b.ad] = sure
	b.savas[a.ad] = sure
	a.savas_sayisi += 1
	b.savas_sayisi += 1
	_log("SAVAS", "%s ile %s arasinda savas patlak verdi! Sebep: %s" % [a.ad, b.ad, sebep])

	for m_ad in a.muttefik.duplicate():
		var m: Country = null
		for x in D:
			if x.ad == m_ad:
				m = x
				break
		if m != null and not m.savasta() and rng.random() < 0.5:
			m.savas[b.ad] = sure
			b.savas[m.ad] = sure
			m.savas_sayisi += 1
			b.savas_sayisi += 1


## Karlilik sikismasi ve saldirganlik parametrelerine gore otonom savas kararlari.
func savas_karari() -> void:
	var kap: Array[Country] = []
	var sos: Array[Country] = []
	for c in D:
		if c.rejim == "kapitalist":
			kap.append(c)
		elif c.rejim == "sosyalist":
			sos.append(c)

	# Sosyalist blok buyudukce kapitalist merkezin mudahale istegi buyur.
	var blok_pay := float(sos.size()) / float(maxi(D.size(), 1))
	var tehdit_carpani := 1.0 + P.sv_blok_tehdidi * blok_pay
	for s in sos:
		if s.devrim_t == null or s.savasta():
			continue
		var gecen: int = t - int(s.devrim_t)
		if not (gecen > 0 and gecen <= P.sv_mudahale_pencere):
			continue
		for m in kap:
			if m.tip != "merkez" or m.savasta():
				continue
			var istek := (P.sv_mudahale * m.saldirganlik * tehdit_carpani
					* (1.0 if m.guc() > s.guc() * 0.8 else 0.3))
			if rng.random() < istek * P.sv_carpan * 0.10:
				ilan(m, s, "emperyalist mudahale")
				break

	for c in kap:
		if c.savasta():
			continue
		var sikisma := maxf(0.0, (P.sv_r_ref - c.r) / P.sv_r_ref)
		var kaynak := P.sv_kaynak if c.era >= 3 else 0.0
		var p := (P.sv_taban + P.sv_kar_baskisi * sikisma + kaynak
				+ P.sv_doktrin * c.saldirganlik) * c.saldirganlik
		if rng.random() < p * 0.06 * P.sv_carpan:
			var adaylar: Array[Country] = []
			for x in D:
				if x != c and not c.muttefik.has(x.ad) and not x.savasta() and x.guc() < c.guc() * 1.15:
					adaylar.append(x)
			if not adaylar.is_empty():
				# max(..., key=...) Python'da ILK azami ogeyi tutar; skor her
				# aday icin rng cektigi icin cekilis sirasi da korunmali.
				var en_iyi: Country = null
				var en_skor := -INF
				for x in adaylar:
					var skor := (x.L_max * x.q) / maxf(x.guc(), 1.0) + rng.random() * 0.4
					if skor > en_skor:
						en_skor = skor
						en_iyi = x
				ilan(c, en_iyi, "pazar ve hammadde arayisi")


## Aktif savaslarin fiziksel altyapi hasarlari ve rejim mesruiyet etkileri.
func savas_yikim_isle() -> void:
	var ad2c := {}
	for c in D:
		ad2c[c.ad] = c
	for c in D:
		if not c.savasta():
			continue
		c.savas_toplam += 1
		for rk in c.savas.keys():
			c.savas[rk] = int(c.savas[rk]) - 1
			if int(c.savas[rk]) <= 0:
				var rakip: Country = ad2c.get(rk, null)
				if rakip != null:
					var oran := c.guc() / maxf(c.guc() + rakip.guc(), 1e-6)
					if oran < 0.42:
						c.Omega = minf(1.0, c.Omega + P.sv_yenilgi_omega)
						c.K *= 0.94
						_log("YENILGI", "%s savasi kaybetti. Toplumsal gerilim patladi." % c.ad)
					var _ezildi := oran < P.kd_yenilgi_orani
					var _ic_cokus := c.PKE < P.kd_pke_esigi
					if (c.rejim == "sosyalist" and rakip.rejim == "kapitalist"
							and ((_ezildi and rng.random() < P.kd_askeri_olasilik)
								or (_ic_cokus and rng.random() < P.kd_olasilik))):
						c.rejim = "kapitalist"
						c.Omega = 0.10
						c.org *= 0.5
						c.devrim_t = null
						c.devrim_era = null
						c.pay = maxf(0.15, c.pay * 0.75)
						c.IR = 0.75
						c.muttefik.clear()
						_log("KARSI-DEVRIM", "%s rejiminde kapitalizm zorla restore edildi!" % c.ad)
				c.savas.erase(rk)


## Sosyalist ve kapitalist bloklarin diplomatik ittifaklarini gunceller.
func ittifak_isle() -> void:
	var sos: Array[Country] = []
	for c in D:
		if c.rejim == "sosyalist":
			sos.append(c)

	if not sos.is_empty():
		var anahtar := ["yatirim", "tuketim", "arge", "savunma"]
		var ort := {}
		for k in anahtar:
			var terimler := []
			for c in sos:
				terimler.append(float(c.plan[k]))
			ort[k] = Formulas.py_sum(terimler) / float(sos.size())
		for c in sos:
			var d_terimler := []
			for k in anahtar:
				d_terimler.append(absf(float(c.plan[k]) - float(ort[k])))
			c.ideolojik_mesafe = Formulas.py_sum(d_terimler) / 2.0
			# AI ulkeler mesafeye gore durus alir; oyuncunun ulkesi muaf.
			if not c.ai_muaf and rng.random() < P.pakt_durus_hiz:
				c.pakt_durusu = ("rekabet" if c.ideolojik_mesafe > P.pakt_mesafe_esigi
						else "ittifak")

	# Rekabet halindeki sosyalist ulkeler birbirinin muttefiki OLMAZ.
	for a in sos:
		if a.pakt_durusu == "rekabet":
			a.muttefik = []
		else:
			var yeni: Array = []
			for b in sos:
				if b != a and b.pakt_durusu != "rekabet":
					yeni.append(b.ad)
			a.muttefik = yeni

	var kap: Array[Country] = []
	for c in D:
		if c.rejim == "kapitalist":
			kap.append(c)
	var tehdit := float(sos.size()) / float(maxi(D.size(), 1))
	for a in kap:
		if tehdit > P.it_esik:
			for b in kap:
				if b == a:
					continue
				if (a.tip == "merkez" and b.tip == "merkez" and a.era == b.era
						and a.saldirganlik > 0.6 and b.saldirganlik > 0.6):
					continue
				if rng.random() < tehdit * 0.02:
					if not a.muttefik.has(b.ad):
						a.muttefik.append(b.ad)
					if not b.muttefik.has(a.ad):
						b.muttefik.append(a.ad)
		if rng.random() < P.it_kopma and not a.muttefik.is_empty():
			a.muttefik.erase(rng.choice(a.muttefik))


## Sinifsal bloklara gore dis ticaret ablukasi ve ambargolari gunceller.
func abluka_ambargo_isle() -> void:
	var sos: Array[Country] = []
	var kap: Array[Country] = []
	for c in D:
		if c.rejim == "sosyalist":
			sos.append(c)
		elif c.rejim == "kapitalist":
			kap.append(c)
	for c in D:
		c.abluka = 0
		c.ambargo = false

	if sos.size() >= P.amb_sos_esigi and not kap.is_empty():
		var mrk := 0
		for m in kap:
			if m.tip == "merkez" and m.saldirganlik > 0.4:
				mrk += 1
		for s in sos:
			s.ambargo = true
			s.abluka = mrk

	for c in D:
		if c.savasta():
			c.abluka += c.savas.size()


## Her ulke icin coklu olay bayragi + TEK birincil kriz nedeni uretir.
## Bir ulke ayni turda resesyon + Minsky + FX krizi yasayabilir; frekanslar
## cakismasin diye `birincil_kriz` karsilikli dislayicidir.
func kriz_siniflandir() -> void:
	for c in D:
		# Anahtar SIRASI onemli: ikincil bayrak listesi bu sirayla uretiliyor.
		var b := {
			"RESESYON": not c.resesyonlar.is_empty() and int(c.resesyonlar[-1][0]) == t,
			"ASIRI_URETIM": not c.asiri_uretim_krizleri.is_empty() and int(c.asiri_uretim_krizleri[-1][0]) == t,
			"BUYUK_BUNALIM": not c.bunalimlar.is_empty() and int(c.bunalimlar[-1][0]) == t,
			"FX_KRIZI": not c.fx_krizleri.is_empty() and int(c.fx_krizleri[-1]) == t,
			"MORATORYUM": not c.moratoryumlar.is_empty() and int(c.moratoryumlar[-1]) == t,
			"DEVLET_COKUSU": not c.temerrutler.is_empty() and int(c.temerrutler[-1]) == t,
			"DEVRIM": c.devrim_t != null and int(c.devrim_t) == t,
			"RESTORASYON": c.restorasyon_t != null and int(c.restorasyon_t) == t,
			"PLAN_KITLIGI": c.rejim == "sosyalist" and c.kitlik > P.izo_kitlik_esigi,
			"MINSKY": false,
			"BORC_KRIZI": false,
		}
		var bas := maxi(0, log.size() - 12)
		for i in range(bas, log.size()):
			var kayit: Array = log[i]
			if int(kayit[0]) == t and String(kayit[1]) == "COKME" and String(kayit[2]).contains(c.ad):
				var g := String(kayit[2]).to_upper()
				if g.contains("MINSKY"):
					b["MINSKY"] = true
				elif g.contains("BORC"):
					b["BORC_KRIZI"] = true
		c.olay_bayraklari = b
		c.birincil_kriz = null
		for k in KRIZ_ONCELIK:
			if b.get(k, false):
				c.birincil_kriz = k
				break
		if c.birincil_kriz != null:
			var ikincil: Array = []
			for k in b:
				if b[k] and k != c.birincil_kriz:
					ikincil.append(k)
			c.kriz_gunlugu.append([t, c.birincil_kriz, ikincil])


func run_simulation(turlar: int = 1200) -> void:
	for _i in range(turlar):
		step()


# ===========================================================================
# BIR TUR
# ---------------------------------------------------------------------------
# SIRA RASTGELE DEGILDIR, nedensellik zincirini o belirler. Iki nokta kritik:
#   * O blogu (teknoloji) P ve Q'dan ONCE calisir; hem Phillips hem Goodwin
#     GERCEKLESEN verimlilik artisina ihtiyac duyar.
#   * Karanlik devlet blogu deger gasbindan once calisir ama `c.r` bir onceki
#     turun degeriyle okunur -- bir turluk gecikme KASITLIDIR: devlet politikasi
#     gozlemlenmis karliliga tepki verir.
# ===========================================================================
func step() -> void:
	# 1. Uluslararasi ittifaklar ve ambargolar
	ittifak_isle()
	abluka_ambargo_isle()
	# Dunya devrimi bir kez tetiklendiginde abluka/ambargo/deger transferini
	# kalici olarak kapatir; bu yuzden abluka isleminden HEMEN SONRA calisir.
	dunya_devrimi_isle()
	savas_karari()

	# 2. Kurumsal rejimlerin kontrolu
	for c in D:
		politika_kuyrugu_isle(c)
		izolasyon_sapmasi_isle(c)
		kurumsal_gecis_isle(c)
		can_simidi_isle(c)
		politika_ai_isle(c)
		kurumsal_insa_isle(c)

	var blok := 0
	for c in D:
		if c.rejim == "sosyalist":
			blok += 1

	# 3. Hegemonya ve rezerv para birimi
	var kap_ler: Array[Country] = []
	for c in D:
		if c.rejim == "kapitalist":
			kap_ler.append(c)
	if not kap_ler.is_empty():
		var mevcut: Country = null
		for c in D:
			if c.hegemon:
				mevcut = c
				break
		var aday: Country = kap_ler[0]
		for c in kap_ler:
			if c.guc() > aday.guc():
				aday = c
		if mevcut == null or mevcut.rejim != "kapitalist":
			for c in D:
				c.hegemon = false
			aday.hegemon = true
			aday.heg_sayac = 0
			_log("HEGEMONYA", "%s rezerv para statusunu kazandi." % aday.ad)
		elif aday != mevcut and aday.guc() > mevcut.guc() * P.heg_esik:
			aday.heg_sayac += 1
			if aday.heg_sayac >= P.heg_sure:
				mevcut.hegemon = false
				aday.hegemon = true
				aday.heg_sayac = 0
				_log("HEGEMONYA", "%s küresel para unvanini %s'dan devraldi." % [aday.ad, mevcut.ad])
		else:
			aday.heg_sayac = maxi(0, aday.heg_sayac - 1)

	# Dunya ortalamalari: esitsiz mubadele ve Thirlwall karsilastirmalarinin capasi.
	var Yv := {}
	for c in D:
		Yv[c.ad] = minf(c.K / kappa_v(Formulas.organik_bilesim(c.q) * c.deger_carpani, c.q),
				c.q * c.l_etkin())
	# Butun dunya toplamlari `Formulas.py_sum` ile alinir: CPython 3.12'nin
	# `sum()`'i float'lar icin Neumaier telafili toplama yapiyor ve naif
	# toplamayla ayni sonucu vermiyor (bkz. formulas.gd).
	var Yv_terimler := []
	var cv_terimler := []
	var sv_terimler := []
	var q_terimler := []
	var y_terimler := []
	for c in D:
		Yv_terimler.append(float(Yv[c.ad]))
		cv_terimler.append(Formulas.organik_bilesim(c.q) * c.deger_carpani * float(Yv[c.ad]))
		sv_terimler.append((1.0 / maxf(c.pay, 0.05) - 1.0) * float(Yv[c.ad]))
		q_terimler.append(c.q * float(Yv[c.ad]))
		y_terimler.append(c.y_buyume)

	var top := Formulas.py_sum(Yv_terimler)
	if top == 0.0:
		top = 1e-6
	var ort_cv := Formulas.py_sum(cv_terimler) / top
	var ort_sv := Formulas.py_sum(sv_terimler) / top
	var ort_q := Formulas.py_sum(q_terimler) / top
	var y_dunya := 0.02
	if t > 0:
		y_dunya = Formulas.py_sum(y_terimler) / float(D.size())

	# 4. Ajan bazli makro akislar
	for c in D:
		var E: Dictionary = Tables.ERAS[c.era]
		# Deger bilesimi = teknik bilesim x kriz devaluasyonu. Deger carpani her
		# tur yavasca 1.0'a doner (yeni yatirimlar eski deger duzeyini yeniden
		# kurar), krizlerde asagi sicrar.
		c.deger_carpani = minf(1.0, c.deger_carpani + P.dev_geri * (1.0 - c.deger_carpani))
		if c.savasta():
			c.deger_carpani = maxf(P.dev_taban, c.deger_carpani * (1.0 - P.dev_savas))
		var cv := Formulas.organik_bilesim(c.q) * c.deger_carpani
		var kv := kappa_v(cv, c.q)
		var Y_onceki := c.Y

		# --- A. Merkez bankasi: Taylor kurali + balon/kriz duyarliligi ---
		var varlik_o := c.varlik / maxf(c.Y, 1e-6)
		var kriz_sinyal := 1.0 if (c.delev > 0 or c.r < P.r_kriz_esigi or c.fx_kriz > 0) else 0.0
		var i_hedef := (P.i_notr + P.tay_pi * (c.pi_inf - P.pi_hedef)
				+ P.tay_u * (c.u - P.u_normal) + P.tay_e * (c.e - P.e0)
				+ P.tay_balon * maxf(0.0, varlik_o - 1.0)
				- P.tay_kriz * kriz_sinyal)
		c.i_pol = maxf(P.i_min, minf(P.i_max, P.tay_atalet * c.i_pol + (1.0 - P.tay_atalet) * i_hedef))

		# --- B. Dis ticaret & Thirlwall BoPC kisiti ---
		# Lumpenlesme endojen esneklikleri negatif yonde donusturur: nitelik
		# birikimi kaybi ihracat gelir esnekligini dusurur, ithalat bagimliligini
		# artirir; BoP-kisitli buyume dogrudan daralir.
		var q_rel := c.q / maxf(ort_q, 1e-6)
		c.eps = (P.eps0 * (0.45 + P.eps_q * minf(q_rel, 2.2))
				* (1.0 + P.eps_vt * maxf(0.0, c.VT_net / maxf(c.Y, 1e-6))) * (1.0 + c.deval)
				* (1.0 - P.eps_lumpen * c.lumpen_pay))
		c.pi_m = maxf(0.35, P.pi0 * (1.45 - P.pi_q * minf(q_rel, 2.0)) * (1.0 + P.pi_lumpen * c.lumpen_pay))
		if c.rejim == "sosyalist":
			c.pi_m *= 0.85   # sosyalist ithal ikamesi

		var y_max := c.eps * maxf(y_dunya, 0.0) / maxf(c.pi_m, 0.2)
		var asim := c.y_buyume - y_max
		var muaf := P.heg_muafiyet if c.hegemon else 0.0
		c.BoP_R = Formulas.sg(P.kappa_B * asim * 8.0) * (1.0 - muaf)
		c.i_ham = c.i_pol * (1.0 + c.BoP_R + (P.mor_ceza_prim if c.mor_ceza > 0 else 0.0))
		# Uretken yatirimin esik getirisi -- Marx III/22 tavani BURAYA.
		c.i_reel = minf(c.i_ham, P.faiz_kar_tavani * maxf(c.r, 0.0) + P.faiz_taban_marj)
		# Spekulatif finansman maliyeti -- TAVANSIZ.
		c.i_spec = c.i_ham
		c.i_ef = c.i_reel

		# --- C. Cari acik sizintisi & uluslararasi deger transferi ---
		var ihr_carpani := (1.0 - P.ab_vt * float(mini(c.abluka, 3)) / 3.0) if c.abluka else 1.0
		var aciklik_ef := maxf(0.05, P.ticaret_aciklik + c.ticaret_durusu)
		c.cari = (-P.cari_kats * _kur(c, "sermaye_hareketi") * aciklik_ef * c.Y * asim * 4.0 * (1.0 - muaf)
				+ 0.30 * c.VT_net) * ihr_carpani
		c.FX += c.cari

		# --- D. Ani durus & dis borclanma tikaci ---
		if c.dis_borc > P.dis_borc_tavani or c.mor_ceza > 0:
			c.cari = maxf(c.cari, 0.006 * c.Y)
			if c.fx_kriz == 0 and c.dis_borc > P.dis_borc_tavani:
				c.fx_kriz = maxi(c.fx_kriz, 12)

		var db_carpan := maxf(0.97, minf(1.020, 1.0 + c.i_ef - maxf(c.y_buyume, -0.02)))
		c.dis_borc = maxf(0.0, minf(P.borc_orani_tavani, c.dis_borc * db_carpan - c.cari / maxf(c.Y, 1e-6)))

		# --- E. Borc yapilandirma & moratoryum (Meksika '82, Arjantin '01) ---
		var db_orani := c.dis_borc
		if (db_orani > P.mor_borc_esigi and c.fx_kriz > 0 and c.mor_ceza == 0
				and c.rejim == "kapitalist" and rng.random() < 0.20):
			c.dis_borc *= (1.0 - P.mor_kesinti)
			c.mor_ceza = P.mor_ceza_sure
			c.moratoryumlar.append(t)
			_log("MORATORYUM", "%s dis borclarini yapilandirdi. Oran: %.2f" % [c.ad, db_orani])

		if c.mor_ceza > 0:
			c.mor_ceza -= 1
			c.BoP_R = minf(1.0, c.BoP_R + P.mor_ceza_prim)

		c.deval = maxf(0.0, c.deval - P.deval_sonum)

		# --- F. Rezerv erimesi ve doviz krizi (Tip C) ---
		c.fx_baski = (c.fx_baski + 1) if c.FX < -0.04 * c.Y else 0
		if c.fx_baski >= 8 and c.fx_kriz == 0 and c.rejim == "kapitalist":
			c.fx_kriz = P.fx_kriz_sure
			c.FX = 0.06 * c.Y
			c.deval = P.devaluasyon
			c.borc *= 1.12
			c.fx_krizleri.append(t)
			c.fx_baski = 0
			_log("DOVIZ KRIZI", "%s odemeler dengesi krizine girdi! Para birimi coktu." % c.ad)

		if c.fx_kriz > 0:
			c.fx_kriz -= 1

		# --- G. Arz kapasitesi + OTOMASYON ---
		var Y_K := c.K / kv
		# Otomasyon stoku cag 5'ten itibaren, mekanizasyon durtusu olcusunde
		# birikir. Bu bir POLITIKA degil, rekabetin zorlayici yasasinin sonucu:
		# duran geride kalir.
		if c.era >= P.oto_esik_era:
			var hedef_oto := P.oto_tavan * minf(1.0, c.ito / P.ito_tavan) * minf(
					1.0, float(c.era - P.oto_esik_era + 1) / 2.0)
			c.oto += P.oto_hiz * (hedef_oto - c.oto)
		c.oto = maxf(0.0, minf(P.oto_tavan, c.oto))

		# Fiili emek girdisi: cag normu x paylasim payi. hafta_norm cag
		# ilerledikce dustugu icin ayni istihdam daha az emek-saati verir.
		var canli_emek := c.l_etkin() * c.hafta_saati(P)
		# Robotlar FIZIKSEL uretime katilir; emek esdegeri olarak olculur.
		var robot_esdeger := P.oto_verim * c.oto * c.K / maxf(c.q, 1e-6)
		var emek_esdeger := canli_emek + robot_esdeger
		# Canli emegin fiziksel hasiladaki payi -- YENI DEGERIN olcusu budur.
		c.canli_pay = maxf(P.oto_canli_taban, canli_emek / maxf(emek_esdeger, 1e-9))
		var Y_L := c.q * emek_esdeger
		var Y_pot := (minf(Y_K, Y_L) * (1.0 - minf(P.ab_uretim * c.abluka, 0.45))
				* (1.0 - (P.fx_kriz_uretim if c.fx_kriz > 0 else 0.0)))

		# --- H. Efektif talep & borclanma siniri (Clarke & Fisher) ---
		var etg_ucret_kesinti := P.etg_vergi_ucret * c.etg_vergi_ucret_o
		# Satinalma gucu YENI DEGERDEN gelir (ucretler + kar), fiziksel hasiladan
		# degil. Otomasyon ilerledikce Y buyur ama V kucuulur: kronik asiri
		# uretim / gerceklesme krizi bu makastan dogar.
		var V_onceki := maxf(c.V_yeni, c.Y * c.canli_pay)
		var C_temel := (P.c_ucret * c.pay * V_onceki * maxf(0.15, 1.0 - _kur(c, "v_ucret") - etg_ucret_kesinti)
				+ P.c_kar * (1.0 - c.pay) * V_onceki * (1.0 - _kur(c, "v_kar")))
		var gerceklesen_oran := C_temel / maxf(c.Y, 1e-6)
		var hedef_norm := P.norm_agirlik * P.tuketim_normu + (1.0 - P.norm_agirlik) * gerceklesen_oran
		c.norm += P.norm_uyum * (hedef_norm - c.norm)
		c.norm = maxf(P.gecim_tabani, minf(P.norm_tavan, c.norm))
		var hedef_tuketim := c.norm * c.Y
		var acik := maxf(0.0, hedef_tuketim - C_temel)

		var yeni_kredi := 0.0
		if c.rejim == "kapitalist" and c.delev == 0:
			# Kredi istahi borc oranina gore soner: borc limite yaklastikca yeni
			# kredi kurur, borc orani limitin ALTINDA asimptot yapar.
			var kredi_istahi := maxf(0.0, 1.0 - pow(c.borc / maxf(c.Y, 1e-6) / P.borc_limiti, P.kredi_us))
			yeni_kredi = (P.kredi_egilimi * _kur(c, "kredi")
					* maxf(0.0, c.kredi_durusu) * acik * kredi_istahi)
			c.borc += yeni_kredi

		if c.delev > 0:
			c.borc = maxf(0.0, c.borc * (1.0 - P.delev_hiz))
			c.delev -= 1

		var borc_servisi := (c.i_ef + P.borc_faizi_marj) * Formulas.TUR_YIL * c.borc
		var C := C_temel + yeni_kredi - borc_servisi
		var I := maxf(0.0, (c.g + P.delta_K) * c.K) * (1.0 - (P.delev_yatirim_soku if c.delev > 0 else 0.0))

		# --- I. Kamu maliyesi, vergi & kemer sikma ---
		c.etg_vergi_sermaye_o = P.etg_maliyet * c.etg * c.etg_sermaye_payi
		c.etg_vergi_ucret_o = P.etg_maliyet * c.etg * (1.0 - c.etg_sermaye_payi)
		var v_ucret_ef := _kur(c, "v_ucret") + c.etg_vergi_ucret_o / maxf(c.pay, 0.05)
		var v_kar_ef := _kur(c, "v_kar") + c.etg_vergi_sermaye_o / maxf(1.0 - c.pay, 0.05)
		c.vergi_geliri = (minf(0.85, v_ucret_ef) * c.pay + minf(0.90, v_kar_ef) * (1.0 - c.pay)) * c.Y
		var taban_hasila := maxf(c.Y_trend, Y_pot)
		# Karseral harcama butcenin bir kalemidir (el kitabi Bolum 5: "sosyal
		# yatirimlarin yerini guvenlik harcamalarina birakmasi").
		var G_arzu := taban_hasila * (float(P.devlet_pay[c.era - 1]) * _kur(c, "devlet")
				+ P.issizlik_sigortasi * maxf(0.0, (1.0 - c.e) - 0.05)
				+ P.karseral_maliyet * c.cezaevi_orani
				+ P.etg_maliyet * c.etg
				+ ((P.devlet_kriz * float(Tables.KURUMLAR[c.kurum].get("kars_dongusel", 1.0)))
					if (c.delev > 0 or c.r < P.r_kamu_kriz) else 0.0))

		c.vergi_carpani += 0.030 * (c.kamu_borc - 0.55)
		c.vergi_carpani = maxf(0.70, minf(2.20, c.vergi_carpani))
		c.vergi_geliri *= c.vergi_carpani

		if c.kamu_borc > P.kamu_borc_limiti:
			c.kemer = 40
		if c.kemer > 0:
			G_arzu *= (1.0 - P.kemer_siddeti)
			c.kemer -= 1
		var G := G_arzu

		var birincil := (G - c.vergi_geliri) / maxf(c.Y, 1e-6)
		var kb_carpan := maxf(0.97, minf(1.020, 1.0 + c.i_ef - maxf(c.y_buyume, -0.02)))
		c.kamu_borc = maxf(0.0, minf(P.borc_orani_tavani, c.kamu_borc * kb_carpan + birincil))

		# Kamu iflasi / temerrut
		if c.kamu_borc > P.kamu_temerrut and rng.random() < 0.02:
			c.kamu_borc *= (1.0 - P.mor_kesinti)
			c.mor_ceza = P.mor_ceza_sure
			c.vergi_carpani = minf(2.20, c.vergi_carpani + 0.15)
			c.temerrutler.append(t)
			_log("TEMERRUT", "%s kamu borclarini odeyemedi! İflas ilan edildi." % c.ad)

		var D_talep := C + I + G + maxf(c.VT_net, 0.0)
		if c.savasta():
			D_talep = maxf(D_talep, Y_pot * 0.95)

		# ASIRI URETIM: Y_pot ile efektif talep arasindaki HAM acik.
		c.talep_acigi = maxf(0.0, (Y_pot - D_talep) / maxf(Y_pot, 1e-9))

		var Y := 0.0
		if c.rejim == "sosyalist":
			# Sosyalist rejimde hasila PLANA gore belirlenir, efektif talebe gore
			# degil. Gerceklesme krizi kapitalizme ozgudur; planli ekonominin
			# kendi kriz bicimi kitliktir.
			Y = Y_pot * minf(0.99, P.plan_kullanim + P.plan_pke_kullanim * c.PKE)
		else:
			Y = minf(Y_pot, maxf(D_talep, Y_pot * P.gecim_tabani))

		c.Y = Y
		c.Y_zirve = maxf(c.Y_zirve, Y)
		c.y_buyume = 0.85 * c.y_buyume + 0.15 * ((Y - Y_onceki) / maxf(Y_onceki, 1e-6))
		c.u = maxf(0.20, minf(1.0, Y / maxf(Y_K, 1e-9)))

		if c.savasta():
			c.u = minf(1.0, c.u + P.sv_seferberlik)

		if c.rejim == "sosyalist":
			var gereken_saat := (Y / c.q) / maxf(
					c.l_etkin() * P.plan_istihdam * float(P.hafta_norm[mini(c.era, 6) - 1]), 1e-9)
			c.saat = maxf(c.saat_tabani(P), minf(1.0, gereken_saat))
			c.e = maxf(P.e_taban, minf(1.0, Y / maxf(Y_L, 1e-9)))
		else:
			# Istihdam artik FIZIKSEL kapasitenin kullanimidir; robotlar
			# kapasiteyi buyuttukce ayni hasila daha az canli emek ister.
			c.e = maxf(P.e_taban, minf(1.0, Y / maxf(Y_L, 1e-9)))

		var iss := 1.0 - c.e

		# --- EVRENSEL TEMEL GELIR ---
		# ETG YALNIZCA KAPITALIST REJIMDE tanimlidir: planli ekonomide ucret
		# zaten planla belirlenir; "emek gucunun degeri", "rezervasyon ucreti" ve
		# "metasizlasma" kavramlarinin ucu de piyasa uzerinden calisir.
		if c.rejim != "kapitalist":
			c.etg_hedef = 0.0
			c.etg = 0.0
			c.etg_metasiz = 0.0
		else:
			c.etg += P.etg_yerlesme * politika_hizi(c) * (maxf(0.0, c.etg_hedef) - c.etg)
			c.etg = maxf(0.0, minf(0.40, c.etg))
			# Hangi okumanin baskin oldugu ORGUTLULUGE baglidir: org yuksek ->
			# metasizlasma (isci el koyar), dusuk -> subvansiyon (isveren el koyar).
			c.etg_metasiz = minf(1.0, c.org / P.etg_org_ref)

		var hedef_katilim := P.kat_taban + (1.0 - P.kat_taban) * minf(1.0, c.e / P.kat_e_ref)
		# Gonullu cekilme: ETG katilimi dusurur. DIKKAT -- bu L_etkin'i kucultup
		# olculen istihdam oranini MEKANIK olarak yukseltir. Gercek bir etki ve
		# gercek bir elestiri; gizlenmiyor, `iss_duzeltilmis` ile gorunur birakiliyor.
		c.katilim_etg = P.etg_katilim * c.etg
		hedef_katilim -= c.katilim_etg
		c.katilim += P.kat_hiz * (hedef_katilim - c.katilim)
		c.katilim = maxf(P.kat_taban, minf(1.0, c.katilim))

		# --- KARANLIK DEVLET ---
		# 1) ENDOJEN MAFYA TOLERANSI. Devlet uyusturucu ekonomisine, birikim
		# tikandiginda ve sinif ofkesini bastirmanin baska araci kalmadiginda goz
		# yumar. c.r ve c.i_ef BURADA BIR ONCEKI TURUN degerleridir.
		if c.mafya_kilit != null:
			c.mafya_tolerans = maxf(0.0, minf(1.0, float(c.mafya_kilit)))
			c.kd_hedef = c.mafya_tolerans
		elif c.rejim == "kapitalist":
			var tikanma := minf(1.0, maxf(0.0, (c.i_ef - c.r) / P.kd_tikanma_olcek))
			# Refah yatistirmasi mumkunse karanlik araca gerek kalmaz.
			var refah_yoklugu := 1.0 - minf(1.0, maxf(0.0, c.r - P.r_referans) / P.r_refah_olcek)
			c.kd_hedef = maxf(0.0, minf(P.kd_tavan,
					P.kd_taban
					+ P.kd_tikanma * tikanma
					+ P.kd_omega * c.Omega * refah_yoklugu * maxf(0.0, 1.0 - P.etg_kd * c.etg)
					+ P.kd_baski * c.baski_egilimi
					- P.kd_mesruiyet * minf(c.PC, 1.0)
					- P.kd_org * c.org))
			c.mafya_tolerans += P.kd_hiz * (c.kd_hedef - c.mafya_tolerans)
		else:
			c.kd_hedef = 0.0
			c.mafya_tolerans += P.kd_hiz * (0.0 - c.mafya_tolerans)
		c.mafya_tolerans = maxf(0.0, minf(1.0, c.mafya_tolerans))

		# 2) UYUSTURUCU YAYILIMI -- lojistik, ic dengeli. Yayilim ve bastirma
		# IKISI DE uo ile orantili; boylece tolerans surekli bir kadran gibi
		# davranir (onceki surumde ac/kapa dugmesiydi).
		var yayilim := (P.uo_omega * c.Omega * c.mafya_tolerans          # MERKEZI KANAL
				+ P.uo_iss * maxf(0.0, iss - P.uo_iss_esik)              # yedek sanayi ordusu
				+ P.uo_gecim * maxf(0.0, P.gecim_tabani - c.pay))        # gecim krizi
		# Bastirma kapasitesi mesruiyete TAM bagli degildir: rizasi cokmus bir
		# devletin de zor aygiti vardir.
		var bastirma := P.uo_bastirma * (1.0 - c.mafya_tolerans) * (
				P.uo_bastirma_taban + (1.0 - P.uo_bastirma_taban) * minf(c.PC, 1.0))
		var d_uo := (yayilim * (1.0 - c.uyusturucu_orani / P.uo_tavan)
				- (bastirma + P.uo_cozulme) * c.uyusturucu_orani)
		c.uyusturucu_orani = maxf(0.0005, minf(P.uo_tavan, c.uyusturucu_orani + d_uo))

		# 3) KARSERAL NUFUS. Ampirik capa: dunya rekoru ~%0.65 (ABD), tipik OECD
		# ~%0.1-0.2; tavan %2.5 asiri karseral devlet senaryosudur.
		c.cezaevi_orani = maxf(0.0008, minf(P.cezaevi_tavan,
				P.karseral_taban
				+ P.karseral_uo * c.uyusturucu_orani
				+ P.karseral_iss * iss
				+ P.karseral_baski * c.baski_egilimi * c.Omega))

		# Endojen dogum orani (demografik kriz)
		var era_katsayi := 1.0 - 0.12 * float(c.era - 1)
		var refah_etki := maxf(0.0, c.pay - 0.30) + P.etg_dogum * c.etg
		var huzursuzluk_soku := (0.35 * c.Omega + 0.20 * iss
				+ 0.15 * maxf(0.0, c.pi_inf) + 0.40 * c.uyusturucu_orani)

		var base_br := 0.012 if c.tip == "merkez" else (0.018 if c.tip == "yari" else 0.026)
		c.dogum_orani = maxf(0.004, minf(0.045, base_br * era_katsayi
				* (1.0 - minf(0.85, huzursuzluk_soku)) + 0.01 * refah_etki))

		# Savas, uyusturucu salgini ve yaslilik olum oranini artirir.
		c.olum_orani = maxf(0.003, minf(0.030, (0.008 if c.tip == "merkez" else 0.006)
				+ (0.008 if c.savasta() else 0.0) + 0.05 * c.uyusturucu_orani))

		c.e_norm = (1.0 - P.e_norm_hiz) * c.e_norm + P.e_norm_hiz * c.e

		# --- TONAK DEGER GASBI ---
		# YENI DEGER yalnizca canli emekten gelir. Fiziksel hasila Y devasa
		# olabilir; deger buyuklugu V bundan bagimsiz olarak buzulur.
		c.V_yeni = Y * c.canli_pay
		var s_ham := c.V_yeni * (1.0 - c.pay) * (1.0 - c.kamu_pay * (1.0 - P.kamu_r_farki))
		c.s_v = (1.0 - c.pay) / maxf(c.pay, 1e-6)     # KODEY: somuru orani s/v
		c.lumpen_pay = minf(P.lumpen_tavan, P.lumpen_carpani * c.uyusturucu_orani)
		# Illegal sektor payinin OTESINDE deger ceker (illegalite primi).
		c.gasp = s_ham * c.lumpen_pay * P.illegalite_primi
		# ETG'nin sermayeden finansmani NET karliligi dusurur: birikimi
		# yavaslatarak LTRPF'yi hizlandirir ve kendi vergi tabanini asindirir.
		s_ham *= maxf(0.15, 1.0 - P.etg_vergi_sermaye * c.etg_vergi_sermaye_o)
		var s := s_ham * (1.0 - c.lumpen_pay)         # uretken birikime kalan
		# Gasbedilen deger uretken sermayeye degil asalak/spekulatif stoka akar.
		c.varlik += P.gasp_varlik * c.gasp
		c.r = s / maxf(c.K, 1e-6)

		# --- J. Spekulatif varlik balonu (finansallasma + Minsky) ---
		var v_oran_onc := c.varlik / maxf(Y, 1e-6)
		if c.rejim == "kapitalist" and c.delev == 0:
			# (i) Kar sikismasi kanali: uretken alan spekulatif getiriyi
			#     yenemedigi olcude artik deger finansa kayar.
			var makas0 := maxf(0.0, (c.i_spec - c.r) / maxf(c.i_spec, 1e-6))
			# Arti-deger AKIMINDAN kayis + SERMAYE STOKUNDAN kayis. Yalnizca akim
			# olsaydi otomasyon aciklaninca s cokup spekulasyon kanali da olurdu;
			# oysa uretken karlilik dustukce finansallasmanin ARTMASI beklenir --
			# finansal getiri arayan sey atil duran SERMAYE STOKUDUR.
			var kayan := P.fin_pay * _kur(c, "finans") * maxf(s, 0.0) * makas0
			kayan += P.fin_stok * _kur(c, "finans") * c.K * makas0
			# (ii) Kaldiracli spekulasyon: balon kendi beklentisini besler.
			kayan += (P.spec_kredi * _kur(c, "kredi") * c.varlik * maxf(0.0, c.varlik_beklenti))
			# (iii) Doygunluk: mutlak sinira yaklastikca akim soner.
			kayan *= maxf(0.0, 1.0 - v_oran_onc / P.balon_limiti)
			c.varlik += kayan
		c.varlik *= (1.0 - P.balon_sonum)

		# Varlik FIYATI (varlik/Y) uzerinden getiri beklentisi -- ekstrapolatif
		# (Minsky). Ham stok yerine orani kullanmak gerekir: hasila buyurken sabit
		# bir stok reel olarak deger kaybediyor demektir.
		var v_oran_yeni := c.varlik / maxf(Y, 1e-6)
		var getiri := (v_oran_yeni / v_oran_onc - 1.0) if v_oran_onc > 1e-9 else 0.0
		c.varlik_beklenti = minf(P.beklenti_tavan,
				(1.0 - P.beklenti_hiz) * c.varlik_beklenti + P.beklenti_hiz * getiri)
		# Kirilganlik + tersine donus SAYACI. Tek turluk bir kosul yetmez:
		# balon_sonum yuzunden varlik zaten eriyor, beklenti cogu turda negatif.
		if v_oran_yeni > P.minsky_esik and c.varlik_beklenti < c.i_spec:
			c.minsky_sayac += 1
		else:
			c.minsky_sayac = maxi(0, c.minsky_sayac - 1)

		var varlik_orani := c.varlik / maxf(Y, 1e-6)
		var borc_orani := c.borc / maxf(Y, 1e-6)

		# --- K. Fisher & Clarke borc/balon patlamasi (Tip B) ---
		var cokme := ""
		if c.rejim == "kapitalist" and c.delev == 0:
			if borc_orani > P.borc_limiti:
				cokme = "BORC"        # Tip B2: hanehalki borc krizi
			elif varlik_orani > P.balon_limiti:
				cokme = "BALON"       # Tip B: mutlak balon siniri
			elif c.minsky_sayac >= P.minsky_sure:
				cokme = "MINSKY"      # varlik getirisi finansman maliyetinin altina dustu

			if cokme != "":
				c.minsky_sayac = 0
				c.delev = P.delev_sure
				c.varlik *= 0.35
				c.borc *= (1.0 + P.deflasyon + maxf(0.0, -c.pi_inf) * 3.0)
				c.K *= 0.97
				# Finansal cokme sabit sermayeyi degersizlestirir.
				c.deger_carpani = maxf(P.dev_taban, c.deger_carpani * (1.0 - P.dev_cokme))
				_log("COKME", "%s spekulatif varlik balonu %s patladi! Sistem de-leveraginge giriyor." % [c.ad, cokme])

		# --- L. Bolgeler arasi deger transferi (sizinti) ---
		var disa := 0.0
		if c.rejim == "sosyalist":
			disa = (1.0 / (1.0 + 0.6 * float(blok))) * (1.0 - P.ab_vt * float(mini(c.abluka, 3)) / 3.0)
		else:
			disa = (1.0 - P.ab_vt * float(mini(c.abluka, 3)) / 3.0) if c.abluka else 1.0

		var d1 := (cv - ort_cv) / maxf(ort_cv, 0.05)
		var d2 := ((1.0 / maxf(c.pay, 0.05) - 1.0) - ort_sv) / maxf(ort_sv, 0.05)
		var wd1 := 0.9 if c.tip == "cevre" else 0.2
		var wd2 := 0.1 if c.tip == "cevre" else 0.8

		c.VT_net = P.vt_siddet * Y * (wd1 * d1 + wd2 * d2) * maxf(disa, 0.0)
		var r_ef := (s + c.VT_net) / maxf(c.K, 1e-6)

		# --- M. Kamu sermayesi & birikim ---
		var kamu_hedef_ef := maxf(0.0, minf(0.95, _kur(c, "kamu_hedef") + c.yatirim_durusu))
		c.kamu_pay += P.kamu_uyum * (kamu_hedef_ef - c.kamu_pay)
		c.kamu_pay = maxf(0.0, minf(0.85, c.kamu_pay))

		if c.rejim == "kapitalist":
			# Hizlandirici KURUMSALDIR: yuksek deger = kisa yatirim ufku, finans
			# gudumlu, cevrimsel yatirim -> daha buyuk K salinimi -> daha hizli
			# mekanizasyon -> daha buyuk yedek sanayi ordusu.
			var hz := float(Tables.KURUMLAR[c.kurum].get("hizlandirici", P.hizlandirici))
			var g_ozel := P.g_taban + P.g_duy * (r_ef - c.i_ef) + hz * (c.u - P.u_normal)
			if c.delev > 0:
				g_ozel -= 0.0025
			var g_kamu := 0.004 - P.kamu_istikrar * minf(0.0, r_ef - c.i_ef)
			c.g = (1.0 - c.kamu_pay) * g_ozel + c.kamu_pay * g_kamu
		else:
			# Blok bonusu yalnizca ITTIFAK halindeki ulkelere; rekabet halindeki
			# bir ulke fiilen yalnizdir.
			var _ittifakta := c.pakt_durusu != "rekabet" and blok > 1
			c.PKE = minf(0.99, float(E["pke"]) + (P.blok_pke_bonus if _ittifakta else 0.0))
			# Plan profili hedefe YAVAS yakinsar (plan degisikligi bir tur meselesi
			# degildir) ve her zaman normalize edilir.
			if c.plan_hedef != null:
				var ph := P.plan_hiz * politika_hizi(c)
				var ph_hedef: Dictionary = c.plan_hedef
				for k in c.plan:
					c.plan[k] = float(c.plan[k]) + ph * (float(ph_hedef.get(k, c.plan[k])) - float(c.plan[k]))
			var tp_terimler := []
			for k in c.plan:
				tp_terimler.append(maxf(0.0, float(c.plan[k])))
			var tp := Formulas.py_sum(tp_terimler)
			if tp == 0.0:
				tp = 1.0
			for k in c.plan:
				c.plan[k] = maxf(0.0, float(c.plan[k])) / tp
			# KITLIK: planli ekonominin kendine ozgu kriz bicimi. IKI kaynagi var:
			#  (a) planin tuketime ayirdigi payin norm altinda kalmasi
			#  (b) ABLUKA/AMBARGO: tuketim mali ithal edilemez, plan ne olursa olsun
			#      kitlik dogar. Kusatma altinda plan degistirmek kitligi gidermeye
			#      yetmez -- Kuba ve SSCB deneyimi budur.
			var _plan_kitlik := 1.0 - float(c.plan["tuketim"]) / maxf(P.plan_tuketim_ref, 1e-6)
			var _kusatma := (P.izo_abluka_kitlik * (float(mini(c.abluka, 3)) / 3.0)
					+ (P.izo_ambargo_kitlik if c.ambargo else 0.0))
			c.kitlik = maxf(0.0, minf(1.0, _plan_kitlik + _kusatma))
			c.g = (P.plan_g * c.PKE * P.plan_yatirim_olcek * float(c.plan["yatirim"])
					+ P.plan_u_duy * (c.u - P.u_normal))
			c.g = maxf(-P.g_daralma_tavani, minf(P.g_tavani, c.g))

		# `g` NET birikim oranidir; amortisman zaten I'nin icinde telafi edildigi
		# icin stok guncellemesi net oranla yapilir.
		c.K = maxf(1.0, c.K * (1.0 + c.g))

		if c.savasta():
			var rg_terimler := []
			for k in c.savas:
				var g_rakip := 0.0
				for x in D:
					if x.ad == k:
						g_rakip = x.guc()
						break
				rg_terimler.append(g_rakip)
			var rg := Formulas.py_sum(rg_terimler)
			var oran2 := rg / maxf(c.guc() + rg, 1e-6)
			c.K *= (1.0 - P.sv_yikim * (0.5 + oran2))
			c.pay = maxf(0.12, c.pay * (1.0 - P.sv_tuketim))
			c.Omega = minf(1.0, c.Omega + P.sv_yorgunluk * 0.8)

		# --- N. Haftalik calisma suresi ---
		if c.rejim != "sosyalist":
			if iss > 0.06:
				c.saat -= P.saat_org * c.org * minf(iss, 0.30)
			elif iss < 0.05:
				c.saat += P.saat_geri * (0.05 - iss) * 10.0
			c.saat = maxf(c.saat_tabani(P), minf(1.0, c.saat))

		# --- O. Egitim, AR-GE & nitelik birikimi ---
		# Guvenlik harcamasi egitim butcesini DISLAR.
		var egitim_pay_ef := _kur(c, "egitim_pay") * (
				1.0 - P.karseral_egitim_disla * minf(1.0, c.cezaevi_orani / P.cezaevi_ref))
		var egitim_harcama := G * egitim_pay_ef / maxf(c.Y, 1e-6)
		c.egitim += egitim_harcama * 0.25 - P.egitim_asinma * 3.0 * c.egitim
		c.egitim = maxf(0.0, minf(1.0, c.egitim))

		var rd := 0.0
		if c.rejim == "kapitalist":
			rd = P.rd_pay * maxf(s, 0.0) / maxf(c.K, 1.0)
		else:
			# Planli ekonomide AR-GE artik degerin bir payi degil PLANIN kalemidir.
			rd = P.plan_arge_olcek * float(c.plan["arge"]) * c.PKE * P.rd_pay
		var hiz := 1.0
		if c.ambargo:
			hiz *= (1.0 - P.amb_q)
		if c.rejim == "sosyalist" and blok > 1:
			hiz *= (1.0 + 0.10 * float(mini(blok, 6)))

		# Asimetrik teknolojik yayilim hizi (orta gelir tuzagi kilidi)
		if c.tip == "merkez":
			hiz *= P.yayilim_merkez
		elif c.tip == "yari":
			hiz *= P.yayilim_yari
		else:
			hiz *= P.yayilim_cevre
		# Uyusturucu kullanimi nitelikli emek birikimini dogrudan asindirir.
		var nitelik := maxf(0.1, (1.0 + P.egitim_q * c.egitim) * (1.0 - 0.70 * c.uyusturucu_orani))
		var kamu_din := 1.0 - c.kamu_pay * (1.0 - P.kamu_verimlilik)

		var doyum := maxf(P.q_doyum_taban, 1.0 - c.q / float(E["q_tavan"]))
		if c.rejim == "sosyalist":
			# Kitlik verimliligi asindirir (moral, devamsizlik, ikinci ekonomi).
			doyum *= maxf(0.15, 1.0 - P.plan_kitlik_q * c.kitlik)
		# Mekanizasyonun DURTUSU: emek kitligi x ucret baskisi. Emek bol ve
		# ucuzsa sermaye emegi ikame etmez.
		var ito_ucret := (c.pay / P.ito_pay_ref) * (c.e / P.ito_e_ref)
		# Rekabetin zorlayici yasasi: frontier'in gerisine dusen mekanize etmek
		# ZORUNDADIR, ucreti ucuz olsa bile.
		var ito_rek := P.ito_rekabet * maxf(0.0, 1.0 - c.q / maxf(ort_q, 1e-6))
		var ito_mak := P.ito_makine * ucuzlama_orani(c.q)
		# Demografik kitlik: yaslanan nufusta isgucu daralir.
		var nufus_hizi := c.dogum_orani - c.olum_orani
		var ito_dem := P.ito_demografi * maxf(0.0, 1.0 - nufus_hizi / P.ito_nufus_ref)
		c.ito = P.ito_taban + (1.0 - P.ito_taban) * minf(
				P.ito_tavan, ito_ucret + ito_rek + ito_mak + ito_dem)
		c.ito_bilesen = [ito_ucret, ito_rek, ito_mak, ito_dem]
		var q_buyume := float(E["qg"]) * (0.5 + 1.6 * minf(rd * P.rd_olcek, 1.2)) * hiz * nitelik * kamu_din * doyum * c.ito
		if rng.random() < 0.012:
			q_buyume += 0.03 * doyum
		c.q *= (1.0 + q_buyume)
		c.q_buyume = q_buyume

		# Cag atlama -- ICSEL ama TARIHSEL BANDA CAKILI. Hizli gelisen bir oyuncu
		# 1900'de tam otomasyona varamaz, geride kalan bir dunya da 2100'de buhar
		# caginda kalmaz.
		var _atla := false
		if c.era < 6:
			var _E2: Dictionary = Tables.ERAS[c.era + 1]
			var _yil := yil()
			_atla = _yil >= float(_E2["yil_alt"]) and (
					c.q > float(_E2["q_esik"]) or _yil >= float(_E2["yil_ust"]))
		if _atla:
			c.era += 1
			c.IR = minf(1.0, c.IR + 0.08)
			c.K *= (1.0 - P.gecis_yikim)
			c.gecis_sok = P.gecis_sok_sure
			if c.rejim == "kapitalist":
				c.Omega = minf(1.0, c.Omega + P.gecis_omega)
			_log("CAG", "%s sanayisi cag atladi: %s evresine girdi!" % [c.ad, Tables.ERAS[c.era]["name"]])

		# --- P. Phillips egrisi & enflasyon ---
		var birim_emek := maxf(-0.15, minf(0.25, c.w_nom_buyume - q_buyume))
		var sok := P.ph_sok if (c.savasta() or c.fx_kriz > 0) else 0.0
		var bosluk := c.u - P.u_normal
		var talep_etkisi := (P.ph_talep * bosluk if bosluk > 0.0
				else P.ph_talep * P.ph_asimetri * maxf(bosluk, -0.30))
		var pi_ham := (P.ph_beklenti * c.pi_bek + talep_etkisi
				+ P.ph_maliyet * maxf(birim_emek, -0.04) + sok)
		if c.delev > 0:
			pi_ham -= P.delev_deflasyon

		# Fiyat kontrolleri
		if c.kontrol == 0 and pi_ham > P.kont_esigi and c.rejim == "kapitalist":
			c.kontrol = P.kont_sure
			_log("KONTROL", "%s hiperenflasyon baskisi altinda fiyat kontrolleri baslatti." % c.ad)

		if c.kontrol > 0:
			var bastirilan := pi_ham * P.kont_etki
			c.bastirilmis_pi += bastirilan
			pi_ham -= bastirilan
			c.kontrol -= 1
			if c.kontrol == 0:
				pi_ham += c.bastirilmis_pi * P.kont_patlama
				c.bastirilmis_pi = 0.0
				_log("KONTROL BITTI", "%s fiyat kontrol donemi bitti, bastirilmis enflasyon puskurdu!" % c.ad)

		c.pi_inf = maxf(P.pi_min, minf(P.pi_max, pi_ham))
		c.pi_bek = 0.80 * c.pi_bek + 0.14 * c.pi_inf + 0.06 * P.pi_hedef
		c.p_duzey *= (1.0 + c.pi_inf)

		if c.pi_inf > P.stagf_pi_esigi and iss > 0.10:
			c.stagflasyon += 1
		else:
			c.stagflasyon = maxi(0, c.stagflasyon - 1)

		# --- Q. Goodwin sinifsal nominal ucret pazarligi ---
		if c.rejim == "kapitalist":
			var telafi := P.w_beklenti * (1.0 + P.w_org * c.org)
			# Goodwin terimi SABIT bir hedefe degil ulkenin kendi HAREKETLI
			# istihdam normuna gore calisir.
			var bos_e := c.e - c.e_norm
			# METASIZLASMA: garantili gelir rezervasyon ucretini yukseltir; isci
			# ucret indirimini reddedebilir hale gelir, asagi yonlu nominal
			# katilik ARTAR.
			var kat := P.w_katilik + (1.0 - P.w_katilik) * minf(1.0, iss / P.katilik_cozulme)
			kat = minf(1.0, kat + P.etg_katilik * c.etg * c.etg_metasiz)
			var goodwin := P.phi * bos_e if bos_e > 0.0 else P.phi * kat * bos_e
			var taban := _kur(c, "emek_pay")
			var aktarim := taban + (1.0 - taban) * c.org
			c.w_nom_buyume = (telafi * c.pi_bek + goodwin + P.w_org_e * c.org * (c.e - P.e0) + aktarim * q_buyume)

			if c.kontrol > 0:
				c.w_nom_buyume *= (1.0 - P.kont_etki)
			var d_pay := maxf(-P.pay_degisim_tavani, minf(P.pay_degisim_tavani,
					c.w_nom_buyume - c.pi_inf - q_buyume))
			c.pay *= (1.0 + d_pay)
		else:
			# Ucret payi hedefi kitliktan dusulur: nominal pay yuksek olsa da
			# tuketim mali yoksa gercek bolusum duser.
			var hedef_pay := (P.sos_pay_taban + P.sos_pay_pke * c.PKE - P.plan_kitlik_pay * c.kitlik)
			c.pay += P.sos_pay_hiz * (hedef_pay - c.pay)

		# Illegal sektorun super-somurusu ucret payinin TABANINI dusurur (seviye
		# etkisi; bir buyume orani drenaji DEGIL -- oyle kurulunca 1200 turda
		# bilesiklenip payi 0.58'den 0.17'ye suruyordu).
		# UCRET SUBVANSIYONU: gecimin toplumsallasan kismi kadar emek gucunun
		# degeri duser; yalnizca subvansiyon agirligi (1-metasiz) olcusunde --
		# orgutlu isci bunu ucret indirimine cevirtmez.
		var etg_taban_etkisi := P.etg_taban_dus * c.etg * (1.0 - c.etg_metasiz)
		var pay_taban := maxf(0.10, P.pay_taban0 + P.pay_taban_org * c.org
				- P.gasp_taban * c.lumpen_pay
				- etg_taban_etkisi)
		if c.parti_iktidari:
			# Parti iktidari + kapitalist birikim: emegin pazarlik zemini
			# siyaseten bastirilmis oldugu icin ucret payi tabani duser.
			pay_taban = minf(pay_taban, P.parti_pay_taban)
		c.pay = maxf(pay_taban, minf(P.pay_tavani, c.pay))

		# --- R. Iki kademeli kriz tescili (resesyon / bunalim) ---
		c.Y_ort = (0.90 * c.Y_ort + 0.10 * Y) if t > 0 else Y
		c.Y_trend = maxf(c.Y_trend * P.trend_asinma, c.Y_ort)
		var derinlik := 1.0 - c.Y_ort / maxf(c.Y_trend, 1e-9)

		# Asiri uretim krizi: emilemeyen talep acigi. Planli ekonomide YOK --
		# gerceklesme krizi kapitalizme ozgudur.
		c.au_bekle = maxi(0, c.au_bekle - 1)
		if c.rejim == "kapitalist" and c.talep_acigi > P.au_esik:
			c.au_ici += 1
			if c.au_ici >= P.au_sure and c.au_bekle == 0:
				c.asiri_uretim_krizleri.append([t, Formulas.py_round(c.talep_acigi, 4)])
				c.au_bekle = P.au_bekleme
				c.Omega = minf(1.0, c.Omega + P.au_omega)
				_log("ASIRI URETIM", "%s: satilamayan urun kitlesi birikti (talep acigi %%%.0f). Asiri uretim krizi."
						% [c.ad, c.talep_acigi * 100])
		else:
			c.au_ici = 0

		# Resesyon: art arda daralan hasila (konjonkturel olgu)
		c.res_bekle = maxi(0, c.res_bekle - 1)
		if c.y_buyume < P.res_daralma:
			c.res_ici += 1
			if c.res_ici >= P.res_sure and c.res_bekle == 0:
				c.resesyonlar.append([t, Formulas.py_round(c.y_buyume, 4)])
				c.res_bekle = P.res_bekleme
		else:
			c.res_ici = 0

		if derinlik > P.bun_esik:
			c.bun_ici += 1
			if c.bun_ici == P.bun_sure:
				var n := c.tarih.tur_sayisi()
				var lo := maxi(0, n - 45)
				var hi := mini(n, maxi(1, n - 15))
				var rli_t := 0.0
				if hi > lo:
					var rs := c.tarih.seri("r")
					var isp := c.tarih.seri("i_spec")
					var say := 0
					for i in range(lo, hi):
						if rs[i] < isp[i]:
							say += 1
					rli_t = float(say) / float(maxi(hi - lo, 1))
				var stagf := c.stagflasyon > 15
				var btip := ""
				if stagf or rli_t > 0.30:
					btip = "STAGFLASYON" if stagf else "KAR SIKISMASI"
				elif c.fx_kriz > 0 or (not c.fx_krizleri.is_empty() and t - int(c.fx_krizleri[-1]) < 40):
					btip = "DOVIZ"
				elif c.delev > 0:
					btip = "FINANSAL"
				elif c.pay < 0.45 and c.u < 0.75:
					btip = "GERCEKLESME"
				else:
					btip = "KARMA"
				# Buyuk bunalim: kitlesel iflas ve defterden silme.
				c.deger_carpani = maxf(P.dev_taban, c.deger_carpani * (1.0 - P.dev_bunalim))
				c.bunalimlar.append([t, btip, Formulas.py_round(derinlik, 3)])
				_log("BUYUK BUNALIM", "%s bolgesinde %s bunalimi koptu! Derinlik: %.2f" % [c.ad, btip, derinlik])
		else:
			c.bun_ici = 0

		# --- S. Sinif orgutlenme stoku & kentlesme (lojistik stok) ---
		if c.gecis_sok > 0:
			c.gecis_sok -= 1
		var krizde := (c.r < P.r_kriz_esigi) or (iss > 0.13) or c.savasta() or c.gecis_sok > 0 or c.delev > 0
		c.kriz = (c.kriz + 1) if krizde else maxi(0, c.kriz - 2)
		var kriz_n := minf(float(c.kriz) / 25.0, 1.2)

		if c.rejim == "kapitalist":
			var aktif_pr := Formulas.sg(P.kappa * (P.b_pay * (1.0 - c.pay) + P.b_iss * iss - P.theta))
			var baski0 := c.baski_egilimi * minf(c.PC, 1.0) * (1.0 if (aktif_pr > P.tepki_esigi or kriz_n > P.tepki_esigi) else 0.0)
			var eroz := P.org_erozyon * _kur(c, "org_eroz") * (P.org_era_era_erozyon * float(c.era - 2) if c.era >= 3 else 0.0)
			var buyume := (P.org_kent * float(E["kent"]) + P.org_kriz * kriz_n + P.egitim_org * c.egitim)
			var azalma := (P.org_baski * baski0 + eroz)
			var dorg := buyume * (1.0 - c.org) - azalma * c.org
			# Cozulme POLITIKA degiskenine degil FIILI lumpenlesmeye baglidir:
			# devletin savastigi ama yine de yayilmis bir uyusturucu ekonomisi de
			# sendikal dokuyu cozer.
			dorg -= P.lumpen_org * c.lumpen_pay * c.org
			c.org = maxf(0.0, minf(0.98, c.org + dorg))
		else:
			c.org = minf(0.98, c.org + 0.001 * (0.98 - c.org))

		# --- T. Lojistik protesto riski & sosyalist devrim ---
		var arg := 0.0
		if c.rejim == "kapitalist":
			arg = P.b_pay * (1.0 - c.pay) + P.b_iss * iss - P.theta
		else:
			# Gerilim (1-PKE) vekilinden degil FIILI KITLIKTAN gelir: planlama
			# gucu yuksek ama tuketimi kisan bir plan da huzursuzluk uretir --
			# tarihsel olarak olan tam budur.
			var bolluk := maxf(0.0, 1.0 - c.kitlik / maxf(P.sos_bolluk_esigi, 1e-6))
			var iss_agirlik := 1.0 - P.sos_iss_bolluk * minf(1.0, bolluk)
			arg = (P.b_pay * P.sos_kitlik_agirlik * (0.5 * (1.0 - c.PKE) + c.kitlik)
					+ P.b_iss * iss * iss_agirlik - P.theta)

		# --- MARKSIST POLITIK OZNE ---
		# Zemin: issizler kitlesi + yoksullasma + kriz deneyimi.
		# Yikici: baski aygiti ve lumpenlesme.
		var _iss_simdi := 1.0 - c.e
		var _zemin := (P.parti_iss * _iss_simdi
				+ P.parti_yoksullasma * maxf(0.0, 1.0 - c.pay / P.parti_pay_ref)
				+ P.parti_kriz * kriz_n)
		var _yikim := P.parti_baski * c.baski_egilimi + P.parti_lumpen * c.lumpen_pay
		var _hedef := maxf(0.0, minf(P.parti_tavan, _zemin - _yikim))
		c.parti += P.parti_hiz * (_hedef - c.parti)
		c.parti = maxf(0.0, minf(P.parti_tavan, c.parti))
		# Parti, sendikanin ulasamadigi kitleyi kapsar.
		c.orgutlu = c.org + c.parti * (1.0 - c.org)

		# Bolme/yozlastirma politikalarina direnc: bilinclendirme sonumlemeyi kirar.
		var _direnc := 1.0 - P.parti_direnc * c.parti
		var lumpen_sonum := 1.0 - minf(0.85, P.lumpen_sonum_gucu * c.lumpen_pay * _direnc)
		# Karseral disiplin: hapsetme, disipline edilemeyen nufusu fiziksel olarak
		# izole ederek protesto riskini dogrudan bastirir.
		var karseral_sonum := 1.0 - minf(0.40, P.karseral_disiplin * minf(
				2.0, c.cezaevi_orani / P.cezaevi_ref) * _direnc)
		var PR := Formulas.sg(P.kappa * arg) * lumpen_sonum * karseral_sonum
		var _esik_ef := maxf(P.pr_esik_min, P.pr_esik - P.pr_esik_omega * c.Omega)
		c.pr_sayac = (c.pr_sayac + 1) if PR >= _esik_ef else 0

		if c.rejim == "kapitalist":
			var aktif := 1.0 if (PR > P.tepki_esigi or kriz_n > P.tepki_esigi) else 0.0
			var baski := c.baski_egilimi * minf(c.PC, 1.0) * aktif
			var reform := (1.0 - c.baski_egilimi) * minf(c.PC, 1.0) * aktif
			# PASIFIZASYON: ETG, karliliga bagli refah yatistirmasindan BAGIMSIZ
			# bir yatistirma kanalidir -- kar sikismasi altinda bile calisir.
			# Bedeli butcededir, birikimde degil.
			var refah := P.som_refah * minf(1.0, maxf(0.0, c.r - P.r_referans) / P.r_refah_olcek)
			refah += P.etg_omega * c.etg
			var vt_baris := P.som_vt * _kur(c, "vt_baris") * maxf(0.0, c.VT_net / maxf(Y, 1e-6))
			if c.savasta():
				refah *= P.savas_baris_kesinti
				vt_baris *= P.savas_baris_kesinti

			# ASIRI URETIM: fiziksel hasila ile satinalma gucu arasindaki makas.
			# canli_pay dustukce Y buyur ama V kucuulur; arada kalan satilamayan
			# urun kitlesi sinif gerilimi uretir.
			var makas := maxf(0.0, (1.0 - c.canli_pay) - P.asiri_esik)
			var asiri := P.asiri_uretim * makas * (0.4 + 1.6 * c.orgutlu)

			var dO := (P.org_omega * (P.a1 * PR + P.a2 * kriz_n) * (0.4 + 1.6 * c.orgutlu)
					+ asiri
					- P.a4 * baski - P.a5 * reform - P.omega_sonum - refah - vt_baris)
			c.Omega = maxf(0.0, minf(1.0, c.Omega + dO))

			if blok != 0:
				c.Omega = minf(1.0, c.Omega + P.yayilma * float(blok) / float(D.size()))
			c.IR = minf(1.0, c.IR + 0.003 * baski)
			# Riza artik PERFORMANSIN sonucudur: refah (buyume, istihdam, ucret
			# payi) ve istikrar (dusuk huzursuzluk) bilesenlerinden.
			var pc_refah := (0.40 * minf(1.0, maxf(0.0, c.y_buyume / P.pc_buyume_ref))
					+ 0.35 * minf(1.0, maxf(0.0, c.e / P.e0))
					+ 0.25 * minf(1.0, maxf(0.0, c.pay / P.pc_pay_ref)))
			var istikrar := 1.0 - minf(1.0, c.Omega)
			var hedef_pc := maxf(0.0, minf(1.0, P.pc_taban + P.pc_refah * pc_refah + P.pc_istikrar * istikrar))
			c.PC += P.pc_hiz * (hedef_pc - c.PC)
			c.PC = maxf(0.0, minf(1.0, c.PC - 0.06 * (baski + reform)
					- P.karseral_mesruiyet * minf(2.0, c.cezaevi_orani / P.cezaevi_ref)))

			# Devrim kontrolu
			if P.devrim_acik and c.pr_sayac >= P.pr_sure and c.Omega >= P.omega_kritik:
				c.rejim = "sosyalist"
				c.devrim_t = t
				c.devrim_era = c.era
				c.IR = 0.25
				c.pay = minf(0.80, c.pay + 0.12)
				c.borc = 0.0
				c.varlik = 0.0
				c.delev = 0
				c.FX = maxf(c.FX, 0.15 * Y)
				c.fx_kriz = 0
				c.savas.clear()
				_log("DEVRIM", "%s bolgesinde SOSYALİST DEVRİM patlak verdi! Yeni rejim kuruldu." % c.ad)
		else:
			c.Omega = maxf(0.0, c.Omega - 0.002)

		# --- Veri kaydi ---
		c.tarih.kaydet({
			"t": float(t), "r": c.r, "g": c.g, "e": c.e, "u": c.u, "pay": c.pay,
			"q": c.q, "cv": cv, "Om": c.Omega, "PR": PR, "era": float(c.era),
			"VT": c.VT_net, "PKE": c.PKE, "K": c.K, "Y": Y,
			"borc": borc_orani, "varlik": varlik_orani, "kitlik": c.kitlik,
			"plan_yatirim": float(c.plan["yatirim"]), "plan_tuketim": float(c.plan["tuketim"]),
			"plan_arge": float(c.plan["arge"]), "org": c.org, "delev": float(c.delev),
			"savas": 1.0 if c.savasta() else 0.0, "derinlik": derinlik,
			"i_pol": c.i_pol, "i_ef": c.i_ef, "FX": c.FX / maxf(Y, 1e-6),
			"eps": c.eps, "pi_m": c.pi_m, "BoP": c.BoP_R, "y": c.y_buyume, "pi": c.pi_inf,
			"heg": 1.0 if c.hegemon else 0.0, "stagf": float(c.stagflasyon), "saat": c.saat,
			"kamu_borc": c.kamu_borc, "kamu_pay": c.kamu_pay, "dis_borc": c.dis_borc,
			"egitim": c.egitim, "kontrol": float(c.kontrol), "L": c.L_max,
			"vergi": c.vergi_geliri / maxf(Y, 1e-6),
			"uyusturucu": c.uyusturucu_orani, "cezaevi": c.cezaevi_orani,
			"mafya_tolerans": c.mafya_tolerans, "kd_hedef": c.kd_hedef,
			"dogum": c.dogum_orani, "olum": c.olum_orani,
			"i_spec": c.i_spec, "i_reel": c.i_reel, "varlik_beklenti": c.varlik_beklenti,
			"katilim": c.katilim, "ito": c.ito, "deger": c.deger_carpani,
			"oto": c.oto, "canli_pay": c.canli_pay, "V_yeni": c.V_yeni,
			"parti": c.parti, "orgutlu": c.orgutlu, "hafta": c.hafta_saati(P), "PC": c.PC,
			"kredi_durusu": c.kredi_durusu, "yatirim_durusu": c.yatirim_durusu,
			"ticaret_durusu": c.ticaret_durusu,
			"etg": c.etg, "etg_metasiz": c.etg_metasiz, "cs_kisit": float(c.cs_kisit),
			"etg_v_sermaye": c.etg_vergi_sermaye_o, "etg_v_ucret": c.etg_vergi_ucret_o,
			"iss_duz": c.iss_duzeltilmis(), "katilim_etg": c.katilim_etg,
			# KODEY metrik seti (el kitabi Bolum 6)
			"s_v": c.s_v, "lumpen_pay": c.lumpen_pay,
			"gasp_orani": c.gasp / maxf(Y, 1e-6), "atil_endeks": c.atil_endeks(),
			"L_etkin": c.l_etkin(),
		}, {"rej": c.rejim, "kurum": c.kurum})

	# 5. Sifir toplamli uluslararasi goc akislari
	var cek := {}
	var cek_terimler := []
	for c in D:
		cek[c.ad] = c.pay * c.q * c.e
		cek_terimler.append(float(cek[c.ad]))
	var ort_cek := 1.0
	if not D.is_empty():
		ort_cek = Formulas.py_sum(cek_terimler) / float(D.size())
	var akislar := {}
	for c in D:
		var fark := (float(cek[c.ad]) - ort_cek) / maxf(ort_cek, 1e-6)
		akislar[c.ad] = maxf(-P.goc_tavan, minf(P.goc_tavan, P.goc_duyarlilik * fark))

	var net_terimler := []
	var L_terimler := []
	for c in D:
		net_terimler.append(float(akislar[c.ad]) * c.L_max)
		L_terimler.append(c.L_max)
	var net := Formulas.py_sum(net_terimler)
	var tot_L := Formulas.py_sum(L_terimler)
	if tot_L == 0.0:
		tot_L = 1.0
	for c in D:
		# Endojen nufus artisi (dogum - olum), yillik orandan tura olceklenir.
		var nufus_artis_endojen := (c.dogum_orani - c.olum_orani) * Formulas.TUR_YIL
		c.L_max *= (1.0 + nufus_artis_endojen)
		c.goc_net = float(akislar[c.ad]) - net / tot_L
		c.L_max *= (1.0 + c.goc_net)

	# Savas hasarlarinin dagitimi
	savas_yikim_isle()
	# Kriz siniflandirmasi turun SONUNDA calisir: tur ici tescillerin (resesyon,
	# Minsky, FX, temerrut, devrim) tamami olustuktan sonra.
	kriz_siniflandir()
	t += 1


# ===========================================================================
# RAPORLAMA
# ---------------------------------------------------------------------------
# Bu katmanda parite BIT-BIREBIR DEGIL, SIKI TOLERANSLIDIR ve bu bilincli.
# Kaynak `statistics.mean` kullaniyor; CPython onu Fraction tabanli TAM
# rasyonel toplamayla hesaplayip tek seferde yuvarliyor, yani `sum(x)/n`'den
# farkli. Bunu GDScript'te birebir uretmek buyuk tamsayi aritmetigi gerektirir.
# Karsiliginda kazanilacak sey yok: bu degerler yalnizca RAPORLANIYOR, hicbiri
# motora geri beslenmiyor ve kabul bantlari ([-0.95,-0.55] gibi) 1e-16'lik bir
# farka duyarli degil. Neumaier toplamasiyla hesaplanan ortalama tam ortalamadan
# en fazla 1-2 ulp sapar.
#
# TEK ISTISNA `kar_orani_trendi`: LTRPF olcutunu besliyor. Orada da olcut
# r_son/r_ilk oraninin YONU ve buyuklugu; ulp duyarli degil.
# ===========================================================================

## Ortalama -- `statistics.mean` yerine Neumaier toplama / n (yukaridaki nota bak).
static func _ort(degerler: Array) -> float:
	if degerler.is_empty():
		return NAN
	return Formulas.py_sum(degerler) / float(degerler.size())


func _log_sayaci(anahtar: String) -> int:
	var n := 0
	for kayit in log:
		if String(kayit[1]) == "COKME" and String(kayit[2]).contains(anahtar):
			n += 1
	return n


## Genel istatistikler ve KODEY metrik seti.
func get_summary() -> Dictionary:
	var devrimler := 0
	var baslangic_sos := 0
	var cokmeler := 0
	var savaslar := 0
	for c in D:
		if c.devrim_t != null:
			devrimler += 1
		if c.baslangic_rejimi_t != null:
			baslangic_sos += 1
		savaslar += c.savas_sayisi
	for kayit in log:
		if String(kayit[1]) == "COKME":
			cokmeler += 1

	var kap: Array[Country] = []
	for c in D:
		if c.rejim == "kapitalist":
			kap.append(c)
	if kap.is_empty():
		kap = D

	var sv := []
	var tol := []
	for c in kap:
		sv.append(c.s_v)
		tol.append(c.mafya_tolerans)
	var lump := []
	var cez := []
	var atil := []
	var eps_pi := []
	var L_top := []
	var kat := []
	var etg_l := []
	var ito_l := []
	var deger_l := []
	for c in D:
		lump.append(c.lumpen_pay)
		cez.append(c.cezaevi_orani)
		atil.append(c.atil_endeks())
		eps_pi.append(c.eps / maxf(c.pi_m, 1e-6))
		L_top.append(c.L_max)
		kat.append(c.katilim)
		etg_l.append(c.etg)
		ito_l.append(c.ito)
		deger_l.append(c.deger_carpani)

	var res := 0
	var bun := 0
	var tem := 0
	var kg := 0
	var piyasa := 0
	var restorasyon := 0
	var pakt_rekabet := 0
	var gecis_dn := 0
	var gecis_nd := 0
	var ideo := []
	for c in D:
		res += c.resesyonlar.size()
		bun += c.bunalimlar.size()
		tem += c.temerrutler.size()
		kg += c.kurum_gecmis.size()
		if c.parti_iktidari:
			piyasa += 1
		if c.restorasyon_t != null and not c.parti_iktidari:
			restorasyon += 1
		if c.rejim == "sosyalist":
			if c.pakt_durusu == "rekabet":
				pakt_rekabet += 1
			ideo.append(c.ideolojik_mesafe)
		for g in c.kurum_gecmis:
			if String(g[1]) == "duzenli" and String(g[2]) == "neoliberal":
				gecis_dn += 1
			elif String(g[1]) == "neoliberal" and String(g[2]) == "duzenli":
				gecis_nd += 1

	return {
		"toplam_tur": t,
		"sosyalist_devrimler": devrimler,
		"baslangicta_sosyalist": baslangic_sos,
		"ekonomik_cokmeler": cokmeler,
		"toplam_savaslar": savaslar / 2,
		"kucuk_resesyonlar": res,
		"buyuk_bunalimlar": bun,
		"cokme_BORC": _log_sayaci("BORC"),
		"cokme_BALON": _log_sayaci("BALON"),
		"cokme_MINSKY": _log_sayaci("MINSKY"),
		"kurumsal_gecisler": kg,
		"temerrutler": tem,
		# --- KODEY metrik seti ---
		"ort_somuru_orani_sv": Formulas.py_round(_ort(sv), 3),
		"ort_lumpen_payi": Formulas.py_round(_ort(lump), 4),
		"ort_mafya_toleransi": Formulas.py_round(_ort(tol), 3),
		"ort_cezaevi_orani": Formulas.py_round(_ort(cez), 4),
		"ort_atil_endeks": Formulas.py_round(_ort(atil), 4),
		"ort_thirlwall_eps_pi": Formulas.py_round(_ort(eps_pi), 3),
		"toplam_nufus": Formulas.py_round(Formulas.py_sum(L_top), 1),
		"ort_katilim_orani": Formulas.py_round(_ort(kat), 3),
		"piyasa_sosyalizmi": piyasa,
		"restorasyon": restorasyon,
		"dunya_devrimi": dunya_devrimi,
		"pakt_uyumu": Formulas.py_round(pakt_uyumu, 3),
		"pakt_rekabet": pakt_rekabet,
		"ort_ideolojik_mesafe": Formulas.py_round(_ort(ideo), 4) if not ideo.is_empty() else 0.0,
		"kap_kriz_payi": Formulas.py_round(kap_kriz_payi, 3),
		"ort_etg": Formulas.py_round(_ort(etg_l), 4),
		"kurum_gecis_duzenli_neoliberal": gecis_dn,
		"kurum_gecis_neoliberal_duzenli": gecis_nd,
		"ort_mekanizasyon_durtusu": Formulas.py_round(_ort(ito_l), 3),
		"ort_deger_carpani": Formulas.py_round(_ort(deger_l), 3),
	}


## LTRPF tarihsel dogrulamasi: kar oraninin dilim dilim seyri.
## Kabul olcutu `r_son/r_ilk` oranidir; belgenin birincil iddiasini bu tablo tasir.
func kar_orani_trendi(dilim: int = 150) -> Array:
	var out := []
	var lo := 0
	while lo < t:
		var hi: int = lo + dilim
		var rs := []
		var cvs := []
		var kys := []
		var us := []
		for c in D:
			var n := c.tarih.tur_sayisi()
			var a: int = mini(lo, n)
			var b: int = mini(hi, n)
			if b > a:
				var s_r := c.tarih.seri("r")
				var s_cv := c.tarih.seri("cv")
				var s_K := c.tarih.seri("K")
				var s_Y := c.tarih.seri("Y")
				var s_u := c.tarih.seri("u")
				var vr := []
				var vcv := []
				var vky := []
				var vu := []
				for i in range(a, b):
					vr.append(s_r[i])
					vcv.append(s_cv[i])
					vky.append(s_K[i] / maxf(s_Y[i], 1e-6))
					vu.append(s_u[i])
				rs.append(_ort(vr))
				cvs.append(_ort(vcv))
				kys.append(_ort(vky))
				us.append(_ort(vu))
		if not rs.is_empty():
			out.append({
				"t0": lo, "t1": hi - 1,
				"r": _ort(rs),
				"r_yillik": Formulas.yillik(_ort(rs)),
				"cv": _ort(cvs),
				"K/Y": _ort(kys),
				"u": _ort(us),
			})
		lo += dilim
	return out


## KODEY metrik setinin zaman icindeki seyri (el kitabi Bolum 6).
func kodey_trendi(dilim: int = 150) -> Array:
	var out := []
	var lo := 0
	while lo < t:
		var hi: int = lo + dilim
		var kova := {}
		for ad in ["mafya_tolerans", "uyusturucu", "cezaevi", "lumpen_pay",
				"gasp_orani", "s_v", "dogum"]:
			kova[ad] = []
		var eps_pi := []
		for c in D:
			var n := c.tarih.tur_sayisi()
			var a: int = mini(lo, n)
			var b: int = mini(hi, n)
			if b <= a:
				continue
			for ad in kova.keys():
				var s := c.tarih.seri(ad)
				for i in range(a, b):
					kova[ad].append(s[i])
			var s_eps := c.tarih.seri("eps")
			var s_pim := c.tarih.seri("pi_m")
			for i in range(a, b):
				eps_pi.append(s_eps[i] / maxf(s_pim[i], 1e-6))
		if not eps_pi.is_empty():
			out.append({
				"t0": lo, "t1": hi - 1,
				"tolerans": Formulas.py_round(_ort(kova["mafya_tolerans"]), 4),
				"uyusturucu": Formulas.py_round(_ort(kova["uyusturucu"]), 4),
				"cezaevi": Formulas.py_round(_ort(kova["cezaevi"]), 4),
				"lumpen_pay": Formulas.py_round(_ort(kova["lumpen_pay"]), 4),
				"gasp_orani": Formulas.py_round(_ort(kova["gasp_orani"]), 4),
				"s_v": Formulas.py_round(_ort(kova["s_v"]), 3),
				"eps/pi": Formulas.py_round(_ort(eps_pi), 3),
				"dogum": Formulas.py_round(_ort(kova["dogum"]), 5),
			})
		lo += dilim
	return out


## Kriz sikliklari ULKE-YIL basina. Birincil neden uzerinden sayilir, yani ayni
## turda coklu kriz frekanslari sismez.
func kriz_oranlari() -> Dictionary:
	var ulke_yil := float(D.size()) * float(t) * Formulas.TUR_YIL
	var say := {}
	for c in D:
		for kayit in c.kriz_gunlugu:
			var bir := String(kayit[1])
			say[bir] = int(say.get(bir, 0)) + 1
	var anahtarlar := say.keys()
	anahtarlar.sort_custom(func(a, b): return int(say[a]) > int(say[b]))
	var out := {}
	for k in anahtarlar:
		var v: int = say[k]
		out[k] = {
			"toplam": v,
			"ulke_yil_basina": Formulas.py_round(float(v) / maxf(ulke_yil, 1e-9), 6),
			"aralik_yil": Formulas.py_round(ulke_yil / float(v), 1) if v > 0 else null,
		}
	return out


## Bir kosunun TARIHSEL SONUC RAPORU.
##
## Bu oyunda zafer/yenilgi YOKTUR. Devrim bir kayip degil, oyuncunun elindeki
## politika setinin degismesidir: bolusum ve kurum kollarinin yerini plan
## paylari alir. Rapor kazanip kazanmadigini soylemez -- NE OLDUGUNU anlatir.
func tarihsel_rapor(ulke = null, dilim: int = 150) -> Dictionary:
	var c: Country = D[0]
	if ulke != null:
		for x in D:
			if x.ad == ulke:
				c = x
				break
	var n := c.tarih.tur_sayisi()
	if n == 0:
		return {}

	var ilk_son: int = mini(dilim, n)
	var son_bas: int = maxi(0, n - dilim)

	var donemler := []
	var lo := 0
	while lo < n:
		var hi: int = mini(lo + dilim, n)
		donemler.append({
			"t0": lo, "t1": hi - 1,
			"kurum": _en_sik_metin(c, "kurum", lo, hi),
			"rejim": _en_sik_metin(c, "rej", lo, hi),
			"issizlik": Formulas.py_round(1.0 - _dilim_ort(c, "e", lo, hi), 3),
			"ucret_payi": Formulas.py_round(_dilim_ort(c, "pay", lo, hi), 3),
			"kar_orani": Formulas.py_round(_dilim_ort(c, "r", lo, hi), 5),
			"orgutluluk": Formulas.py_round(_dilim_ort(c, "org", lo, hi), 3),
			"huzursuzluk": Formulas.py_round(_dilim_ort(c, "Om", lo, hi), 3),
			"otomasyon": Formulas.py_round(_dilim_ort(c, "oto", lo, hi), 3),
			"canli_emek_payi": Formulas.py_round(_dilim_ort(c, "canli_pay", lo, hi), 3),
			"etg": Formulas.py_round(_dilim_ort(c, "etg", lo, hi), 4),
			"kitlik": Formulas.py_round(_dilim_ort(c, "kitlik", lo, hi), 3),
		})
		lo += dilim

	var olaylar := []
	for kayit in log:
		var tip := String(kayit[1])
		var mesaj := String(kayit[2])
		if mesaj.contains(c.ad) or tip == "SENARYO":
			olaylar.append({
				"tur": int(kayit[0]),
				"yil_kabaca": Formulas.py_round(float(kayit[0]) * Formulas.TUR_YIL, 1),
				"tip": tip, "mesaj": mesaj,
			})

	return {
		"ulke": c.ad,
		"tip": c.tip,
		"son_rejim": c.rejim,
		"son_kurum": c.kurum,
		"devrim_turu": c.devrim_t,
		"kurum_gecisleri": c.kurum_gecmis.duplicate(true),
		"baslangic": {
			"issizlik": Formulas.py_round(1.0 - _dilim_ort(c, "e", 0, ilk_son), 3),
			"ucret_payi": Formulas.py_round(_dilim_ort(c, "pay", 0, ilk_son), 3),
			"kar_orani": Formulas.py_round(_dilim_ort(c, "r", 0, ilk_son), 5),
			"cag": Formulas.py_round(_dilim_ort(c, "era", 0, ilk_son), 1),
		},
		"bitis": {
			"issizlik": Formulas.py_round(1.0 - _dilim_ort(c, "e", son_bas, n), 3),
			"ucret_payi": Formulas.py_round(_dilim_ort(c, "pay", son_bas, n), 3),
			"kar_orani": Formulas.py_round(_dilim_ort(c, "r", son_bas, n), 5),
			"cag": Formulas.py_round(_dilim_ort(c, "era", son_bas, n), 1),
		},
		"kriz_sayilari": {
			"resesyon": c.resesyonlar.size(),
			"buyuk_bunalim": c.bunalimlar.size(),
			"doviz_krizi": c.fx_krizleri.size(),
			"temerrut": c.temerrutler.size(),
			"moratoryum": c.moratoryumlar.size(),
			"savas": c.savas_sayisi,
		},
		"donemler": donemler,
		"olaylar": olaylar,
	}


func _dilim_ort(c: Country, alan: String, lo: int, hi: int) -> float:
	var s := c.tarih.seri(alan)
	var a: int = maxi(0, mini(lo, s.size()))
	var b: int = maxi(a, mini(hi, s.size()))
	if b <= a:
		return NAN
	var v := []
	for i in range(a, b):
		v.append(s[i])
	return _ort(v)


## Bir dilimde en sik gorulen metin degeri. Kaynakta `max(set(...), key=count)`
## kullaniliyor; beraberlikte Python'un set sirasi belirleyici oluyor ve o sira
## surece ozgu. Burada beraberligi ILK GORULEN kazanir -- daha kararli bir kural.
func _en_sik_metin(c: Country, alan: String, lo: int, hi: int) -> String:
	var say := {}
	var sira := []
	for i in range(lo, mini(hi, c.tarih.tur_sayisi())):
		var m := c.tarih.metin(alan, i)
		if not say.has(m):
			say[m] = 0
			sira.append(m)
		say[m] = int(say[m]) + 1
	var en := ""
	var en_say := -1
	for m in sira:
		if int(say[m]) > en_say:
			en_say = say[m]
			en = m
	return en


## Kosunun yeniden uretilebilir kimligi: hangi kodla, hangi parametreyle.
##
## Parametre karmasi Python tarafinda uretim aninda olculup `param_set.gd`'ye
## gomuluyor. Burada YENIDEN HESAPLANMIYOR: karma, parametrelerin Python
## `str()` bicimlendirmesi uzerinden aliniyor ve o bicimlendirme (en kisa
## gidis-donus temsili) GDScript'te birebir uretilemiyor. Gomulu deger her
## uretimde dogrulaniyor, dolayisiyla ayni seyi soyler.
func deney_kimligi(senaryo = null) -> Dictionary:
	return {
		"model": Formulas.SURUM,
		"parametre_karmasi": ParamSet.BEKLENEN_KARMA,
		"tohum": tohum,
		"senaryo": senaryo if senaryo != null else "varsayilan",
		"tur": t,
		"ulke_sayisi": D.size(),
		"baslangic_yili": baslangic_yili,
	}


## Iktisadi muhasebe degismezlerini denetler.
## NaN/Inf ya da imkansiz deger sessizce DEVAM ETMEZ: olay olarak kaydedilir,
## boylece "bu ulke neden coktu" sorusu sonradan cevaplanabilir.
func degismez_denetle() -> Array:
	var hata := []
	for c in D:
		for alan in [["pay", c.pay, 0.0, 1.0], ["e", c.e, 0.0, 1.0],
				["u", c.u, 0.0, 5.0], ["org", c.org, 0.0, 1.0],
				["Omega", c.Omega, 0.0, 1.0], ["canli_pay", c.canli_pay, 0.0, 1.0],
				["oto", c.oto, 0.0, 1.0], ["etg", c.etg, 0.0, 1.0]]:
			var v: float = alan[1]
			var alt: float = alan[2]
			var ust: float = alan[3]
			if is_nan(v) or is_inf(v) or not (alt - 1e-9 <= v and v <= ust + 1e-9):
				hata.append("%s.%s=%s" % [c.ad, alan[0], v])
		for alan2 in [["q", c.q], ["K", c.K], ["Y", c.Y]]:
			var v2: float = alan2[1]
			if is_nan(v2) or v2 <= 0.0:
				hata.append("%s.%s=%s" % [c.ad, alan2[0], v2])
	if not hata.is_empty():
		var ilk := []
		for i in range(mini(6, hata.size())):
			ilk.append(hata[i])
		_log("DEGISMEZ IHLALI", "; ".join(ilk))
	return hata
