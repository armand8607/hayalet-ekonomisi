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
	var hedef := 0.0
	for c in D:
		hedef += (kappa_v(Formulas.organik_bilesim(c.q), c.q) * c.q * c.L_max
				* hedef_istihdam / P.u_normal)

	var mevcut := 0.0
	for c in D:
		mevcut += c.K
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


func step() -> void:
	push_error("GhostEngine.step(): A-T bloklari henüz taşınmadı.")
