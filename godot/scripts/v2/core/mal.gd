class_name MalKatmani
extends RefCounted

## v2'nin MAL PIYASASI -- B2c.
##
## Tasarim belgesi §5.10. Victoria'nin ~50 mali degil DORT KATEGORI, ve
## katmanin bu oyundaki isi tek:
##
##   > Satilamayan mal yigini GORUNUR olsun. Gerceklesme krizi bir sayi
##   > olarak degil, depoda biriken bir KUTLE olarak okunmali.
##
## ------------------------------------------------------------------------
## AKIM DEGIL STOK -- B2c'nin tek yapisal iddiasi
## ------------------------------------------------------------------------
## Cekirdek satilamayan urunu `satilamayan_I` / `satilamayan_II` diye
## tutuyordu, ama bunlar AKIMDIR: o donem satilamayan miktar, ve donem
## bitince buharlasir. Bir akimin HAFIZASI yoktur, dolayisiyla:
##
##   - kriz ANLIKTIR: talep toparlaninca acik ayni anda kapanir
##   - toparlanma BEDELSIZDIR: dolu bir depo sonraki donemi kisitlamaz
##   - cevrimin SURESI yoktur; yalnizca esik gecisleri sayilir
##
## Marx'ta asiri uretim krizi tam olarak bir YIGIN sorunudur: mallar satilmaz,
## depoda birikir, kapitalist dolu depoya uretim yapmaz, uretim kisilir,
## istihdam duser, talep daha da duser. Krizi SUREKLI kilan sey stokun
## kendisidir. Akimla bu zincir kurulamaz -- ve kurulamadigi icin `--v2-tarih`
## krizleri sayabiliyor ama SURELERINI uretemiyordu.
##
## Bu katmanin tek yapisal eklemesi budur: `stok += uretim - satis`.
##
## ------------------------------------------------------------------------
## KORUNUM
## ------------------------------------------------------------------------
## Kategorinin defteri her donem birebir kapanir:
##
##     stok_yeni == stok_eski + uretim - satis
##
## `Dunya`nin `sum(VT) == 0`i ve `NufusKatmani`nin `sum(kohort)`u ile ayni
## disiplin. Satis asla arzi (stok + uretim) asamaz, dolayisiyla stok negatife
## dusemez -- bu bir kirpma degil, `min` ile YAPISAL olarak saglanir.
##
## ------------------------------------------------------------------------
## OTORITE
## ------------------------------------------------------------------------
##   ALAN            OTORITE   GEREKCE
##   stok            mal       tek sahibi
##   talep_acigi     mal       artik akim orani degil STOK fazlasi
##   satilamayan_I/II mal      kategorilerden toplanir (tani olarak korunur)
##   Y, Y_I, Y_II    CEKIRDEK  uretim karari deger katmanindadir
##   kap_I, kap_II   CEKIRDEK  kapasite mikro katmandan gelir

## §5.10'un dort kategorisi. `dept` Marx'in yeniden uretim semasindaki yeri:
## uretim araci ve hammadde Departman I, tuketim ve luks Departman II.
##
## `pay0` departman ICINDEKI baslangic bolusumu -- iki kategori ayni
## departmanda oldugunda kapasitenin ve talebin nasil bolundugu.
enum {TUKETIM, SERMAYE, HAMMADDE, LUKS}

const MALLAR: Array[Dictionary] = [
	{"ad": "tuketim",  "dept": 2, "pay0": 0.82},
	{"ad": "sermaye",  "dept": 1, "pay0": 0.62},
	{"ad": "hammadde", "dept": 1, "pay0": 0.38},
	{"ad": "luks",     "dept": 2, "pay0": 0.18},
]

## Kac donemlik uretim kadar stok "normal" sayilir. Uzerine cikildiginda
## fazla yigin sayilir ve uretimi kisar.
##
## Bir stok/akim oranidir, dolayisiyla YIL cinsinden tanimlanir -- donem
## basina tanimlansaydi haftalik kosuda 14 kat kucuk olur ve depo hic
## dolmadan kriz ateslerdi. Deponun en pahali tuzagi (bkz. CLAUDE.md).
var normal_stok_yil: float = 0.25

## Fazla yiginin uretimi kisma siddeti. Sifir olursa stok yalnizca BIRIKIR
## ama hicbir seyi etkilemez -- karsi-olgusal kolun kapisi budur.
##
## KALIBRE EDILDI (`--v2-mal-tarama`) ve capa BU KEZ TARIHSELDIR, cekirdegin
## kapali formu DEGIL. Sebep: kapali formda asiri uretim epizodu ortalama
## 15.7 YIL suruyor, yani capa olacak buyukluk orada zaten bozuk -- bir kriz
## degil kalici bir durum. Tarihsel kayitta asiri uretim krizleri 1-3 yil
## surer.
##
##   kisma  erime   epizot   ort sure   ort acik
##    0.05   0.20        8      19.48     0.3504
##    0.20   0.20       13       9.30     0.1401
##    0.28   0.20       26       3.72     0.1026
##    0.30   0.20       27       3.65     0.0970
##   *0.33   0.20       43       2.07     0.0881
##    0.36   0.20       50       1.46     0.0805
##    0.60   0.20       78       0.21     0.0349
##
## 0.33 secildi: 2.07 yil ile bandin ortasinda.
##
## IKI CAPA CELISIYOR VE SECIM KAYDA GECIYOR. Epizot SAYISI icin en iyi
## deger 0.30 (27 epizot, tarihsel 27 ile birebir), SURE icin 0.33 (2.07 yil).
## Sure secildi cunku B2c'nin iddiasi suredir; sayiyi `--v2-tarih` zaten
## kendi olcutuyle kapiliyor. 43 epizot tarihsel 27'nin ustunde, ama bu
## B2c'nin getirdigi bir fazlalik degil: B1a'dan beri bilinen "model
## tarihten daha kriz-yatkin" ozelligi (19.2'ye karsi 12.1 olay/100 yil).
var yigin_kisma: float = 0.33

## Stokun kendiliginden erimesi (YILLIK). Mallar bozulur, demode olur,
## indirimle elden cikarilir. Sifir olsaydi bir kez biriken yigin sonsuza
## kadar kalir ve ekonomi hic toparlanamazdi.
var erime_yil: float = 0.20


## Kategori stoklari (kutle, hasila ile ayni birimde).
var stok: PackedFloat64Array = PackedFloat64Array()

## TANI -- test ve arayuz okur, mekanizma okumaz.
var son_uretim: PackedFloat64Array = PackedFloat64Array()
var son_satis: PackedFloat64Array = PackedFloat64Array()

## `max(0, ...)` KORUMASININ ATESLENDIGI EN BUYUK MIKTAR.
##
## Defter `stok += uretim - satis` ile kapanir ve `satis <= arz` oldugu icin
## sonuc matematiksel olarak negatif OLAMAZ. Koruma yine de duruyor, ve bu
## alan onun hic ateslenmedigini OLCUYOR: ateslendigi an demektir ki akim
## birimleri karismistir (`donem_yil` bir yerde unutulmustur) -- deponun en
## pahali tuzaginin bu katmandaki gorunumu. Sifirdan buyukse korunum
## iddiasi gecersizdir.
var koruma_atesledi: float = 0.0


func baslat(_d: KrizDurumu) -> void:
	stok.resize(MALLAR.size())
	son_uretim.resize(MALLAR.size())
	son_satis.resize(MALLAR.size())
	for i in range(MALLAR.size()):
		stok[i] = 0.0
		son_uretim[i] = 0.0
		son_satis[i] = 0.0
	koruma_atesledi = 0.0


## Bir kategorinin stok/uretim orani (YIL cinsinden). Kriz okumasi bunun
## uzerinden yapilir: "kac donemlik satilamayan mal birikti".
func stok_orani(i: int) -> float:
	return stok[i] / maxf(son_uretim[i], 1e-9)


## FAZLA YIGIN -- normal stokun uzerindeki kisim, hasilaya oranli.
## `talep_acigi`nin yerine gecen buyukluk.
func fazla_yigin(Y_pot: float) -> float:
	var t := 0.0
	for i in range(MALLAR.size()):
		t += maxf(0.0, stok[i] - son_uretim[i] * normal_stok_yil)
	return t / maxf(Y_pot, 1e-9)


## URETIM KISMA CARPANI -- dolu depoya uretim yapilmaz.
##
## Krizi SUREKLI kilan zincirin halkasi budur ve yalnizca stok varken
## tanimlidir: bir akim "gecen donem satilmadi" der ve susar; bir stok
## "hala duruyor" demeye devam eder.
func kisma_carpani(i: int) -> float:
	var fazla := maxf(0.0, stok_orani(i) - normal_stok_yil)
	return clampf(1.0 - yigin_kisma * fazla / maxf(normal_stok_yil, 1e-9),
			0.15, 1.0)


## Bir donem. `kap` kategori kapasiteleri, `talep` kategori talepleri
## (ikisi de YILLIK akim). Cekirdek `_departmanlar` icinden cagirir.
##
## Sira: kisma -> uretim -> satis -> stok. Kisma ONCE gelir cunku kapitalist
## uretim kararini deponun MEVCUT halina bakarak verir, uretimden sonrasina
## degil.
func adim(donem_yil: float, kap: PackedFloat64Array,
		talep: PackedFloat64Array) -> void:
	for i in range(MALLAR.size()):
		var uretim := kap[i] * kisma_carpani(i)
		# Arz = eldeki stok + bu donemin uretimi. Ikisi de AYNI donemde
		# satilabilir; depoda bekleyen mal satisa kapali degildir.
		var arz := stok[i] / maxf(donem_yil, 1e-9) + uretim
		var satis := minf(arz, maxf(0.0, talep[i]))

		# KORUNUM. Defter birebir kapanir; `min` yuzunden stok negatife
		# DUSEMEZ, yani bir kirpmaya gerek yok. Kirpma gerekseydi bu, akim
		# birimlerinin karistigi anlamina gelirdi.
		var eski := stok[i]
		var delta := (uretim - satis) * donem_yil
		var ham := eski + delta
		stok[i] = maxf(0.0, ham)
		koruma_atesledi = maxf(koruma_atesledi, stok[i] - ham)

		# Bozulma / demode olma. Bir kez biriken yigin sonsuza kadar kalmaz.
		stok[i] *= (1.0 - Oran.donem_uyum(erime_yil, donem_yil))

		son_uretim[i] = uretim
		son_satis[i] = satis


## Toplam gerceklesen uretim (YILLIK) -- cekirdegin `Y`sine girer.
func uretim_toplam() -> float:
	var t := 0.0
	for x in son_uretim:
		t += x
	return t


## Departman bazinda gerceklesen uretim -- cekirdek `Y_I_yil` / `Y_II_yil`
## olarak okur, boylece eski tani alanlari anlamini korur.
func uretim_dept(dept: int) -> float:
	var t := 0.0
	for i in range(MALLAR.size()):
		if int(MALLAR[i]["dept"]) == dept:
			t += son_satis[i]
	return t


## Satilamayan kutle, departman bazinda (STOK -- akim degil).
func stok_dept(dept: int) -> float:
	var t := 0.0
	for i in range(MALLAR.size()):
		if int(MALLAR[i]["dept"]) == dept:
			t += stok[i]
	return t


## Kategori dagilimi -- tani ve arayuz icin.
func dagilim() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(MALLAR.size()):
		out.append({
			"ad": str(MALLAR[i]["ad"]),
			"stok": stok[i],
			"uretim": son_uretim[i],
			"satis": son_satis[i],
			"oran": stok_orani(i),
		})
	return out
