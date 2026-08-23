class_name Oran
extends RefCounted

## Donem uzunlugu donusumleri -- v2'nin 14 KATLIK TUZAGA karsi sigortasi.
##
## SORUN. v4.4'un butun oran ve akim parametreleri TUR BASINA tanimliydi ve
## 1 tur = 0.27 yildi. v2 haftalik kosuyor (1/52 yil), yani donem 14.04 KAT
## kisa. Parametreler oldugu gibi kopyalanirsa motor 14 kat hizli kosar:
## kar orani birkac yilda coker, kampanya anlamsizlasir. Ve bu OYNAYARAK FARK
## EDILMEZ -- egriler makul gorunur, yalnizca takvim yanlistir.
##
## COZUM. Donusumu dikkate birakmiyoruz, YAPISAL olarak imkansiz kiliyoruz:
## butun parametreler YILLIK saklanir (`KrizParam`), cekirdek hesabini YILLIK
## yapar, ve donem uzunlugu YALNIZCA stok guncellemesinde bir kez devreye
## girer. Boylece "donem uzunlugunu unutmak" diye bir hata kalmaz.
##
## HER PARAMETRE KENDI TURUNE GORE DONUSUR. Toplu carpan YOKTUR; bir buyume
## orani ile bir yumusatma katsayisi ayni sekilde donusmez.

## v4.4'un tur uzunlugu. Yalnizca eski parametreleri yilliga cevirirken
## kullanilir; v2'nin kendi kosusunda bir anlami yoktur.
const V44_TUR_YIL := 0.27

const HAFTA_YIL := 1.0 / 52.0


# ===========================================================================
# DONEM -> YIL  (eski parametreleri iceri alirken)
# ===========================================================================

## BUYUME: donem basina bilesik buyume orani -> yillik.
## Ornek: tur basina %0.8 birikim -> yillik %2.99.
static func yillik_buyume(x_donem: float, donem_yil: float) -> float:
	return pow(1.0 + x_donem, 1.0 / donem_yil) - 1.0


## UYUM: ussel yumusatma katsayisi (`x += a * (hedef - x)`) -> yillik.
## Donem basina kalma orani (1-a); yillik kalma orani (1-a)^(1/donem).
static func yillik_uyum(a_donem: float, donem_yil: float) -> float:
	return 1.0 - pow(1.0 - clampf(a_donem, 0.0, 0.999999), 1.0 / donem_yil)


## AKIM: donem basina eklenen/carpan bir buyukluk -> yillik. Dogrusal olcek.
static func yillik_akim(x_donem: float, donem_yil: float) -> float:
	return x_donem / donem_yil


## SURE: donem sayisi -> yil.
static func yillik_sure(n_donem: int, donem_yil: float) -> float:
	return float(n_donem) * donem_yil


## DUZEY: oran, pay, esik, us, katsayi -- DEGISMEZ.
##
## Cagrilmasi gereksiz gorunur ama gereklidir: her parametrenin turu
## `KrizParam` icinde ACIKCA yazilsin diye. Tur belirtilmeyen parametre,
## unutulmus parametredir.
static func duzey(x: float) -> float:
	return x


# ===========================================================================
# YIL -> DONEM  (kosu sirasinda)
# ===========================================================================

static func donem_buyume(x_yil: float, donem_yil: float) -> float:
	return pow(1.0 + x_yil, donem_yil) - 1.0


static func donem_uyum(a_yil: float, donem_yil: float) -> float:
	return 1.0 - pow(1.0 - clampf(a_yil, 0.0, 0.999999), donem_yil)


static func donem_akim(x_yil: float, donem_yil: float) -> float:
	return x_yil * donem_yil


## Yil -> donem sayisi. Yukari/asagi degil EN YAKINA yuvarlanir.
static func donem_sayisi(yil: float, donem_yil: float) -> int:
	return int(round(yil / donem_yil))


# ===========================================================================
# KOLAYLIK
# ===========================================================================

## v4.4 tur parametresini dogrudan yilliga cevirir.
static func v44_buyume(x_tur: float) -> float:
	return yillik_buyume(x_tur, V44_TUR_YIL)


static func v44_uyum(a_tur: float) -> float:
	return yillik_uyum(a_tur, V44_TUR_YIL)


## v4.4 TUR cinsinden bir SAYACI bu donemin sayacina cevirir.
##
## v4.4'un butun `*_sure` sabitleri tur (0.27 yil) cinsindendir. Haftalik
## donguye oldugu gibi kopyalanirsa sayac 14 KAT hizli dolar -- birim
## sozlesmesinin onlemek icin var oldugu hata tam olarak budur, ve
## `fx_baski >= 8` ile bir kez yasandi: 8 tur (2.16 yil) yerine 8 hafta
## (0.15 yil) beklendigi icin doviz krizi salgin haline geldi.
static func v44_sayac(tur: float, donem_yil: float) -> int:
	return maxi(1, donem_sayisi(tur * V44_TUR_YIL, donem_yil))


static func v44_akim(x_tur: float) -> float:
	return yillik_akim(x_tur, V44_TUR_YIL)
