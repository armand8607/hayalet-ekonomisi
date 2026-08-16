class_name Dunya
extends RefCounted

## v2'nin DUNYA KATMANI -- ulkeler arasi deger akisi (v4.4'un C ve L bloklari).
##
## TEK KURAL:  **birinden eksilen digerine gider.**
##
##     sum(VT_net) == 0
##
## ve bu NORMALIZASYONLA degil INSAAT ILE saglanir. Her akim bir CIFT uzerinde
## tanimlidir ve ciftin iki ucuna ayni buyuklukte ters isaretle yazilir; ayni
## sayi iki yere birden gittigi icin gonderensiz alici OLAMAZ. Korunum bir
## dogrulama adimi degil, formun kendisidir.
##
## NEDEN BU KADAR ISRARLI -- v4.4'un kusuru olculdu. Orada (`motor.py:2162`)
## transfer her ulke icin BAGIMSIZ hesaplaniyordu:
##
##     VT_net = vt_siddet * Y * (wd1*d1 + wd2*d2) * disa
##
## `d1`/`d2` dunya ortalamasindan sapma oldugu icin toplamlari sifirdir -- ama
## `Y` ile CARPILDIKLARI icin agirlikli toplam sifir degildir. Ustune agirliklar
## ulke tipine gore degisiyor (`cevre` 0.9/0.1, digerleri 0.2/0.8) ve `disa`
## tek tarafli kirpiyor. Uc bagimsiz kirilma noktasi.
##
## Olculdu (tohum 42, varsayilan dunya, 20 ulke):
##
##     tur   25 : 20 ulkenin YIRMISI de negatif, sum(VT) = -19.6
##     tur 1000 : sum(VT) = +14964,  sum|VT| = 26304  ->  korunum hatasi %57
##
## Yani deger once dunyadan sizip yok oluyor, sonra yoktan yaratiliyor. v4.4'te
## "transfer" adi yanlisti: varis yeri hic modellenmemis bir SIZINTI vardi.
##
## MERKEZ/CEVRE FORMULE GIRMEZ. v4.4 agirliklari `c.tip == "cevre"` ile
## seciyordu. Burada ulke tipi diye bir girdi YOKTUR: kimin alici kimin verici
## oldugu organik bilesim farkindan DOGAR. Konum bir sonuctur, bir etiket
## degil -- ve tam da bu yuzden olculebilir bir iddiadir.

## Ticaret yogunlugu. Cift basina hacim gravite formundadir:
## `yogunluk * Y_i * Y_j / Y_dunya`. Iki ekonomi de buyudukce aralarindaki
## ticaret buyur, dunya buyudukce tek bir ciftin dunya icindeki payi kuculur.
var ticaret_yogunlugu: float = 1.0

## Deger transferinin olcek carpani.
##
## v4.4'un `vt_siddet`'i (0.05) BURAYA UYMAZ: o sabit, ulke basina bagimsiz
## hesaplanan ve `Y` ile carpilan baska bir formulun kalibrasyonuydu. Buradaki
## cift-bazli gravite formu bambaska bir geometridir, dolayisiyla ayni sayi
## ayni AGIRLIGI vermez -- olculdu, 0.05 ile |VT|/Y = 0.0053 cikiyor.
##
## Iki bagimsiz olcut ayni degeri gosteriyor (`--v2-dunya-siddet`):
##
##   siddet   |VT|/Y    ALAN dogru   VEREN dogru
##     0.05   0.0053          5/6           6/6
##     0.10   0.0115          6/6           6/6     <-- secilen
##     0.20   0.0239          6/6           5/6
##     0.80   0.1230          6/6           6/6
##
##   1. AGIRLIK: v4.4 varsayilan dunyada |VT|/Y ~ 0.01-0.03 uretiyordu
##      (olculdu). 0.10 o bandin alt ucuna oturuyor. Elimizdeki tek ampirik
##      capa bu; 0.80 kurali saglar ama hasilanin %12'sini transfer eder.
##   2. SAGLAMLIK: kuralin alti tohumun ALTISINDA da dogru isaret verdigi EN
##      DUSUK siddet. Daha yukarisi kurali guclendirmiyor, yalnizca buyutuyor.
##
## Kapiyi yesile boyamak icin secilmedi: 0.05 ile de medyanlar dogru isaretli
## ve test "geciyordu" -- ama alti tohumun yalnizca besinde, yani gurultude.
var siddet: float = 0.10

var ulkeler: Array[KrizDurumu] = []
var cekirdekler: Array[KrizCekirdegi] = []
var adlar: PackedStringArray = PackedStringArray()

## Disa aciklik [0,1]. Abluka/ambargo ve planli ekonominin dis ticaret kapanmasi
## buraya yazilir. CIFT BAZINDA ve SIMETRIK uygulanir (`min(a_i, a_j)`) --
## ticaret iki tarafin da razi olmasini ister. Tek tarafa uygulanirsa korunum
## kirilir; v4.4'un uc kirilma noktasindan biri tam olarak buydu.
var aciklik: PackedFloat64Array = PackedFloat64Array()

## Son tikin net transferleri (YILLIK akim, ulke basina).
var son_vt: PackedFloat64Array = PackedFloat64Array()

## Kampanya boyunca birikmis net alinan deger. Kim kazandi kim kaybetti
## sorusunun cevabi; olcut bunu okur.
var toplam_vt: PackedFloat64Array = PackedFloat64Array()

## Korunum kaydi: her tikte olculen bagil hata. Testin asil kaniti.
var en_buyuk_korunum_hatasi: float = 0.0

## Transferin AGIRLIGI: |VT|/Y'nin kosu boyunca ortalamasi. Kural yon olarak
## dogru olsa bile bu buyukluk kucukse mekanizma olculemez -- gurultuye
## gomulur. Kalibrasyonun gorunur olmasi icin kaydediliyor.
var _vt_y_toplam: float = 0.0
var _vt_y_say: int = 0

var yil: float = 1836.0


func _init(_p_ornek: KrizParam = null) -> void:
	pass


## Dunyaya bir ulke katar. Her ulkenin KENDI cekirdegi ve KENDI parametre
## kumesi olur: `KrizCekirdegi.adim` her cagride `P.cag_uygula(d.era)` yapar,
## yani paylasilan tek bir parametre blogu farkli caglardaki ulkeler arasinda
## sessizce dolasirdi. Ayrica politika ileride ulke bazinda ayrisacak.
func ekle(d: KrizDurumu, ad: String, tohum: int = 42, ulke_acikligi: float = 1.0) -> void:
	ulkeler.append(d)
	# Tohum ulkeye gore kaydirilir, yoksa butun ulkeler ayni devrim
	# cekilisini yapar ve dunya yapay olarak eszamanli hareket eder.
	var cekirdek := KrizCekirdegi.new(null, tohum + ulkeler.size() * 1000)
	cekirdek.baslat(d)
	cekirdekler.append(cekirdek)
	adlar.append(ad)
	aciklik.append(ulke_acikligi)
	son_vt.append(0.0)
	toplam_vt.append(0.0)


## Ulkeler arasi net deger transferini hesaplar (YILLIK akim).
##
## ESITSIZ MUBADELE. Ayni emek-saati farkli organik bilesimlerde farkli
## miktarda deger tasiyor; mubadele fiyat duzeyinde esitken deger duzeyinde
## esit degildir. Yuksek bilesimli taraf, verdiginden fazla deger ALIR.
##
## Cift basina akim:
##
##     T_ij = siddet * hacim_ij * (cv_i - cv_j) / (cv_i + cv_j)
##
## `T_ji = -T_ij` OZDESLIKLE saglanir: hacim simetrik, fark ise ters isaretli.
## Toplami bu yuzden sifirdir ve bu bir kalibrasyon degil, cebirdir.
func transferler() -> PackedFloat64Array:
	var n := ulkeler.size()
	var vt := PackedFloat64Array()
	vt.resize(n)
	vt.fill(0.0)
	if n < 2:
		return vt

	var Y_dunya := 0.0
	for d in ulkeler:
		Y_dunya += maxf(d.Y_yil, 0.0)
	if Y_dunya <= 0.0:
		return vt

	for i in range(n):
		for j in range(i + 1, n):
			var a := ulkeler[i]
			var b := ulkeler[j]
			# Gravite hacmi -- SIMETRIK, yani ciftin iki ucu icin ayni sayi.
			var hacim := (ticaret_yogunlugu
					* maxf(a.Y_yil, 0.0) * maxf(b.Y_yil, 0.0) / Y_dunya)
			# Aciklik ZAYIF HALKA ile girer: ticaret iki tarafin da razi
			# olmasini ister. Simetrik oldugu icin antisimetri bozulmaz.
			hacim *= minf(aciklik[i], aciklik[j])
			var toplam_cv := a.cv + b.cv
			if toplam_cv <= 0.0 or hacim <= 0.0:
				continue
			var t := siddet * hacim * (a.cv - b.cv) / toplam_cv
			vt[i] += t
			vt[j] -= t
	return vt


## Butun dunyayi bir donem ilerletir.
##
## TRANSFERLER ONCE, ADIMLAR SONRA. Akimlar tikin BASINDAKI durumdan
## hesaplanir ve ancak ondan sonra ulkeler ilerletilir. Ic ice yapilsaydi
## birinci ulkenin guncellenmis `cv`'si ikincinin transferine girer, sonuc
## ULKE SIRASINA bagli olurdu -- fizikte karsiligi olmayan bir esitsizlik.
func adim(donem_yil: float) -> void:
	var vt := transferler()
	_korunumu_kaydet(vt)
	for i in range(ulkeler.size()):
		var Y := ulkeler[i].Y_yil
		if Y > 0.0:
			_vt_y_toplam += absf(vt[i]) / Y
			_vt_y_say += 1
		cekirdekler[i].adim(ulkeler[i], donem_yil, {"VT_net_yil": vt[i]})
		toplam_vt[i] += vt[i] * donem_yil
	son_vt = vt
	yil += donem_yil


## Transferin ortalama agirligi: |VT|/Y. v4.4 varsayilan dunyada 0.01-0.03
## mertebesindeydi (olculdu); bu formul baska bir geometri oldugu icin ayni
## sabit ayni agirligi vermez.
func vt_agirligi() -> float:
	return _vt_y_toplam / maxf(float(_vt_y_say), 1.0)


## Bagil korunum hatasi: |sum(VT)| / sum|VT|. Sifir = tam korunum,
## 1 = hic korunmuyor (v4.4 son turda 0.57 veriyordu).
func korunum_hatasi(vt: PackedFloat64Array) -> float:
	var toplam := 0.0
	var mutlak := 0.0
	for v in vt:
		toplam += v
		mutlak += absf(v)
	if mutlak <= 0.0:
		return 0.0
	return absf(toplam) / mutlak


func _korunumu_kaydet(vt: PackedFloat64Array) -> void:
	en_buyuk_korunum_hatasi = maxf(en_buyuk_korunum_hatasi, korunum_hatasi(vt))


## Bir ulkenin kriz tescillerinin toplami.
func kriz_sayisi(i: int) -> int:
	var d := ulkeler[i]
	return (d.asiri_uretim_krizleri.size() + d.resesyonlar.size()
			+ d.bunalimlar.size())
