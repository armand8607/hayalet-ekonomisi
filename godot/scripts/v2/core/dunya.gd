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


## Kampanya boyunca disaridan alinan NET DEGERIN TOPLAMI -- DORT KANAL.
##
##     ticaret dengesi + esitsiz mubadele + dis faiz + temerrut
##
## Dordu de korunumlu oldugu icin `sum(toplam_dis) == 0`; bu, dorduncu
## korunum ozdesligidir ve kapida ayrica sinanir.
var toplam_dis: PackedFloat64Array = PackedFloat64Array()


## BILESIK DIS KONUM -- hasilaya oranlanmis.
##
## Once yalnizca `NX + VT` idi ve gradyan -0.006'ya dusmustu. Sebep: dis
## kanal sayisi BIRDEN BESE cikti. Bunalimi artik ticaret dengesi tek basina
## surüklemiyor; borc servisi, temerrut ve doviz krizi de ayni sonuca
## bastiriyor. Iki kanali olcup besini birden sormak, gradyani seyreltir.
##
## HASILAYA BOLUNUR. Mutlak akim ulke buyuklugu ile olceklenir; buyuk ulkenin
## buyuk akimi "daha cok deger aldi" demek degildir. Ulkeler arasi
## karsilastirma yogunluk cinsinden yapilmali.
func dis_konum(i: int) -> float:
	return toplam_dis[i] / maxf(ulkeler[i].Y_yil, 1e-9)

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

## Son tikin dis pazar itkisi, ulke basina. 1.0 = baski yok. Kampanya boyunca
## yukselmesi pazar kavgasinin kizistigi anlamina gelir.
var son_itki: PackedFloat64Array = PackedFloat64Array()

## DIS BORC MATRISI, duz dizi: `borc[i*n + j]` = i'nin j'ye borcu.
## Ozdeslik: `sum(net_dis_varlik) == 0` -- her borcun bir alacaklisi var.
var borc: PackedFloat64Array = PackedFloat64Array()

## Borc/kriz kapilarinin RNG'si. Ulke cekirdeklerininkinden AYRI: moratoryum
## dunya katmaninin karari, ulkenin degil.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Dis varlik korunum kaydi.
var en_buyuk_borc_hatasi: float = 0.0

## Moratoryum kapisi. Karsi-olgusal icin kapatilabilir: temerrudun ALACAKLIYA
## ne yaptigini olcmenin tek yolu, temerrudun olmadigi bir kolla karsilastirmak.
var moratoryum_acik: bool = true

## Moratoryum tehlike orani carpani. Duzlugun GERCEK mi ESER mi oldugunu
## ayirmak icin taranir: temerrut seyrekken gradyan geri geliyorsa duzluk
## temerrut sikliginin eseridir, her siddette duzse yapisaldir.
var mor_carpan: float = 1.0

## BUTUN BORC KANALI (D/E/F). Kapatilinca dis borc, faiz, temerrut ve doviz
## krizi devre disi kalir -- ticaret ve transfer kalir. Ayrim testinin
## referans kolu: borc yokken gradyan -0.80'e donuyor mu?
var borc_acik: bool = true

## DOVIZ KRIZI (F blogu) ayri kapatilabilir. Ayrim taramasinda E ile F'yi
## birbirinden ayirmak icin: temerrut sifirken bile gradyan cokuyorsa
## suclu moratoryum degildir.
var fx_acik: bool = true

## TEMERRUT ZARARININ HENUZ SINDIRILMEMIS KISMI, ulke basina.
##
## Silinen borc bir STOK kaybidir ve tek basina reel ekonomiye degmez -- ilk
## yazimda oyleydi ve alacaklinin bunalim yogunlugu hic kipirdamadi (-0.01).
## Oysa temerrut alacaklinin saydigi degerin GELMEMESIDIR; motorda bunun
## karsiligi transferle ayni kanaldir (talep ve `r_ef`).
##
## TEK TIKTA degil, `mor_ceza_sure` boyunca sindirilir: 1.6 katlik bir borcun
## %45'i tek haftaya yazilsaydi yillik olcekte hasilanin 37 kati bir sok
## olurdu. Gercekte de zarar karsilik ayirarak zamana yayilir.
##
## Dizi toplami HER AN sifirdir (alacaklinin eksisi = borclunun artisi),
## dolayisiyla korunum bozulmaz.
var _mor_bekleyen: PackedFloat64Array = PackedFloat64Array()

var P: KrizParam


## SAVAS KATMANI (B4). Takili degilse hicbir ulke savasa girmez ve
## `d.savasta()` her zaman false doner -- yani cekirdegin butun savas
## kollari kapali kalir ve B1/B2/B3 olcumleri gecerliligini korur.
##
## Digerlerinden bagimsiz takilir; §3.2'nin muhasebesi ("kar orani yukari,
## nufus asagi") ancak acik/kapali karsilastirmasiyla olculebilir.
var savas: SavasKatmani = null

## POLITIKA AKTORU (B7b). Takili degilse hicbir AI ulkesi karanlik devletin
## sekiz taktigini yazmaz ve `t_*` alanlari 0.0'da kalir -- yani B1/B2/B3
## olcumleri gecerliligini korur, tipki savas katmani gibi.
##
## §4.5'in AI tarafi. `null` birakilmasi bir "kapali politika" degil, POLITIKA
## OLMAMASIDIR; `dunya_testi` ve `savas_testi` kendi dunyalarini `Dunya.new()`
## ile kurdugu icin onlarin olctugu sayilar bu katmandan etkilenmez.
var aktor: PolitikaAktoru = null

## ABLUKA MATRISI, duz dizi: `abluka[i*n + j]` = i-j ciftinin ticaretine
## uygulanan kesinti [0,1]. 1.0 = tam abluka.
##
## CIFT UZERINDE TANIMLI, VE BU ZORUNLU. Deponun kurali acik: "ulke basina
## carpan uygulamak (abluka, aciklik) CIFTE SIMETRIK olmalidir -- tek tarafa
## uygulanan carpan korunumu kirar", ve v4.4'un L blogunu bozan sey tam olarak
## buydu (olculdu: korunum hatasi %57).
##
## Burada kesinti ciftin TOPLAM HACMINE uygulanir; iki taraf ayni kuculmus
## hacmi paylastigi icin `sum(NX) == 0` ozdesligi kirilmaz. Ablukayi "abluka
## edilen ulkenin acikligi" diye yazmak cazip ama YANLIS olurdu: o zaman
## abluka eden ulke kaybettigi ihracati baska yerde bulmus gibi gorunurdu.
var abluka: PackedFloat64Array = PackedFloat64Array()


## Bir ciftin bu tikteki gerceklesen ticaret hacmi. Yalnizca tani ve test
## icin; `_son_hacim` yalnizca i<j icin dolu oldugundan siralamayi burada
## normallestiriyoruz.
func cift_hacmi(i: int, j: int) -> float:
	var n := ulkeler.size()
	if _son_hacim.size() != n * n:
		return 0.0
	return _son_hacim[mini(i, j) * n + maxi(i, j)]


## Cift bazli ticaret engeli [0,1]. 1.0 = engel yok.
func _engel(i: int, j: int) -> float:
	var n := ulkeler.size()
	if abluka.size() != n * n:
		return 1.0
	return clampf(1.0 - abluka[i * n + j], 0.0, 1.0)


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
	toplam_dis.append(0.0)
	son_itki.append(1.0)
	_mor_bekleyen.append(0.0)
	if ulkeler.size() == 1:
		rng.seed = tohum
	_borc_matrisini_buyut()


## Borc matrisini n x n'e buyutur, MEVCUT girdileri koruyarak. Duz dizi
## oldugu icin satir uzunlugu degisince yeniden yerlestirmek gerekir; naif
## `resize` butun alacaklari kaydirirdi.
func _borc_matrisini_buyut() -> void:
	var n := ulkeler.size()
	var yeni := PackedFloat64Array()
	yeni.resize(n * n)
	yeni.fill(0.0)
	var eski_n := n - 1
	for i in range(eski_n):
		for j in range(eski_n):
			yeni[i * n + j] = borc[i * eski_n + j]
	borc = yeni
	var yeni_abluka := PackedFloat64Array()
	yeni_abluka.resize(n * n)
	yeni_abluka.fill(0.0)
	for i in range(eski_n):
		for j in range(eski_n):
			yeni_abluka[i * n + j] = abluka[i * eski_n + j]
	abluka = yeni_abluka


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
		# Devaluasyon ihracati ucuzlatir (v4.4 `motor.py:1769`): doviz krizi
		# ulkeyi ihracata mahkum eder, F blogu B blogunu boyle besler.
		d.eps = (P.v44.eps0 * (0.45 + P.v44.eps_q * minf(q_rel, 2.2))
				* (1.0 + d.deval)
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

	# CIFTTEN BAGIMSIZ BUYUKLUKLER DONGUDEN ONCE (B6). Ic dongu n^2 kez
	# kosuyor ve icindeki uc ifade yalnizca `i`ye baglıydı: `_itki(i)`,
	# `eps/pi_m` bolumu ve `maxf(Y,0)`. 113 ulkede bu, tik basina 6328
	# gereksiz `_itki` cagrisi demekti.
	#
	# HOIST SONUCU DEGISTIRMEZ, ve bu KONTROL EDILDI: `--v2-dunya` ciktisi
	# optimizasyon oncesi ve sonrasi BAYT BAYT ayni. Ifade sirasi bilerek
	# korundu -- `(yog * Ya) * Yb / Yd` ile `(yog * Ya / Yd) * Yb` ayni sayi
	# DEGILDIR (kayan nokta), o yuzden bolum yerinde birakildi.
	var Y_poz := PackedFloat64Array()
	var k_rekabet := PackedFloat64Array()
	Y_poz.resize(n)
	k_rekabet.resize(n)
	for i in range(n):
		var d := ulkeler[i]
		Y_poz[i] = maxf(d.Y_yil, 0.0)
		k_rekabet[i] = d.eps / maxf(d.pi_m, 1e-6) * _itki(i)
	var abluka_var := abluka.size() == n * n

	for i in range(n):
		var a := ulkeler[i]
		var a_yog := ticaret_yogunlugu * Y_poz[i]
		var a_aciklik := aciklik[i]
		var ka := k_rekabet[i]
		# `a`nin toplamlari YERELDE birikir, dongu bitince bir kez yazilir.
		# Toplama SIRASI ayni (j artan), dolayisiyla sonuc bit-birebir ayni;
		# kazanc cift basina dort mulk yazmasindan ikisini silmek.
		var a_X := a.X_yil
		var a_M := a.M_yil
		for j in range(i + 1, n):
			var b := ulkeler[j]
			var hacim := a_yog * Y_poz[j] / Y_dunya
			# Abluka ve savas ciftin HACMINI keser (bkz. `abluka`).
			var engel := (clampf(1.0 - abluka[i * n + j], 0.0, 1.0)
					if abluka_var else 1.0)
			hacim *= minf(a_aciklik, aciklik[j]) * engel
			if hacim <= 0.0:
				continue
			# Thirlwall orani: rekabet gucu -- CARPANI gerceklesme baskisidir.
			#
			# Mallari satilamayan ulke dis pazara ASILIR (§3.1). Itki paylari
			# carptigi ve pay `k_i/(k_i+k_j)` oldugu icin SIFIR TOPLAMLIDIR:
			# tek basina iten kazanir, iki taraf da iterse paylar degismez.
			# Pazar kavgasinin cikmaz olmasi buradan gelir, bir olay
			# tablosundan degil.
			var kb := k_rekabet[j]
			var pay := ka / maxf(ka + kb, 1e-9)
			var X_ab := hacim * pay              # a -> b
			var X_ba := hacim * (1.0 - pay)      # b -> a
			a_X += X_ab
			b.M_yil += X_ab
			b.X_yil += X_ba
			a_M += X_ba
			# Deger transferi GERCEKLESEN ticaretin uzerinde yurur; ayri bir
			# vekil buyukluk degil. Esitsiz mubadele mubadelede olur.
			_son_hacim[i * n + j] = hacim
		a.X_yil = a_X
		a.M_yil = a_M

	for d in ulkeler:
		d.NX_yil = d.X_yil - d.M_yil


## Bir ulkenin DIS PAZAR ITKISI. Gerceklesme baskisi (`talep_acigi`, yani
## satilamayan malin potansiyel hasilaya orani) ulkeyi ihracata iter.
##
## Esik olarak asiri uretim krizinin kendi esigi (`au_esik`) kullanilir: itki
## kriz tescilinin olcegiyle ayni olcekte olsun, ayri bir kalibrasyon sayisi
## dogmasin diye. `son_itki` tani icin saklanir -- kampanya boyunca yukselmesi
## "pazar kavgasi kiziisiyor" demektir.
func _itki(i: int) -> float:
	var d := ulkeler[i]
	var baski := d.talep_acigi / maxf(P.v44.au_esik, 1e-6)
	var it := 1.0 + P.ihracat_itkisi * clampf(baski, 0.0, 3.0)
	# ANI DURUS (D blogu) ZORLAMAYI ARTIRIR. Dis finansmani kesilen ulke
	# ithalatini ihracatiyla odemek ZORUNDADIR -- kredi kapaninca cari denge
	# bir tercih olmaktan cikar. D blogunun B bloguna bagli oldugu yer burasi:
	# borc krizi, pazar kavgasina bir katilimci daha sokar.
	if d.ani_durus:
		it *= (1.0 + P.ani_durus_itkisi)
	son_itki[i] = it
	return it


## DIS BORC -- CIFT BAZLI. `borc[i*n+j]` = i'nin j'ye borcu.
##
## v4.4'te `dis_borc` alacaklisiz bir skalerdi ve moratoryum onu carpip
## buharlastiriyordu (`motor.py:1806`). Kimse zarar etmiyordu, dolayisiyla
## temerrut bir kriz KANALI degil bir MUAFIYETTI. Oysa cevrenin odeyememesi
## merkezin bilancosuna yazilir; krizin merkeze DONDUGU yol budur.
##
## Ozdeslik: `sum(net dis varlik) == 0`. Her borcun bir alacaklisi var.
func net_dis_varlik(i: int) -> float:
	var n := ulkeler.size()
	var net := 0.0
	for j in range(n):
		net += borc[j * n + i] - borc[i * n + j]
	return net


## Cari fazla/acigi dis borca cevirir; acigi FAZLA VEREN ulkeler finanse eder.
##
## Kim borc verir sorusu kendiliginden cevaplaniyor: fazla veren ulkenin
## elinde baskasinin satin almadigi deger birikir ve o deger bir yerde alacak
## olarak durmak zorundadir. Sermaye ihraci bir tercih degil, fazlanin
## KACINILMAZ bicimidir.
## Donen: ulke basina REZERVE dokunan artik akim.
##
## CIFTE SAYIM TUZAGI. Ilk yazimda cari akimin TAMAMI rezerve yaziliyordu ve
## ayrica borcla finanse ediliyordu; ayni acik iki kez sayilinca rezerv
## hasilanin -5 katina iniyor ve doviz krizi neredeyse SUREKLI atesleniyordu
## (olculdu: 198 yilda 173 kriz). Oysa finanse edilen bir acik rezervi
## azaltmaz -- borca donusur. Rezerve YALNIZCA finanse EDILEMEYEN kisim iner.
##
## Bunun sonucu D ile F'yi birbirine baglar ve dogru sirayla: once dis
## finansman kesilir (ani durus), sonra kapatilamayan acik rezervi eritir,
## sonra doviz krizi gelir. Once kriz, sonra sebep degil.
func _dis_finansman(donem_yil: float) -> PackedFloat64Array:
	var n := ulkeler.size()
	var artik := PackedFloat64Array()
	artik.resize(n)
	for i in range(n):
		artik[i] = ulkeler[i].cari_yil * donem_yil

	# GERI ODEME ONCE. Fazla veren bir BORCLU once kendi borcunu kapatir,
	# ancak artani baskasina borc verir.
	#
	# Ilk yazimda bu yoktu ve borc hic azalmiyordu: alt uc ulke tavana
	# yapisip KALICI ani durusa giriyor, kalici bir itki carpani tasiyor ve
	# `ZORLAMA` sinyalini boguyordu (olculdu: +0.383 -> -0.154, isaret
	# donmesi). Ani durus bir EPIZOT olmali, bir kader degil -- kisit zaten
	# ulkeyi fazlaya zorluyor, o fazlanin borcu eritmesi gerekir.
	for i in range(n):
		var d := ulkeler[i]
		if d.cari_yil <= 0.0:
			continue
		var odenecek := d.cari_yil * donem_yil
		var brut := 0.0
		for j in range(n):
			brut += borc[i * n + j]
		if brut <= 0.0:
			continue
		var oran := minf(1.0, odenecek / brut)
		for j in range(n):
			var odenen := borc[i * n + j] * oran
			borc[i * n + j] -= odenen
			# Odeme borcludan cikar, alacakliya girer -- toplami sifir.
			artik[i] -= odenen
			artik[j] += odenen

	var fazla_toplam := 0.0
	for i in range(n):
		# Borcunu kapattiktan SONRA elinde kalan, baskasina verilebilecek fazla.
		if artik[i] > 0.0:
			fazla_toplam += artik[i] / maxf(donem_yil, 1e-9)
	if fazla_toplam <= 0.0:
		return artik

	for i in range(n):
		var d := ulkeler[i]
		if artik[i] >= 0.0:
			continue
		# ANI DURUS (D): borc tavani asilmissa yeni kredi YOK. Ulke acigini
		# kapatamaz, ithalati sikistirmak zorunda kalir -- ve kapatamadigi
		# kisim rezervinden cikar.
		if d.ani_durus:
			continue
		var ihtiyac := -artik[i]
		for j in range(n):
			if i == j or artik[j] <= 0.0:
				continue
			var pay := (artik[j] / maxf(donem_yil, 1e-9)) / fazla_toplam
			var kredi := ihtiyac * pay
			borc[i * n + j] += kredi
			# Borclanan acigini kapatir, alacakli fazlasini krediye baglar.
			# Ikisi ayni sayi oldugu icin toplam korunur.
			artik[i] += kredi
			artik[j] -= kredi
	return artik


## D / E / F -- ani durus, moratoryum, doviz krizi.
func borc_ve_krizler(donem_yil: float) -> void:
	var n := ulkeler.size()

	# FAIZ ve CARI DENGE once; finansman sonra (acik ne kadarsa o kadar borc).
	for i in range(n):
		var d := ulkeler[i]
		var Y := maxf(d.Y_yil, 1e-6)
		var brut := 0.0
		for j in range(n):
			brut += borc[i * n + j]
		d.dis_borc = brut / Y
		d.dis_varlik = net_dis_varlik(i) / Y

		# FAIZ: borclu odur, alacakli alir. CIFT uzerinde tanimli oldugu icin
		# toplami sifirdir -- faiz de bir deger akimidir ve korunur.
		var net_faiz := 0.0
		for j in range(n):
			net_faiz += borc[j * n + i] * ulkeler[j].i_yil
			net_faiz -= borc[i * n + j] * d.i_yil
		d.faiz_dis_yil = net_faiz

		# CARI DENGE BIR OZDESLIKTIR, bir proxy DEGIL.
		#
		# v4.4 onu ulke basina bagimsiz hesapliyordu (`motor.py:1789`):
		# `cari = -kats * Y * bop_asim * 4 + 0.30*VT`. Ticaret diye bir akim
		# olmadigi icin baska caresi yoktu, ama sonucu ayni kusurdu -- toplami
		# sifir degil. Olculdu: o formulle butun ulkeler ayni anda acik
		# veriyor, dolayisiyla acigi finanse edecek FAZLA hic olusmuyor ve
		# borc matrisi kampanya boyunca BOS kaliyordu; D/E/F hic atesli.
		#
		# Artik ucu de gercek ve korunumlu oldugu icin cari denge tanimindan
		# yazilabiliyor ve `sum(cari) == 0` kendiliginden saglaniyor.
		d.cari_yil = d.NX_yil + d.faiz_dis_yil + son_vt[i]

	# Rezerve YALNIZCA finanse edilemeyen artik iner (bkz. `_dis_finansman`).
	var artik := _dis_finansman(donem_yil)

	for i in range(n):
		var d := ulkeler[i]
		var Y := maxf(d.Y_yil, 1e-6)
		d.FX += artik[i]

		# D. ANI DURUS -- borc tavani asilinca dis finansman kesilir.
		d.ani_durus = d.dis_borc > P.v44.dis_borc_tavani or d.mor_ceza > 0

		# F. DOVIZ KRIZI -- rezerv erimesi.
		# SAYACLAR TUR DEGIL DONEM CINSINDEN. v4.4'un 8 turu 2.16 yildir;
		# haftalik donguye 8 diye kopyalanirsa 0.15 yil olur ve doviz krizi
		# salgina doner (olculdu: 3 tohumda 325 kriz, ve gradyani yok etti).
		d.fx_baski = d.fx_baski + 1 if d.FX < -0.04 * Y else 0
		if (fx_acik and d.fx_baski >= Oran.v44_sayac(8.0, donem_yil)
				and d.fx_kriz == 0 and d.rejim == "kapitalist"):
			d.fx_kriz = Oran.v44_sayac(P.v44.fx_kriz_sure, donem_yil)
			d.FX = 0.06 * Y
			d.deval = P.v44.devaluasyon
			d.borc *= 1.12
			d.fx_krizleri.append(d.yil)
			d.fx_baski = 0
		if d.fx_kriz > 0:
			d.fx_kriz -= 1
		d.deval = maxf(0.0, d.deval - P.v44.deval_sonum)

		# E. MORATORYUM -- ve ZARARI ALACAKLIYA YAZILIR.
		if (moratoryum_acik and d.dis_borc > P.v44.mor_borc_esigi and d.fx_kriz > 0
				and d.mor_ceza == 0 and d.rejim == "kapitalist"
				and rng.randf() < 1.0 - pow(1.0 - clampf(
						P.mor_tehlike_yil * mor_carpan, 0.0, 0.999), donem_yil)):
			for j in range(n):
				# Silinen borc alacaklinin VARLIGINDAN dusulur. v4.4 bu
				# satiri hic yazmamisti; borc yoktan siliniyordu.
				var silinen := borc[i * n + j] * P.v44.mor_kesinti
				borc[i * n + j] -= silinen
				# Zarar alacakliya, kurtulus borcluya -- toplami sifir.
				_mor_bekleyen[j] -= silinen
				_mor_bekleyen[i] += silinen
			d.mor_ceza = Oran.v44_sayac(P.v44.mor_ceza_sure, donem_yil)
			d.moratoryumlar.append(d.yil)
		if d.mor_ceza > 0:
			d.mor_ceza -= 1
			d.BoP_R = minf(1.0, d.BoP_R + P.v44.mor_ceza_prim)


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
	# `cv` bir kez okunur: ic dongude n^2 kez mulk erisimi yapiliyordu.
	var cv := PackedFloat64Array()
	cv.resize(n)
	for i in range(n):
		cv[i] = ulkeler[i].cv

	for i in range(n):
		var cv_a := cv[i]
		var vt_i := vt[i]
		for j in range(i + 1, n):
			# GERCEKLESEN ticaret hacmi. `ticaret()` yazdi; esitsiz mubadele
			# mubadelede olur, ayri bir vekil buyuklukte degil.
			var hacim := _son_hacim[i * n + j]
			var toplam_cv := cv_a + cv[j]
			if toplam_cv <= 0.0 or hacim <= 0.0:
				continue
			var t := siddet * hacim * (cv_a - cv[j]) / toplam_cv
			vt_i += t
			vt[j] -= t
		vt[i] = vt_i
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
	# SAVAS EN BASTA. Sira zorunludur: savas durumu bu donemin talep, kapasite
	# ve uretim hesabina girmeli. Sonra cagrilsaydi seferberlik ve savas
	# talebi bir donem geriden is gorurdu -- ve `--v2-olcek`in olcek
	# degismezligi denetiminde gorunmeyecek kadar kucuk, ama kampanya
	# boyunca birikecek kadar buyuk bir kayma olurdu.
	# POLITIKA EN BASTA: karar once verilir, dunya sonra kosar. Yalnizca `t_*`
	# alanlarina yazar ve onlar cekirdegin S/Q/T bloklarinda okunur, yani
	# savasin sira zorunlulugu ile carpismaz.
	if aktor != null:
		aktor.adim(ulkeler, donem_yil)
	if savas != null:
		savas.adim(ulkeler, adlar, donem_yil)
		savas.abluka_kur(ulkeler, adlar, abluka, donem_yil)
	ticaret()
	_ticaret_korunumunu_kaydet()
	var vt := transferler()
	_korunumu_kaydet(vt)
	son_vt = vt
	thirlwall(donem_yil)
	# D/E/F Thirlwall'dan SONRA: cari denge orada kuruluyor, borc ondan dogar.
	if borc_acik:
		borc_ve_krizler(donem_yil)
		_borc_korunumunu_kaydet()
	for i in range(ulkeler.size()):
		var Y := ulkeler[i].Y_yil
		if Y > 0.0:
			_vt_y_toplam += absf(vt[i]) / Y
			_vt_y_say += 1
		# DIS FAIZ ve SINDIRILEN TEMERRUT ZARARI da birer deger akimidir ve
		# transferle ayni kanallardan girer (talep ve `r_ef`). Ayri anahtar
		# acilmadi cunku cekirdek icin ucu de "disaridan gelen/giden net
		# deger"; bilesenleri `KrizDurumu`da tani olarak ayri duruyor.
		var mor_pay := 1.0 / maxf(float(P.v44.mor_ceza_sure), 1.0)
		var mor_akim := _mor_bekleyen[i] * mor_pay / maxf(donem_yil, 1e-9)
		_mor_bekleyen[i] -= _mor_bekleyen[i] * mor_pay
		ulkeler[i].mor_akim_yil = mor_akim
		cekirdekler[i].adim(ulkeler[i], donem_yil,
				{"VT_net_yil": vt[i] + ulkeler[i].faiz_dis_yil + mor_akim})
		toplam_vt[i] += vt[i] * donem_yil
		toplam_nx[i] += ulkeler[i].NX_yil * donem_yil
		# Bilesik konum: dort kanalin toplami.
		toplam_dis[i] += (ulkeler[i].NX_yil + vt[i] + ulkeler[i].faiz_dis_yil
				+ mor_akim) * donem_yil
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
## Her borcun bir alacaklisi var: net dis varlik konumlarinin toplami sifir.
func _borc_korunumunu_kaydet() -> void:
	var net := PackedFloat64Array()
	for i in range(ulkeler.size()):
		net.append(net_dis_varlik(i))
	en_buyuk_borc_hatasi = maxf(en_buyuk_borc_hatasi, korunum_hatasi(net))


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
