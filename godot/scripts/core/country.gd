class_name Country
extends RefCounted

# =============================================================
# BU DOSYA URETILMISTIR -- ELLE DUZENLEMEYIN.
# Kaynak : docs/hayalet_ekonomisi_v44_frozen.md (tek dogruluk kaynagi)
#          -> python/hayalet_ekonomi_motoru_v43.py
# Ureten : tools/gen_gdscript.py
# Yeniden uretmek icin: python tools/gen_gdscript.py
# =============================================================

## Bir egemen bolge -- Python `Country` sinifinin birebir karsiligi.
##
## TIPLER OLCUMLE BELIRLENDI, tahminle degil (`tools/probe_types.py`).
## Python'da `self.L_max = 110` diye baslayan alan demografi calisinca
## 110.37 olur; GDScript'te `int` diye tiplenirse bu SESSIZCE kirpilir ve
## nufus her tur asagi yuvarlanir. Hicbir hata cikmaz, motor yanlis calisir.
##
## `null` tasiyabilen alanlar TIPSIZ birakildi: motor 'henuz olmadi'
## durumunu null ile anlatiyor (devrim_t == null -> devrim olmadi),
## sifirla degil. Tipli bir alana null atanamaz.

var ad: String = ""
var tip: String = "merkez"
var K: float = 0.0
var L_max: float = 0.0
var q: float = 0.0
var pay: float = 0.0
var IR: float = 0.0
var baski_egilimi: float = 0.0
var saldirganlik: float = 0.0
var rejim: String = "kapitalist"
var era: int = 1
var Omega: float = 0.05
var u: float = 0.82
var e: float = 0.9
var r: float = 0.04
var g: float = 0.02
var PKE: float = 0.0
var plan: Dictionary = {"yatirim": 0.3, "tuketim": 0.55, "arge": 0.1, "savunma": 0.05}
var plan_hedef = null
var kitlik: float = 0.0
var parti_iktidari: bool = false
var pakt_durusu: String = "ittifak"
var ideolojik_mesafe: float = 0.0
var izo_sayac: int = 0
var restorasyon_t = null
var VT_net: float = 0.0
var kriz: int = 0
var pr_sayac: int = 0
var devrim_t = null
var baslangic_rejimi_t = null
var devrim_era = null
var PC: float = 1.0
var savas: Dictionary = {}
var abluka: int = 0
var ambargo: bool = false
var muttefik: Array = []
var savas_toplam: int = 0
var savas_sayisi: int = 0
var gecis_sok: int = 0
var borc: float = 0.0
var varlik: float = 0.0
var Y: float = 1.0
var Y_zirve: float = 1.0
var delev: int = 0
var norm: float = 0.72
var org: float = 0.08
var i_pol: float = 0.0106
var i_ef: float = 0.0106
var i_ham: float = 0.0106
var i_reel: float = 0.0106
var i_spec: float = 0.0106
var varlik_beklenti: float = 0.0
var minsky_sayac: int = 0
var FX: float = 0.35
var eps: float = 1.0
var pi_m: float = 1.0
var cari: float = 0.0
var BoP_R: float = 0.0
var fx_kriz: int = 0
var fx_baski: int = 0
var deval: float = 0.0
var y_buyume: float = 0.02
var fx_krizleri: Array = []
var pi_inf: float = 0.0054
var pi_bek: float = 0.0054
var p_duzey: float = 1.0
var w_nom: float = 1.0
var w_nom_buyume: float = 0.0054
var q_buyume: float = 0.0
var e_norm: float = 0.88
var katilim: float = 1.0
var etg_hedef: float = 0.0
var etg: float = 0.0
var etg_metasiz: float = 0.0
var etg_sermaye_payi: float = 0.5
var etg_vergi_sermaye_o: float = 0.0
var etg_vergi_ucret_o: float = 0.0
var cs_kisit: int = 0
var katilim_etg: float = 0.0
var deger_carpani: float = 1.0
var ito: float = 1.0
var ito_bilesen: Array = [0.0, 0.0, 0.0, 0.0]
var oto: float = 0.0
var canli_pay: float = 1.0
var V_yeni: float = 0.0
var saat: float = 1.0
var stagflasyon: int = 0
var hegemon: bool = false
var heg_sayac: int = 0
var kurum: String = "neoliberal"
var kurum_t: int = 0
var kurum_gecmis: Array = []
var kurum_insa_t: int = -9999
var kurum_insa_hedef = null
var ai_muaf: bool = false
var pol_kuyruk: Dictionary = {}
var kredi_durusu: float = 1.0
var yatirim_durusu: float = 0.0
var ticaret_durusu: float = 0.0
var kamu_borc: float = 0.0
var vergi_geliri: float = 0.0
var vergi_carpani: float = 1.0
var kemer: int = 0
var kamu_pay: float = 0.08
var kontrol: int = 0
var bastirilmis_pi: float = 0.0
var dis_borc: float = 0.0
var mor_ceza: int = 0
var moratoryumlar: Array = []
var goc_net: float = 0.0
var egitim: float = 0.08
var temerrutler: Array = []
var bunalimlar: Array = []
var resesyonlar: Array = []
var Y_ort: float = 1.0
var Y_trend: float = 1.0
var res_ici: int = 0
var res_bekle: int = 0
var talep_acigi: float = 0.0
var parti: float = 0.0
var orgutlu: float = 0.0
var au_ici: int = 0
var au_bekle: int = 0
var asiri_uretim_krizleri: Array = []
var olay_bayraklari: Dictionary = {}
var birincil_kriz = null
var kriz_gunlugu: Array = []
var bun_ici: int = 0
var uyusturucu_orani: float = 0.01
var cezaevi_orani: float = 0.003
var mafya_tolerans: float = 0.0
var mafya_kilit = null
var kd_hedef: float = 0.0
var lumpen_pay: float = 0.0
var gasp: float = 0.0
var s_v: float = 1.0
var dogum_orani: float = 0.0   # _init icinde tip'e gore atanir
var olum_orani: float = 0.0   # _init icinde tip'e gore atanir

## Tur-tur kayit. Python'da duz bir dict listesi; burada SUTUN DEPOSU
## (bkz. history.gd) -- bir kampanya 20 ulke x 1259 tur x ~60 alan eder.
var tarih := History.new()


func _init(p_ad: String = "", p_tip: String = "merkez", p_K: float = 0.0,
		p_L_max: float = 0.0, p_q: float = 0.0, p_pay: float = 0.0,
		p_IR: float = 0.0, p_baski_egilimi: float = 0.0,
		p_saldirganlik: float = 0.0) -> void:
	ad = p_ad
	tip = p_tip
	K = p_K
	L_max = p_L_max
	q = p_q
	pay = p_pay
	IR = p_IR
	baski_egilimi = p_baski_egilimi
	saldirganlik = p_saldirganlik

	# Referans tipler ornek basina TAZE olmali. GDScript'te `var d := {}`
	# alan varsayilani her ornek icin yeni bir sozluk uretir, ama plan gibi
	# ic ice yapilarda paylasim riskini tamamen kesmek icin burada
	# yeniden kuruluyor -- bir ulkenin planini degistirmek digerininkini
	# degistirmemeli.
	plan = {"yatirim": 0.3, "tuketim": 0.55, "arge": 0.1, "savunma": 0.05}
	savas = {}
	muttefik = []
	pol_kuyruk = {}
	olay_bayraklari = {}
	for liste in ["fx_krizleri", "moratoryumlar", "temerrutler", "bunalimlar",
			"resesyonlar", "asiri_uretim_krizleri", "kriz_gunlugu", "kurum_gecmis"]:
		set(liste, [])
	ito_bilesen = [0.0, 0.0, 0.0, 0.0]
	tarih = History.new()

	FX = 0.35 * Y

	# Baslangic kaba dogum/olum oranlari (tip ve gelismisliğe bagli).
	match tip:
		"merkez":
			dogum_orani = 0.012
			olum_orani = 0.008
		"yari":
			dogum_orani = 0.018
			olum_orani = 0.006
		_:   # cevre
			dogum_orani = 0.026
			olum_orani = 0.006


## Is paylasimi marjinin alt siniri.
func saat_tabani(P: ParamSet) -> float:
	return P.saat_min


## Fiili haftalik calisma suresi (cag normu x paylasim payi).
## Raporlama icindir: 1.00 = 1760'in tam haftasi (~70 saat).
func hafta_saati(P: ParamSet) -> float:
	return float(P.hafta_norm[mini(era, 6) - 1]) * saat


## Karseral nufus dusulmus ETKIN isgucu arzi.
## Itoh: hapsedilen kitle artik arti-deger uretiminin oznesi degil,
## "atil sermaye" yonetiminin nesnesidir; emek arzindan dusulur.
func l_etkin() -> float:
	return L_max * katilim * (1.0 - minf(0.90, cezaevi_orani))


## ETG'nin gonullu cekilmesi geri eklenmis issizlik orani.
## ETG katilimi dusurur, bu da OLCULEN istihdam oranini mekanik olarak
## yukseltir -- gercek bir etki ama ETG'nin is yaratmasiyla karistirilmamali.
func iss_duzeltilmis() -> float:
	if katilim_etg <= 0.0:
		return 1.0 - e
	return 1.0 - e * katilim / maxf(katilim + katilim_etg, 1e-9)


## KODEY: karseral nufus / uretken emek gucu.
func atil_endeks() -> float:
	return cezaevi_orani / maxf(1.0 - cezaevi_orani, 1e-6)


func savasta() -> bool:
	return savas.size() > 0


func guc() -> float:
	return K * q
