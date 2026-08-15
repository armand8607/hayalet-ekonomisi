class_name KrizParam
extends RefCounted

## Kriz cekirdeginin parametreleri.
##
## SABITLER ELLE KOPYALANMAZ. Depo kurali acik: "355 kalibrasyon sabitini elle
## kopyalamak kabul edilemez bir risktir -- tek basamak hatasi motoru sessizce
## degistirir ve oynayarak fark edilmez." Bu yuzden buradaki hicbir sayi elle
## yazilmaz; hepsi `ParamSet`'ten OKUNUR. `ParamSet` de donmus belgeden
## uretilmistir, yani zincir belgeye kadar izlenebilir.
##
## ISIMLENDIRME SOZLESMESI -- her cagri yerinde birimi gorunur kilar:
##
##   `P.v44.x`    -> DUZEY. Oran, pay, esik, us, katsayi. Zaman olceginden
##                   bagimsizdir, dogrudan kullanilir.
##   `P.x_yil`    -> DONUSTURULMUS. Buyume orani, akim ya da uyum katsayisi.
##                   Yillik tanimlidir; donem uzunluguna `Oran` ile cevrilir.
##
## Bir buyuklugu `P.v44.x` diye okuyorsan zamana bagli OLMADIGINI iddia
## ediyorsun demektir. Bu iddia yanlissa motor sessizce 14 kat hizli kosar.
##
## `const` DEGIL `var`: yon testleri parametreleri ORNEK BAZINDA degistirir
## (`p.fin_stok_yil = 0.0` gibi). v4.4'te de boyleydi, sebebi aynidir.

## Donmus kalibrasyonun kendisi. DUZEY parametreler buradan okunur.
var v44: ParamSet

# ---------------------------------------------------------------------------
# BUYUME  --  bilesik oranlar, (1+x)^(1/donem) ile cevrilir
# ---------------------------------------------------------------------------
var g_taban_yil: float
var g_tavani_yil: float
var g_daralma_tavani_yil: float
var qg_yil: float                  ## cag tablosundan, `cag_uygula()` yazar

# ---------------------------------------------------------------------------
# AKIM  --  donem basina eklenen/carpan buyuklukler, dogrusal olcek
# ---------------------------------------------------------------------------
var hizlandirici_yil: float
var gasp_varlik_yil: float
var fin_pay_yil: float
var fin_stok_yil: float
var spec_kredi_yil: float
var balon_sonum_yil: float
var delev_hiz_yil: float
var kredi_egilimi_yil: float
var omega_sonum_yil: float
var org_kent_yil: float
var org_kriz_yil: float
var org_baski_yil: float
var org_erozyon_yil: float
var egitim_org_yil: float
var lumpen_org_yil: float
var org_omega_yil: float
var asiri_uretim_yil: float
var som_refah_yil: float
var a1_yil: float
var a2_yil: float
var a4_yil: float
var a5_yil: float
var trend_asinma_yil: float        ## <1 sonum: (asinma)^donem

# ---------------------------------------------------------------------------
# UYUM  --  `x += a * (hedef - x)` katsayilari
# ---------------------------------------------------------------------------
var beklenti_hiz_yil: float
var oto_hiz_yil: float
var norm_uyum_yil: float
var kamu_uyum_yil: float
var e_norm_hiz_yil: float
var pc_hiz_yil: float
var parti_hiz_yil: float
var etg_yerlesme_yil: float
var kat_hiz_yil: float

# ---------------------------------------------------------------------------
# SURE  --  tur cinsinden sayaclar; donem sayisina cevrilir
# ---------------------------------------------------------------------------
var delev_sure_yil: float
var kont_sure_yil: float
var au_sure_yil: float
var au_bekleme_yil: float
var res_sure_yil: float
var res_bekleme_yil: float
var bun_sure_yil: float
var pr_sure_yil: float


func _init(kaynak: ParamSet = null) -> void:
	v44 = kaynak if kaynak != null else Params.make()

	# --- BUYUME ---
	g_taban_yil = Oran.v44_buyume(v44.g_taban)
	g_tavani_yil = Oran.v44_buyume(v44.g_tavani)
	g_daralma_tavani_yil = Oran.v44_buyume(v44.g_daralma_tavani)
	qg_yil = 0.0

	# --- AKIM ---
	hizlandirici_yil = Oran.v44_akim(v44.hizlandirici)
	gasp_varlik_yil = Oran.v44_akim(v44.gasp_varlik)
	fin_pay_yil = Oran.v44_akim(v44.fin_pay)
	fin_stok_yil = Oran.v44_akim(v44.fin_stok)
	spec_kredi_yil = Oran.v44_akim(v44.spec_kredi)
	balon_sonum_yil = Oran.v44_akim(v44.balon_sonum)
	delev_hiz_yil = Oran.v44_akim(v44.delev_hiz)
	kredi_egilimi_yil = Oran.v44_akim(v44.kredi_egilimi)
	omega_sonum_yil = Oran.v44_akim(v44.omega_sonum)
	org_kent_yil = Oran.v44_akim(v44.org_kent)
	org_kriz_yil = Oran.v44_akim(v44.org_kriz)
	org_baski_yil = Oran.v44_akim(v44.org_baski)
	org_erozyon_yil = Oran.v44_akim(v44.org_erozyon)
	egitim_org_yil = Oran.v44_akim(v44.egitim_org)
	lumpen_org_yil = Oran.v44_akim(v44.lumpen_org)
	org_omega_yil = Oran.v44_akim(v44.org_omega)
	asiri_uretim_yil = Oran.v44_akim(v44.asiri_uretim)
	som_refah_yil = Oran.v44_akim(v44.som_refah)
	a1_yil = Oran.v44_akim(v44.a1)
	a2_yil = Oran.v44_akim(v44.a2)
	a4_yil = Oran.v44_akim(v44.a4)
	a5_yil = Oran.v44_akim(v44.a5)
	# Sonum carpani: her tur x ile carpiliyor -> yillik x^(1/0.27).
	trend_asinma_yil = pow(v44.trend_asinma, 1.0 / Oran.V44_TUR_YIL)

	# --- UYUM ---
	beklenti_hiz_yil = Oran.v44_uyum(v44.beklenti_hiz)
	oto_hiz_yil = Oran.v44_uyum(v44.oto_hiz)
	norm_uyum_yil = Oran.v44_uyum(v44.norm_uyum)
	kamu_uyum_yil = Oran.v44_uyum(v44.kamu_uyum)
	e_norm_hiz_yil = Oran.v44_uyum(v44.e_norm_hiz)
	pc_hiz_yil = Oran.v44_uyum(v44.pc_hiz)
	parti_hiz_yil = Oran.v44_uyum(v44.parti_hiz)
	etg_yerlesme_yil = Oran.v44_uyum(v44.etg_yerlesme)
	kat_hiz_yil = Oran.v44_uyum(v44.kat_hiz)

	# --- SURE (tur -> yil) ---
	delev_sure_yil = Oran.yillik_sure(v44.delev_sure, Oran.V44_TUR_YIL)
	kont_sure_yil = Oran.yillik_sure(v44.kont_sure, Oran.V44_TUR_YIL)
	au_sure_yil = Oran.yillik_sure(v44.au_sure, Oran.V44_TUR_YIL)
	au_bekleme_yil = Oran.yillik_sure(v44.au_bekleme, Oran.V44_TUR_YIL)
	res_sure_yil = Oran.yillik_sure(v44.res_sure, Oran.V44_TUR_YIL)
	res_bekleme_yil = Oran.yillik_sure(v44.res_bekleme, Oran.V44_TUR_YIL)
	bun_sure_yil = Oran.yillik_sure(v44.bun_sure, Oran.V44_TUR_YIL)
	pr_sure_yil = Oran.yillik_sure(v44.pr_sure, Oran.V44_TUR_YIL)


## Cag tablosundaki tur basina uretkenlik buyumesini yilliga cevirip yazar.
func cag_uygula(era: int) -> void:
	qg_yil = Oran.v44_buyume(float(Tables.ERAS[clampi(era, 1, 6)]["qg"]))


## Bir sureyi (yil) donem sayisina cevirir. Sayaclar donem cinsinden tutulur.
static func sure_donem(yil: float, donem_yil: float) -> int:
	return maxi(1, Oran.donem_sayisi(yil, donem_yil))
