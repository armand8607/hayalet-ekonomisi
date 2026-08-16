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
##
## Varsayilani v4.4'un `ticaret_aciklik`'idir (0.22): gravite toplami kabaca
## `Y_i` verdigi icin bu carpan dogrudan TICARET/HASILA oranini kurar.
var ticaret_yogunlugu: float = 0.22

## Deger transferinin olcek carpani.
##
## v4.4'un `vt_siddet`'i (0.05) BURAYA UYMAZ: o sabit, ulke basina bagimsiz
## hesaplanan ve `Y` ile carpilan baska bir formulun kalibrasyonuydu. Buradaki
## cift-bazli gravite formu bambaska bir geometridir, dolayisiyla ayni sayi
## ayni AGIRLIGI vermez -- olculdu, 0.05 ile |VT|/Y = 0.0053 cikiyor.
##
## TICARET EKLENINCE BU KALIBRASYON ZAYIF BELIRLENIR HALE GELDI. Once iki
## bagimsiz olcut (v4.4'un olculen |VT|/Y bandi ve kuralin saglamligi) ayni
## sayiyi gosteriyordu. Artik gostermiyor, cunku VT tek basina IKINCI
## DERECEDE kaldi: NX/Y ~ %6 iken VT/Y ~ %0.5, ticaret transferi bir mertebe
## bastiriyor. Havuzlanmis gradyan (`--v2-dunya-siddet`):
##
##   siddet   |VT|/Y   gradyan(30 gozlem)
##     0.10   0.0027              -0.125
##     0.20   0.0054              -0.160
##     0.40   0.0108              -0.058   <-- secilen
##     0.60   0.0163              +0.005
##     0.80   0.0219              +0.030
##
## Hicbir agirlikta -0.16'yi gecmiyor, yani saglamlik olcutu artik AYIRT
## ETMIYOR -- aralarindaki fark 30 gozlemde gurultu. Geriye tek dayanak
## ampirik capa kaliyor: v4.4 varsayilan dunyada |VT|/Y ~ 0.01-0.03
## uretiyordu ve 0.40 o bandin icine dusen en dusuk degerdir.
##
## Yuksek siddette isaretin donmesi (0.60'tan sonra) ACIK BIR SORUDUR.
## Devrim zamanlamasi degil (olculdu: her agirlikta 30/30 devrim, ortalama
## 1932), yani payda kaymasi degil. B/D/E/F tamamlanmadan kovalanmamali.
var siddet: float = 0.40

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

## Kampanya boyunca birikmis net ihracat. Ticaret fazlasi da GELEN degerdir:
## "birinden eksilen digerine gider" kurali iki akima da ayni sekilde uygulanir.
var toplam_nx: PackedFloat64Array = PackedFloat64Array()


## Bir ulkenin TOPLAM dis deger konumu: ticaret dengesi + esitsiz mubadele.
## Kuralin dogru degiskeni budur -- VT tek basina, ticaret varken ikinci
## derecede kalir (olculdu: NX/Y ~ %6, VT/Y ~ %0.5).
func dis_konum(i: int) -> float:
	return toplam_nx[i] + toplam_vt[i]

## Korunum kaydi: her tikte olculen bagil hata. Testin asil kaniti.
var en_buyuk_korunum_hatasi: float = 0.0

## Transferin AGIRLIGI: |VT|/Y'nin kosu boyunca ortalamasi. Kural yon olarak
## dogru olsa bile bu buyukluk kucukse mekanizma olculemez -- gurultuye
## gomulur. Kalibrasyonun gorunur olmasi icin kaydediliyor.
var _vt_y_toplam: float = 0.0
var _vt_y_say: int = 0

var yil: float = 1836.0

## Cift basina gerceklesen ticaret hacmi (i*n+j, yalnizca i<j dolu).
## `ticaret()` yazar, `transferler()` okur -- deger transferi bu hacmin
## uzerinde yurur.
var _son_hacim: PackedFloat64Array = PackedFloat64Array()
var _onceki_Y_dunya: float = 0.0

## Ticaret korunum kaydi: sum(NX) / sum|NX|. VT ile ayni disiplin.
var en_buyuk_ticaret_hatasi: float = 0.0

var P: KrizParam


func _init(p_ornek: KrizParam = null) -> void:
	P = p_ornek if p_ornek != null else KrizParam.new()
	ticaret_yogunlugu = P.v44.ticaret_aciklik


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
	toplam_nx.append(0.0)


## DIS TICARET (B bloku) -- cift bazli, korunumlu.
##
## v4.4'te ticaret diye bir AKIM yoktu: `eps` ve `pi_m` her ulke icin dunya
## ortalamasindan hesaplaniyor, `y_max` oradan cikiyordu (`motor.py:1762`).
## Kimse kimsenin ithalatcisi degildi -- bir ulkenin ihracati baska hicbir
## ulkenin ithalati olarak gorunmuyordu. Deger transferindeki kusurun aynisi.
##
## Burada akim yine CIFT uzerinde tanimli: `X_ij` hem i'nin ihracati hem
## j'nin ithalatidir, ayni sayi iki deftere yazilir. Dolayisiyla
##
##     sum(NX) == 0
##
## ozdeslikle saglanir; dunya kendi kendine ihracat fazlasi veremez.
##
## YON REKABETTEN GELIR. Ciftin toplam hacmi gravite ile belirlenir, ikiye
## bolunusu ise Thirlwall oraniyla: `k = eps / pi_m`. Yuksek uretkenlikli
## ulke hem daha kolay ihrac eder (`eps` yuksek) hem daha az ithal eder
## (`pi_m` dusuk), dolayisiyla ciftin buyuk yarisini alir. Ticaret fazlasi
## bir GIRDI degil, uretkenlik farkinin SONUCUDUR.
func ticaret() -> void:
	var n := ulkeler.size()
	var Y_dunya := 0.0
	var q_toplam := 0.0
	for d in ulkeler:
		Y_dunya += maxf(d.Y_yil, 0.0)
		q_toplam += d.q
	var q_ort := q_toplam / maxf(float(n), 1.0)

	# Esneklikler -- v4.4'un B blogundan (`motor.py:1768`), ayni bicim.
	for i in range(n):
		var d := ulkeler[i]
		var q_rel := d.q / maxf(q_ort, 1e-6)
		d.eps = (P.v44.eps0 * (0.45 + P.v44.eps_q * minf(q_rel, 2.2))
				* (1.0 - P.v44.eps_lumpen * d.lumpen_pay))
		d.pi_m = maxf(0.35, P.v44.pi0 * (1.45 - P.v44.pi_q * minf(q_rel, 2.0))
				* (1.0 + P.v44.pi_lumpen * d.lumpen_pay))
		if d.rejim == "sosyalist":
			d.pi_m *= 0.85          # sosyalist ithal ikamesi
		d.X_yil = 0.0
		d.M_yil = 0.0

	if n < 2 or Y_dunya <= 0.0:
		for d in ulkeler:
			d.NX_yil = 0.0
		return

	_son_hacim.clear()
	_son_hacim.resize(n * n)
	for i in range(n):
		for j in range(i + 1, n):
			var a := ulkeler[i]
			var b := ulkeler[j]
			var hacim := (ticaret_yogunlugu
					* maxf(a.Y_yil, 0.0) * maxf(b.Y_yil, 0.0) / Y_dunya)
			hacim *= minf(aciklik[i], aciklik[j])
			if hacim <= 0.0:
				continue
			# Thirlwall orani: rekabet gucu.
			var ka := a.eps / maxf(a.pi_m, 1e-6)
			var kb := b.eps / maxf(b.pi_m, 1e-6)
			var pay := ka / maxf(ka + kb, 1e-9)
			var X_ab := hacim * pay              # a -> b
			var X_ba := hacim * (1.0 - pay)      # b -> a
			a.X_yil += X_ab
			b.M_yil += X_ab
			b.X_yil += X_ba
			a.M_yil += X_ba
			# Deger transferi GERCEKLESEN ticaretin uzerinde yurur; ayri bir
			# vekil buyukluk degil. Esitsiz mubadele mubadelede olur.
			_son_hacim[i * n + j] = hacim

	for d in ulkeler:
		d.NX_yil = d.X_yil - d.M_yil


## THIRLWALL KISITI. Odemeler dengesiyle uyumlu azami buyume `eps*z/pi_m`'dir;
## bunu asan ulke dis finansmani daha pahaliya bulur. Kisit SERT DEGILDIR --
## buyumeyi kesmez, pahalilastirir; birikimi bogan sey faizin yukselmesidir.
func thirlwall(donem_yil: float) -> void:
	# Dunya buyumesi: hasila agirlikli, gecen tikin toplamina gore.
	var Y_dunya := 0.0
	for d in ulkeler:
		Y_dunya += maxf(d.Y_yil, 0.0)
	var z := 0.0
	if _onceki_Y_dunya > 0.0:
		z = (Y_dunya - _onceki_Y_dunya) / _onceki_Y_dunya / maxf(donem_yil, 1e-9)
	_onceki_Y_dunya = Y_dunya

	for i in range(ulkeler.size()):
		var d := ulkeler[i]
		d.y_max = d.eps * maxf(z, 0.0) / maxf(d.pi_m, 0.2)
		d.bop_asim = d.y_buyume - d.y_max
		d.BoP_R = Formulas.sg(P.v44.kappa_B * d.bop_asim * 8.0)
		# Cari denge: asim kadar acik verilir, deger transferi de buraya
		# akar (v4.4 `motor.py:1789` ile ayni bicim).
		d.cari_yil = (-P.v44.cari_kats * d.Y_yil * d.bop_asim * 4.0
				+ 0.30 * son_vt[i])
		d.FX += d.cari_yil * donem_yil


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

	if _son_hacim.size() != n * n:
		return vt
	for i in range(n):
		for j in range(i + 1, n):
			var a := ulkeler[i]
			var b := ulkeler[j]
			# GERCEKLESEN ticaret hacmi. `ticaret()` yazdi; esitsiz mubadele
			# mubadelede olur, ayri bir vekil buyuklukte degil.
			var hacim := _son_hacim[i * n + j]
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
	# SIRA ONEMLI. Ticaret once kurulur cunku deger transferi GERCEKLESEN
	# ticaretin uzerinde yurur; Thirlwall primi ise transferi bilmek zorunda
	# (cari denge onu tasir). Ucu de tikin BASINDAKI duruma bakar.
	ticaret()
	_ticaret_korunumunu_kaydet()
	var vt := transferler()
	_korunumu_kaydet(vt)
	son_vt = vt
	thirlwall(donem_yil)
	for i in range(ulkeler.size()):
		var Y := ulkeler[i].Y_yil
		if Y > 0.0:
			_vt_y_toplam += absf(vt[i]) / Y
			_vt_y_say += 1
		cekirdekler[i].adim(ulkeler[i], donem_yil, {"VT_net_yil": vt[i]})
		toplam_vt[i] += vt[i] * donem_yil
		toplam_nx[i] += ulkeler[i].NX_yil * donem_yil
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


## Ticaret de ayni disipline tabidir: bir ulkenin ihracati baskasinin
## ithalatidir, dolayisiyla sum(NX) == 0. Dunya kendine ihracat yapamaz.
func _ticaret_korunumunu_kaydet() -> void:
	var nx := PackedFloat64Array()
	for d in ulkeler:
		nx.append(d.NX_yil)
	en_buyuk_ticaret_hatasi = maxf(en_buyuk_ticaret_hatasi, korunum_hatasi(nx))


## Bir ulkenin kriz tescillerinin toplami.
func kriz_sayisi(i: int) -> int:
	var d := ulkeler[i]
	return (d.asiri_uretim_krizleri.size() + d.resesyonlar.size()
			+ d.bunalimlar.size())
