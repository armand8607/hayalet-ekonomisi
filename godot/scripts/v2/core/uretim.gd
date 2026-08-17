class_name UretimKatmani
extends RefCounted

## v2'nin MIKRO KATMANI -- sektor, bina, uretim yontemi.
##
## Tasarim belgesi §2.1 ve §5.11. Deger katmani (`KrizCekirdegi`) toplam
## buyuklukler uzerinde calisir; bu katman o toplamlarin NEREDEN geldigini
## kurar. Oyuncunun asil kolu buradadir ve §2.4'un tuzagi burada yasar:
##
##   uretim yontemi yukseltmesi -> q yukselir -> c/v yukselir -> r DUSER
##
## Tek tek binalar karli gorunurken toplam kar orani duser. Bu iddia bir
## mikro katman OLMADAN tanimsizdir; B2'nin ayirt edici olcutu budur.
##
## ------------------------------------------------------------------------
## OTORITE TABLOSU -- §8.2'nin (mikro-makro tutarsizligi) kapatilmasi
## ------------------------------------------------------------------------
## Her paylasilan alan icin KIM YAZAR sorusu bir kez karara baglanir; iki
## katman ayni alani yazarsa birbirini ezer ve hangisinin kazandigi kosu
## sirasina bagli olur -- bu, oynayarak fark edilmeyen bir hatadir.
##
##   ALAN        OTORITE   GEREKCE
##   K           mikro     binalarin birikmis insaat maliyeti (OZDESLIK)
##   q           mikro     aktif uretim yontemlerinin agirlikli seviyesi
##   oto         mikro     makine-agirlikli yontemlerin sermaye payi
##   pay_I       mikro     Dept I binalarinin sermaye payi
##   Y_K (kap.)  mikro     bina kapasitelerinin toplami
##   cv, kv      CEKIRDEK  q'dan turer -- mikro katman c/v'yi YAZMAZ
##   L, e, pay   CEKIRDEK  B2b'de pop katmanina gecer
##   Y_yil       CEKIRDEK  efektif talep belirler; mikro yalnizca kapasite verir
##   g, r        CEKIRDEK  §2.4: kar orani PIYASADAN OKUNMAZ, hesaplanir
##
## SERMAYE YOGUNLUGU CIFT YAZILMAZ. Bir basamagin "daha sermaye-yogun"
## olmasi buraya ELLE girilmez; `kappa_v(cv, q)` zaten q'ya bakar. Basamak
## yalnizca `q_carpan` (isci basina fiziksel cikti) ve `oto_pay` tasir,
## sermaye ihtiyaci cekirdegin `kv`'sinden TUREIR. Ikisi ayri ayri
## yazilsaydi tuzak iki kez sayilir ve kalibrasyon anlamsizlasirdi.
##
## ------------------------------------------------------------------------
## DUZ MERDIVEN OZDESLIGI -- bu katmanin port disiplini
## ------------------------------------------------------------------------
## Butun binalar 0. basamaktayken bu katmanin toplamlari cekirdegin kapali
## formunu BIREBIR yeniden uretir (`sum(K_i) == K`, `q = q_taban`,
## `sum(kapasite_i) == K/kv`). Yeni katman eskisini OZEL DURUM olarak
## icermelidir; icermiyorsa aradaki fark bir mekanizma degil bir hatadir.
## `--v2-uretim` bunu 1e-12 toleransla olcer.

# ===========================================================================
# SEKTORLER
# ===========================================================================

## §5.10: dort mal kategorisi (tuketim, sermaye, hammadde, luks). Sektor
## basina bir bina turu (§5.11) -- zenginlik tur sayisinda degil, URETIM
## YONTEMI MERDIVENINDE.
##
## `dept`: Marx'in yeniden uretim semasi. I = uretim araci (alicisi yatirim),
## II = tuketim mali (alicisi ucret ve kamu). Ikisi BIRBIRININ YERINE
## GECEMEZ; kriz tam da bu gecissizligin urunudur.
##
## `pay0`: 1836 baslangic sermaye dagilimi. Erken sanayi bir ekonomide
## sermayenin cogu tarim ve hammaddededir; agir sanayi kucuktur.
const SEKTORLER: Array[Dictionary] = [
	{"ad": "tarim",  "dept": 2, "mal": "tuketim",  "pay0": 0.34},
	{"ad": "maden",  "dept": 1, "mal": "hammadde", "pay0": 0.14},
	{"ad": "hafif",  "dept": 2, "mal": "tuketim",  "pay0": 0.26},
	{"ad": "agir",   "dept": 1, "mal": "sermaye",  "pay0": 0.18},
	{"ad": "luks",   "dept": 2, "mal": "luks",     "pay0": 0.08},
]

# ===========================================================================
# URETIM YONTEMI MERDIVENI
# ===========================================================================

## MERDIVEN URETILIR, ELLE YAZILMAZ -- ve tavani CAG TABLOSUNDAN gelir.
##
## Ilk yazimda merdiven elle yazilmis alti basamakti ve her basamak bir
## `era_min` tasiyordu. Olculdu ve YANLIS cikti: 200 yilda yalnizca 8
## yukseltme atesledi, q 1.00'dan ancak 2.13'e cikti -- oysa ayni pencerede
## kapali form 6.24 veriyor. Sebep, alti basamagin cag tablosunun mantigiyla
## uyusmamasiydi.
##
## Cag tablosu (`Tables.ERAS`) teknolojik gelismeyi soyle kuruyor: her cagin
## bir `q_tavan`i var (cag 2'de 8, cag 3'te 17, ... cag 6'da 200) ve q cag
## ICINDE o tavana dogru doyarak buyuyor. Yani cag, uretkenligin ULASABILECEGI
## TAVANI belirler -- hangi tek tek yontemin acildigini degil. Basamaklari
## `era_min` ile kapilamak bu mantigi tersine cevirmis ve 1836-1975 arasi 139
## yil boyunca merdiveni tek basamakta dondurmustu.
##
## Dogrusu: basamaklar INCE ve SUREKLIdir, cagin `q_tavan`i onlari yukaridan
## keser. Boylece yeni bir kalibrasyon sabiti eklenmez -- kapi zaten var olan
## tablodan gelir ve iki tablonun birbirinden kaymasi imkansizlasir.
##
## INCELIK NEDEN ONEMLI. Kaba basamak (1.55 kat) tek bir yatirim kararini
## uretkenligin yarisi kadar buyutur; o zaman q bir merdiven degil bir
## merdiven SAHANLIGI olur ve LTRPF'nin surekli baskisi kesikli sicramalara
## doner. %10'luk basamak, kararin maliyetini (sermayenin %45'i) kazanciyla
## ayni mertebede tutar.
const BASAMAK_SAYISI := 72
const BASAMAK_CARPANI := 1.10

## Otomasyonun basladigi ve doydugu URETKENLIK duzeyleri. Ikisi de cag
## tablosundan okunur (cag 4 ve cag 5'in `q_tavan`lari), yani otomasyon
## v4.4'teki gibi bir CAG ESIGINE degil TEKNIK DUZEYE baglidir -- geride
## kalan bir ulke 2000'e geldi diye otomatiklesmez.
const OTO_BAS := 36.0
const OTO_DOYUM := 80.0
const OTO_TAVAN := 0.80


## Bir basamagin uretkenlik carpani. 0. basamak 1.0'dir, yani duz merdivende
## toplam q tam olarak `q_taban`a esittir -- ozdeslik testinin dayandigi yer.
static func basamak_q(n: int) -> float:
	return pow(BASAMAK_CARPANI, float(n))


## Bir basamagin makine-agirlikligi. `d.oto` bunun sermaye-agirlikli
## ortalamasi olur; robotlar FIZIKSEL uretime katilir ama DEGER uretmez
## (cekirdek, `_arz_kapasitesi`).
static func basamak_oto(mutlak_q: float) -> float:
	return OTO_TAVAN * clampf((mutlak_q - OTO_BAS) / (OTO_DOYUM - OTO_BAS), 0.0, 1.0)

## Bir basamak yukseltmenin EK maliyeti, binanin sermayesine oran olarak.
##
## DIKKAT -- BU SAYI TEKNIGIN TOPLAM MALIYETI DEGILDIR. Teknigin asil bedeli
## deger katmaninda zaten odenmektedir: q yukselince c/v yukselir, `kv`
## buyur ve AYNI SERMAYE DAHA AZ KAPASITE verir. Buraya yontemin tam
## bedelini yazmak ayni maliyeti IKI KEZ saymaktir -- otorite tablosunun
## "sermaye yogunlugu cift yazilmaz" kurali tam olarak bunu yasaklar.
##
## Burada odenen sey yalnizca FARKTIR: yeni teknigi kurmak, eskisini oldugu
## gibi yenilemekten ne kadar pahalidir.
##
## OLCULDU VE ILK DEGER YANLISTI. Once 0.45 yazilmisti (binanin sermayesinin
## %45'i). `--v2-uretim-tarama`, capa olarak cekirdegin KAPALI FORMUNU alarak
## (o kalibrasyon `--v2-olcek` 23/23 ve `--v2-tarih`ten geciyor, yani
## uretkenlik buyume hizi bu motorda zaten sinanmis):
##
##   CAPA (mikro yok): q = 55.43,  ort r = 0.0425
##
##   maliyet   yukseltme   q(2036)   q/capa    ort r
##     0.450          15     1.331     0.02   0.06698
##     0.200          35     1.949     0.04   0.06728
##     0.100          80     4.595     0.08   0.06000
##    *0.050         203    48.524     0.88   0.04100
##     0.020         225    72.890     1.32   0.02744
##     0.010         225    72.890     1.32   0.02833
##     0.005         225    72.890     1.32   0.02892
##
## 0.050 secildi: capaya en yakin (log-uzaklik 0.133) ve ortalama kar orani
## da capayla ortusuyor (0.0410 / 0.0425).
##
## ESIGIN ALTI DOYUYOR. 0.02'nin altinda tablo DONUYOR -- 225 yukseltme,
## q = 72.89, hepsi ayni. Baglayici kisit artik maliyet degil CAGIN
## `q_tavan`i; daha ucuz teknik daha hizli gelisme uretmiyor. Bu, merdivenin
## cag tablosuna dogru bagli oldugunun kaniti: ucuzluk teknolojiyi
## sinirsizlastirmiyor.
var yukseltme_maliyeti: float = 0.05

## Brut yatirimin yukseltmeye ayrilan payi. Kalani yeni kapasiteye gider.
## Yogun (intensive) ve yaygin (extensive) birikim arasindaki bolusme.
var yukseltme_payi: float = 0.35

## Departmanlar arasi sermaye kaymasinin YILLIK hizi.
##
## Bu sayinin kucuk olmasi bir kusur degil MEKANIZMADIR: sermaye binalara
## GOMULUDUR ve isinmadigi departmana isinlanamaz. Tasarim belgesi §8.6 ve
## B1a notu: "Sermayenin departmanlar arasi yeniden dagilimi yavastir --
## kriz tam da bu yavasligin urunudur."
var dept_kayma_yil: float = 0.12

## Bir binanin yukseltilmesi icin gereken en az mikro marj iyilesmesi.
## Sifirdan buyuk olmasi gerekir, yoksa kapitalist her donem her binayi
## yukseltir ve merdiven bir kol olmaktan cikar.
var yukseltme_esigi: float = 0.02


# ===========================================================================
# BINA
# ===========================================================================

## Tek bir uretim birimi. Sektor basina bir tane degil -- ayni sektorde
## FARKLI BASAMAKTA binalar bir arada durur, cunku yukseltme sermaye ister
## ve hepsi ayni anda yukseltilemez. Teknik esitsizlik bu yuzden ULKE ICINDE
## de vardir; ortalama q bunun agirlikli sonucudur.
class Bina extends RefCounted:
	var sektor: int = 0
	var basamak: int = 0
	var K: float = 0.0

	## BIR UST BASAMAK ICIN BIRIKEN YATIRIM.
	##
	## Yukseltme TOPLU bir bedeldir, yatirim ise HAFTALIK bir akimdir; ikisi
	## dogrudan karsilastirilamaz. Ilk yazimda karsilastirildi ve sonucu
	## olculdu: haftalik yukseltme butcesi ~0.17 iken en kucuk binanin bedeli
	## ~44 idi, yani kosul 200 yilda BIR KEZ BILE saglanmadi -- merdiven
	## kuruldu ama hic tirmanilmadi, `--v2-uretim` 8/14 ile kaldi.
	##
	## Cozum taksitlendirmedir ve iktisadi olarak da dogrusudur: yeni teknik
	## yapi bir gunde satin alinmaz, PARCA PARCA INSA EDILIR. Odenen her
	## taksit ANINDA binanin sermayesine yazilir (`K += ...`), bu yuzden
	## `sum(bina.K) == d.K` ozdesligi kirilmaz -- para bir fonda beklemez,
	## yarim kalmis tesis olarak durur. Basamak ancak insaat tamamlaninca
	## doner ve o an bedel zaten odenmistir.
	var birikim: float = 0.0

	## Birikimin hedefi. Baslarken SABITLENIR: `K` insaat boyunca buyudugu
	## icin her adimda yeniden hesaplansaydi hedef kacar ve insaat asla
	## bitmezdi.
	var hedef_bedel: float = 0.0

	func _init(p_sektor: int = 0, p_basamak: int = 0, p_K: float = 0.0) -> void:
		sektor = p_sektor
		basamak = p_basamak
		K = p_K

	## Basamagin uretkenlik carpani -- ulkenin kendi tabanina GORE.
	func q_duzeyi() -> float:
		return UretimKatmani.basamak_q(basamak)

	func dept() -> int:
		return int(UretimKatmani.SEKTORLER[sektor]["dept"])


var binalar: Array[Bina] = []

## Baslangic uretkenlik duzeyi. Bina q'lari bunun basamak carpanlaridir,
## boylece duz merdivende toplam q tam olarak buna esit cikar.
var q_taban: float = 1.0

## TANI SAYACLARI -- test ve arayuz okur, mekanizma okumaz.
var yukseltme_sayisi: int = 0

## ONCU KARI. Her yukseltme aninda, yukselen binanin marjinin ulke
## ortalamasindan farki. Marx'in GOREL ARTI DEGER'inin motordaki karsiligi:
## once davranan, herkes yetisene kadar ortalamanin ustunde bir marj
## toplar. Tani icindir; mekanizma bunu okumaz.
var oncu_farklari: Array[float] = []


# ===========================================================================
# KURULUS
# ===========================================================================

## Cekirdegin `baslat()`indan SONRA cagrilir: `d.K` ve `d.q` orada kalibre
## edilir, bu katman onlari BOLUSTURUR, degistirmez.
##
## Butun binalar 0. basamakta baslar ve `q_taban = d.q` alinir; boylece
## `q_toplam()` tam olarak `d.q` doner. Kurulus bir kalibrasyon degil bir
## AYRISTIRMADIR -- toplamlar korunur.
func baslat(d: KrizDurumu) -> void:
	binalar.clear()
	q_taban = d.q
	var toplam_pay := 0.0
	for s in SEKTORLER:
		toplam_pay += float(s["pay0"])
	# Paylar normalize edilir ki `sum(bina.K) == d.K` OZDESLIK olsun,
	# tabloya yazilan sayilarin toplamina bagli olmasin.
	for i in range(SEKTORLER.size()):
		var pay := float(SEKTORLER[i]["pay0"]) / toplam_pay
		binalar.append(Bina.new(i, 0, d.K * pay))


# ===========================================================================
# TOPLAMLAR  --  mikro -> makro
# ===========================================================================

## Sermaye stoku. OZDESLIK: cekirdegin `d.K`si bundan baska bir sey degildir.
func K_toplam() -> float:
	var t := 0.0
	for b in binalar:
		t += b.K
	return t


## Bir binanin kapasitesi. Sermaye yogunlugu CEKIRDEKTEN gelir (`kv`), yani
## basamak kapasiteyi dogrudan buyutmez: ayni sermaye, ayni kapasite.
## Basamagin yaptigi sey o kapasiteyi DAHA AZ ISCIYLE uretmektir.
##
## Bu ve `emek_ihtiyaci` mekanizmada cagrilmaz -- `q_toplam` ve
## `kapasite_toplam` sadelesmis biciMLERINI kullanir. Yine de burada
## duruyorlar cunku TANIMDIRLAR: sadelesmelerin turetildigi yer bunlar, ve
## B2b (pop -> bina basina emek talebi) ile B2c (mal -> bina basina cikti)
## dogrudan bunlari okuyacak.
func kapasite(b: Bina, kv: float) -> float:
	return b.K / maxf(kv, 1e-9)


## Toplam kapasite (TUR akimi -- cekirdegin `Y_K`si ile ayni birimde).
## Duz merdivende `sum(K_i)/kv == K/kv`, yani cekirdegin kapali formu.
func kapasite_toplam(kv: float) -> float:
	return K_toplam() / maxf(kv, 1e-9)


## Bir binanin emek ihtiyaci: kapasitesini uretmek icin gereken emek.
func emek_ihtiyaci(b: Bina, kv: float) -> float:
	return kapasite(b, kv) / maxf(q_taban * b.q_duzeyi(), 1e-9)


## TOPLAM URETKENLIK -- bir secim degil bir OZDESLIK.
##
## q tanimi geregi "emek basina cikti"dir. Toplam cikti `sum(Y_i)`, toplam
## emek `sum(Y_i / q_i)` oldugu icin toplam q bunlarin oranidir. Agirlik
## secmek gerekmez; secilseydi duz merdivende bile cekirdekten sapabilirdi.
##
## `kv` SADELESIR ve bu onemlidir. `Y_i = K_i/kv` oldugu icin pay ve
## paydadaki 1/kv birbirini goturur: `q = sum(K_i) / sum(K_i/q_i)`. Yani bu
## katman q'yu hesaplarken cekirdegin `kv`sine IHTIYAC DUYMAZ -- oysa `kv`
## `cv`den, `cv` de `q`dan turer. Sadelesme olmasaydi zincir DAIRESEL olurdu
## ve hangi degerin once hesaplandigi sonucu belirlerdi. Kanit cebirsel
## oldugu icin kod da kv almaz: alsaydi ileride birinin onu bir yerde
## kullanmasi ve daireyi sessizce kapatmasi mumkun olurdu.
##
## Sonuc HARMONIK ortalamadir, aritmetik degil: dusuk basamakli binalar
## toplami asagi ceker cunku ayni ciktiyi uretmek icin cok daha fazla isci
## yerler. Teknik geriligin agirligi budur ve aritmetik ortalama onu
## sistematik olarak kucuk gosterirdi.
func q_toplam() -> float:
	var sermaye := 0.0
	var emek := 0.0
	for b in binalar:
		sermaye += b.K
		emek += b.K / maxf(b.q_duzeyi(), 1e-9)
	if emek <= 1e-12:
		return q_taban
	return q_taban * sermaye / emek


## SERMAYE AGIRLIKLI ORTALAMA MARJ -- ve bir OZDESLIK.
##
##     ort(marj) = sum(K_i * (1 - w/q_i)) / sum(K_i)
##               = 1 - w * sum(K_i/q_i)/sum(K_i)
##               = 1 - w / q_toplam()          (harmonik tanim geregi)
##               = 1 - pay                     (w = pay * q_toplam())
##
## Yani ULKE ORTALAMASI MARJ TEKNIKTEN TAMAMEN BAGIMSIZDIR; yalnizca ucret
## payina bakar. Bu bir kalibrasyon sonucu degil cebirsel bir ozdesliktir ve
## §2.4'un tuzaginin en keskin bicimidir:
##
##   > Teknik degismenin toplam kaybi, kararin VERILDIGI defterde
##   > GORUNMEZ. Orada yalnizca oncunun gecici kazanci vardir.
##
## Kayip yalnizca kar ORANINDA (r = s/K) gorunur, cunku onu asindiran sey
## `kv`nin buyumesi ve `canli_pay`in erimesidir -- ikisi de bina defterinde
## yazmayan makro buyukluklerdir.
func marj_ortalama(d: KrizDurumu) -> float:
	return 1.0 - d.pay


## Otomasyon payi -- makine-agirlikli yontemlerin SERMAYE agirlikli payi.
## Basamagin MUTLAK uretkenlik duzeyine bakar (`q_taban * carpan`), goreli
## basamak numarasina degil: otomatiklesme teknigin nerede oldugunun
## sonucudur, ulkenin kendi gecmisine gore ne kadar ilerledginin degil.
func oto_toplam() -> float:
	var t := 0.0
	var top_K := 0.0
	for b in binalar:
		t += b.K * basamak_oto(q_taban * b.q_duzeyi())
		top_K += b.K
	if top_K <= 1e-12:
		return 0.0
	return t / top_K


## Departman I'in sermaye payi. Cekirdekte `pay_I` YAVAS degisen bir skalerdi;
## artik binalarin fiili dagilimidir ve yavasligi yapisaldir.
func pay_I_toplam() -> float:
	var t := 0.0
	var top_K := 0.0
	for b in binalar:
		if b.dept() == 1:
			t += b.K
		top_K += b.K
	if top_K <= 1e-12:
		return 0.0
	return t / top_K


## MIKRO MARJ -- tek bir binanin kendi defterindeki karlilik gorunumu.
##
##     marj_i = (Y_i - w*L_i) / Y_i = 1 - w/q_i
##
## SATIS uzerinden marjdir, SERMAYE uzerinden kar orani DEGILDIR. Ayrim bu
## dosyanin en onemli ayrimi ve ilk yazimda YANLIS yapildi: marj
## `(Y_i - w*L_i)/K_i` diye yazilmisti, o da cebirsel olarak
## `(1 - w/q_i)/kv`ye esit -- yani icinde `kv` tasiyor. `kv` bir MAKRO
## buyukluktur (c/v'den turer) ve yukseltmeyle birlikte yukselir, dolayisiyla
## "mikro" marj makro tuzagi zaten iceriyordu. Olculdu: iki katman ayni
## isareti verdi (mikro -0.0033, makro -0.0123) ve tuzak olculemedi.
##
## Tek tek kapitalist ekonominin `kv`sini GORMEZ. Onun defterinde teknik
## degisme sudur: ayni ciktiyi daha az isciyle uretirim, ucret giderim
## duser, marjim yukselir. `kv`nin yukselmesi genel bir sonuctur ve yalnizca
## TOPLAMDA gorunur. Marx'in kar marji ile kar orani arasindaki ayrimi
## tam olarak budur ve oyunun tuzagi o ayrimda yasar.
func mikro_marj(b: Bina, ucret: float) -> float:
	return 1.0 - ucret / maxf(q_taban * b.q_duzeyi(), 1e-9)


# ===========================================================================
# ADIM  --  yatirimin bolusulmesi
# ===========================================================================

## Bir donem ilerletir. `yatirim` brut yatirimdir ve CEKIRDEK hesaplar
## (§2.4: birikim hizi deger katmanindadir); bu katman onu HARCAR.
##
## Sira onemlidir: once yukseltme (yogun birikim), sonra yeni kapasite
## (yaygin birikim). Tersi olsaydi yeni binalar hep en dusuk basamakta
## kurulur ve merdiven hic tirmanilamazdi.
func adim(d: KrizDurumu, donem_yil: float, yatirim: float) -> void:
	if yatirim <= 0.0 or binalar.is_empty():
		_asinma(d, donem_yil)
		return

	var ucret := _birim_ucret(d)
	var yuk_butce := yatirim * yukseltme_payi
	var yeni_butce := yatirim - yuk_butce
	# Harcanamayan yukseltme butcesi yeni kapasiteye doner: sermaye bosta
	# beklemez. (Bekleseydi bu bir tasarruf kanali olurdu ve motorda onun
	# yeri `amortisman`dir, burasi degil.)
	yeni_butce += _yukselt(d, yuk_butce, ucret)
	_yeni_kapasite(d, donem_yil, yeni_butce)
	_asinma(d, donem_yil)


## Ucret duzeyi -- binanin defterindeki emek gideri (emek birimi basina).
##
## Deger katmanindan TUREIR: ucret payi carpi hasila, bolu emek. Mikro
## katmanin kendi ucret pazarligi YOKTUR; o B2b'de pop katmaninin isidir.
##
## Sadelesme: `w = pay * (K/kv) / sum(K_i/(kv*q_i)) = pay * q_toplam()`.
## `kv` burada da goturuyor, yani ucret duzeyi ORTALAMA URETKENLIGE ve
## ucret payina baglidir, sermaye yogunluguna degil.
func _birim_ucret(d: KrizDurumu) -> float:
	return d.pay * q_toplam()


## YOGUN BIRIKIM -- uretim yontemi yukseltmesi.
##
## Kapitalist en cok MIKRO MARJ kazandiran binayi yukseltir. Oyunun merkezi
## tuzagi tam olarak buradadir: bu karar bina defterinde DOGRUDUR ve toplam
## kar oranini asindirir. Yanlis bir karar degil, celiskili bir karardir.
##
## Harcanmayan butceyi geri dondurur.
func _yukselt(d: KrizDurumu, butce: float, ucret: float) -> float:
	if butce <= 0.0:
		return 0.0

	# YARIM KALAN INSAAT TERK EDILMEZ. Devam eden bir yukseltme varsa butce
	# ona gider. Her donem yeniden en iyi adayi secseydik butce en karli
	# adayin pesinde dolasir, hicbir insaat bitmez ve merdiven yine
	# tirmanilmazdi -- taksitlendirmenin cozdugu sorunun ikinci bicimi.
	var secim := -1
	for i in range(binalar.size()):
		if binalar[i].birikim > 0.0 and _yukseltilebilir(binalar[i], d):
			secim = i
			break

	if secim < 0:
		var en_iyi_kazanc := yukseltme_esigi
		for i in range(binalar.size()):
			var b := binalar[i]
			if not _yukseltilebilir(b, d):
				continue
			var simdi := mikro_marj(b, ucret)
			b.basamak += 1
			var sonra := mikro_marj(b, ucret)
			b.basamak -= 1
			# Kazanc ORANSAL olculur, mutlak degil: marj [0,1] araliginda
			# doyan bir buyukluk oldugu icin ayni mutlak artis dusuk marjda
			# hayati, yuksek marjda onemsizdir.
			var kazanc := (sonra - simdi) / maxf(absf(simdi), 1e-9)
			if kazanc > en_iyi_kazanc:
				en_iyi_kazanc = kazanc
				secim = i
		if secim < 0:
			# Yukseltmeye deger aday yok: butce yaygin birikime doner.
			return butce
		binalar[secim].hedef_bedel = binalar[secim].K * yukseltme_maliyeti

	var b2 := binalar[secim]
	# Taksit ANINDA sermayeye yazilir -- ozdeslik burada korunur.
	b2.K += butce
	b2.birikim += butce
	if b2.birikim >= b2.hedef_bedel and b2.hedef_bedel > 0.0:
		b2.birikim -= b2.hedef_bedel
		b2.hedef_bedel = 0.0
		b2.basamak += 1
		yukseltme_sayisi += 1
		# ONCU KARI, yukseltmeden HEMEN SONRA olculur: bu binanin marji ile
		# ulke ortalamasinin farki. Ortalama marj `1 - pay`e ozdes oldugu
		# icin (bkz. `marj_ortalama`) fark tam olarak oncunun goreli teknik
		# ustunlugudur ve digerleri yetistikce SONER.
		oncu_farklari.append(mikro_marj(b2, ucret) - marj_ortalama(d))
		# Artan taksit bir sonraki insaata devredilmez: basamak dondugunde
		# hesap kapanir. Devretseydi ust basamaklar giderek ucuzlar ve
		# merdivenin sonuna dogru yukseltmeler hizlanirdi -- teknolojik
		# gelismenin ivmelenmesi bir mekanizma olarak SAVUNULABILIR ama
		# olculmeden konulmaz.
		b2.birikim = 0.0
	return 0.0


## Bir bina bir ust basamaga gecebilir mi: merdivenin sonunda mi, ve cagin
## uretkenlik TAVANI o basamaga izin veriyor mu.
##
## Kapi `era_min` degil `q_tavan`dir. Gerekcesi merdiven tanimindadir: cag,
## hangi yontemin acildigini degil uretkenligin nereye kadar cikabilecegini
## belirler. Bu ayni zamanda cag gecisini ANLAMLI kilar -- yeni cag yeni bir
## capa acar, birikim dalgasi yeniden baslar (tasarim belgesi §6, doyum notu).
func _yukseltilebilir(b: Bina, d: KrizDurumu) -> bool:
	if b.basamak + 1 >= BASAMAK_SAYISI:
		return false
	var E: Dictionary = Tables.ERAS[clampi(d.era, 1, 6)]
	return q_taban * basamak_q(b.basamak + 1) <= float(E["q_tavan"])


## YAYGIN BIRIKIM -- yeni kapasite.
##
## Sermaye departmanlar arasinda YAVAS kayar: hedef dagilim talebin
## departman bolusumunden gelir ama fiili dagilim ona `dept_kayma_yil`
## hiziyla yaklasir. Aninda kaysaydi orantisizlik dogamaz, dolayisiyla
## gerceklesme krizi de dogamazdi.
func _yeni_kapasite(d: KrizDurumu, donem_yil: float, butce: float) -> void:
	if butce <= 0.0:
		return
	var hedef_I := _hedef_pay_I(d)
	var fiili_I := pay_I_toplam()
	var uy := Oran.donem_uyum(dept_kayma_yil, donem_yil)
	var pay_I := fiili_I + uy * (hedef_I - fiili_I)

	# Departman icinde sektorler mevcut sermaye paylarina gore boluser:
	# yeni yatirim var olan yapiyi izler, sifirdan sektor kurmaz.
	var toplam_I := 0.0
	var toplam_II := 0.0
	for b in binalar:
		if b.dept() == 1:
			toplam_I += b.K
		else:
			toplam_II += b.K

	# BOS DEPARTMANIN PAYI DIGERINE GECER -- ozdeslik burada YAPISAL olarak
	# korunur. `maxf(toplam, 1e-9)` ile bolmek yeterli DEGILDIR: sermayesi
	# cok kucuk ama sifirdan buyuk bir departmanda payda gercek toplamdan
	# buyuk olur, dagitilan tutar butceden az kalir ve `sum(bina.K)` ile
	# `d.K` sessizce ayrisir. Kampanyada henuz olmadi (olculen sapma 1.5e-16)
	# ama "henuz olmadi" bir korunum garantisi degildir.
	if toplam_I <= 0.0 and toplam_II <= 0.0:
		return
	if toplam_I <= 0.0:
		pay_I = 0.0
	elif toplam_II <= 0.0:
		pay_I = 1.0

	for b in binalar:
		var dilim := 0.0
		if b.dept() == 1:
			dilim = butce * pay_I * (b.K / toplam_I) if toplam_I > 0.0 else 0.0
		else:
			dilim = butce * (1.0 - pay_I) * (b.K / toplam_II) if toplam_II > 0.0 else 0.0
		b.K += dilim


## Talebin departman bolusumu -- yatirim talebi Dept I'e, tuketim Dept II'ye.
## Cekirdek ikisini de hesapliyor; burada yalnizca okunur.
func _hedef_pay_I(d: KrizDurumu) -> float:
	var toplam := d.I_yil + d.C_yil + d.G_yil
	if toplam <= 1e-9:
		return pay_I_toplam()
	return clampf(d.I_yil / toplam, 0.10, 0.75)


## Cag gecisinde eskiyen sermaye binalardan dusulur. Cekirdek `K`yi
## `gecis_yikim` ile kirpiyordu; ozdeslik korunsun diye ayni kirpma
## binalara ORANTILI uygulanir ve en dusuk basamaklilar once kapanir.
func gecis_yikimi(oran: float) -> void:
	for b in binalar:
		b.K *= (1.0 - oran)


## Fiziksel asinma binalara YAZILMAZ: cekirdek amortismani zaten `kv` ve
## yenileme yatirimi uzerinden tasiyor. Burada iki kez dusulseydi sermaye
## stoku cekirdekten ayrisir ve ozdeslik kirilirdi. Yer tutucu olarak durur
## cunku B2c'de (mal piyasasi) kapanan bina mekanizmasi buraya baglanacak.
func _asinma(_d: KrizDurumu, _donem_yil: float) -> void:
	pass


## Butun toplamlari duruma YAZAR. Cekirdek bunu adiminin basinda cagirir;
## tek yazma noktasi olmasi otorite tablosunun kod icindeki karsiligidir.
func topla(d: KrizDurumu) -> void:
	d.K = K_toplam()
	d.q = q_toplam()
	d.oto = oto_toplam()
	d.pay_I = pay_I_toplam()


## Binalarin sektor-basamak dagilimi -- tani ve arayuz icin.
func basamak_dagilimi() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in binalar:
		out.append({
			"sektor": str(SEKTORLER[b.sektor]["ad"]),
			"basamak": b.basamak,
			"q": q_taban * b.q_duzeyi(),
			"K": b.K,
		})
	return out
