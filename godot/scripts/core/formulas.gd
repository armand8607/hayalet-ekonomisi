class_name Formulas
extends RefCounted

## Motorun modul duzeyi sabitleri ve SAF fonksiyonlari.
##
## Buradakiler durum tutmaz: ayni girdi her zaman ayni ciktiyi verir. Portun
## dogrulanmasinda ilk hedef bunlardir (katman 2) -- sabit bir girdi izgarasi
## uzerinde Python ile karsilastirilirlar ve motorun geri kalanindan bagimsiz
## olarak kanitlanabilirler.

## Model kimligi. `deney_kimligi()` ve butun raporlar bunu kullanir.
const SURUM := "v4.4-Frozen"

## BIRIM SOZLESMESI: butun oran ve akim parametreleri TUR BASINA tanimlidir.
## 1 tur = 0.27 yil (~bir ceyrek). Bunun onemli bir sonucu var: `Y` bir
## tur-akimidir, dolayisiyla sermaye/hasila katsayisi `kv` de tur cinsindendir
## ve YILLIK K/Y orani `kv * 0.27`'dir. Kodda kv ~ 22 gormek yillik K/Y ~ 5.9
## demektir.
const TUR_YIL := 0.27

const BASLANGIC_YILI := 1760
const BITIS_YILI := 2100

## int(round((2100 - 1760) / 0.27)) == 1259. GDScript'te const ifadeler
## fonksiyon cagiramadigi icin sabit yazildi; `kampanya_turu_dogru()` bunu
## calisma aninda dogrular ve parite kosusu da ayrica olcer.
const KAMPANYA_TURU := 1259

const P_BASLANGIC_CAGI := 1


## CPython'un `sum()` fonksiyonunun float davranisi -- NEUMAIER TELAFILI TOPLAMA.
##
## BU BIR IYILESTIRME DEGIL, ZORUNLULUKTUR. Python 3.12 `sum()`'i float dizileri
## icin gelistirilmis Kahan-Babuska (Neumaier) algoritmasina cevirdi; naif
## soldan-saga toplamayla ayni sonucu VERMEZ. Motor dunya ortalamalarini
## (`ort_cv`, `ort_sv`, `y_dunya`, `tot_L` ...) bu toplamlarla kuruyor ve
## `VT_net` bunlara bolunuyor; naif toplamayla port 1-3 ulp sapiyor ve sapma
## 1259 tur boyunca kaotik olarak buyur.
##
## Olculdu: ayni 20 terim icin `sum()` ile naif toplama `ort_cv_ham` ve
## `ort_sv_ham`'da farkli, `top`/`ort_q_ham`/`tot_L`'de tesadufen ayni cikiyor.
## Yani "cogu yerde tutuyor" aldaticidir; kural her yerde uygulanmalidir.
##
## DIKKAT: bu davranis PYTHON SURUMUNE BAGLIDIR. 3.11 ve oncesi naif toplar.
## Kahin baska bir surumle kosulursa parite kirilir.
##
## CPython akisi birebir: baslangic int 0'dir, ilk float terim `0 + x0` ile
## sonucu float'a cevirir ve telafi ANCAK ondan sonra baslar.
static func py_sum(degerler) -> float:
	var n: int = degerler.size()
	if n == 0:
		return 0.0
	var f := float(degerler[0])
	var c := 0.0
	for i in range(1, n):
		var x := float(degerler[i])
		var tt := f + x
		if absf(f) >= absf(x):
			c += (f - tt) + x
		else:
			c += (x - tt) + f
		f = tt
	return f + c


## CPython'un `round(x, n)` fonksiyonu -- `snappedf` DEGIL.
##
## `snappedf(x, 0.0001)` sonucu `floor(x/0.0001 + 0.5)*0.0001` ile hesaplar:
## yarimda sifirdan UZAGA yuvarlar ve bolme/carpma iki ek yuvarlama hatasi
## ekler. CPython ise sayiyi once DOGRU YUVARLANMIS ondalik metne cevirir
## (yarimda CIFTE yuvarlama), sonra geri okur. Ikisi son bitte ayrisir.
##
## Onemsiz gorunur ama degil: `bunalimlar` kaydindaki yuvarlanmis derinlik
## `kurumsal_gecis_isle` icinde `derin >= P.kg_derin_bunalim` esigine giriyor,
## yani bir ulp kurumsal rejim gecisini cevirebilir.
##
## Ondalik metin uzerinden gitmek C kutuphanesinin dogru yuvarlamasini
## kullanir ve CPython ile ayni sonucu verir.
static func py_round(x: float, n: int) -> float:
	return (("%%.%df" % n) % x).to_float()


## Tur basi bir oranin yillik bilesik karsiligi.
static func yillik(x_tur: float) -> float:
	return pow(1.0 + x_tur, 1.0 / TUR_YIL) - 1.0


## Lojistik (sigmoid). Girdi +/-60'a kirpilir -- Python tarafinda da ayni
## kirpma var ve `exp` tasmasini engelliyor.
static func sg(x: float) -> float:
	return 1.0 / (1.0 + exp(-clampf(x, -60.0, 60.0)))


## c/v'yi q'nun surekli fonksiyonu olarak verir (log-log parcali dogrusal).
##
## Capalar CAG TABLOSUNUN KENDI DEGERLERIDIR: her cagin c/v'si o caga giris
## esigindeki q ile eslesir, boylece cag esiklerinde eski kalibrasyon birebir
## korunur. Cag 6'nin capasinin OTESINDE son segmentin egimiyle ekstrapole
## edilir ve TAVANI YOKTUR -- kar oraninin dusme egiliminin yakiti budur.
## (Onceki surumde c/v cag basina sabit bir basamak fonksiyonuydu ve 15'te
## doyuyordu; egilim yakitsiz kaliyordu.)
## Capa noktalari ve segment egimleri BIR KEZ hesaplanir. Bu fonksiyon tur
## basina ~60 kez cagriliyor; her cagrida capalari yeniden kurup egimleri
## `log()` ile yeniden hesaplamak kampanya suresinin buyuk kismini yiyordu.
static var _q: PackedFloat64Array = PackedFloat64Array()
static var _cv: PackedFloat64Array = PackedFloat64Array()
static var _egimler: PackedFloat64Array = PackedFloat64Array()


static func _capalari_kur() -> void:
	if not _q.is_empty():
		return
	for c in Tables.cv_capalari():
		_q.append(float(c[0]))
		_cv.append(float(c[1]))
	for i in range(_q.size() - 1):
		_egimler.append(log(_cv[i + 1] / _cv[i]) / log(_q[i + 1] / _q[i]))


static func organik_bilesim(q: float) -> float:
	_capalari_kur()
	var qq := maxf(q, 1e-6)
	var n := _q.size()

	if qq <= _q[0]:
		return maxf(0.05, _cv[0] * pow(qq / _q[0], _egimler[0]))

	for i in range(n - 1):
		if qq <= _q[i + 1]:
			return _cv[i] * pow(qq / _q[i], _egimler[i])

	# Cag 6'nin capasinin OTESI: son segmentin egimiyle ekstrapole, TAVAN YOK.
	return _cv[n - 1] * pow(qq / _q[n - 1], _egimler[n - 2])


## Sabit yazilan KAMPANYA_TURU'nun turetimle uyustugunu dogrular.
static func kampanya_turu_dogru() -> bool:
	return KAMPANYA_TURU == roundi(float(BITIS_YILI - BASLANGIC_YILI) / TUR_YIL)
