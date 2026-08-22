class_name Gecmis
extends RefCounted

## B7 -- oyun katmaninin zaman serisi deposu.
##
## SUTUN DEPOSU, satir deposu degil. Bir kampanya 113 ulke x 265 ornek x 12
## metrik = ~350 000 deger eder; her ornegi bir `Dictionary` yapmak bunu
## nesne basina onlarca bayta cikarirdi. `PackedFloat64Array` kullanilir,
## `Float32` DEGIL -- panelde cizilen sayi motorun kendi sayisi olmali.
##
## ------------------------------------------------------------------------
## ORNEKLEME YILLIKTIR, HAFTALIK DEGIL
## ------------------------------------------------------------------------
## Olcu karari: haftalik ornek 13 728 satir eder ve tam kadroda ~150 MB'a
## cikar. Yillik ornek 265 satirdir (~3 MB) ve 200 piksellik bir grafik zaten
## bundan fazlasini gosteremez. Grafigin cozunurlugu ekranin cozunurlugunu
## asamaz; asarsa yalnizca bellek harcar.
##
## ORNEK ZAMANI TIK SAYARAK BULUNUR, `w.yil`e BAKARAK DEGIL. `yil` her tik
## 1/52 artar ve 52 tikten sonra 1837.0'a degil 1836.9999999999998'e varir;
## esik karsilastirmasi bu yuzden bir yil atlar ya da tekrarlar. Tik saymak
## kayan noktadan bagimsizdir ve ornek sayisi TAM olarak yil sayisi olur --
## kapinin sayabilecegi bir sey.

## Ornek araligi: 52 tik = 1 yil (haftalik dongu).
const YILDA_TIK := 52

## Metrik tanimlari (`Oyun.CEKIRDEK_METRIKLER`). Bu sinif kendi listesini
## TUTMAZ; iki yerin birbirinden kaymasi boylece imkansiz olur.
var metrikler: Array[Dictionary] = []

var ulke_sayisi: int = 0

## Her ornegin takvim yili. `_sutun` ile ayni satir sirasi.
var yillar: PackedFloat64Array = PackedFloat64Array()

## anahtar -> degerler. Duzlestirilmis: [ornek * ulke_sayisi + ulke].
var _sutun: Dictionary = {}


func kur(p_metrikler: Array[Dictionary], p_ulke_sayisi: int) -> void:
	metrikler = p_metrikler
	ulke_sayisi = p_ulke_sayisi
	yillar = PackedFloat64Array()
	_sutun = {}
	for m in metrikler:
		_sutun[String(m["anahtar"])] = PackedFloat64Array()


## Bir satir ekler. `Oyun` bunu 52 tikte bir cagirir.
##
## SALT OKUR. Kabuk motoru degistirmez; `--v2-oyun`un birinci kademesi bunu
## bayt bayt karsilastirarak sinar.
## `takvim` DISARIDAN verilir ve `w.yil`den OKUNMAZ. Sebep olculdu: `yil`
## her tik 1/52 ekleyerek birikir ve 52 tik sonra 1837.0'a degil
## 1836.9999999999998'e varir; `int()` bunu 1836'ya KIRPAR ve grafigin,
## guncenin ve ust seridin butun yil etiketleri bir yil geri kayar. Tik
## sayisindan turetilen deger tamdir.
func ornekle(w: Dunya, takvim: float) -> void:
	yillar.append(takvim)
	for m in metrikler:
		var anahtar := String(m["anahtar"])
		var sutun: PackedFloat64Array = _sutun[anahtar]
		var taban := sutun.size()
		sutun.resize(taban + ulke_sayisi)
		for i in range(ulke_sayisi):
			sutun[taban + i] = _oku(w.ulkeler[i], m)
		_sutun[anahtar] = sutun


## Metrik bir ALAN ya da bir ISLEV olabilir. Issizlik ikincisidir
## (`iss_duzeltilmis()`), cunku haritanin `issizlik` modu de onu kullanir ve
## panel ile harita ayni ulke icin farkli sayi gosterirse hangisinin dogru
## oldugu sorusu ekranda cevaplanamaz.
## `payda` verilirse deger BIR ORANDIR, ham alan degil.
##
## Olculdu ve ekranda yakalandi: `borc` ve `varlik` mutlak STOKTUR, ve panel
## onlari "Hanehalki borcu / Y" diye etiketleyip HAM STOKU gosteriyordu --
## Osmanli'da 244.34, yani hasilanin 244 kati gibi okunuyordu. Cekirdegin
## kendisi bu iki buyuklugu her kullandigi yerde `Y_yil`e boluyor
## (`kriz_cekirdegi.gd:499, 550, 966`); ekran da ayni seyi yapmali, yoksa
## eksen adi ile eksendeki sayi ayri seyler anlatir.
static func _oku(d: KrizDurumu, m: Dictionary) -> float:
	if m.has("islev"):
		return float(d.call(String(m["islev"])))
	var v := float(d.get(String(m["anahtar"])))
	if m.has("payda"):
		return v / maxf(float(d.get(String(m["payda"]))), 1e-9)
	return v


## Bir ulkenin bir metrigi boyunca zaman serisi.
func seri(anahtar: String, ulke: int) -> PackedFloat64Array:
	var c := PackedFloat64Array()
	if not _sutun.has(anahtar) or ulke < 0 or ulke >= ulke_sayisi:
		return c
	var sutun: PackedFloat64Array = _sutun[anahtar]
	var n := sutun.size() / ulke_sayisi
	c.resize(n)
	for k in range(n):
		c[k] = sutun[k * ulke_sayisi + ulke]
	return c


func ornek_sayisi() -> int:
	return yillar.size()


## Son ornegin degeri; ornek yoksa `NAN`. Panel "su anki deger"i buradan
## okur, motordan DEGIL: iki kaynak arasinda bir tik kaymasi olsun istemiyoruz.
func son(anahtar: String, ulke: int) -> float:
	if not _sutun.has(anahtar) or ulke < 0 or ulke >= ulke_sayisi:
		return NAN
	var sutun: PackedFloat64Array = _sutun[anahtar]
	if sutun.is_empty():
		return NAN
	return sutun[sutun.size() - ulke_sayisi + ulke]
