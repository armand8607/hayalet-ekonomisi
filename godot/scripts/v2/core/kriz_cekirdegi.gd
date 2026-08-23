class_name KrizCekirdegi
extends RefCounted

## v2'nin DEGER KATMANI -- Marksist kriz teorisi cekirdegi.
##
## v4.4-Frozen'in `step()` fonksiyonundan ayiklandi. Oradan taşınan tek şey
## DENKLEMLERDIR; 20 ulke, 1259 tur, senaryo odalari ve kalibrasyonun kendisi
## taşınmadi (docs/oyun_tasarimi_v2.md §1).
##
## ANA DONGU:
##     c/v  = organik_bilesim(q)             TAVANSIZ -- egilimin yakiti
##     kv   = kv0 * c/v^us / (1 + ucuzlama)
##     Y_p  = min(K/kv, q * emek_esdeger)    arz kapasitesi
##     V    = Y * canli_pay                  YENI DEGER yalnizca canli emekten
##     s    = V * (1 - pay)                  arti deger
##     r    = s / K                          KAR ORANI
##     g    = g_taban + g_duy*(r-i) + hizlandirici*(u-u_normal)
##     K   *= (1 + g)
##
## Dongu buradan kapanir: q yukselir -> c/v yukselir ve otomasyon canli_pay'i
## dusurur -> V kuculur -> s kuculur -> r duser -> g duser. Oyuncunun her
## "iyilestirmesi" kendi kar oranini asindirir.
##
## DONEM UZUNLUGU. `adim()` bir `donem_yil` alir ve hesabin TAMAMINI YILLIK
## yapar; donem uzunlugu yalnizca stok/sayac guncellemelerinde devreye girer.
## Haftalik, aylik ve turluk kosu ayni yorungeyi verir (`OlcekTesti`).
##
## KAPSAM. Ulke-ICI bloklarin tamami buradadir:
##   c/v, G (arz+otomasyon), H (efektif talep), I (kamu maliyesi), J (Minsky),
##   K (borc/balon patlamasi), A (merkez bankasi), P (Phillips), Q (Goodwin),
##   R (kriz tescili), S (orgutlenme), T (protesto ve devrim),
##   Tonak deger gasbi, ETG, Marksist politik ozne.
##
## DIS bloklar BURADA YOKTUR; hepsi ticaret ortagi ister. Yerlerine `dis`
## sozlugu uzerinden disaridan deger alinir, boylece cekirdek tek basina test
## edilebilir kalir. Durumlari:
##
##   C/L deger transferi -- KURULDU. `Dunya` hesaplar, `dis.VT_net_yil` ile
##                          girer. Korunumlu: sum(VT) == 0 ozdeslikle.
##   B Thirlwall, D ani durus, E moratoryum, F doviz krizi -- HENUZ YOK.
##                          B1b'nin kalan isi (bkz. tasarim belgesi §6).

var P: KrizParam

## Cag gecisini kapatir. YALNIZCA test icindir: `Oran.donem_buyume`'yi kapali
## formulle sinarken `qg`'nin sabit kalmasi gerekir, yoksa test cevrimin
## kendisini degil cag tablosunu olcer.
var cag_sabit := false

## Cag ici teknolojik doyumu kapatir. YALNIZCA test icindir, `cag_sabit` ile
## ayni gerekcesi var: `Oran.donem_buyume`'yi q'nun KAPALI FORMULUNE karsi
## sinamak icin buyume oraninin sabit kalmasi gerekir. `doyum` q'ya bagli
## oldugu icin q'yu geri beslemeli yapar ve kapali formul gecerliligini
## yitirir -- o zaman test donem cevrimini degil DOYUM EGRISINI olcer.
var doyum_sabit := false

## Ucret PAZARLIGINI dondurur: `w_nom_buyume_yil` enflasyona esitlenir, yani
## reel ucret duzeyi sabit kalir. YALNIZCA TEST ICINDIR ve B2b'nin asil
## kapisinin dayandigi yer: pazarlik dondurulunca `pay`i hareket ettirebilecek
## TEK sey kohort BILESIMI kalir. Bu bayrak olmadan bilesim etkisi pazarligin
## gurultusunden ayrilamaz -- disaridan `w_nom_buyume_yil` yazmak islemez,
## `_goodwin` onu her adimda yeniden hesaplar.
var pazarlik_sabit := false

## Devrim gibi ayrik olaylar icin. Motorun kendi RNG'si degil -- v2'nin
## belirlenimciligi kendi tohumundan gelir.
var rng: PyRandom

## MIKRO KATMAN (B2). Takili degilse cekirdek bu dosyadaki KAPALI FORMLARLA
## calisir ve davranisi zerre degismez -- B1a/B1b'nin butun olcumleri
## gecerliligini korur. Takiliysa dort alanin otoritesi ona gecer:
## `K`, `q`, `oto`, `pay_I` (otorite tablosu: `uretim.gd`).
##
## ACIK/KAPALI OLMASI BIR TEST KOLAYLIGI DEGIL, DENEY TASARIMIDIR. B1b'de
## ogrenildi: bir mekanizmanin etkisi ancak AYNI TOHUMLA acik ve kapali
## kosulup karsilastirilarak olculebilir; kesitsel karsilastirma mekanizmanin
## etkisiyle yapisal farki birbirine karistirir ve bir kez yanlis sonuc
## verdi (§6, "Kesitsel degil karsi-olgusal").
var mikro: UretimKatmani = null

## NUFUS KATMANI (B2b). Takili degilse cekirdek eski kapali formlarla calisir.
## Takiliysa emek arzi, istihdam ve ucret payi otoritesi ona gecer:
## `L_etkin`, `e`, `emek_gerginlik`, `pay` (otorite tablosu: `nufus.gd`).
##
## MIKRO'DAN BAGIMSIZ TAKILIR. Ikisi ayri ayri acilip kapanabilmeli, yoksa
## B2a ile B2b'nin etkileri ayri olculemez ve "hangisi yaptI" sorusu
## yanitsiz kalir. B2a'da devrimin 20 yil kaymasinin sebebini eleme yoluyla
## bulmamiz tam da bu ayrilabilirlik sayesinde oldu.
var nufus: NufusKatmani = null

## Goodwin blogunun bu adimda hesapladigi UCRET PAYI DEGISIM ORANI (yillik,
## kirpilmis). Nufus katmani onu okur; pazarlik orani cekirdekte kalsin ama
## uygulandigi yer degissin diye ayri bir alanda durur. Nufus takili degilse
## yalnizca tanidir.
var son_d_pay: float = 0.0

## MAL KATMANI (B2c). Takili degilse satilamayan urun bir AKIMDIR ve donem
## bitince buharlasir; takiliysa depoda BIRIKIR ve sonraki donemin uretimini
## kisar. Otoritesi: `talep_acigi`, `satilamayan_I/II` (bkz. `mal.gd`).
##
## Digerlerinden bagimsiz takilir -- ucu de ayri ayri acilip kapanmali.
var mal: MalKatmani = null

## KARANLIK DEVLET KATMANI (B3). Takili degilse `bolunme` 0.0'da durur ve bu
## dosyadaki butun bolunme carpanlari OZDESLIKLE 1.0 doner -- yani cekirdek
## zerre degismez ve B1/B2 olcumleri gecerliligini korur.
##
## Takiliysa otoritesi: `bolunme`, `mafya_tolerans`, `uyusturucu_orani`,
## `cezaevi_orani`, `egitim`, `nitelik`, `sehit`, `katilim_baski`
## (otorite tablosu: `karanlik.gd`).
##
## DIGERLERINDEN BAGIMSIZ TAKILIR. B2a'da devrimin 20 yil kaymasinin sebebi
## tam da bu ayrilabilirlik sayesinde eleme yoluyla bulunmustu; B3 uc kanal
## birden actigi icin ayrilabilirlik burada daha da onemli.
var karanlik: KaranlikDevlet = null


func _init(p_param: KrizParam = null, tohum: int = 42) -> void:
	P = p_param if p_param != null else KrizParam.new()
	rng = PyRandom.new(tohum)


## Kurumsal rejim tablosundan bir alan okur. Polanyi'nin cifte hareketi bu
## tablo uzerinden calisir: liberal <-> duzenli <-> neoliberal gecisleri
## kamu hedefini, hizlandiriciyi, emegin pazarlik zeminini ve orgutlenme
## erozyonunu ayni anda degistirir.
func _kur(d: KrizDurumu, alan: String, varsayilan: float = 1.0) -> float:
	return float(Tables.KURUMLAR[d.kurum].get(alan, varsayilan))


## BOLME/YOZLASTIRMA KANALLARINA DIRENC -- bilinclendirme sonumlemeyi kirar.
##
## Karsi hareketin IKINCI katmani (§4.4). Parti yalnizca `bolunme` stokunu
## eritmez; karanlik devletin uc kanalinin UCUNDE birden sonumlemeyi
## zayiflatir. Yani sosyalist politik ozne hem bolunmeyi geri iter hem de
## bolunmenin is gormesini engeller -- ve mucadelenin iki tarafli olmasi
## motorda bu ikilikten dogar.
##
## v4.4'te ayni katsayi lumpen ve karseral sonumlerde zaten kullaniliyordu;
## B3 onu bolunmeye de baglar, yani yeni bir sabit gerekmez.
func _direnc(d: KrizDurumu) -> float:
	return 1.0 - P.v44.parti_direnc * d.parti


# Kanal kapilari -- deney tasarimi icin (bkz. `karanlik.gd`). Katman takili
# degilken hepsi acik doner; `bolunme` zaten 0.0 oldugu icin sonuc degismez.
func _kanal_org() -> bool:
	return karanlik == null or karanlik.kanal_org


func _kanal_pazarlik() -> bool:
	return karanlik == null or karanlik.kanal_pazarlik


func _kanal_protesto() -> bool:
	return karanlik == null or karanlik.kanal_protesto


## YENI DEGERIN TOPLAM URUN DEGERINDEKI PAYI --  W = c + v + s  icinde (v+s).
##
## `c` OLU emektir: urune aktarilir ama YENIDEN yaratilmaz. Dolayisiyla
## fiziksel hasila buyurken satinalma gucu ayni hizda buyumez, cunku hasilanin
## giderek buyuyen bir kismi yalnizca AKTARILAN degerdir.
##
##     canli = (v+s) / (c+v+s) = (1 + s/v) / (c/v + 1 + s/v)
##
## Iki girdisi de motorda ZATEN VAR, yeni parametre gerekmez: `cv` organik
## bilesim, `pay` ise yeni degerin ucret payi oldugu icin s/v = (1-pay)/pay.
##
## NEDEN EKLENDI. Bu makas -- uretim kapasitesinin tuketim kapasitesinden
## HIZLI buyumesi -- oyunun ilan edilmis teziydi ama motorda YALNIZCA robot
## orani uzerinden kuruluydu, o da `era >= 5` kapisinin arkasindaydi ve cag
## 5'in `yil_alt`'i 2000. Olculdu: `canli_pay` 1825-2003 arasi tam 1.000,
## yani 198 yilin 178'inde model "fiziksel urunun TAMAMI yeni degerdir"
## diyordu -- bu da c = 0 demektir, W = c+v+s ile celisir.
##
## Marx'ta bu asinma dokuma tezgahindan itibaren SUREKLIDIR; otomasyon onun
## 21. yuzyila ozgu siddetlenmesidir, baslangici degil. Kanal artik c/v'den
## dogar, yani 1825'ten itibaren ve teknolojik gelisme hizlandikca hizlanarak
## acilir. `oto` bunun UZERINE binen ikinci kanaldir.
##
## Artik oran yukseldikce (ucret payi dustukce) `canli` YUKSELIR: ayni c/v
## icin daha cok arti deger, yani (v+s) c'ye gore daha buyuk. Somuru
## yogunlasmasi Kapital III bol. 14'un ikinci karsi-egilimidir.
func _yeni_deger_payi(cv: float, pay: float) -> float:
	var artik_oran := (1.0 - pay) / maxf(pay, 1e-6)
	return (1.0 + artik_oran) / maxf(cv + 1.0 + artik_oran, 1e-9)


func kappa_v(cv: float, q: float) -> float:
	var L := maxf(0.0, log(maxf(q, 0.05) / 0.5))
	var ucuz := P.v44.ucuzlama_max * L / (L + P.v44.ucuzlama_h)
	return P.v44.kv0 * pow(cv, P.v44.kv_us) / (1.0 + ucuz)


## BASLANGIC KALIBRASYONU -- cagrilmasi ZORUNLUDUR.
##
## Sermaye stoku keyfi verilemez: kapasite (K/kv) ile emek arzi (q*L) ayni
## mertebede olmali ki ikisi de SIRAYLA baglayici kisit olabilsin. Aksi
## halde biri surekli baglar, istihdam ya tavanda ya tabanda takilir ve
## konjonktur dalgasi hic dogmaz.
##
## v4.4 bunu `init_simulation()` icinde dunya olceginde yapiyordu:
##     hedef = kappa_v(cv,q) * q * L * hedef_istihdam / u_normal
##     K    *= hedef / K
## Burada tek ulke icin ayni sey yapilir.
##
## Ilk yazimda bu adim ATLANDI ve K elle 320 verildi. Sonucu: emek surekli
## baglayici kisit oldu, istihdam %100'de takildi, talep hic baglamadi ve
## 100 yilda sifir kriz tescil edildi -- tarihsel kayit ayni pencerede on
## ikiden fazla kriz sayarken.
func baslat(d: KrizDurumu, hedef_istihdam: float = 0.90) -> void:
	P.cag_uygula(d.era)
	_calisma_suresi(d)
	d.cv = Formulas.organik_bilesim(d.q) * d.deger_carpani
	d.kv = kappa_v(d.cv, d.q)

	var emek := d.l_etkin() * d.hafta_saati
	# Kapasiteyi hedef istihdama oturt.
	d.K = d.kv * d.q * emek * hedef_istihdam / P.v44.u_normal

	d.Y_yil = minf(d.K / d.kv, d.q * emek) * P.v44.u_normal / Oran.V44_TUR_YIL
	d.Y_pot_yil = d.Y_yil
	d.Y_zirve = d.Y_yil
	d.Y_ort = d.Y_yil
	d.Y_trend = d.Y_yil
	d.norm = P.v44.tuketim_normu
	d.e = hedef_istihdam
	d.e_norm = hedef_istihdam
	d.u = P.v44.u_normal
	# Baslangicta da deger bilesimi kanali gecerli: `V_onceki` ilk adimin
	# tuketim tabanini kurar, 1.0 birakilirsa ilk adim yapay bir talep siciramasi
	# gorur.
	d.canli_pay = maxf(P.v44.oto_canli_taban, _yeni_deger_payi(d.cv, d.pay))
	d.V_yil = d.Y_yil * d.canli_pay


## Bir donem ilerletir.
##   `donem_yil` : 1/52 haftalik, 0.27 v4.4 turu, 1.0 yillik
##   `dis`       : dis dunyadan gelen buyuklukler (B2'de baglanir)
##                 "VT_net_yil" -> deger transferi, "blok" -> yayilma
func adim(d: KrizDurumu, donem_yil: float, dis: Dictionary = {}) -> void:
	P.cag_uygula(d.era)
	var VT_net_yil := float(dis.get("VT_net_yil", 0.0))
	var Y_onceki := d.Y_yil

	# MIKRO KATMAN EN BASTA TOPLAR. Sira zorunludur: `_deger_bilesimi` c/v'yi
	# q'dan turetir, dolayisiyla q bu adimda kullanilmadan ONCE binalardan
	# okunmalidir. `q_toplam()` cebirsel olarak `kv`den bagimsiz oldugu icin
	# (kanit: uretim.gd) bu sira daireyi kapatmaz.
	if mikro != null:
		mikro.topla(d)

	_deger_bilesimi(d, donem_yil)
	_calisma_suresi(d)
	var Y_pot := _arz_kapasitesi(d, donem_yil)
	_merkez_bankasi(d, donem_yil)
	var talep := _efektif_talep(d, donem_yil, Y_pot, VT_net_yil)
	_hasila_ve_istihdam(d, donem_yil, Y_pot, talep, Y_onceki)
	# EMEK PIYASASI hasiladan SONRA temizlenir: istihdam gerceklesen hasilanin
	# istedigi emek ile kohortlarin sundugu emegin orani. `u` cekirdekte kalir
	# (sermaye kullanimi), `e` ve gerginlik nufus katmanina gecer.
	if nufus != null:
		nufus.emek_piyasasi(d, mikro)
	_etg(d, donem_yil)
	_arti_deger_ve_kar(d, donem_yil, VT_net_yil)
	_minsky(d, donem_yil)
	_birikim(d, donem_yil, VT_net_yil)
	_phillips(d, donem_yil)
	_goodwin(d, donem_yil)
	# BOLUSUM Goodwin'DEN SONRA. Sira zorunludur: Goodwin pazarlik ORANINI
	# (`w_nom_buyume_yil`) hesaplar, nufus katmani onu bir ucret DUZEYINE
	# uygular ve `pay`i kohort bilesiminden turetir. Once cagrilsa oran bir
	# donem eski kalirdi.
	if nufus != null:
		nufus.bolusum(d, donem_yil, son_d_pay)
		d.pay = nufus.pay_hesapla(d)
		pay_sinirla(d)
	_kriz_tescili(d, donem_yil)
	# KARANLIK DEVLET SIYASI BLOKLARDAN ONCE. Sira zorunludur: `bolunme` bu
	# adimda hesaplanan `org`, `parti` ve `pay`dan dogar, ve hemen ardindan
	# gelen S ve T bloklari onu OKUR. Sonra cagrilsaydi bolunme bir donem
	# geriden is gorurdu.
	#
	# `cezaevi_orani` ve `l_etkin()` icin bir donemlik GECIKME kalir: karseral
	# formul bu adimin basindaki `Omega`yi okur ve emek arzi etkisi gelecek
	# donem gorunur. Gecikme v4.4'te de vardi ve orada da KASITLIYDI --
	# devlet politikasi GOZLEMLENMIS duruma tepki verir (`motor.py:2002`).
	if karanlik != null:
		karanlik.adim(d, donem_yil)
	_orgutlenme(d, donem_yil)
	_protesto_ve_devrim(d, donem_yil, dis)

	# Uretkenlik en sonda: bu donemin hasilasi bu donemin q'suyla uretildi.
	_uretkenlik(d, donem_yil)
	_nufus(d, donem_yil)
	_cag_gecisi(d, donem_yil)
	d.yil += donem_yil


## URETKENLIK -- CAG ICINDE DOYUMA GIRER.
##
## v4.4 (`motor.py:2253`):
##     doyum    = max(q_doyum_taban, 1 - q/E["q_tavan"])
##     q_buyume = E["qg"] * ... * doyum * ito
##
## v2'nin ilk yaziminda `doyum` HIC TASINMADI: q sabit oranda, sinirsiz
## bilesikleniyordu. Sonucu olculdu -- 198 yilda c/v 15 olan cag-6 capasini
## asip 112'ye, yillik K/Y ise 21'e cikiyor.
##
## NEDEN OLDURUCU. `Y_pot = K/kv` oldugu icin K/Y ozdeslikle `kv*TUR_YIL`e
## esittir ve `kv` yalnizca c/v'ye bakar. Yani K/Y'yi baska HICBIR SEY
## sinirlayamaz -- sermaye stokunu kucultmek Y'yi ayni oranda kucultur.
## (Olculdu: ahlaki asinma kanali 0'dan 1'e tarandi, K/Y 21.2'de kipirdamadi.)
## K/Y buyudukce brut yatirim talebi `(g + yenileme*delta)*K` hasilayi asar --
## 2023'te I/Y_pot = 1.80, D/Y_pot = 2.36. Talep arzi kalici olarak astigi
## icin hicbir departmanda mal yigilamaz, `talep_acigi` sifirda kalir ve
## ASIRI URETIM, RESESYON, BUNALIM kanallarinin ucu de ARITMETIK OLARAK
## kapanir. 198 yilda sifir cevrimsel kriz, tek terminal devrim.
##
## Doyum bunu yapisal olarak kapatir ve oyunun asil iddiasini kurar:
## teknolojik gelisme SICRAMALIDIR. Cag icinde buyume yavaslar, egilim
## (LTRPF) ustunluk kurar ve kriz olgunlasir; cag atlamasi yeni bir capa
## acar ve yeni bir birikim dalgasi baslar. Kriz artik takvimin degil
## TEKNOLOJIK DONEMIN fonksiyonudur.
##
## MIKRO KATMAN TAKILIYSA BU BLOK KOSMAZ. Uretkenlik artik takvimin degil
## YATIRIM KARARININ sonucudur: q ancak bir bina bir ust basamaga gectiginde
## yukselir, ve o gecis sermaye ister. Teknolojik gelismenin "sicramali"
## olmasi boylece bir cag TABLOSUNDAN degil, birikimin kendisinden dogar.
##
## Doyum egrisi de gereksizlesir: merdivenin ustu sonludur ve bir sonraki
## basamak `era_min` ile kapalidir, yani cag ici doyum YAPISALDIR.
func _uretkenlik(d: KrizDurumu, donem_yil: float) -> void:
	if mikro != null:
		return
	var E: Dictionary = Tables.ERAS[clampi(d.era, 1, 6)]
	var doyum := 1.0 if doyum_sabit else maxf(
			P.v44.q_doyum_taban, 1.0 - d.q / float(E["q_tavan"]))
	d.q_doyum = doyum
	# NITELIKLI EMEK (B3, §4.3): riza aygitinin bedeli buradan cikar. Bilim
	# karsitligi ve uyusturucu egitim tabanini curutur, `nitelik` duser, `q`
	# buyumesi yavaslar -- ve `qg` LTRPF'ye karsi elde kalan TEK karsi
	# egilimdir. Karanlik devlet toplumsal barisi kendi gelecekteki birikimini
	# yiyerek satin alir. Katman takili degilken `nitelik` 1.0'dir.
	d.q *= (1.0 + Oran.donem_buyume(P.qg_yil * doyum * d.nitelik, donem_yil))


## Nufus. Katman takiliysa kohortlar buyur ve aralarinda gecis olur (B2b);
## takili degilse toplam emek arzi tek bir oranla buyur.
func _nufus(d: KrizDurumu, donem_yil: float) -> void:
	var artis := Oran.v44_buyume(P.v44.nufus_artis)
	if nufus != null:
		nufus.nufus_adim(d, donem_yil, artis)
		return
	d.L_etkin *= (1.0 + Oran.donem_buyume(artis, donem_yil))


## CAG GECISI -- takvim yili VE uretkenlik esigi birlikte belirler.
##
## Cift kosul bilerektir: erken sanayilesen bir ulke 1900'de tam otomasyona
## varamaz (yil_alt onu tutar), geride kalan bir ulke de sonsuza kadar buhar
## caginda kalmaz (yil_ust onu iter).
##
## DIKKAT -- v2 icin onemli sonuc: cag 5 (otomasyon) `yil_alt = 2000`'dir.
## 1836-1936 penceresinde OTOMASYON HIC BASLAMAZ, dolayisiyla canli_pay
## dusmez ve otomasyon kaynakli gerceklesme krizi o pencerede ateslenemez.
## Bu bir hata degil, tarih araliginin sonucudur; tasarim kararidir ve
## docs/oyun_tasarimi_v2.md §5.3'te tartisilmalidir.
func _cag_gecisi(d: KrizDurumu, donem_yil: float) -> void:
	if cag_sabit or d.era >= 6:
		return
	var E2: Dictionary = Tables.ERAS[d.era + 1]
	var atla := d.yil >= float(E2["yil_alt"]) and (
			d.q > float(E2["q_esik"]) or d.yil >= float(E2["yil_ust"]))
	if not atla:
		return
	d.era += 1
	d.kent = float(E2["kent"])
	d.IR = minf(1.0, d.IR + 0.08)
	# Cag gecisi sermayeyi eskitir: eski teknik yapinin bir kismi silinir.
	d.K *= (1.0 - P.v44.gecis_yikim)
	# Ayni kirpma binalara da yazilmali, yoksa `sum(bina.K)` ile `d.K`
	# ayrisir ve ozdeslik cag gecisinde sessizce kirilir -- kampanyada
	# yalnizca bes kez olan, dolayisiyla gozden kacmasi en kolay yer.
	if mikro != null:
		mikro.gecis_yikimi(P.v44.gecis_yikim)
	if d.rejim == "kapitalist":
		d.Omega = minf(1.0, d.Omega + P.v44.gecis_omega)


# ===========================================================================
# DEGER BILESIMI
# ===========================================================================

## SABIT SERMAYENIN KRIZDE DEGERSIZLESMESI -- Kapital III bol. 14'un
## karsi-egilimler listesindeki BIRINCI madde.
##
## `deger_carpani` v2'nin ilk yaziminda YAZILIYOR ama HIC OKUNMUYORDU: kriz
## tescili ve Minsky patlamasi carpani dusuruyor, sonra kimse ona bakmiyordu.
## Yani kriz yalnizca yikiyor, HICBIR SEYI ONARMIYORDU.
##
## Bu tam olarak v4.4'un kendi belgesinin §17'de tarif ettigi hastaliktir:
## "Model r = (1-pay)*u/kv ozdesligine indirgendigi icin sermaye yikimi kar
## oranini HIC yukseltmiyordu; kriz yalnizca yikiyor, hicbir seyi onarmiyordu."
## v4.4 mekanizmayi tam da bunun icin eklemisti; v2'ye ayiklanirken dustu.
##
## SONUCU OLCULDU: cevrim dogmuyor. Kar orani 0.098'den 0.010'a TEK YONLU
## iniyor, hicbir yerde geri donmuyor, ve 198 yilda sifir cevrimsel kriz ile
## tek bir terminal devrim cikiyor. Marx'ta kriz dongunun SONU degil
## DONUM NOKTASIDIR: sermayeyi degersizlestirir, boylece kar oranini onarir
## ve bir sonraki birikim dalgasini acar.
##
## Zincir: kriz -> deger_carpani duser -> c/v duser -> kv duser -> ayni
## sermaye ile daha cok hasila -> r YUKSELIR -> birikim yeniden baslar.
## `dev_geri` ile carpan yavasca 1.0'a doner, yani onarim kalici degildir --
## egilim yeniden ustunluk kurar ve bir sonraki kriz gelir.
func _deger_bilesimi(d: KrizDurumu, donem_yil: float) -> void:
	# Devaluasyon yavas geri doner: onarim gecicidir, egilim kalicidir.
	d.deger_carpani = minf(1.0, d.deger_carpani
			+ Oran.donem_uyum(P.dev_geri_yil, donem_yil) * (1.0 - d.deger_carpani))
	# c/v'nin TAVANI YOKTUR. Egilimin yakiti budur: q buyudukce c/v buyur ve
	# geri donmez -- ama KRIZ onu geri iter. Egilim ile karsi-egilim.
	d.cv = Formulas.organik_bilesim(d.q) * d.deger_carpani
	d.kv = kappa_v(d.cv, d.q)


# ===========================================================================
# N. HAFTALIK CALISMA SURESI
# ===========================================================================

## Cag ilerledikce haftalik emek-saati normu DUSER: [1.0, .86, .74, .64,
## .55, .47]. Bu kozmetik degil, motorun en onemli kanallarindan biri:
##
##   sure duser -> canli emek girdisi duser -> Y_L duser -> emek yerine
##   SERMAYE baglayici kisit olur -> istihdam tavandan iner -> yedek sanayi
##   ordusu dogar -> Goodwin salinimi ve talep yetersizligi mumkun hale gelir.
##
## Ilk yazimda bu blok cekirdegin kapsaminda SAYILDI ama uygulanmadi
## (`hafta_saati` 1.0'da sabit kaldi). Sonucu: istihdam surekli %100'de
## takildi, talep hic baglamadi ve 100 yilda SIFIR kriz tescil edildi --
## oysa tarihsel kayit ayni pencerede on ikiden fazla kriz sayiyor.
func _calisma_suresi(d: KrizDurumu) -> void:
	d.hafta_saati = float(P.v44.hafta_norm[clampi(d.era, 1, 6) - 1]) * d.saat


# ===========================================================================
# G. ARZ KAPASITESI + OTOMASYON
# ===========================================================================

func _arz_kapasitesi(d: KrizDurumu, donem_yil: float) -> float:
	# Otomasyon bir POLITIKA degil, rekabetin zorlayici yasasinin sonucudur:
	# duran geride kalir. Oyuncunun kapatabilecegi bir kol degildir.
	#
	# MIKRO KATMAN TAKILIYSA bu blok atlanir: `oto` artik cag tablosundan
	# gelen bir hedefe yaklasan bir sayi degil, MAKINE-AGIRLIKLI BASAMAKTAKI
	# BINALARIN SERMAYE PAYIDIR. Ikisi birden yazsaydi hangisinin kazandigi
	# cagri sirasina baglanirdi -- §8.2'nin tarif ettigi hata tam olarak budur.
	if mikro == null:
		if d.era >= P.v44.oto_esik_era:
			var hedef := P.v44.oto_tavan * minf(1.0, d.ito / P.v44.ito_tavan) * minf(
					1.0, float(d.era - P.v44.oto_esik_era + 1) / 2.0)
			d.oto += Oran.donem_uyum(P.oto_hiz_yil, donem_yil) * (hedef - d.oto)
		d.oto = clampf(d.oto, 0.0, P.v44.oto_tavan)

	# Satinalma gucu iki AYRI kanaldan asinir; ikisi zincirin ayri
	# noktalarinda oturur, o yuzden carpilirlar:
	#   (1) toplam urun degerinin ne kadari YENI degerdir  -> `_yeni_deger_payi`
	#   (2) o yeni degerin uretiminde canli emegin payi     -> robot orani
	var canli_emek := d.l_etkin() * d.hafta_saati
	var robot := P.v44.oto_verim * d.oto * d.K / maxf(d.q, 1e-6)
	var emek_esdeger := canli_emek + robot
	# Robotlar FIZIKSEL uretime katilir ama DEGER uretmezler.
	var robot_pay := canli_emek / maxf(emek_esdeger, 1e-9)
	d.canli_pay = maxf(P.v44.oto_canli_taban,
			_yeni_deger_payi(d.cv, d.pay) * robot_pay)

	# TUZAK -- `kv` ZAMAN BIRIMI TASIR. `kappa_v` v4.4'ten geldigi icin TUR
	# basina sermaye/hasila oranidir: kodda kv~22 gormek YILLIK K/Y~5.9
	# demektir (CLAUDE.md, birim sozlesmesi). Ayni sekilde `q * emek_esdeger`
	# de bir TUR akimidir. Ikisi de yilliga cevrilmeden kullanilirsa hasila
	# 14 kat kucuk cikar, yatirim talebi hasilayi asar ve TALEP HIC BAGLAMAZ --
	# yani gerceklesme krizi imkansizlasir.
	#
	# Bu, olcek tuzaginin en sinsi kiligi: bir ORAN, birimini adinda tasimaz.
	# Ilk yazimda gozden kacti ve `--v2-iz` ile yakalandi (Y == Y_pot her
	# satirda, talep_acigi hep sifir).
	var Y_K := d.K / maxf(d.kv, 1e-9)
	var Y_L := d.q * emek_esdeger
	d.Y_pot_yil = minf(Y_K, Y_L) / Oran.V44_TUR_YIL
	return d.Y_pot_yil


# ===========================================================================
# A. MERKEZ BANKASI -- Taylor kurali + balon/kriz duyarliligi
# ===========================================================================

func _merkez_bankasi(d: KrizDurumu, donem_yil: float) -> void:
	var balon := maxf(0.0, d.varlik / maxf(d.Y_yil, 1e-6) - 1.0)
	var hedef := (P.v44.i_notr
			+ P.v44.tay_pi * (d.pi_inf - P.v44.pi_hedef)
			+ P.v44.tay_u * (d.u - P.v44.u_normal)
			+ P.v44.tay_e * (d.e - P.v44.e0)
			+ P.v44.tay_balon * balon
			- (P.v44.tay_kriz if d.delev > 0 else 0.0))
	# Atalet bir UYUM katsayisidir: politika faizi hedefe yavas yakinsar.
	var uy := Oran.donem_uyum(Oran.v44_uyum(1.0 - P.v44.tay_atalet), donem_yil)
	d.i_pol_yil += uy * (hedef - d.i_pol_yil)
	d.i_pol_yil = clampf(d.i_pol_yil, P.v44.i_min, P.v44.i_max)

	# Efektif borclanma maliyeti: politika faizi + risk marji. Kar oraninin
	# ustune cikabilir -- LTRPF'nin birikimi bogdugu kanal budur.
	#
	# ODEMELER DENGESI PRIMI (Thirlwall, B bloku). Odeyebileceginden hizli
	# buyuyen ulke dis finansmani daha pahaliya bulur; prim politika faizini
	# CARPAR (v4.4 `motor.py:1779` ile ayni bicim). Kisitin birikimi bogdugu
	# kanal budur: `g = g_taban + g_duy*(r_ef - i) + ...` icinde `i` yukselir.
	# `Dunya` yazmazsa `BoP_R = 0` kalir ve kapali ekonomi etkilenmez.
	d.i_yil = d.i_pol_yil * (1.0 + d.BoP_R) + P.v44.faiz_taban_marj
	# Spekulatif finansman maliyeti TAVANSIZ.
	d.i_spec_yil = d.i_yil + P.v44.borc_faizi_marj


# ===========================================================================
# H. EFEKTIF TALEP & BORCLANMA SINIRI  (Clarke & Fisher)
# ===========================================================================

func _efektif_talep(d: KrizDurumu, donem_yil: float, Y_pot: float,
		VT_net_yil: float) -> float:
	# Satinalma gucu YENI DEGERDEN gelir, fiziksel hasiladan degil. Otomasyon
	# ilerledikce Y buyur ama V kuculur: kronik asiri uretim bu makastan dogar.
	var V_onceki := maxf(d.V_yil, d.Y_yil * d.canli_pay)
	var etg_kesinti := P.v44.etg_vergi_ucret * d.etg_vergi_ucret_o
	var C_temel := (P.v44.c_ucret * d.pay * V_onceki * maxf(0.15, 1.0 - etg_kesinti)
			+ P.v44.c_kar * (1.0 - d.pay) * V_onceki)

	var gerceklesen := C_temel / maxf(d.Y_yil, 1e-6)
	var hedef_norm := (P.v44.norm_agirlik * P.v44.tuketim_normu
			+ (1.0 - P.v44.norm_agirlik) * gerceklesen)
	d.norm += Oran.donem_uyum(P.norm_uyum_yil, donem_yil) * (hedef_norm - d.norm)
	d.norm = clampf(d.norm, P.v44.gecim_tabani, P.v44.norm_tavan)
	var acik := maxf(0.0, d.norm * d.Y_yil - C_temel)

	# --- Kredi: acigi bugun kapatir, yarin Minsky bombasini kurar ---
	var yeni_kredi := 0.0
	if d.rejim == "kapitalist" and d.delev == 0:
		# Kredi istahi borc oranina gore soner: borc limite yaklastikca yeni
		# kredi kurur ve borc orani limitin ALTINDA asimptot yapar.
		var istah := maxf(0.0, 1.0 - pow(
				d.borc / maxf(d.Y_yil, 1e-6) / P.v44.borc_limiti, P.v44.kredi_us))
		yeni_kredi = P.kredi_egilimi_yil * acik * istah
		d.borc += Oran.donem_akim(yeni_kredi, donem_yil)

	# --- K. Fisher & Clarke: de-leveraging ---
	if d.delev > 0:
		d.borc = maxf(0.0, d.borc * (1.0 - Oran.donem_akim(P.delev_hiz_yil, donem_yil)))
		d.delev -= 1

	var borc_servisi := (d.i_yil + P.v44.borc_faizi_marj) * d.borc
	var C := C_temel + yeni_kredi - borc_servisi
	# --- BRUT YATIRIM: yenileme KARLILIGA baglidir (v2 eklemesi) ---
	#
	# v4.4'te brut yatirim `(g + delta)*K` idi ve `delta*K` karliliktan
	# bagimsiz bir TALEP TABANI kuruyordu: kar orani cokse, net birikim dursa
	# bile amortisman talebi hasilayi ayakta tutuyordu. Sonucu, kapali bir
	# ekonomide gerceklesme krizinin ATESLENEMEMESIYDI -- oysa Marx'ta kriz
	# egilimi tam da sermayenin kendi icindedir.
	#
	# Duzeltme: karlilik faizin altina dustukce kapitalist eskiyen sermayeyi
	# yenilemez. Parayi tutar, ya da spekulasyona kaydirir (J blogu zaten o
	# kanali tasiyor). Yenileme tabana kadar duser ama sifirlanmaz -- bakimin
	# tamamen durmasi fiziksel olarak mumkun degil.
	# Makas KAR ORANI OLCEGINE gore normalize edilir, faize gore DEGIL.
	#
	# Onceki hali `(r - i) / max(i, 0.01)` idi. Faiz taban degerine (0.005)
	# indiginde payda 0.01'e sabitlenir ve makas 100*(r-i) olur: r'deki en
	# kucuk kipirti sigmoidi bir ucundan otekine atar. Fren o zaman bir fren
	# degil ANAHTARdir, ve motor bir GEVSEME SALINIMINA doner -- olculdu,
	# yatirim her dokuz yilda tam sifira, istihdam 0.27'ye iniyordu. Keskin
	# bir limit cevrimi faza duyarlidir, o yuzden haftalik ve aylik kosu
	# ayni yorungede kalmiyordu (K %27 ayrisma).
	#
	# `r_referans` (0.03) kar oraninin kendi buyukluk mertebesidir; makas ona
	# gore olculunce sigmoid butun bantta duyarli kalir ve fren surekli
	# calisir. Kar-faiz makasinin ISARETI korunur: r < i iken fren yine kapanir.
	var marj := (d.r_yil - d.i_yil) / P.v44.r_referans
	var yenileme := (P.yenileme_taban + (1.0 - P.yenileme_taban)
			* Formulas.sg(P.yenileme_duyarlilik * marj))
	d.yenileme_orani = yenileme

	# --- SEMA KAPANIR: TUKETILEN SABIT SERMAYE DE TALEPTIR ---
	#
	# Urun degeri W = c + v + s. Satinalma gucu olarak yalnizca (v+s) sayilirsa
	# `c` hicbir yerde talep olarak GORUNMEZ ve talep yapay olarak coker.
	# Marx'ta oyle degildir: `c` Departman I'in urunune yonelen taleptir --
	# tuketilen uretim araci YERINE KONMAK zorundadir.
	#
	# Olculdu: `c` talep tarafina eklenmeden `canli_pay` c/v'ye baglandiginda
	# yatirim tam SIFIRA, istihdam 0.27'ye iniyor ve yirmi yilda bir 1929'dan
	# agir bir cokus tekrarliyordu. Sema kapanmadigi icin.
	#
	# `delta_K * K` ARTIK YOK: tuketilen sabit sermayenin karsiligi c'nin
	# kendisidir, ikisini birden saymak amortismani cift sayardi.
	var c_akim := d.Y_yil * (1.0 - d.canli_pay)

	# --- SABIT SERMAYENIN DEVIR CEVRIMI (Kapital II, bol. 9 ve 20) ---
	#
	# `c` her donem AYNI donemde harcanirsa yenileme talebi cari hasilayi
	# birebir kovalar ve D/Y ~ 1'e kilitlenir: olculdu, cevrim sonuyordu.
	# Marx'ta oyle degildir ve bunu ACIKCA krizin periyoduna baglar: sabit
	# sermaye YILLAR BOYU asinir ama TOPTAN yenilenir. Asinma payi bu arada
	# bir AMORTISMAN FONUNDA para olarak yatar -- yani satis gerceklesmis
	# ama karsit alis HENUZ YAPILMAMISTIR. Gerceklesme kriziinin imkani tam
	# olarak bu ayrilmadan dogar.
	#
	# Fon `c` ile dolar, `omur` boyunca bosalir ve bosalma hizina karlilik
	# freni biner. Durgun durumda harcama = c_akim, yani yeniden uretim
	# semasi UZUN VADEDE aynen kapanir; kisa vadede ise `omur` kadar bir
	# GECIKME vardir ve cevrimi ureten budur. Karlilik dustugunde kapitalist
	# fonu harcamaz, TUTAR: talep dusen kar oranini takip eder, gecikmeyle.
	# Harcama donem BASINDAKI fondan hesaplanir, bu donemin girisi eklenmeden:
	# aksi halde cikis kendi girisine baglanir ve bagi donem uzunlugu tasir.
	var yenileme_harcamasi := yenileme * d.amortisman / P.yenileme_omru_yil

	# --- FONUN SIZINTISI: AMORTISMAN URETIME DONMEYEBILIR ---
	#
	# Fonun harcanmayan payi fonda BEKLEMEK zorunda degildir. Marx amortisman
	# fonunu zaten ATIL PARA SERMAYE olarak tarif eder (Kapital II, bol. 20);
	# atil para sermaye ise faiz getiren sermayeye donusur. Yenilenmeyen
	# sermayenin karsiligi uretime geri donmez, finansal varliga kayar.
	#
	# NEDEN ONEMLI. `c_akim = Y * (1 - canli_pay)` oldugu icin fon teknolojik
	# gelismeyle BUYUR: canli_pay 0.58'den 0.07'ye inerken hasilanin giderek
	# daha buyuk kismi fondan gecer. Sizinti da onunla buyur. Olculdu -- bu
	# kanal yokken balon 19. yuzyil olgusu cikiyordu (1865'te varlik/Y 1.88,
	# 1920'lerden sonra sifir), yani tarihin tersi. Sebebi yapisaldi: c/v
	# yukseldikce yenileme talebi Departman I'i doyuruyor, `talep_acigi`
	# kapaniyor ve finansallasmanin yakiti tukeniyordu -- oysa uretim ile
	# tuketim kapasitesi arasindaki makas acilmaya devam ediyor.
	#
	# Sizinti iki ucu birden baglar: hem talebi KALICI olarak dusurur (fondaki
	# para bekleyip sonra harcanmaz, hic donmez), hem de gec donemde
	# finansallasmayi besler.
	var sizinti := P.fin_sizinti * (1.0 - yenileme) * d.amortisman / P.yenileme_omru_yil
	d.varlik += Oran.donem_akim(sizinti, donem_yil)
	d.amortisman = maxf(0.0, d.amortisman
			+ Oran.donem_akim(c_akim - yenileme_harcamasi - sizinti, donem_yil))

	# NET BIRIKIM TALEBI `max(0, g)`'dir. Negatif `g` sermayenin ERIMESIDIR --
	# eksi satin alma degil, satin ALMAMA. Toplamda birakilirsa daralma
	# doneminde `g*K` butun yenileme talebini gotururdu ve brut yatirim
	# `max(0, .)` tabanina carpardi: olculdu, yatirim her dokuz yilda TAM
	# SIFIRA iniyordu. O sert taban motoru katilastirir (haftalik ile aylik
	# kosu ayni yorungede kalamaz) ve gercek bir ekonomide karsiligi yoktur.
	# Sermayenin erimesi zaten `d.K *= (1+g)` ile ayrica gerceklesir.
	var I := ((maxf(0.0, d.g_yil) * d.K + yenileme_harcamasi)
			* (1.0 - (P.v44.delev_yatirim_soku if d.delev > 0 else 0.0)))
	var G := _kamu_maliyesi(d, donem_yil, Y_pot)

	# DEGER TRANSFERI TALEBE ISARETIYLE GIRER.
	#
	# v4.4 burada `max(VT_net, 0)` yaziyordu (`motor.py:1930`): gelen deger
	# talebe EKLENIYOR, giden deger hicbir yerden DUSULMUYORDU. Muhasebe tek
	# yonluydu -- bir ulke deger kaybederken satin alma gucu kaybetmiyordu.
	#
	# Olculdu: bu haliyle transferin verici uzerindeki etkisi SIFIR. Alti
	# tohumun altisinda da veren ulkenin bunalim yogunlugu transfer acikken ve
	# kapaliyken BIREBIR ayni cikiyordu (degisim +0.0), cunku negatif VT'nin
	# tek kanali `r_ef` idi ve orada da VT/K ~ 0.0006 mertebesinde kaliyordu.
	#
	# Oysa esitsiz mubadelede giden sey GERCEKLESMIS SATIN ALMA GUCUDUR: cevre
	# ulke kendi urununu satin alamaz hale gelir. Gerceklesme krizinin
	# emperyalizm uzerinden cevreye tasinma kanali tam olarak budur, ve tek
	# yonlu muhasebeyle o kanal kapalidir.
	# NET IHRACAT -- gerceklesmenin DIS cikisi.
	#
	# Asiri uretim krizinin ilk cikisi yeni pazardir (tasarim belgesi §3.1):
	# iceride satilamayan mal disarida alici bulur. Bu yuzden `NX` talebe
	# dogrudan girer -- ihracat yerli urune talep, ithalat ise yerli talebin
	# disariya kacan kismidir.
	#
	# `Dunya` yazmazsa sifirdir; kapali ekonomi testleri etkilenmez.
	var D_talep := C + I + G + VT_net_yil + d.NX_yil
	# SAVAS TALEBI (B4, v4.4 `motor.py:1931`). Savas ekonomisi kapasiteyi
	# neredeyse tamamen sogurur -- silah da bir metadir ve alicisi devlettir.
	#
	# §3.1'in "asiri uretim -> yeni pazar, gerekirse zorla" satirinin motordaki
	# en dogrudan bicimi budur: savas gerceklesme krizini COZER, cunku
	# satilamayan urun sorunu ortadan kalkar. Bedeli asagida, `SavasKatmani`de.
	if d.savasta():
		D_talep = maxf(D_talep, Y_pot * 0.95)
	d.C_yil = C
	d.I_yil = I
	d.G_yil = G
	d.D_yil = D_talep

	# Ihracat tuketim mali da uretim araci da olabilir; departman ayriminda
	# Departman II'ye yazmak yerine ikiye BOLUNUR, yoksa dis pazar yalnizca
	# tuketim mali sikisikligini cozer ve Departman I orantisizligi yapay
	# olarak agirlasir.
	_departmanlar(d, donem_yil, Y_pot,
			C + G + VT_net_yil + 0.5 * d.NX_yil, I + 0.5 * d.NX_yil)
	return D_talep


# ===========================================================================
# DEPARTMAN I / II  --  Marx'in yeniden uretim semalari
# ===========================================================================

## Hasilayi iki departmana boler ve HER BIRINI KENDI TALEBIYLE karsilastirir.
##
## NEDEN ZORUNLU. Tek mallik bir modelde gerceklesme krizi YAPISAL OLARAK
## imkansizdir: yatirim talebi ile tuketim talebi ayni farksiz hasilayi satin
## alir, biri digerinin yerine gecer, orantisizlik dogamaz. Olculdu -- tek
## mallik surumde 198 yilda SIFIR asiri uretim krizi cikti.
##
## Marx'ta kriz tam da bu orantisizliktan dogar:
##   Departman I  uretim araci uretir, alicisi YATIRIMDIR
##   Departman II tuketim mali uretir, alicisi UCRET ve KAMU harcamasidir
## Ikisi birbirinin yerine GECEMEZ. Celik fabrikasina ekmek talebi gelmez.
##
## Kriz mekanizmasi: patlama doneminde yatirim payi buyur, sermaye Departman
## I'e akar; kar orani dusup yatirim cokunce o kapasite MAHSUR kalir --
## satilamayan uretim araci yigilir. Sermayenin yeniden dagilimi YAVASTIR ve
## krizi ureten sey tam olarak bu yavasliktir.
func _departmanlar(d: KrizDurumu, donem_yil: float, Y_pot: float,
		D_tuketim: float, D_yatirim: float) -> void:
	# Sermaye, talebin gectigimiz donemlerdeki bilesimini KOVALAR -- ama yavas.
	var toplam := maxf(D_tuketim + D_yatirim, 1e-9)
	var hedef := clampf(D_yatirim / toplam, 0.05, 0.90)
	d.pay_I += Oran.donem_uyum(P.dept_uyum_yil, donem_yil) * (hedef - d.pay_I)
	d.pay_I = clampf(d.pay_I, 0.05, 0.90)

	var kap_I := Y_pot * d.pay_I
	var kap_II := Y_pot * (1.0 - d.pay_I)

	if mal != null:
		_mal_piyasasi(d, donem_yil, Y_pot, kap_I, kap_II, D_tuketim, D_yatirim)
		return

	d.Y_I_yil = minf(kap_I, D_yatirim)
	d.Y_II_yil = minf(kap_II, D_tuketim)
	d.satilamayan_I = maxf(0.0, kap_I - D_yatirim)
	d.satilamayan_II = maxf(0.0, kap_II - D_tuketim)

	# ASIRI URETIM: satilamayan urun kitlesi. Artik "toplam talep toplam
	# arzdan kucuk mu" degil, "HANGI DEPARTMANDA mal yigildi" sorusu.
	d.talep_acigi = (d.satilamayan_I + d.satilamayan_II) / maxf(Y_pot, 1e-9)


## MAL KATMANI TAKILIYKEN (B2c). Departman kapasitesi ve talebi dort
## kategoriye bolunur, satis kategori bazinda temizlenir ve satilamayan
## kutle DEPODA BIRIKIR.
##
## Fark akim/stok farkidir ve tek satirda gorunur: yukaridaki kolda
## `satilamayan_I` o donemin artigidir ve donem bitince yok olur; burada
## `stok` gecmisin toplamidir ve sonraki donemin uretimini kisar.
func _mal_piyasasi(d: KrizDurumu, donem_yil: float, Y_pot: float,
		kap_I: float, kap_II: float, D_tuketim: float, D_yatirim: float) -> void:
	var kap := PackedFloat64Array()
	var talep := PackedFloat64Array()
	kap.resize(MalKatmani.MALLAR.size())
	talep.resize(MalKatmani.MALLAR.size())
	for i in range(MalKatmani.MALLAR.size()):
		var pay := float(MalKatmani.MALLAR[i]["pay0"])
		var dept := int(MalKatmani.MALLAR[i]["dept"])
		kap[i] = (kap_I if dept == 1 else kap_II) * pay
		talep[i] = (D_yatirim if dept == 1 else D_tuketim) * pay

	mal.adim(donem_yil, kap, talep)

	d.Y_I_yil = mal.uretim_dept(1)
	d.Y_II_yil = mal.uretim_dept(2)
	# Tani alanlari korunuyor ama anlamlari DEGISTI: artik akim degil STOK.
	d.satilamayan_I = mal.stok_dept(1)
	d.satilamayan_II = mal.stok_dept(2)
	# ASIRI URETIM artik NORMALIN USTUNDEKI YIGIN. Bir miktar stok saglikli
	# bir ekonominin normalidir; kriz olan sey fazlasidir.
	d.talep_acigi = mal.fazla_yigin(Y_pot)


# ===========================================================================
# I. KAMU MALIYESI, VERGI & KEMER SIKMA
# ===========================================================================

func _kamu_maliyesi(d: KrizDurumu, donem_yil: float, Y_pot: float) -> float:
	d.etg_vergi_sermaye_o = P.v44.etg_maliyet * d.etg * P.v44.etg_sermaye_payi
	d.etg_vergi_ucret_o = P.v44.etg_maliyet * d.etg * (1.0 - P.v44.etg_sermaye_payi)
	var v_ucret := _kur(d, "v_ucret", 0.05) + d.etg_vergi_ucret_o / maxf(d.pay, 0.05)
	var v_kar := _kur(d, "v_kar", 0.08) + d.etg_vergi_sermaye_o / maxf(1.0 - d.pay, 0.05)
	d.vergi_geliri_yil = (minf(0.85, v_ucret) * d.pay
			+ minf(0.90, v_kar) * (1.0 - d.pay)) * d.Y_yil

	var taban := maxf(d.Y_trend, Y_pot)
	# Karseral harcama butcenin bir kalemidir: sosyal yatirimlarin yerini
	# guvenlik harcamalarinin almasi.
	var G := taban * (float(P.v44.devlet_pay[clampi(d.era, 1, 6) - 1]) * _kur(d, "devlet", 1.0)
			+ P.v44.issizlik_sigortasi * maxf(0.0, (1.0 - d.e) - 0.05)
			+ P.v44.karseral_maliyet * d.cezaevi_orani
			+ P.v44.etg_maliyet * d.etg
			+ (P.v44.devlet_kriz if (d.delev > 0 or d.r_yil < P.v44.r_kamu_kriz) else 0.0))

	d.vergi_carpani += Oran.donem_akim(Oran.v44_akim(0.030), donem_yil) * (d.kamu_borc - 0.55)
	d.vergi_carpani = clampf(d.vergi_carpani, 0.70, 2.20)
	d.vergi_geliri_yil *= d.vergi_carpani

	if d.kamu_borc > P.v44.kamu_borc_limiti:
		d.kemer = KrizParam.sure_donem(Oran.yillik_sure(40, Oran.V44_TUR_YIL), donem_yil)
	if d.kemer > 0:
		G *= (1.0 - P.v44.kemer_siddeti)
		d.kemer -= 1

	var birincil := (G - d.vergi_geliri_yil) / maxf(d.Y_yil, 1e-6)

	# --- PARASALLASTIRMA: ACIGIN BIR KISMI BORCLANMAZ, BASILIR ---
	#
	# Motorda kamu acigi YALNIZCA borc oranina gidiyordu; fiyat duzeyine giden
	# hicbir kanal yoktu. Sonucu olculdu ve zinciri bastan asagi kilitliyordu:
	# enflasyon 198 yil ortalamasinda -%0.47 (hedef +%0.54), politika faizi
	# koşunun %82'sinde TABANINDA, borc servisi arti degerin en fazla %19'u,
	# Ponzi bolgesine hic girilmiyor. Kredi iki yuzyil bedavaya yakin olunca
	# ne kar sikismasi ne Minsky ateslenebiliyordu.
	#
	# TAKVIME BAGLANMADI, BORC ORANINA BAGLANDI. Devlet emisyona keyfinden
	# degil MECBUR KALDIGINDA basvurur: borc yuku agirlastikca borclanmak
	# pahalilasir ve enflasyon borcu eritmenin -- yani temerrudun -- alternatifi
	# haline gelir. Boylece kanal icseldir, bir tarih tablosuna degil motorun
	# kendi durumuna baglidir, ve kendi geri beslemesini kurar: acik -> borc ->
	# parasallastirma -> enflasyon -> Taylor faizi yukseltir -> borc servisi
	# artar. Finansal kanalin ihtiyaci olan sey tam olarak bu dongudur.
	var parasal_pay := P.parasallasma_tavani * minf(
			1.0, d.kamu_borc / maxf(P.v44.kamu_borc_limiti, 1e-6))
	# Yalnizca ACIK parasallastirilir; fazla veren butce para YARATMAZ.
	d.parasallasma = parasal_pay * maxf(0.0, birincil)
	var borclanan := birincil - d.parasallasma

	var carpan := clampf(1.0 + d.i_yil - maxf(d.y_buyume, P.kamu_buyume_taban_yil),
			0.97, 1.020)
	# Borc orani bir STOKtur ama carpani donem basinadir.
	var carpan_d := pow(carpan, donem_yil / Oran.V44_TUR_YIL)
	d.kamu_borc = clampf(d.kamu_borc * carpan_d + Oran.donem_akim(borclanan, donem_yil),
			0.0, P.v44.borc_orani_tavani)

	# Kamu iflasi: olasilik DONEM BASINADIR, yillik oranindan turetilir --
	# yoksa haftalik kosu 14 kat sik temerrut eder.
	var p_yil := Oran.v44_akim(0.02)
	if d.kamu_borc > P.v44.kamu_temerrut and rng.random() < p_yil * donem_yil:
		d.kamu_borc *= (1.0 - P.v44.mor_kesinti)
		d.vergi_carpani = minf(2.20, d.vergi_carpani + 0.15)
		d.temerrutler.append(d.q)
	return G


# ===========================================================================
# HASILA, KAPASITE, ISTIHDAM
# ===========================================================================

func _hasila_ve_istihdam(d: KrizDurumu, donem_yil: float, Y_pot: float, D_talep: float,
		Y_onceki: float) -> void:
	var Y := 0.0
	if d.rejim == "sosyalist":
		# Planli ekonomide hasila PLANA gore belirlenir, efektif talebe gore
		# degil. Gerceklesme krizi kapitalizme ozgudur; planli ekonominin
		# kendi kriz bicimi kitliktir.
		Y = Y_pot * P.v44.plan_kullanim
	else:
		# Hasila artik DEPARTMANLARIN TOPLAMIDIR. Her departman kendi
		# talebiyle sinirli; birinin fazlasi digerinin acigini kapatmaz.
		Y = maxf(d.Y_I_yil + d.Y_II_yil, Y_pot * P.v44.gecim_tabani)

	d.Y_yil = Y
	d.Y_zirve = maxf(d.Y_zirve, Y)
	# `y_buyume` YILLIK bir buyume oranidir. Ham fark donem basinadir; once
	# yilliga cevrilir, sonra yillik tanimli bir uyum katsayisiyla yumusatilir.
	# Ikisi de cevrilmezse olcu donem uzunluguyla birlikte kayar ve ona bakan
	# esikler (resesyon, kamu borcu, riza) haftalik kosuda hic, yillik kosuda
	# kolayca tetiklenir.
	# Yilliga cevirme DOGRUSALDIR (akim), bilesik degil. Bilesik bicim
	# `(1+x)^(1/donem)` disbukeydir: haftalik kosuda donem basina gurultuyu
	# asimetrik buyutur, ayni yorunge farkli olceklerde farkli ortalama verir.
	# Olculdu -- bilesik bicimle haftalik <-> aylik K %25 ayrisiyordu.
	var ham := (Y - Y_onceki) / maxf(Y_onceki, 1e-6)
	var buyume_yil := ham / maxf(donem_yil, 1e-9)
	var uy_y := Oran.donem_uyum(P.y_buyume_uyum_yil, donem_yil)
	d.y_buyume = (1.0 - uy_y) * d.y_buyume + uy_y * buyume_yil

	# Y_K de YILLIGA cevrilir; yoksa `u` 14 kat yanlis cikar.
	var Y_K := d.K / maxf(d.kv, 1e-9) / Oran.V44_TUR_YIL
	d.u = clampf(Y / maxf(Y_K, 1e-9), 0.20, 1.0)
	# SEFERBERLIK (B4, v4.4 `motor.py:1948`). Savas atil kapasiteyi calistirir.
	if d.savasta():
		d.u = minf(1.0, d.u + P.v44.sv_seferberlik)

	# Istihdam artik FIZIKSEL kapasitenin kullanimidir: robotlar kapasiteyi
	# buyuttukce ayni hasila daha az canli emek ister.
	var canli_emek := d.l_etkin() * d.hafta_saati
	var robot := P.v44.oto_verim * d.oto * d.K / maxf(d.q, 1e-6)
	var Y_L := d.q * (canli_emek + robot) / Oran.V44_TUR_YIL
	d.e = clampf(Y / maxf(Y_L, 1e-9), P.v44.e_taban, 1.0)

	# EMEK GERGINLIGI -- Goodwin salinimini tam istihdamda da yasatir.
	#
	# `e` tanimi geregi 1.0'da doyar. Emek baglayici kisit oldugunda (Y = Y_L)
	# istihdam orani sabitlenir, `bos_e = e - e_norm` sifira gider ve GOODWIN
	# TERIMI OLUR. Olculdu: istihdam 1836'dan sonra kalici olarak 1.000, ucret
	# pazarligi donuyor, kar sikismasi hic gelmiyor, konjonktur dalgasi
	# dogmuyor.
	#
	# Gercekte tam istihdam ucret baskisinin BITTIGI yer degil, en siddetli
	# oldugu yerdir: sermaye kapasitesi emek arzini astikca karsilanmamis emek
	# talebi birikir ve ucretleri yukari iter. Gerginlik bunu tasir ve 1.0'i
	# asabilir.
	var Y_K2 := d.K / maxf(d.kv, 1e-9) / Oran.V44_TUR_YIL
	d.emek_gerginlik = clampf(minf(Y_K2, D_talep) / maxf(Y_L, 1e-9), 0.2, 1.6)


func _etg(d: KrizDurumu, donem_yil: float) -> void:
	# ETG YALNIZCA KAPITALIST REJIMDE tanimlidir: planli ekonomide ucret zaten
	# planla belirlenir.
	if d.rejim != "kapitalist":
		d.etg_hedef = 0.0
		d.etg = 0.0
		d.etg_metasiz = 0.0
	else:
		d.etg += Oran.donem_uyum(P.etg_yerlesme_yil, donem_yil) * (
				maxf(0.0, d.etg_hedef) - d.etg)
		d.etg = clampf(d.etg, 0.0, 0.40)
		# Hangi okumanin baskin oldugu ORGUTLULUGE baglidir: org yuksek ->
		# metasizlasma (isci el koyar), dusuk -> subvansiyon (isveren el koyar).
		d.etg_metasiz = minf(1.0, d.org / P.v44.etg_org_ref)

	var hedef_kat := P.v44.kat_taban + (1.0 - P.v44.kat_taban) * minf(
			1.0, d.e / P.v44.kat_e_ref)
	d.katilim_etg = P.v44.etg_katilim * d.etg
	hedef_kat -= d.katilim_etg
	d.katilim += Oran.donem_uyum(P.kat_hiz_yil, donem_yil) * (hedef_kat - d.katilim)
	d.katilim = clampf(d.katilim, P.v44.kat_taban, 1.0)


# ===========================================================================
# TONAK DEGER GASBI + KAR ORANI
# ===========================================================================

func _arti_deger_ve_kar(d: KrizDurumu, donem_yil: float, _VT: float) -> void:
	# YENI DEGER yalnizca canli emekten gelir. Fiziksel hasila devasa olabilir;
	# deger buyuklugu bundan bagimsiz olarak buzulur.
	d.V_yil = d.Y_yil * d.canli_pay
	var s_ham := d.V_yil * (1.0 - d.pay) * (1.0 - d.kamu_pay * (1.0 - P.v44.kamu_r_farki))
	d.lumpen_pay = minf(P.v44.lumpen_tavan, P.v44.lumpen_carpani * d.uyusturucu_orani)
	# Illegal sektor payinin OTESINDE deger ceker (illegalite primi).
	d.gasp = s_ham * d.lumpen_pay * P.v44.illegalite_primi
	# ETG'nin sermayeden finansmani NET karliligi dusurur: birikimi
	# yavaslatarak LTRPF'yi hizlandirir ve kendi vergi tabanini asindirir.
	s_ham *= maxf(0.15, 1.0 - P.v44.etg_vergi_sermaye * d.etg_vergi_sermaye_o)
	d.s_yil = s_ham * (1.0 - d.lumpen_pay)
	# Gasbedilen deger uretken sermayeye DEGIL asalak/spekulatif stoka akar.
	d.varlik += Oran.donem_akim(P.gasp_varlik_yil * d.gasp, donem_yil)
	d.r_yil = d.s_yil / maxf(d.K, 1e-6)


# ===========================================================================
# J. SPEKULATIF BALON (finansallasma + Minsky) + K. PATLAMA
# ===========================================================================

func _minsky(d: KrizDurumu, donem_yil: float) -> void:
	var v_onc := d.varlik / maxf(d.Y_yil, 1e-6)

	if d.rejim == "kapitalist" and d.delev == 0:
		# (i) Kar sikismasi kanali: uretken alan spekulatif getiriyi yenemedigi
		#     olcude arti deger finansa kayar. Kayan sey yalnizca AKIM degil
		#     atil duran SERMAYE STOKUDUR -- karlilik dustukce finansallasmanin
		#     ARTMASI beklenir.
		# "URETIME DONMEMEK ICIN SEBEP" iki kaynaktan gelir; finansa kayis
		# ikisinin de sonucudur, o yuzden ayri bir akim degil AYNI sinyalin
		# iki bileseni olarak kurulur (doygunluk ve sonum aynen gecerli kalir).
		#
		# (a) KAR SIKISMASI: uretken getiri spekulatif getiriyi yenemiyor.
		var makas_kar := maxf(0.0, (d.i_spec_yil - d.r_yil) / maxf(d.i_spec_yil, 1e-6))
		# (b) GERCEKLESME ENGELI: mal satilamiyor. Kar orani faizin USTUNDE
		#     olsa bile satilamayan urun yiginlari varken uretimi genisletmenin
		#     anlami yoktur -- sermaye o zaman uretime degil PARA SERMAYEYE
		#     doner. Marx buna "sermaye bollugu" der (Kapital III, bol. 15 §3
		#     ve 30-32): degerlenemeyen sermaye yok olmaz, para piyasasina akar.
		#
		# Bu kanal v2'de HIC YOKTU. `talep_acigi` yalnizca kriz tesciline
		# gidiyordu; finansallasmanin tek surukleyicisi (a) idi ve o da koşunun
		# 198 yilinin 178'inde NEGATIFTI. Olculdu: varlik/Y butun kosu boyunca
		# 0.000, yani balon hic sismiyor ve Minsky hic atesle(n)miyordu.
		# Uretim kapasitesinin tuketim kapasitesini asmasi, asiri
		# finansallasmanin sebebidir; zincir artik motorda kurulu.
		var makas_gerc := minf(1.0, d.talep_acigi / maxf(P.fin_tikanma_ref, 1e-6))
		var makas := minf(1.0, maxf(makas_kar, makas_gerc))
		var kayan := P.fin_pay_yil * maxf(d.s_yil, 0.0) * makas
		kayan += P.fin_stok_yil * d.K * makas
		# (ii) Kaldiracli spekulasyon: balon kendi beklentisini besler.
		kayan += P.spec_kredi_yil * d.varlik * maxf(0.0, d.varlik_beklenti)
		# (iii) Doygunluk: mutlak sinira yaklastikca akim soner.
		kayan *= maxf(0.0, 1.0 - v_onc / P.v44.balon_limiti)
		d.varlik += Oran.donem_akim(kayan, donem_yil)
	d.varlik *= (1.0 - Oran.donem_akim(P.balon_sonum_yil, donem_yil))

	# Varlik FIYATI (varlik/Y) uzerinden ekstrapolatif beklenti. Ham stok
	# yerine ORANI kullanmak gerekir: hasila buyurken sabit bir stok reel
	# olarak deger kaybediyor demektir.
	var v_yeni := d.varlik / maxf(d.Y_yil, 1e-6)
	var getiri := (v_yeni / v_onc - 1.0) if v_onc > 1e-9 else 0.0
	# Beklenti bir ORAN DEGISIMIDIR, yani donem uzunluguna baglidir: haftalik
	# olcumde ayni yillik egilim 14 kat kucuk gorunur. Yilliga cevriliyor.
	var getiri_yil := getiri / maxf(donem_yil, 1e-9)
	var uy := Oran.donem_uyum(P.beklenti_hiz_yil, donem_yil)
	d.varlik_beklenti = minf(P.v44.beklenti_tavan,
			(1.0 - uy) * d.varlik_beklenti + uy * getiri_yil)

	# --- K. Fisher & Clarke borc/balon patlamasi ---
	if v_yeni > P.v44.minsky_esik and d.varlik_beklenti < d.i_spec_yil:
		d.minsky_sayac += 1
	else:
		d.minsky_sayac = maxi(0, d.minsky_sayac - 1)

	var esik := KrizParam.sure_donem(
			Oran.yillik_sure(P.v44.minsky_sure, Oran.V44_TUR_YIL), donem_yil)
	if d.minsky_sayac >= esik and d.delev == 0:
		d.delev = KrizParam.sure_donem(P.delev_sure_yil, donem_yil)
		d.minsky_sayac = 0
		d.varlik *= (1.0 - P.v44.deflasyon)
		d.deger_carpani = maxf(P.v44.dev_taban, d.deger_carpani * (1.0 - P.v44.dev_cokme))


# ===========================================================================
# M. BIRIKIM
# ===========================================================================

func _birikim(d: KrizDurumu, donem_yil: float, VT_net_yil: float) -> void:
	var kamu_hedef := clampf(_kur(d, "kamu_hedef", 0.05), 0.0, 0.95)
	d.kamu_pay += Oran.donem_uyum(P.kamu_uyum_yil, donem_yil) * (kamu_hedef - d.kamu_pay)
	d.kamu_pay = clampf(d.kamu_pay, 0.0, 0.85)

	var r_ef := (d.s_yil + VT_net_yil) / maxf(d.K, 1e-6)
	if d.rejim == "kapitalist":
		# Kar orani faizin altina dustukce birikim durur: LTRPF'nin yatirima
		# aktarildigi yer burasidir.
		# Hizlandirici KURUMSALDIR: yuksek deger = kisa yatirim ufku, finans
		# gudumlu cevrimsel yatirim -> daha buyuk K salinimi -> daha hizli
		# mekanizasyon -> daha buyuk yedek sanayi ordusu.
		var hz := Oran.v44_akim(_kur(d, "hizlandirici", P.v44.hizlandirici))
		var g_ozel := (P.g_taban_yil + P.v44.g_duy * (r_ef - d.i_yil)
				+ hz * (d.u - P.v44.u_normal))
		if d.delev > 0:
			g_ozel -= Oran.v44_akim(0.0025)
		var g_kamu := Oran.v44_akim(0.004) - P.v44.kamu_istikrar * minf(0.0, r_ef - d.i_yil)
		d.g_yil = (1.0 - d.kamu_pay) * g_ozel + d.kamu_pay * g_kamu
	else:
		d.g_yil = P.v44.plan_g / Oran.V44_TUR_YIL + P.v44.plan_u_duy * (d.u - P.v44.u_normal)

	d.g_yil = clampf(d.g_yil, -P.g_daralma_tavani_yil, P.g_tavani_yil)
	# DONEM UZUNLUGU YALNIZCA BURADA.
	var K_yeni := maxf(1.0, d.K * (1.0 + Oran.donem_buyume(d.g_yil, donem_yil)))

	if mikro == null:
		d.K = K_yeni
		return

	# MIKRO KATMAN: birikim HIZI burada kalir (§2.4 -- kar orani piyasadan
	# okunmaz), birikimin NEREYE gittigi asagi iner. Toplam degismez:
	# `_yukselt` odedigi bedeli binanin sermayesine yazar, `_yeni_kapasite`
	# kalanini dagitir, dolayisiyla `sum(bina.K)` tam olarak `K_yeni` olur.
	# Bu bir kalibrasyon degil OZDESLIKTIR ve `--v2-uretim` onu 1e-12 ile
	# olcer -- kirilirsa iki katman sermaye stoku konusunda anlasmazliga
	# duser ve hangisinin hakli oldugu hicbir yerde yazmaz.
	var yatirim := K_yeni - d.K
	if yatirim > 0.0:
		mikro.adim(d, donem_yil, yatirim)
	else:
		# Sermaye ERIYOR (g < 0). Kucultme binalara orantili yazilir; hangi
		# binanin kapanacagi B2c'nin (mal piyasasi) isidir -- orada
		# satilamayan mal yigini kapanmayi SECER, burada henuz secemeyiz.
		mikro.gecis_yikimi(1.0 - K_yeni / maxf(d.K, 1e-9))
	d.K = mikro.K_toplam()


# ===========================================================================
# P. PHILLIPS EGRISI & ENFLASYON
# ===========================================================================

func _phillips(d: KrizDurumu, donem_yil: float) -> void:
	var birim_emek := clampf(d.w_nom_buyume_yil - P.qg_yil, -0.15, 0.25)
	var bosluk := d.u - P.v44.u_normal
	var talep_etkisi := (P.v44.ph_talep * bosluk if bosluk > 0.0
			else P.v44.ph_talep * P.v44.ph_asimetri * maxf(bosluk, -0.30))
	# Parasallastirilan acik dogrudan fiyat duzeyine biner: karsiliginda mal
	# uretilmeyen bir satinalma gucu yaratilmistir.
	var pi := (P.v44.ph_beklenti * d.pi_bek + talep_etkisi
			+ P.v44.ph_maliyet * maxf(birim_emek, -0.04)
			+ P.ph_parasal * d.parasallasma)
	if d.delev > 0:
		pi -= P.v44.delev_deflasyon

	# Fiyat kontrolleri
	if d.kontrol == 0 and pi > P.v44.kont_esigi and d.rejim == "kapitalist":
		d.kontrol = KrizParam.sure_donem(P.kont_sure_yil, donem_yil)
	if d.kontrol > 0:
		var bastirilan := pi * P.v44.kont_etki
		d.bastirilmis_pi += bastirilan
		pi -= bastirilan
		d.kontrol -= 1
		if d.kontrol == 0:
			# Bastirilmis enflasyon puskurur.
			pi += d.bastirilmis_pi * P.v44.kont_patlama
			d.bastirilmis_pi = 0.0

	d.pi_inf = clampf(pi, P.v44.pi_min, P.v44.pi_max)
	var uy := Oran.donem_uyum(Oran.v44_uyum(0.20), donem_yil)
	d.pi_bek += uy * (0.70 * d.pi_inf + 0.30 * P.v44.pi_hedef - d.pi_bek)
	d.p_duzey *= (1.0 + Oran.donem_buyume(d.pi_inf, donem_yil))

	if d.pi_inf > P.v44.stagf_pi_esigi and (1.0 - d.e) > 0.10:
		d.stagflasyon += 1
	else:
		d.stagflasyon = maxi(0, d.stagflasyon - 1)


# ===========================================================================
# Q. GOODWIN SINIFSAL UCRET PAZARLIGI
# ===========================================================================

func _goodwin(d: KrizDurumu, donem_yil: float) -> void:
	var iss := 1.0 - d.e
	d.e_norm += Oran.donem_uyum(P.e_norm_hiz_yil, donem_yil) * (
			d.emek_gerginlik - d.e_norm)

	if d.rejim == "kapitalist":
		# BOLUNME (B3, §4.1): sendikanin PAZARLIK gucunu kirar.
		#
		# Orgutlenme stoku (`d.org`) degismez -- bolunmus bir sinif orgutludur
		# ama BIRLIKTE PAZARLIK EDEMEZ. Goodwin blogunun uc yerinde `org`
		# gecer (beklenti telafisi, uretkenlik aktarimi, istihdam primi) ve
		# ucu de pazarlik gucudur, dolayisiyla ucu de bu buyuklugu okur.
		#
		# Sermaye icin sonuc §4.1'in vaadidir: ucret payi baskilanir, kar
		# orani KORUNUR. Bedeli baska defterden cikar (§4.3).
		var org_p := KaranlikDevlet.pazarlik_gucu(P, d, _direnc(d), _kanal_pazarlik())
		var telafi := P.v44.w_beklenti * (1.0 + P.v44.w_org * org_p)
		# Goodwin terimi SABIT bir hedefe degil ulkenin kendi HAREKETLI
		# istihdam normuna gore calisir.
		# Ucret pazarligi ISTIHDAM ORANINA degil EMEK GERGINLIGINE bakar:
		# tavanda doyan bir olcuyle pazarlik yapilamaz.
		var bos_e := d.emek_gerginlik - d.e_norm
		# METASIZLASMA: garantili gelir rezervasyon ucretini yukseltir; isci
		# ucret indirimini reddedebilir hale gelir, asagi yonlu katilik ARTAR.
		var kat := P.v44.w_katilik + (1.0 - P.v44.w_katilik) * minf(
				1.0, iss / P.v44.katilik_cozulme)
		kat = minf(1.0, kat + P.v44.etg_katilik * d.etg * d.etg_metasiz)
		var goodwin := P.v44.phi * bos_e if bos_e > 0.0 else P.v44.phi * kat * bos_e
		# Emegin uretkenlik artisindan pay alma zemini kurumsaldir; orgutluluk
		# onun uzerine biner. Duzenli rejimde 0.85, neoliberalde 0.40.
		var taban_pay := _kur(d, "emek_pay", 0.5)
		var aktarim := taban_pay + (1.0 - taban_pay) * org_p
		d.w_nom_buyume_yil = (telafi * d.pi_bek + goodwin
				+ P.v44.w_org_e * org_p * (d.e - P.v44.e0) + aktarim * P.qg_yil)
		if d.kontrol > 0:
			d.w_nom_buyume_yil *= (1.0 - P.v44.kont_etki)
		if pazarlik_sabit:
			d.w_nom_buyume_yil = d.pi_inf

		# NUFUS KATMANI TAKILIYSA `pay` BURADA YAZILMAZ. Pazarlik ORANI
		# (`w_nom_buyume_yil`) yukarida hesaplandi ve otoritesi burada kaldi;
		# onu bir ucret DUZEYINE uygulamak ve `pay`i kohort bilesiminden
		# turetmek nufus katmaninin isi (§8.2, otorite tablosu).
		son_d_pay = clampf(d.w_nom_buyume_yil - d.pi_inf - P.qg_yil,
				-P.v44.pay_degisim_tavani, P.v44.pay_degisim_tavani)
		if nufus == null:
			d.pay *= (1.0 + Oran.donem_akim(son_d_pay, donem_yil))
	elif nufus == null:
		var hedef := P.v44.sos_pay_taban
		d.pay += Oran.donem_akim(P.v44.sos_pay_hiz, donem_yil) * (hedef - d.pay)

	if nufus == null:
		pay_sinirla(d)


## UCRET PAYININ TABANI VE TAVANI.
##
## Ayri bir fonksiyon cunku IKI YERDEN cagrilir: `pay` cekirdekte
## pazarlaniyorsa `_goodwin`in sonundan, nufus katmani turetiyorsa `adim`dan.
## Tek bir yerde tanimli olmasi zorunlu -- iki kopya olsaydi biri gunceLLenip
## digeri kalir ve iki kol sessizce ayri sinirlarla kosardi.
##
## Illegal sektorun super-somurusu TABANI dusurur (SEVIYE etkisi; bir buyume
## orani drenaji DEGIL -- oyle kurulunca yuz yilda bilesiklenip payi sifira
## suruyordu).
func pay_sinirla(d: KrizDurumu) -> void:
	var etg_taban := P.v44.etg_taban_dus * d.etg * (1.0 - d.etg_metasiz)
	# TABAN PAZARLIK GUCUYLE HAREKET EDER, ORGUTLENME STOKUYLA DEGIL.
	#
	# B2b'nin acik birakip B3'e devrettigi borc buydu: "ucret payinin tabani
	# `org` ile birlikte hareket edecek". Ucret tabanini kuran sey sendikanin
	# VARLIGI degil, birlikte pazarlik EDEBILMESIDIR -- bolunmus bir sinifin
	# sendikasi vardir ama tabani tutamaz.
	var pay_taban := maxf(0.10, P.v44.pay_taban0
			+ P.v44.pay_taban_org * KaranlikDevlet.pazarlik_gucu(
				P, d, _direnc(d), _kanal_pazarlik())
			- P.v44.gasp_taban * d.lumpen_pay - etg_taban)
	if d.parti_iktidari:
		pay_taban = minf(pay_taban, P.v44.parti_pay_taban)
	d.pay = clampf(d.pay, pay_taban, P.v44.pay_tavani)


# ===========================================================================
# R. IKI KADEMELI KRIZ TESCILI
# ===========================================================================

func _kriz_tescili(d: KrizDurumu, donem_yil: float) -> void:
	var uy := Oran.donem_uyum(Oran.v44_uyum(0.10), donem_yil)
	d.Y_ort = (1.0 - uy) * d.Y_ort + uy * d.Y_yil if d.Y_ort > 0.0 else d.Y_yil
	d.Y_trend = maxf(d.Y_trend * pow(P.trend_asinma_yil, donem_yil), d.Y_ort)
	var derinlik := 1.0 - d.Y_ort / maxf(d.Y_trend, 1e-9)

	# --- Asiri uretim: emilemeyen talep acigi. Planli ekonomide YOK. ---
	d.au_bekle = maxi(0, d.au_bekle - 1)
	if d.rejim == "kapitalist" and d.talep_acigi > P.v44.au_esik:
		d.au_ici += 1
		if d.au_ici >= KrizParam.sure_donem(P.au_sure_yil, donem_yil) and d.au_bekle == 0:
			d.asiri_uretim_krizleri.append([d.yil, d.talep_acigi])
			d.au_bekle = KrizParam.sure_donem(P.au_bekleme_yil, donem_yil)
			d.Omega = minf(1.0, d.Omega + P.v44.au_omega)
	else:
		d.au_ici = 0

	# --- Resesyon: art arda daralan hasila ---
	d.res_bekle = maxi(0, d.res_bekle - 1)
	if d.y_buyume < P.res_daralma_yil:
		d.res_ici += 1
		if d.res_ici >= KrizParam.sure_donem(P.res_sure_yil, donem_yil) and d.res_bekle == 0:
			d.resesyonlar.append([d.yil, d.y_buyume])
			d.res_bekle = KrizParam.sure_donem(P.res_bekleme_yil, donem_yil)
	else:
		d.res_ici = 0

	# --- Buyuk bunalim: kitlesel iflas ve defterden silme ---
	if derinlik > P.v44.bun_esik:
		d.bun_ici += 1
		if d.bun_ici == KrizParam.sure_donem(P.bun_sure_yil, donem_yil):
			d.deger_carpani = maxf(P.v44.dev_taban, d.deger_carpani * (1.0 - P.v44.dev_bunalim))
			d.bunalimlar.append([d.yil, derinlik])
	else:
		d.bun_ici = 0


# ===========================================================================
# S. SINIF ORGUTLENME STOKU & KENTLESME
# ===========================================================================

func _orgutlenme(d: KrizDurumu, donem_yil: float) -> void:
	var iss := 1.0 - d.e
	# SAVAS da bir kriz halidir (v4.4 `motor.py:2426`): orgutlenmeyi besleyen
	# "kriz deneyimi" sayacini o da doldurur.
	var krizde := ((d.r_yil < P.v44.r_kriz_esigi) or (iss > 0.13)
			or d.delev > 0 or d.savasta())
	d.kriz = (d.kriz + 1) if krizde else maxi(0, d.kriz - 2)
	var kriz_n := minf(float(d.kriz) * donem_yil / (25.0 * Oran.V44_TUR_YIL), 1.2)

	if d.rejim == "kapitalist":
		var aktif := Formulas.sg(P.v44.kappa * (P.v44.b_pay * (1.0 - d.pay)
				+ P.v44.b_iss * iss - P.v44.theta))
		var baski := d.baski_egilimi * minf(d.PC, 1.0) * (
				1.0 if (aktif > P.v44.tepki_esigi or kriz_n > P.v44.tepki_esigi) else 0.0)
		var eroz := (P.org_erozyon_yil * _kur(d, "org_eroz", 1.0)
				* P.v44.org_era_era_erozyon * float(d.era - 2) if d.era >= 3 else 0.0)
		var buyume := (P.org_kent_yil * d.kent + P.org_kriz_yil * kriz_n
				+ P.egitim_org_yil * d.egitim)
		# BOLUNME (B3, §4.1): ofkenin sinifsal orgutlenmeye DONUSUMUNU kirar.
		# `kriz_n` bu donusumun motordaki tasiyicisidir -- kriz deneyimi
		# orgutlenmeye cevrilir. Bolunmus bir sinifta ayni kriz ortak bir
		# cikar degil, birbirine dusman topluluklar uretir.
		#
		# KIRILAN BUYUMEDIR, STOK DEGIL. `org`un kendisinden dusulseydi
		# protesto ve parti kanallari da birlikte kapanirdi; §4.1 tam olarak
		# bunun TERSINI soyluyor -- orgutlenme yerinde kalir, ofkeyle
		# arasindaki BAG kirilir.
		buyume *= KaranlikDevlet.org_kirilma(P, d, _direnc(d), _kanal_org())
		var azalma := P.org_baski_yil * baski + eroz
		# SENDIKAL HAREKETE BASKI (§4.2): grev kirma ve sendika kapatma
		# orgutlenmeyi DOGRUDAN asindirir -- bolunmeden bagimsiz, ikinci bir
		# kanal. Bolunme bagi kirar, bu kol dokuyu keser.
		azalma += P.org_baski_yil * P.sendika_baski_egilim * d.t_sendika_baskisi
		var dorg := buyume * (1.0 - d.org) - azalma * d.org
		# Cozulme POLITIKA degiskenine degil FIILI lumpenlesmeye baglidir:
		# yayilmis bir uyusturucu ekonomisi sendikal dokuyu cozer.
		dorg -= P.lumpen_org_yil * d.lumpen_pay * d.org
		# SIYASI CINAYET -- KISA VADE (§4.3). Sehit stogu buyurken orgutlenme
		# kirilir; ayni stok orta vadede `Omega`yi YUKSELTIR (T blogu). Iki
		# etki ayni anda olmaz, gecikmeyi stok tasir.
		dorg -= P.sehit_org_yil * d.sehit * d.org
		d.org = clampf(d.org + Oran.donem_akim(dorg, donem_yil), 0.0, 0.98)
	else:
		d.org = minf(0.98, d.org + Oran.donem_akim(
				Oran.v44_akim(0.001) * (0.98 - d.org), donem_yil))


# ===========================================================================
# T. PROTESTO RISKI, POLITIK OZNE VE DEVRIM
# ===========================================================================

func _protesto_ve_devrim(d: KrizDurumu, donem_yil: float, dis: Dictionary) -> void:
	var iss := 1.0 - d.e
	var kriz_n := minf(float(d.kriz) * donem_yil / (25.0 * Oran.V44_TUR_YIL), 1.2)

	var arg := 0.0
	if d.rejim == "kapitalist":
		arg = P.v44.b_pay * (1.0 - d.pay) + P.v44.b_iss * iss - P.v44.theta
	else:
		arg = P.v44.b_pay * P.v44.sos_kitlik_agirlik * 0.5 + P.v44.b_iss * iss - P.v44.theta

	# --- MARKSIST POLITIK OZNE ---
	# Zemin: issizler kitlesi + yoksullasma + kriz deneyimi.
	# Yikici: baski aygiti ve lumpenlesme.
	var zemin := (P.v44.parti_iss * iss
			+ P.v44.parti_yoksullasma * maxf(0.0, 1.0 - d.pay / P.v44.parti_pay_ref)
			+ P.v44.parti_kriz * kriz_n)
	var yikim := P.v44.parti_baski * d.baski_egilimi + P.v44.parti_lumpen * d.lumpen_pay
	var hedef := clampf(zemin - yikim, 0.0, P.v44.parti_tavan)
	d.parti += Oran.donem_uyum(P.parti_hiz_yil, donem_yil) * (hedef - d.parti)
	d.parti = clampf(d.parti, 0.0, P.v44.parti_tavan)
	# Parti, sendikanin ulasamadigi kitleyi kapsar.
	d.orgutlu = d.org + d.parti * (1.0 - d.org)

	# Bolme/yozlastirma politikalarina DIRENC: bilinclendirme sonumlemeyi kirar.
	var direnc := _direnc(d)
	var lumpen_sonum := 1.0 - minf(0.85, P.v44.lumpen_sonum_gucu * d.lumpen_pay * direnc)
	# Karseral disiplin: hapsetme, disipline edilemeyen nufusu fiziksel olarak
	# izole ederek protesto riskini DOGRUDAN bastirir.
	var karseral_sonum := 1.0 - minf(0.40, P.v44.karseral_disiplin * minf(
			2.0, d.cezaevi_orani / P.v44.cezaevi_ref) * direnc)
	# BOLUNME (B3, §4.1): protestoyu SINIFSAL olmaktan cikarir; ofke topluluklar
	# arasi siddete akar. Motordaki imza tam olarak budur -- `Omega` yerinde
	# durur, `PR` soner. Yani bolunme devrimi ONLEMEZ, ERTELER; ve ertelendigi
	# surece ofke birikmeye devam eder.
	var bolunme_sonum := KaranlikDevlet.protesto_sonum(P, d, direnc, _kanal_protesto())
	# SINIFSAL BASINC -- bolunme UYGULANMADAN once. Lumpen ve karseral
	# sonumler burada zaten var, cunku onlar gercekten YATISTIRIR (uyusturulmus
	# ya da hapsedilmis nufus ofkesini de kaybeder). Bolunme BASKA bir seydir.
	var pr_taban := Formulas.sg(P.v44.kappa * arg) * lumpen_sonum * karseral_sonum
	d.sinif_basinci = pr_taban
	d.PR = pr_taban * bolunme_sonum
	# TOPLULUKLAR ARASI SIDDET (B3, §4.1). Bolunmenin sinifsal kanaldan
	# CEKTIGI enerji YOK OLMAZ -- hedef degistirir. Siniftan komsuya: ic etnik
	# gruplara, multecilere, kadinlara, LGBT'ye. §4.6 geregi bu bir gizli
	# carpan degil GORUNUR bir metriktir; bedeli kimin odedigi sayilabilsin.
	d.topluluk_siddeti = pr_taban - d.PR

	var esik := maxf(P.v44.pr_esik_min, P.v44.pr_esik - P.v44.pr_esik_omega * d.Omega)
	d.pr_sayac = (d.pr_sayac + 1) if d.PR >= esik else 0

	if d.rejim == "kapitalist":
		var aktif := 1.0 if (d.PR > P.v44.tepki_esigi or kriz_n > P.v44.tepki_esigi) else 0.0
		var baski := d.baski_egilimi * minf(d.PC, 1.0) * aktif
		var reform := (1.0 - d.baski_egilimi) * minf(d.PC, 1.0) * aktif
		# PASIFIZASYON: ETG, karliliga bagli refah yatistirmasindan BAGIMSIZ
		# bir yatistirma kanalidir -- kar sikismasi altinda bile calisir.
		var refah := P.som_refah_yil * minf(1.0, maxf(0.0, d.r_yil - P.v44.r_referans)
				/ P.v44.r_refah_olcek)
		refah += Oran.v44_akim(P.v44.etg_omega) * d.etg

		# ASIRI URETIM: fiziksel hasila ile satinalma gucu arasindaki makas.
		# canli_pay dustukce Y buyur ama V kuculur; arada kalan satilamayan
		# urun kitlesi SINIF GERILIMI uretir.
		var makas := maxf(0.0, (1.0 - d.canli_pay) - P.v44.asiri_esik)
		var asiri := P.asiri_uretim_yil * makas * (0.4 + 1.6 * d.orgutlu)

		# SIYASI CINAYET -- ORTA VADE (§4.3). Sehitler radikallestirir: ayni
		# stok S blogunda orgutlenmeyi kirarken burada OFKEYI yukseltir.
		# Zor aygitinin en pahali ozelligi budur -- bastirdigi seyi besler,
		# ve baskidan sag cikan orgutlenme daha radikal doner cunku `org`
		# yeniden buyudugunde `Omega` hala yuksektir.
		var sehit_ofke := P.sehit_omega_yil * d.sehit
		# OFKE `pr_taban`DAN BESLENIR, `d.PR`DEN DEGIL -- ve ayrim §4.1'in
		# TAMAMIDIR.
		#
		# OLCULDU VE YAPISAL CIKTI. Ilk yazimda `d.PR` okunuyordu ve sonuc
		# §4.1'in tam TERSIYDI: tam kapasite karanlik devlet altinda `Omega`
		# 0.238'den 0.0017'ye COKUYORDU. Sebep motorun kendi yapisi -- ofke
		# protesto uzerinden birikiyor, dolayisiyla protestoyu sonumlemek
		# ofkeyi de yok ediyordu. Yani mekanizma bir "bolme" kolu degil bir
		# YATISTIRMA kolu olarak calisiyordu.
		#
		# Dogrusu: bolunme ofkeyi azaltmaz, sinifsal ifadesini kirar. Ofkeyi
		# ureten basinc yerinde durur (`pr_taban`), yalnizca aldigi BICIM
		# degisir -- sinifsal protesto yerine topluluklar arasi siddet.
		var dO := (P.org_omega_yil * (P.a1_yil * pr_taban + P.a2_yil * kriz_n)
					* (0.4 + 1.6 * d.orgutlu)
				+ asiri + sehit_ofke
				- P.a4_yil * baski - P.a5_yil * reform - P.omega_sonum_yil - refah)
		d.Omega = clampf(d.Omega + Oran.donem_akim(dO, donem_yil), 0.0, 1.0)

		var blok := float(dis.get("blok", 0.0))
		if blok != 0.0:
			d.Omega = minf(1.0, d.Omega + Oran.donem_akim(P.v44.yayilma * blok, donem_yil))
		d.IR = minf(1.0, d.IR + Oran.donem_akim(Oran.v44_akim(0.003) * baski, donem_yil))

		# Riza PERFORMANSIN sonucudur: refah (buyume, istihdam, ucret payi) ve
		# istikrar (dusuk huzursuzluk) bilesenlerinden.
		var pc_refah := (0.40 * minf(1.0, maxf(0.0, d.y_buyume / P.pc_buyume_ref_yil))
				+ 0.35 * minf(1.0, maxf(0.0, d.e / P.v44.e0))
				+ 0.25 * minf(1.0, maxf(0.0, d.pay / P.v44.pc_pay_ref)))
		var istikrar := 1.0 - minf(1.0, d.Omega)
		var hedef_pc := clampf(P.v44.pc_taban + P.v44.pc_refah * pc_refah
				+ P.v44.pc_istikrar * istikrar, 0.0, 1.0)
		d.PC += Oran.donem_uyum(P.pc_hiz_yil, donem_yil) * (hedef_pc - d.PC)
		d.PC = clampf(d.PC - Oran.donem_akim(Oran.v44_akim(0.06) * (baski + reform)
				+ Oran.v44_akim(P.v44.karseral_mesruiyet) * minf(
					2.0, d.cezaevi_orani / P.v44.cezaevi_ref), donem_yil), 0.0, 1.0)

		# --- DEVRIM ---
		if (P.v44.devrim_acik
				and d.pr_sayac >= KrizParam.sure_donem(P.pr_sure_yil, donem_yil)
				and d.Omega >= P.v44.omega_kritik):
			d.rejim = "sosyalist"
			# `devrim_yil` tanimliydi ama HIC YAZILMIYORDU. Devrimin ne zaman
			# oldugunu bilmeden kriz takvimi okunamaz: devrimden sonra asiri
			# uretim tescili KAPANIR (`rejim == "kapitalist"` kosulu), yani
			# "kriz uretmiyor" ile "artik kapitalist degil" ayirt edilemez.
			d.devrim_yil = d.yil
			d.parti_iktidari = true
			d.Omega *= 0.35
			d.pr_sayac = 0
