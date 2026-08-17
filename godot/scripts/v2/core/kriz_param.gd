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
##
## KALIBRE EDILDI (`--v2-dunya-siddet`, ikinci tablo). Once 1.5 ile tahmin
## edilmisti ve olculdugunde iki eksende birden kotu cikti:
##
##   itki   ort.itki   ZORLAMA   YAPI gradyani
##   0.00       1.00     0.000          -0.836
##   0.25       1.73     0.106          -0.784
##   0.50       2.46     0.423          -0.551   <-- secilen
##   1.00       3.93     0.536          -0.418
##   1.50       5.38     0.371          -0.218
##
## Odunlesme acik: itki buyudukce zorlama beliriyor ama altindaki YAPIYI
## siliyor -- "dis konum bunalimi belirler" gradyani asiniyor. 1.5'te zorlama
## bile DUSUYOR (0.536 -> 0.371), cunku herkes doyuma ulasip paylar sabitleniyor.
##
## Olcut: itki yapisal rekabet oranini EZMEMELI, MODULE ETMELI. `eps/pi_m`
## ulkeler arasi ~1.13-3.58 araliginda, yani 3.2 kat. 0.50'de itki carpani
## 1.0-2.5 (2.5 kat) ile bunun ALTINDA kalir; 1.0'da 1.0-4.0 ile asar.
## Uretkenlik kimin ne ihrac edecegini belirler, sikisma onu module eder --
## tersi degil.
var ihracat_itkisi: float = 0.50

## ANI DURUSUN ihracat itkisine ek carpani (D blogu).
##
## Dis finansmani kesilen ulke ithalatini ihracatiyla odemek ZORUNDADIR --
## kredi kapaninca cari denge bir tercih olmaktan cikar. Bu, borc krizini
## pazar kavgasina baglayan yerdir: temerrut esigine gelen ulke, kavgaya
## en sert giren ulkeye donusur.
##
## Itkinin kendisiyle ayni olcuye tabi (yapisal orani ezmemeli): 0.50 ile
## ani durustaki bir ulkenin carpani en fazla 2.5 * 1.5 = 3.75 olur.
var ani_durus_itkisi: float = 0.50

## MORATORYUM YILLIK TEHLIKE ORANI -- kosullar saglandiginda.
##
## v4.4'te bu TUR BASINA 0.20 idi (`motor.py:1805`) ve tur 0.27 yil oldugu
## icin yillik karsiligi ~0.74. Ilk portta `0.20 * donem_yil * 52/30` diye
## yazilmisti; `52/30` carpani hicbir yerden gelmiyor ve yillik 0.35 veriyor,
## yani v4.4'un yarisi. Kontrol edilmemis bir sayiydi, acikca yazildi.
##
## Donem uzunluguna `1 - (1-h)^dt` ile cevrilir, `h*dt` ile DEGIL: kucuk
## dt'de ikisi yakin ama yillik 0.74 gibi buyuk bir tehlikede dogrusal
## yaklasim olcek degismezligini kirar.
var mor_tehlike_yil: float = 0.74

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
# B3 -- KARANLIK DEVLET
#
# Iki gruba ayrilir ve ayrimi korumak onemlidir:
#
#   TASINAN : v4.4'un kendi karanlik devlet denklemlerinin katsayilari.
#             Hicbiri elle yazilmaz, hepsi `v44`ten okunup birim cevriminden
#             gecer -- deponun "355 sabiti elle kopyalama" kurali burada da
#             gecerli.
#   EKLENEN : `bolunme` ve karsi hareket. v4.4'te KARSILIGI YOK, dolayisiyla
#             okunacak bir sabit de yok; bunlar v2'nin kendi kalibrasyonudur
#             ve degerleri `--v2-bolunme-tarama` ile secilir.
# ---------------------------------------------------------------------------

## TASINAN -- uyusturucu yayiliminin akimlari (v4.4 tur basina tanimliydi).
var uo_omega_yil: float
var uo_iss_yil: float
var uo_gecim_yil: float
var uo_bastirma_yil: float
var uo_cozulme_yil: float
var kd_hiz_yil: float

## TASINAN -- egitim birikimi. v4.4: `egitim += harcama*0.25 - asinma*3*egitim`.
## Iki katsayi da TUR basinadir; `0.25` ve `3` carpanlari v4.4'un kendi
## formulunden gelir ve orada da ciplak sayilardi.
var egitim_harcama_yil: float
var egitim_asinma_yil: float

## EKLENEN -- riza taktiklerinin egitim tabanina saldirisi (yillik akim).
##
## Mistisizm cemaatten AGIR basar: tarikat agi egitimin yerini alir ama
## kendi icinde bir bilgi aktarimi surdurur; evrim karsitligi ve duz
## dunyacilik ise bilimsel yontemin kendisini hedef alir. Ikisi de `nitelik`
## uzerinden `qg`ye vurur, yani LTRPF'ye karsi elde kalan TEK karsi egilime.
var mistisizm_egitim_yil: float = 0.055
var cemaat_egitim_yil: float = 0.030

## EKLENEN -- cinsiyet baskisinin katilim kanali.
## `cinsiyet_katilim` bir DUZEYdir: taktik tam acikken katilimdan dusulen pay.
## 0.18 secildi -- kadin isgucu katiliminin bastirilmasinin tarihsel buyuklugu
## bu mertebededir ve `cezaevi_orani`nin (%2.5 tavan) bir mertebe ustundedir,
## yani rIza aygiti zor aygitindan DAHA COK canli emek maliyeti uretir.
var cinsiyet_katilim: float = 0.18
var cinsiyet_hiz_yil: float = 0.20   ## UYUM -- yerlesmesi ~5 yil

## EKLENEN -- zor taktiklerinin karseral formule dogrudan girisi (DUZEY).
## `tutuklama_karseral` tam acikken cezaevi oranina eklenen pay; tavan %2.5
## oldugu icin 0.010 tek basina orani ucte bir oraninda buyutur.
var tutuklama_karseral: float = 0.010
var sendika_baski_egilim: float = 0.35   ## grev kirma -> polis baskisi egilimi

## EKLENEN -- sehit stogu. Siyasi cinayetin gecikmeli `Omega` etkisi.
## Sonum 0.22/yil ~ 4.5 yillik hafiza: bir kusagin siyasi hafizasi.
##
## `sehit_org_yil` KISA vadeyi, `sehit_omega_yil` ORTA vadeyi tasir. Ikisinin
## ayni stoktan beslenmesi zorunludur -- ayri iki degiskene baglansaydi
## "once kirilir, sonra radikallesir" iliskisi kurulmus olmaz, iki bagimsiz
## etki yan yana durmus olurdu.
##
## OLCEK MOTORUN KENDI OLCEGIDIR, ve ilk yazimda DEGILDI. Cekirdegin
## orgutlenme akimlari yilda 0.006-0.013 mertebesindedir (`org_kent_yil`
## 0.0059, `org_kriz_yil` 0.0081, `org_baski_yil` 0.0130); ilk deger 0.30
## secilmisti, yani otuz kat buyuk. Sonucu olculdu: `org` 0.465'ten 0.04'e
## cokuyor, `Omega` onunla birlikte sonuyor ve devrim IMKANSIZ hale
## geliyordu -- §8.4'un birinci riski, tam olarak bir mertebe hatasindan.
## Yeni bir kanal eklerken buyuklugu KOMSU TERIMLERLE kiyaslanmali.
var sehit_itki_yil: float = 0.30
var sehit_sonum_yil: float = 0.22
var sehit_org_yil: float = 0.010
var sehit_omega_yil: float = 0.003

## EKLENEN -- BOLUNME ITKISI, taktik basina (yillik akim).
##
## Agirlik sirasi §4.1'den turer, keyfi degil: bolunmeyi asil ureten sey
## ofkenin HEDEFINI degistiren taktiktir. Milliyetcilik tam olarak budur
## (ic etnik gruplar, multeciler, irkcilik); cinsiyet baskisi ve paramiliter
## siddet onun yanindaki iki agir kol; uyusturucu ve cemaat zemini hazirlar;
## mistisizm, sendika baskisi ve tutuklama bolunmeyi ancak dolayli uretir --
## onlarin asil bedeli baska kanalda.
var bol_milliyetcilik_yil: float = 0.075
var bol_cinsiyet_yil: float = 0.045
var bol_paramiliter_yil: float = 0.040
var bol_uyusturucu_yil: float = 0.030
var bol_cemaat_yil: float = 0.030
var bol_mistisizm_yil: float = 0.015
var bol_sendika_yil: float = 0.015
var bol_tutuklama_yil: float = 0.010

## EKLENEN -- KARSI HAREKET (§4.4). Bolunme stokunu eriten kuvvetler.
##
## Sendika ve parti ayni buyuklukte DEGILDIR: parti dagInik ofkeyi sinifsal
## guce ceviren ozgul ozne oldugu icin (tam da karanlik devletin kirmaya
## calistigi kanal) agirligi sendikanin iki katidir. Parti iktidari ayrica
## bir SICRAMA getirir, carpan degil -- iktidar bir esik olayidir.
var bol_org_yil: float = 0.10
var bol_parti_yil: float = 0.20
var bol_iktidar_yil: float = 0.25
var bol_dayanisma_yil: float = 0.35

## EKLENEN -- karsi hareketin YAPISAL tarafi (DUZEY).
## Kentlesme itkiye direnir; dayanisma referansi, ucret payinin ustunde
## kazanimin "dayanisma kazanimi" sayildigi esik.
var bolunme_kent: float = 0.45
var dayanisma_ref: float = 0.45

## EKLENEN -- bolunmenin uc kanalinin siddeti ve TAVANLARI (DUZEY).
##
## Tavanlar zorunludur, kozmetik degil: §8.4 bu kolun yanlis kalibre
## edilirse devrimi IMKANSIZ kilabilecegini soyluyor. Tavan, bolunme 1.0'a
## dayansa bile kanalin tamamen kapanmamasini garanti eder -- yani bolunme
## devrimi ONLEMEZ, ERTELER.
var bolunme_org_kirilma: float = 0.70
var bolunme_org_tavan: float = 0.55
var bolunme_pazarlik: float = 0.75
var bolunme_pazarlik_tavan: float = 0.60
var bolunme_sonum_gucu: float = 0.55
var bolunme_sonum_tavan: float = 0.35

## OFKENIN BOLUNMEYI KIRDIGI DUZEY. `Omega` bu degere yaklastikca protesto
## sonumu ZAYIFLAR; bu duzeyde bolunme anlatisi artik tutmaz.
##
## §8.4'un sigortasi budur ve olcumle secildi (bkz. `protesto_sonum`).
## `omega_kritik` 0.6'dir, yani devrim esigi; 0.85 secilmesi "bolunme devrim
## esigine YAKLASILANA KADAR is gorur, o civarda cozulur" demektir. Daha
## kucuk bir deger kolu erken oldururdu, daha buyugu devrimi kapatirdi --
## §8.4'un iki riski tam olarak bu iki yondur.
var bolunme_omega_kirilma: float = 0.85

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

	# --- B3 KARANLIK DEVLET (tasinan katsayilar) ---
	# Hepsi v4.4'te TUR basinaydi. `egitim`in iki carpani (0.25 ve 3) v4.4'un
	# kendi formulunden gelir; orada da ciplak sayilardi ve buraya oldugu gibi
	# tasinir -- degistirmek bir port degil bir mekanizma degisikligi olurdu.
	uo_omega_yil = Oran.v44_akim(v44.uo_omega)
	uo_iss_yil = Oran.v44_akim(v44.uo_iss)
	uo_gecim_yil = Oran.v44_akim(v44.uo_gecim)
	uo_bastirma_yil = Oran.v44_akim(v44.uo_bastirma)
	uo_cozulme_yil = Oran.v44_akim(v44.uo_cozulme)
	kd_hiz_yil = Oran.v44_uyum(v44.kd_hiz)
	egitim_harcama_yil = Oran.v44_akim(0.25)
	egitim_asinma_yil = Oran.v44_akim(v44.egitim_asinma * 3.0)

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
