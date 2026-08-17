class_name KaranlikDevlet
extends RefCounted

## v2'nin KARANLIK DEVLET KATMANI -- B3.
##
## Tasarim belgesi §4. Ic sinifsal ofke buyudugunde bir toplumsal patlamaya
## donusmesini engellemek icin emekci siniflari YOZLASTIRAN ve BOLEN, yetmezse
## otoriter uygulamalara giden, legal ya da illegal RIZA ve ZOR aygitlarini
## kullanan bir politikadir. Gramsci'nin ayrimi dogrudan iki kola donusur.
##
## Merkezinde §4.1'in yeni durum degiskeni durur:
##
##   > Amac ofkeyi azaltmak degil; ofkenin SINIFSAL ORGUTLENMEYE donusmesini
##   > kirmaktir. Ofke yerinde kalir, hedefi degisir -- siniftan komsuya.
##
## Bu ayrim mekanik olarak sudur: `Omega` (ofke) ile `org` (orgutlenme)
## motorda AYRI degiskenlerdir ve devrim IKISINI BIRDEN ister (T blogu).
## `bolunme` aralarindaki donusumu kirar, dolayisiyla ofkeyi hic azaltmadan
## devrim riskini dusurur. Sermaye icin sonuc nettir: ucret payi baskilanir,
## kar orani korunur, devrim riski duser. Bedeli baska yerden cikar (§4.3).
##
## ------------------------------------------------------------------------
## TEK BIR "KARANLIK DEVLET KADRANI" YOKTUR
## ------------------------------------------------------------------------
## §4.6'nin temsil ilkesi: "bunlar oyunda NE ISELER O OLARAK gorunur --
## magdurlari adlandirilmis, bedelleri sayilmis politikalar; 'etkinlik' kolu
## gibi sunulmaz." Sekiz taktik tek bir olcege indirgenseydi hepsi ayni
## sekilde davranir ve "bedeli kim oduyor" sorusu motorda TANIMSIZ kalirdi.
##
## Her taktigin kendi kanali vardir ve imzalari birbirinden ayirt edilebilir:
##
##  TAKTIK               AYGIT  BOLUNME  KENDI KANALI (bedeli kim oder)
##  uyusturucu           riza    orta    mafya_tolerans -> uo -> lumpen ->
##                                       gasp -> SPEKULATIF STOK (Minsky'yi besler)
##  cemaat/tarikat       riza    orta    egitim tabani asinir
##  mistisizm            riza    dusuk   EGITIM/BILIM en agir asinma -> qg duser
##  milliyetcilik        riza    EN YUK. topluluklar arasi siddet -> PR sonumu
##  cinsiyet baskisi     riza    yuksek  KATILIM duser -> canli emek -> V duser
##  sendika baskisi      zor     dusuk   `org` dogrudan kirilir (baski_egilimi)
##  tutuklama            zor     dusuk   cezaevi_orani -> l_etkin, PC, egitim
##  paramiliter/cinayet  zor     yuksek  SEHIT stogu -> org kisa, Omega orta
##
## Milliyetcilik en yuksek bolunme itkisini tasir cunku §4.1'in tarif ettigi
## sey tam olarak odur: ofkenin hedefini siniftan KOMSUYA cevirmek. Otekiler
## zemini hazirlar, milliyetcilik hedefi degistirir.
##
## ------------------------------------------------------------------------
## NE TASINDI, NE EKLENDI
## ------------------------------------------------------------------------
## v4.4'un karanlik devlet blogu (`motor.py:1998-2049`) DAR degil TAMDI --
## v2'nin ilk yaziminda yalnizca CIKTILARI (`uyusturucu_orani`,
## `cezaevi_orani`) tasinmis, onlari SUREN denklemler tasinmamisti. Iki alan
## cekirdekte okunuyor ama hicbir sey tarafindan yazilmiyordu: lumpen kanali,
## karseral sonum ve mesruiyet asinmasi 0.0'da OLU duruyordu.
##
##   TASINAN (v4.4'un kendi denklemleri, birim cevrimiyle):
##     endojen mafya toleransi   -- birikim tikanmasi x ofke x mesruiyet
##     uyusturucu yayilimi       -- lojistik, ic dengeli
##     karseral nufus            -- uyusturucu + issizlik + polis baskisi
##     egitim birikimi           -- guvenlik harcamasinin egitimi disllamasi
##     nitelikli emek            -- egitim ve uyusturucunun q buyumesine etkisi
##
##   EKLENEN (v4.4'te KARSILIGI YOK, §4'un kendi mekanizmasi):
##     bolunme                   -- ve onun S/Q/T bloklarindaki uc kanali
##     sekiz adlandirilmis taktik-- her biri kendi bedeliyle
##     sehit stogu               -- siyasi cinayetin gecikmeli Omega etkisi
##     KARSI HAREKET             -- sendika, sosyalist parti, kentlesme,
##                                  dayanisma kazanimlari (§4.4)
##
## ------------------------------------------------------------------------
## KARSI HAREKET DEKOR DEGIL, OLCULEBILIR BIR KUVVETTIR (§4.4, §4.6)
## ------------------------------------------------------------------------
## Karanlik devlet tek tarafli bir kol degil, BIR MUCADELENIN BIR TARAFIDIR.
## Karsisinda `bolunme`yi asagi iten kuvvetler durur ve bunlarin motordaki
## etkisi iki katlidir -- yalnizca sonumleme degil:
##
##   1. GERI CEKME  : `_bolunme`de bolunme stokunu dogrudan eritirler
##   2. DIRENC      : `parti_direnc` uc kanalin UCUNDE birden sonumlemeyi
##                    kirar -- yani bilinclendirme, karanlik devletin
##                    kanallarini tek tek kapatir
##
## Sonuc bir YARISTIR: karanlik devlet iter, sendika ve parti ceker. Kim
## kazanirsa krizin siyasi sonucunu o belirler -- patlama mi, curume mu.
##
## ------------------------------------------------------------------------
## CAPA OZDESLIGI -- bu katmanin port disiplini
## ------------------------------------------------------------------------
## Mikro katmanin "duz merdiven ozdesligi"nin karsiligi. Katman TAKILI
## DEGILKEN, ya da takili olup BUTUN TAKTIKLER KAPALIYKEN, cekirdek eskisi
## gibi kosmalidir. Iki sigortasi var:
##
##   1. Cekirdekteki butun carpanlar `bolunme`ye baglidir ve `bolunme = 0`
##      iken OZDESLIKLE 1.0'dir -- yaklasik degil, birebir.
##   2. `nitelik` bir GOLGE CAPAYA gore normalize edilir. Dort golge degisken
##      (`tolerans_capa`, `uo_capa`, `cezaevi_capa`, `egitim_capa`) gercekle
##      AYNI denklemleri kosar, tek fark taktik terimlerinin sifir olmasidir.
##
##      OLCULDU VE GEREKLI CIKTI. Ilk yazimda capa BASLANGIC degeriydi ve
##      ozdeslik KIRILDI: tasinan egitim denklemi kendi dengesine gidiyor
##      (0.30 -> 0.09), ham `nitelik` taktikler KAPALIYKEN bile 0.9019'a
##      dusuyordu. Yani katmani takmak tek basina q buyumesini %10
##      yavaslatirdi -- ve q yalnizca uretkenlik degil CAG TABLOSUNUN
##      TETIKLEYICISIDIR (`q > q_esik`), yani bu sessiz yavaslama devrimin
##      TAKVIMINI kaydirirdi. B2a'da tam olarak bu yasandi (devrim 1923'ten
##      1903'e). Golge capa ile oran taktikler kapaliyken BIREBIR 1.0'dir,
##      cunku pay ile payda ayni fonksiyondan ayni girdilerle gecer.
##
## ------------------------------------------------------------------------
## BIRIMLER
## ------------------------------------------------------------------------
## Deponun sozlesmesi: AKIMLAR YILLIK, stoklar duzey, sayaclar donem.
## v4.4'un butun `uo_*`, `kd_hiz`, `egitim_asinma` sabitleri TUR (0.27 yil)
## cinsindendir; haftalik donguye oldugu gibi kopyalanirsa 14 kat hizli kosar.
## Hepsi `Oran.v44_akim` / `Oran.v44_uyum` ile cevrilir. `karseral_*` ve
## `egitim_q` cebirsel bir formulun katsayilaridir, yani DUZEYdir, cevrilmez.

## Parametreler. Cekirdekle AYNI ornegi paylasir -- yon testleri parametreyi
## ornek bazinda degistirir ve iki kopya olsaydi biri guncellenip digeri
## kalirdi.
var P: KrizParam


## ENDOJEN KOL. Acikken riza aygiti v4.4'un kendi tikanma formulunden dogar,
## yani AI ulkeleri kendi krizlerine gore karanlik araca sarilir (§4.5) ve
## oyuncu baska ulkelerin fasizme kayisini DISARIDAN izler.
##
## Testlerde KAPALIDIR: karsi-olgusal olcum icin kolun disaridan verilmesi
## gerekir, yoksa olculen sey mekanizmanin etkisi degil endojen tepkisidir.
var otomatik: bool = false

## Bolunmenin uc kanalini ayri ayri kapatabilmek icin. Bir mekanizmanin
## etkisi ancak AYNI TOHUMLA acik/kapali kosulup olculebilir (B1b'nin dersi:
## kesitsel karsilastirma mekanizmanin etkisiyle yapisal farki karistirir).
var kanal_org: bool = true
var kanal_pazarlik: bool = true
var kanal_protesto: bool = true


func _init(p_param: KrizParam = null) -> void:
	P = p_param if p_param != null else KrizParam.new()


## GOLGEYI GERCEKLE HIZALAR. Cagrilmasi ZORUNLUDUR -- cagrilmazsa golge
## degiskenler kendi varsayilanlarindan baslar, taktikler kapaliyken bile
## sifirdan farkli bir `nitelik` dogar ve capa ozdesligi kirilir.
func baslat(d: KrizDurumu) -> void:
	d.nitelik = 1.0
	d.mafya_tolerans = 0.0
	d.bolunme = 0.0
	d.sehit = 0.0
	d.katilim_baski = 0.0
	# Golge, gercegin baslangicindan AYNEN baslar. Aksi halde ilk adimda
	# taktikler kapaliyken bile bir sapma olusur ve ozdeslik kirilirdi.
	d.tolerans_capa = d.mafya_tolerans
	d.uo_capa = d.uyusturucu_orani
	d.cezaevi_capa = d.cezaevi_orani
	d.egitim_capa = d.egitim


## Bir donem ilerletir. Cekirdegin `adim()`i icinden cagrilir.
##
## GERCEK ve GOLGE ayni denklemlerden gecer; tek fark `taktikli` bayragidir.
## Ikisi yan yana kostugu icin `nitelik` bir duzey degil SAPMA olcer.
func adim(d: KrizDurumu, donem_yil: float) -> void:
	_aygitlar(d)
	_tolerans(d, donem_yil)
	_uyusturucu(d, donem_yil)
	_karseral(d)
	_katilim_baskisi(d, donem_yil)
	_egitim(d, donem_yil)
	_nitelik(d)
	_sehit(d, donem_yil)
	_bolunme(d, donem_yil)


## IKI AYGITIN BILESKESI -- taktiklerden TURETILIR, elle yazilmaz.
##
## Bileske yalnizca tani ve kapi denetimleri icindir; mekanizmalar taktiklerin
## KENDILERINI okur. Aksi halde sekiz taktik tek bir kadrana geri duserdi ve
## tablodaki ayrim kozmetik kalirdi.
func _aygitlar(d: KrizDurumu) -> void:
	d.riza_kolu = clampf((d.t_uyusturucu + d.t_cemaat + d.t_mistisizm
			+ d.t_milliyetcilik + d.t_cinsiyet) / 5.0, 0.0, 1.0)
	d.zor_kolu = clampf((d.t_sendika_baskisi + d.t_tutuklama
			+ d.t_paramiliter) / 3.0, 0.0, 1.0)


# ===========================================================================
# RIZA AYGITI  --  ucuz, yavas, sinsi
# ===========================================================================

## ENDOJEN MAFYA TOLERANSI (v4.4 `motor.py:2006-2025`).
##
## Devlet uyusturucu ekonomisine, birikim tikandiginda ve sinif ofkesini
## bastirmanin baska araci kalmadiginda goz yumar. Tikanma `i - r` ile
## olculur: faiz kar oranini asinca birikim durur.
##
## OYUNCUNUN TAKTIGI ENDOJEN ZEMINI YUKSELTIR, ezmez. `t_uyusturucu = 0` bir
## "kapali" degil bir "ek yok"tur; endojen tepki `otomatik` ile ayrica
## kapatilir. Ikisi ayri olmali ki testte "taktik kapali" ile "devlet zaten
## sarilmiyordu" birbirine karismasin.
func _tolerans(d: KrizDurumu, donem_yil: float) -> void:
	var hiz := Oran.donem_uyum(P.kd_hiz_yil, donem_yil)
	if d.rejim != "kapitalist":
		d.kd_hedef = 0.0
		d.mafya_tolerans = clampf(
				d.mafya_tolerans + hiz * (0.0 - d.mafya_tolerans), 0.0, 1.0)
		d.tolerans_capa = clampf(
				d.tolerans_capa + hiz * (0.0 - d.tolerans_capa), 0.0, 1.0)
		return

	var endojen := 0.0
	if otomatik:
		var tikanma := minf(1.0, maxf(0.0,
				(d.i_yil - d.r_yil) / P.v44.kd_tikanma_olcek))
		# Refah yatistirmasi mumkunse karanlik araca gerek kalmaz.
		var refah_yoklugu := 1.0 - minf(1.0, maxf(0.0,
				d.r_yil - P.v44.r_referans) / P.v44.r_refah_olcek)
		endojen = (P.v44.kd_taban
				+ P.v44.kd_tikanma * tikanma
				+ P.v44.kd_omega * d.Omega * refah_yoklugu
					* maxf(0.0, 1.0 - P.v44.etg_kd * d.etg)
				+ P.v44.kd_baski * d.baski_egilimi
				- P.v44.kd_mesruiyet * minf(d.PC, 1.0)
				- P.v44.kd_org * d.org)
	endojen = clampf(endojen, 0.0, P.v44.kd_tavan)

	d.kd_hedef = clampf(maxf(endojen, d.t_uyusturucu * P.v44.kd_tavan),
			0.0, P.v44.kd_tavan)
	d.mafya_tolerans = clampf(
			d.mafya_tolerans + hiz * (d.kd_hedef - d.mafya_tolerans), 0.0, 1.0)
	# GOLGE: taktik yokken hedef yalnizca endojen zemindir.
	d.tolerans_capa = clampf(
			d.tolerans_capa + hiz * (endojen - d.tolerans_capa), 0.0, 1.0)


## UYUSTURUCU YAYILIMI -- lojistik, ic dengeli (v4.4 `motor.py:2027-2040`).
##
## Yayilim ve bastirma IKISI DE `uo` ile orantilidir, boylece tolerans surekli
## bir kadran gibi davranir. Bastirma kapasitesi mesruiyete TAM bagli
## degildir: rizasi cokmus bir devletin de zor aygiti vardir.
##
## Bu taktigin bedeli motorda ZATEN kurulu: `uyusturucu_orani` -> `lumpen_pay`
## -> `gasp` -> `varlik`. Yani gasbedilen deger uretken sermayeye DEGIL
## spekulatif stoka akar ve dogrudan Minsky balonunu besler (§4.3).
func _uyusturucu(d: KrizDurumu, donem_yil: float) -> void:
	d.uyusturucu_orani = clampf(d.uyusturucu_orani + Oran.donem_akim(
			_uo_delta(d, d.uyusturucu_orani, d.mafya_tolerans), donem_yil),
			0.0, P.v44.uo_tavan)
	d.uo_capa = clampf(d.uo_capa + Oran.donem_akim(
			_uo_delta(d, d.uo_capa, d.tolerans_capa), donem_yil),
			0.0, P.v44.uo_tavan)


## Yayilimin YILLIK degisim orani. Gercek ve golge ayni fonksiyondan gecer;
## aralarindaki tek fark toleransin kendisidir.
func _uo_delta(d: KrizDurumu, uo: float, tolerans: float) -> float:
	var iss := 1.0 - d.e
	var yayilim := (P.uo_omega_yil * d.Omega * tolerans
			+ P.uo_iss_yil * maxf(0.0, iss - P.v44.uo_iss_esik)
			+ P.uo_gecim_yil * maxf(0.0, P.v44.gecim_tabani - d.pay))
	var bastirma := P.uo_bastirma_yil * (1.0 - tolerans) * (
			P.v44.uo_bastirma_taban
			+ (1.0 - P.v44.uo_bastirma_taban) * minf(d.PC, 1.0))
	return yayilim * (1.0 - uo / P.v44.uo_tavan) - (bastirma + P.uo_cozulme_yil) * uo


## CINSIYET BASKISININ KENDI KANALI -- katilim.
##
## LGBT dusmanligi ve kadinlara karsi baskici politikalar bir "kultur" kolu
## degildir: kadinlari isgucunun disina iterek EMEK ARZINI daraltirlar.
## `l_etkin()` kuculur, yani canli emek, yani yeni degerin kaynagi daralir.
##
## Zor aygitinin `cezaevi_orani` kanaliyla AYNI mekanik, farkli magdur. Ikisi
## de §4.3'un tezinin kanitidir: bunlar bedava kollar degildir, arti degerin
## kaynagini daraltarak calisirlar.
func _katilim_baskisi(d: KrizDurumu, donem_yil: float) -> void:
	var hedef := P.cinsiyet_katilim * d.t_cinsiyet
	d.katilim_baski += Oran.donem_uyum(P.cinsiyet_hiz_yil, donem_yil) * (
			hedef - d.katilim_baski)
	d.katilim_baski = clampf(d.katilim_baski, 0.0, 0.60)


# ===========================================================================
# ZOR AYGITI  --  hizli, pahali, iz birakir
# ===========================================================================

## KARSERAL NUFUS (v4.4 `motor.py:2045-2049`).
##
## Cebirsel bir formuldur, stok degil: hapsetme kapasitesi bir birikim degil
## bir POLITIKA duzeyidir ve talebe aninda uyar. Ampirik capa: dunya rekoru
## ~%0.65 (ABD), tipik OECD %0.1-0.2, tavan %2.5 asiri karseral devlet.
##
## TUTUKLAMA TAKTIGI BURAYA DOGRUDAN GIRER -- v4.4'te yalnizca `baski_egilimi`
## uzerinden dolayli girerdi. §4.2'nin "muhalif siyasi karakterlerin
## tutuklanmasi" kolu budur.
##
## Bedeli motorda ZATEN kurulu ve DORT ayri yerden cikar; bu katman kolu acar:
##   `l_etkin()`      -> canli emek daralir, ARTI DEGERIN KAYNAGI daralir
##   `_kamu_maliyesi` -> `karseral_maliyet` butce kalemi (pahalidir)
##   `PC`             -> `karseral_mesruiyet` mesruiyeti asindirir
##   `egitim`         -> `karseral_egitim_disla` egitim butcesini disllar
func _karseral(d: KrizDurumu) -> void:
	d.cezaevi_orani = _karseral_hesap(d, d.uyusturucu_orani, true)
	d.cezaevi_capa = _karseral_hesap(d, d.uo_capa, false)


func _karseral_hesap(d: KrizDurumu, uo: float, taktikli: bool) -> float:
	var iss := 1.0 - d.e
	# Sendika baskisi polis baskisi egilimini yukseltir; grev kirma bir
	# kolluk faaliyetidir ve karseral orana oradan girer.
	var baski_ef := d.baski_egilimi
	var tutuklama := 0.0
	if taktikli:
		baski_ef += P.sendika_baski_egilim * d.t_sendika_baskisi
		tutuklama = P.tutuklama_karseral * d.t_tutuklama
	return clampf(
			P.v44.karseral_taban
			+ P.v44.karseral_uo * uo
			+ P.v44.karseral_iss * iss
			+ P.v44.karseral_baski * clampf(baski_ef, 0.0, 1.0) * d.Omega
			+ tutuklama,
			0.0, P.v44.cezaevi_tavan)


## SEHIT STOGU -- siyasi cinayetin GECIKMELI etkisi (§4.3).
##
## Iki etki ayni anda olmaz ve olcut tam olarak budur:
##   kisa vade : orgutlenme kirilir  (`_orgutlenme` okur)
##   orta vade : `Omega` YUKSELIR    (`_protesto_ve_devrim` okur)
##
## Gecikmeyi tasiyan sey STOKtur. Bir akimla yazilsaydi cinayet durdugu anda
## etkisi de biterdi ve "sehitler radikallestirir" cumlesi kurulamazdi
## (B2c'nin dersi: bir mekanizmanin hafizasi olmaliysa onu akimla kurma).
##
## Baskidan sag cikan orgutlenmenin DAHA RADIKAL donmesi de buradan gelir:
## `org` yeniden buyudugunde `Omega` hala yuksektir, yani ilimli kanal
## kapalidir.
func _sehit(d: KrizDurumu, donem_yil: float) -> void:
	var ds := P.sehit_itki_yil * d.t_paramiliter - P.sehit_sonum_yil * d.sehit
	d.sehit = maxf(0.0, d.sehit + Oran.donem_akim(ds, donem_yil))


# ===========================================================================
# BEDEL: EGITIM VE NITELIKLI EMEK
# ===========================================================================

## EGITIM BIRIKIMI (v4.4 `motor.py:2228-2233`).
##
## Uc asindirici var ve ucu de karanlik devletin kendi bedelidir:
##   ZOR       : guvenlik harcamasi egitim butcesini DISLLAR (v4.4'un kanali)
##   MISTISIZM : evrim karsitligi, duz dunyacilik, astroloji -- bilim tabanina
##               dogrudan saldiri, en agir asindirici
##   CEMAAT    : tarikat aglari egitimin yerini alir; daha hafif ama surekli
##
## Son ikisi v4.4'te yoktur, B3'un eklemesidir. §4.3 bunlari boyle
## gerekcelendirir: bir "inanc" meselesi degil, NITELIKLI EMEK BIRIKIMININ
## tabanina yapilan bir saldiridir -- ve o taban LTRPF'ye karsi elde kalan
## tek karsi egilimin (`qg`) kaynagidir.
func _egitim(d: KrizDurumu, donem_yil: float) -> void:
	d.egitim = clampf(d.egitim + Oran.donem_akim(
			_egitim_delta(d, d.egitim, d.cezaevi_orani, true), donem_yil), 0.0, 1.0)
	d.egitim_capa = clampf(d.egitim_capa + Oran.donem_akim(
			_egitim_delta(d, d.egitim_capa, d.cezaevi_capa, false), donem_yil), 0.0, 1.0)


func _egitim_delta(d: KrizDurumu, egitim: float, cezaevi: float,
		taktikli: bool) -> float:
	var disla := 1.0 - P.v44.karseral_egitim_disla * minf(
			1.0, cezaevi / P.v44.cezaevi_ref)
	var egitim_pay_ef := float(Tables.KURUMLAR[d.kurum].get("egitim_pay", 0.04)) * disla
	var harcama := d.G_yil * egitim_pay_ef / maxf(d.Y_yil, 1e-6)
	var saldiri := 0.0
	if taktikli:
		saldiri = (P.mistisizm_egitim_yil * d.t_mistisizm
				+ P.cemaat_egitim_yil * d.t_cemaat)
	return P.egitim_harcama_yil * harcama - P.egitim_asinma_yil * egitim - saldiri


## NITELIKLI EMEK CARPANI (v4.4 `motor.py:2250`).
##
##     nitelik = max(0.1, (1 + egitim_q*egitim) * (1 - 0.70*uyusturucu_orani))
##
## v4.4'te `q` buyume hizini carpar. LTRPF'ye karsi elindeki TEK karsi egilim
## `q` buyumesi oldugu icin (§4.3), bu carpani asindirmak dogrudan kar oranini
## asindirir -- ama GECIKMELI. Karanlik devletin asil bedeli budur:
##
##   > Toplumsal barisi, kendi gelecekteki birikimini yiyerek satin alir.
##   > Bugun devrimi oteler, yarin kar oranini daha da dusurur.
##
## GOLGE CAPAYA BOLUNUR (bkz. baslik, "capa ozdesligi"). Taktikler kapaliyken
## pay ile payda AYNI denklemlerden AYNI girdilerle gectigi icin oran BIREBIR
## 1.0'dir -- yaklasik degil. Yani `nitelik` bir DUZEY degil SAPMA olcer:
## "karanlik devlet nitelikli emege ne kadar zarar verdi".
func _nitelik(d: KrizDurumu) -> void:
	d.nitelik = (_nitelik_ham(d.egitim, d.uyusturucu_orani)
			/ maxf(_nitelik_ham(d.egitim_capa, d.uo_capa), 1e-9))


func _nitelik_ham(egitim: float, uo: float) -> float:
	return maxf(0.1, (1.0 + P.v44.egitim_q * egitim) * (1.0 - 0.70 * uo))


# ===========================================================================
# BOLUNME  --  §4.1'in degiskeni, §4.4'un yarisi
# ===========================================================================

## KARANLIK DEVLET ITER, KARSI HAREKET CEKER.
##
## Lojistik bicim `org`un kendi formuyle AYNIDIR (`buyume*(1-x) - azalma*x`)
## ve bu bilerektir: bolunme de bir toplumsal doku meselesidir, sinirsiz
## birikmez ve kendiliginden sifira da gitmez.
##
## ITKI -- her taktik KENDI agirligiyla girer (bkz. baslikta tablo):
##   milliyetcilik en agir basar, cunku §4.1'in tarif ettigi sey tam olarak
##   odur -- ofkenin hedefini SINIFTAN KOMSUYA cevirmek. Otekiler zemini
##   hazirlar; milliyetcilik hedefi degistirir.
##
##   Kentlesme itkiye DIRENIR: fabrika yogunlugu ortak cikari gorunur kilar,
##   bolunme kentte kirda oldugundan zor tutunur (§4.4).
##
## GERI CEKME -- karsi hareket (§4.4):
##   sendika (`org`)     : ortak cikar etrafinda yeniden birlestirir
##   parti (`parti`)     : dagInik ofkeyi sinifsal guce cevirir -- tam da
##                         karanlik devletin kirmaya calistigi kanal
##   parti iktidari      : en hizli geri cekilme
##   dayanisma kazanimi  : ucret payi referansin ustundeyken bolunme anlatisi
##                         zayiflar -- kazanimlar bolunmeyi eritir
func _bolunme(d: KrizDurumu, donem_yil: float) -> void:
	var kent_direnci := maxf(0.0, 1.0 - P.bolunme_kent * d.kent)
	d.bolunme_itki = (P.bol_milliyetcilik_yil * d.t_milliyetcilik
			+ P.bol_cinsiyet_yil * d.t_cinsiyet
			+ P.bol_paramiliter_yil * d.t_paramiliter
			+ P.bol_uyusturucu_yil * d.t_uyusturucu
			+ P.bol_cemaat_yil * d.t_cemaat
			+ P.bol_mistisizm_yil * d.t_mistisizm
			+ P.bol_sendika_yil * d.t_sendika_baskisi
			+ P.bol_tutuklama_yil * d.t_tutuklama) * kent_direnci

	var iktidar := P.bol_iktidar_yil if d.parti_iktidari else 0.0
	d.bolunme_geri = (P.bol_org_yil * d.org
			+ P.bol_parti_yil * d.parti
			+ iktidar
			+ P.bol_dayanisma_yil * maxf(0.0, d.pay - P.dayanisma_ref))
	d.karsi_hareket = d.bolunme_geri

	var db := d.bolunme_itki * (1.0 - d.bolunme) - d.bolunme_geri * d.bolunme
	d.bolunme = clampf(d.bolunme + Oran.donem_akim(db, donem_yil), 0.0, 1.0)


# ===========================================================================
# CEKIRDEGIN OKUDUGU CARPANLAR
# ===========================================================================
#
# Uc kanal da AYNI kurala uyar: `bolunme = 0` iken OZDESLIKLE 1.0 doner.
# Cekirdek bunlari katman TAKILI DEGILKEN de cagirir (o zaman `d.bolunme`
# baslangic degeri 0.0'dir), dolayisiyla TEK bir kod yolu vardir ve "katman
# takiliyken baska, degilken baska" diye bir ayrim olusmaz.
#
# `direnc` UCUNDE de is gorur: bilinclendirme (parti) karanlik devletin
# kanallarini tek tek kapatir. Karsi hareketin ikinci katmani budur (§4.4).

## S BLOGU -- ofkenin orgutlenmeye donusumunu kirar.
static func org_kirilma(P_: KrizParam, d: KrizDurumu, direnc: float,
		acik: bool = true) -> float:
	if not acik:
		return 1.0
	return 1.0 - minf(P_.bolunme_org_tavan,
			P_.bolunme_org_kirilma * d.bolunme * direnc)


## Q BLOGU -- sendikanin PAZARLIK gucunu kirar.
##
## Orgutlenme STOKU degismez: bolunmus bir sinif orgutludur ama BIRLIKTE
## PAZARLIK EDEMEZ. Ayrim onemlidir, cunku `org` ayni zamanda protesto ve
## parti kanallarini besler; bolunmeyi `org`un kendisinden dusmek uc kanali
## birden kapatirdi ve mekanizma "orgutlenmeyi yok eden bir kol" olurdu --
## §4.1 tam olarak bunun TERSINI soyluyor: ofke de orgutlenme de yerinde
## kalir, aralarindaki BAG kirilir.
static func pazarlik_gucu(P_: KrizParam, d: KrizDurumu, direnc: float,
		acik: bool = true) -> float:
	if not acik:
		return d.org
	return d.org * (1.0 - minf(P_.bolunme_pazarlik_tavan,
			P_.bolunme_pazarlik * d.bolunme * direnc))


## T BLOGU -- protestoyu sinifsal olmaktan cikarir.
##
## `PR` soner ama sinifsal BASINC sonmez: cekilen enerji `topluluk_siddeti`ne
## akar (bkz. `_protesto_ve_devrim`). Motordaki imza budur -- basinc yerinde,
## sinifsal ifadesi kirik.
##
## ------------------------------------------------------------------------
## KRIZ SINIF CIZGILERINI NETLESTIRIR -- ve bu satir §8.4'un sigortasidir
## ------------------------------------------------------------------------
## Sonum `Omega` ile ZAYIFLAR: yeterince derinlesmis bir ofkede bolunme
## anlatisi tutmaz. Marx'in kendi iddiasi -- kriz sinif cizgilerini gizlemez,
## GORUNUR KILAR.
##
## OLCULDU VE ZORUNLU CIKTI. Bu satir olmadan bolunme devrimi ERTELEMIYOR,
## TUMDEN KAPATIYORDU -- yani §8.4'un birinci riski gerceklesiyordu. Sebep
## cekirdegin esik yapisinin KESKIN olmasi: `pr_esik = 0.74` ve `pr_esik_omega
## = 0.06`, yani ofke tavana dayansa bile esik ancak 0.68'e iner. Capa
## kosusunda `PR` 0.736 ile o esigi KIL PAYI asiyor; dolayisiyla `PR`yi %8'den
## fazla sonumleyen HERHANGI bir mekanizma devrimi sonsuza kadar kapatir.
##
## Olculdu: sonum tavani 0.35'ten 0.05'e indirildiginde bile (PR 0.580 ->
## 0.728) devrim 575 yillik ufukta bile GELMIYORDU. Yani secenek "mekanizmayi
## olduresiye zayiflat" ile "devrimi imkansiz kil" arasindaydi -- ikisi de
## kabul edilemez. Ucuncu yol mekanizmanin KENDI icindeydi: bolunme mutlak
## degil, ofkenin duzeyine BAGLI bir kuvvettir.
##
## `pr_esik_omega`yi buyutmek de bir secenekti ve REDDEDILDI: o sabit capa
## kosusunu da degistirir, yani B1/B2'nin butun kalibrasyonunu kaydirirdi.
## Buradaki cozum `bolunme = 0` iken OZDESLIKLE notrdur.
static func protesto_sonum(P_: KrizParam, d: KrizDurumu, direnc: float,
		acik: bool = true) -> float:
	if not acik:
		return 1.0
	var netlesme := maxf(0.0, 1.0 - d.Omega / P_.bolunme_omega_kirilma)
	return 1.0 - minf(P_.bolunme_sonum_tavan,
			P_.bolunme_sonum_gucu * d.bolunme * direnc * netlesme)
