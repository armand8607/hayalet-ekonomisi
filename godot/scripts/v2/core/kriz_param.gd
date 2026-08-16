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
# v2'YE OZGU  --  v4.4'te KARSILIGI YOKTUR
#
# Bunlar port degil, EKLEMEDIR. v4.4'un kendi kusurunu gidermek icin
# konuldular: orada brut yatirim `(g + delta)*K` idi ve amortisman talebi
# karliliktan BAGIMSIZ bir taban kuruyordu. Kar orani cokse ve net birikim
# dursa bile `delta*K` talebi ayakta tutuyor, dolayisiyla gerceklesme krizi
# kapali bir ekonomide ateslenemiyordu.
#
# Marx'ta boyle degildir: karlilik kayboldugunda kapitalist eskiyen sermayeyi
# YENILEMEZ bile -- parayi tutar ya da spekulasyona kaydirir. Yenileme
# yatirimi bu yuzden karliliga baglanir.
# ---------------------------------------------------------------------------

## Kar orani sifira dustugunde bile yapilan yenileme payi. Bakimin tamamen
## durmasi fiziksel olarak mumkun degil; taban bunu temsil eder.
var yenileme_taban: float = 0.30

## IHRACAT ITKISI -- gerceklesme baskisinin dis pazar arayisina donusme siddeti.
##
## Bu, "asiri uretim -> yeni pazar" iddiasinin (tasarim belgesi §3.1) motordaki
## KARSILIGIDIR ve olmadan o iddia bir temenniydi: ticaret paylari yalnizca
## uretkenlikten geliyordu, yani mallari satilamayan bir ulke ihracata daha
## fazla ASILMIYORDU. Zorlama yoksa pazar kavgasi da yoktur.
##
## Rekabet gucunu carpar: `k = (eps/pi_m) * (1 + itki * baski)`. Pay
## `k_i/(k_i+k_j)` oldugu icin ITKI SIFIR TOPLAMLIDIR -- iki taraf da ayni
## siddetle itiyorsa paylar DEGISMEZ. Tek basina iten kazanir, herkes
## itince kimse kazanmaz. Cin-ABD tipi bir pazar kavgasinin biciminde
## olmasinin sebebi budur ve bir olay tablosundan degil, `sum(NX) == 0`
## ozdesliginden gelir: dunya kendine ihracat yapamaz.
var ihracat_itkisi: float = 1.5

## Yenilemenin kar orani-faiz makasina duyarliligi. Buyudukce yatirim daha
## sert kesilir, konjonktur dalgasi derinlesir.
var yenileme_duyarlilik: float = 4.0

## SABIT SERMAYENIN DEVIR OMRU (yil). Amortisman fonu bu sure boyunca
## bosalir; yenileme talebinin cari hasiladan GECIKMESI budur.
##
## Marx bu devir cevrimini krizin periyoduna dogrudan baglar (Kapital II,
## bol. 9): sabit sermaye yillar boyu asinir ama toptan yenilenir, ve
## yenilemelerin kumelenmesi konjonktur dalgasini uretir. Tarihsel kayit da
## ayni mertebeyi veriyor -- 1825-1938 arasi 14 kriz, ortalama 8.1 yilda bir.
var yenileme_omru_yil: float = 10.0

## GERCEKLESME ENGELININ DOYUM OLCEGI. `talep_acigi` bu duzeye ulastiginda
## "uretime donmemek icin sebep" sinyali tam guce cikar.
##
## Kar sikismasi kanali (r < i_spec) ile AYNI sinyale beslenir, cunku ikisi de
## ayni soruya cevap verir: arti deger uretime mi doner, para sermayeye mi?
## `au_esik` (0.10) asiri uretim krizinin TESCIL esigidir; finansa kayis ondan
## once baslar ve daha derin bir tikanmada doyar, o yuzden ayri bir olcek.
var fin_tikanma_ref: float = 0.25

## AMORTISMAN FONUNUN FINANSA SIZAN PAYI. Yenilenmeyen sermayenin karsiligi
## fonda beklemez, faiz getiren sermayeye doner (Kapital II, bol. 20: fon atil
## PARA SERMAYEDIR). Yalnizca harcanmayan pay (1 - yenileme) icin gecerlidir:
## yenileme yapiliyorsa para zaten uretime donmustur.
var fin_sizinti: float = 0.5

## PARASALLASTIRMANIN TAVANI. Borc orani `kamu_borc_limiti`'ne ulastiginda
## acigin en fazla bu payi borclanma yerine emisyonla finanse edilir. 1.0
## degil, cunku tam parasallastirma parayi bir anda degersizlestirir; devlet
## her zaman bir miktar borclanmayi surdurur.
var parasallasma_tavani: float = 0.6

## Parasallastirilan acigin fiyat duzeyine gecis katsayisi. `parasallasma`
## hasilaya ORAN oldugu icin bu bir DUZEYDIR, zamana bagli degildir.
var ph_parasal: float = 0.5

## DEPARTMAN I / II -- Marx'in yeniden uretim semalari.
##
## Tek mallik bir modelde gerceklesme krizi YAPISAL OLARAK IMKANSIZDIR:
## yatirim talebi ile tuketim talebi ayni farksiz hasilayi satin alir,
## dolayisiyla biri digerinin yerine gecer ve orantisizlik dogamaz. Marx'ta
## kriz tam da bu orantisizliktan dogar: Departman I uretim araci uretir ve
## alicisi YATIRIMDIR; Departman II tuketim mali uretir ve alicisi UCRET ile
## kamu harcamasidir. Ikisi birbirinin yerine GECEMEZ.
##
## Sermayenin departmanlar arasi yeniden dagilimi YAVASTIR -- bir celik
## fabrikasi bir gecede ekmek fabrikasina donmez. Kriz bu yavasligin
## urunudur: patlama doneminde sermaye Departman I'e akar, yatirim
## coktugunde orada MAHSUR kalir ve satilamayan uretim araci yigilir.
var dept_uyum_yil: float = 0.15      ## yillik yeniden dagilim hizi (~7 yil)
var dept_pay_I: float = 0.35         ## baslangicta uretim araci sektorunun payi

# ---------------------------------------------------------------------------
# BUYUME  --  bilesik oranlar, (1+x)^(1/donem) ile cevrilir
# ---------------------------------------------------------------------------
var g_taban_yil: float
var g_tavani_yil: float
var g_daralma_tavani_yil: float
var qg_yil: float                  ## cag tablosundan, `cag_uygula()` yazar

## HASILA BUYUMESI VE ONA BAKAN ESIKLER.
##
## `y_buyume` v2'nin ilk yaziminda DONEM BASINA kaliyordu (`0.85*eski +
## 0.15*(Y/Y_onceki - 1)`, ikisi de cevrilmeden v4.4'ten kopyalanmis), ona
## bakan uc esik ise `P.v44.x` diye, yani ZAMANDAN BAGIMSIZ DUZEY gibi
## okunuyordu. Oysa ucu de v4.4'un TUR BASINA buyume oranlaridir -- kahinin
## kendi yorumu acik: "Tam puan alinan tur basi buyume".
##
## Sonucu tam olarak `Oran`'in engellemek icin yazildigi tuzaktir: haftalik
## kosuda `y_buyume` yillik kosudakinin ~1/52'si cikiyor, resesyon esigi
## haftalikta neredeyse hic, yillikta kolayca asiliyordu. Motor duz bir
## yorunge izlerken gorunmuyordu; cevrim dogunca K haftalik <-> yillik %34
## ayristi ve olcek testi yakaladi.
var y_buyume_uyum_yil: float       ## UYUM  -- v4.4 turu basina 0.15
var res_daralma_yil: float         ## BUYUME -- altini daralma sayar
var pc_buyume_ref_yil: float       ## BUYUME -- rizada tam puan alinan buyume
var kamu_buyume_taban_yil: float   ## BUYUME -- borc carpaninda buyume tabani

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

## KRIZ DEVALUASYONUNUN GERI DONUSU. v4.4:
##     deger_carpani += dev_geri * (1 - deger_carpani)
## Hedefi 1.0 olan bir UYUM katsayisidir, akim degil -- yanlis turden
## cevrilirse devaluasyon ya hic geri donmez ya da bir donemde silinir.
var dev_geri_yil: float

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
	y_buyume_uyum_yil = Oran.v44_uyum(0.15)
	res_daralma_yil = Oran.v44_buyume(v44.res_daralma)
	pc_buyume_ref_yil = Oran.v44_buyume(v44.pc_buyume_ref)
	kamu_buyume_taban_yil = Oran.v44_buyume(-0.02)

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
	dev_geri_yil = Oran.v44_uyum(v44.dev_geri)

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
