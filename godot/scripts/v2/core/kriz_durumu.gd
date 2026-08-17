class_name KrizDurumu
extends RefCounted

## Kriz cekirdeginin uzerinde calistigi ulke durumu.
##
## v4.4'un `Country`'si ~120 alan tasiyordu; buna savas, ittifak, politika
## kuyrugu, diplomasi ve raporlama dahildi. Burada YALNIZCA deger katmaninin
## okudugu/yazdigi alanlar var. Geri kalan v2'de mikro katmanin (eyalet, pop,
## bina, mal piyasasi) isidir ve buraya TOPLAM olarak girer.
##
## BIRIM SOZLESMESI -- v4.4'ten en onemli ayrilik:
##   AKIM buyuklukleri YILLIKTIR  (`Y_yil`, `V_yil`, `s_yil`, `r_yil`, ...)
##   STOK buyuklukleri duzeydir   (`K`, `borc`, `varlik`, `kamu_borc`)
##   SAYACLAR donem cinsindendir  (`delev`, `kontrol`, `au_ici`, ...)
## v4.4'te akimlar TUR basinaydi ve donem uzunlugu degisince sessizce
## yanlislasan tek sey buydu. Yillik sabitlemek o hatayi imkansiz kilar.

# ---------------------------------------------------------------------------
# MIKRO KATMANDAN GELEN TOPLAMLAR  (B2'de bina/pop/piyasa uretecek)
# ---------------------------------------------------------------------------
var K: float = 1.0                 ## sermaye stoku (STOK)
var L_etkin: float = 1.0           ## etkin emek gucu (kisi)
## Kisi basi emek-saati normu. TUREVDIR: `hafta_norm[cag] * saat`.
## Cekirdek her adimda yeniden hesaplar (blok N); elle yazilmaz.
var hafta_saati: float = 1.0
## Calisma suresi carpani. Kapitalist rejimde 1.0; planli ekonomide plan
## istihdami tutturmak icin asagi cekilir.
var saat: float = 1.0
var yil: float = 1836.0            ## takvim yili -- cag gecisi buna bakar
var era: int = 1                   ## cag
var ito: float = 1.0               ## mekanizasyon durtusu
var egitim: float = 0.3            ## egitim duzeyi
var kent: float = 0.15             ## kentlesme (cag tablosundan)
var rejim: String = "kapitalist"   ## kapitalist | sosyalist
## Kurumsal rejim -- Polanyi'nin cifte hareketi bu eksende salinir.
## liberal | duzenli | neoliberal. Kamu hedefi, hizlandirici, emek payi ve
## orgutlenme erozyonu buradan okunur (`Tables.KURUMLAR`).
var kurum: String = "liberal"

# ---------------------------------------------------------------------------
# CEKIRDEGIN DURUMU -- uretim ve deger
# ---------------------------------------------------------------------------
var q: float = 1.0                 ## uretkenlik
var oto: float = 0.0               ## otomasyon payi
var canli_pay: float = 1.0         ## canli emegin fiziksel hasiladaki payi
var pay: float = 0.5               ## ucret payi
var e: float = 0.9                 ## istihdam orani
var e_norm: float = 0.88           ## hareketli istihdam normu
var u: float = 0.82                ## kapasite kullanimi
var katilim: float = 1.0
var norm: float = 0.72             ## tuketim normu (hareketli)

# ---------------------------------------------------------------------------
# DIS TICARET VE ODEMELER DENGESI  (B bloku -- `Dunya` yazar, cekirdek okur)
# ---------------------------------------------------------------------------
## Ihracat gelir esnekligi. Goreli uretkenlikle YUKSELIR.
var eps: float = 1.0
## Ithalat gelir esnekligi. Goreli uretkenlikle DUSER (sanayilesme ithal
## ikamesi yaratir). Thirlwall orani `eps / pi_m`'dir.
var pi_m: float = 1.0
var X_yil: float = 0.0             ## ihracat (YILLIK)
var M_yil: float = 0.0             ## ithalat (YILLIK)
var NX_yil: float = 0.0            ## net ihracat = X - M (YILLIK)
## BoP-kisitli azami buyume (Thirlwall): `eps * y_dunya / pi_m`.
var y_max: float = 0.0
## Kisitin asilma miktari: `y_buyume - y_max`. Pozitifse ulke odeyebileceginden
## hizli buyuyor demektir.
var bop_asim: float = 0.0
## Odemeler dengesi risk primi. Politika faizini CARPARAK yukseltir.
var BoP_R: float = 0.0
var cari_yil: float = 0.0          ## cari denge (YILLIK)
var FX: float = 0.0                ## rezerv (STOK)

# ---------------------------------------------------------------------------
# D / E / F  --  ani durus, moratoryum, doviz krizi
#
# `dis_borc` burada YALNIZCA TANIDIR: gercek borc `Dunya.borc` matrisinde,
# alacaklisiyla birlikte durur. v4.4'te borc alacaklisiz bir skalerdi ve
# moratoryum onu buharlastiriyordu (`dis_borc *= 1-kesinti`) -- kimse zarar
# etmiyordu. Borcun kime borclu olundugu modellenmedikce temerrut bir kriz
# KANALI olamaz, yalnizca bir muafiyet olur.
# ---------------------------------------------------------------------------
var dis_borc: float = 0.0          ## toplam dis borc / hasila (TANI)
var dis_varlik: float = 0.0        ## net dis varlik konumu / hasila (TANI)
var faiz_dis_yil: float = 0.0      ## net dis faiz akimi (YILLIK, + = alacakli)
## Sindirilen temerrut zarari/kazanci (YILLIK). Alacakliya eksi, borcluya arti.
var mor_akim_yil: float = 0.0
var deval: float = 0.0             ## devaluasyon etkisi, sonumlenir
var fx_baski: int = 0              ## rezerv baskisi sayaci (DONEM)
var fx_kriz: int = 0               ## doviz krizi sayaci (DONEM)
var mor_ceza: int = 0              ## moratoryum cezasi sayaci (DONEM)
var ani_durus: bool = false        ## dis finansman kesildi mi
var moratoryumlar: Array = []
var fx_krizleri: Array = []

# ---------------------------------------------------------------------------
# FINANS
# ---------------------------------------------------------------------------
var borc: float = 0.0              ## hanehalki borcu (STOK)
var varlik: float = 0.0            ## spekulatif varlik (STOK)
var varlik_beklenti: float = 0.0
var minsky_sayac: int = 0
var delev: int = 0                 ## de-leveraging sayaci (DONEM)
var i_yil: float = 0.04            ## efektif faiz (YILLIK)
var i_spec_yil: float = 0.05       ## spekulatif finansman maliyeti (YILLIK)
var i_pol_yil: float = 0.04        ## politika faizi (YILLIK)

# ---------------------------------------------------------------------------
# KAMU
# ---------------------------------------------------------------------------
var kamu_borc: float = 0.4
var kamu_pay: float = 0.05
var vergi_carpani: float = 1.0
var kemer: int = 0                 ## kemer sikma sayaci (DONEM)

# ---------------------------------------------------------------------------
# FIYAT
# ---------------------------------------------------------------------------
var pi_inf: float = 0.02           ## enflasyon (YILLIK)
var pi_bek: float = 0.02           ## enflasyon beklentisi (YILLIK)
var p_duzey: float = 1.0
var w_nom_buyume_yil: float = 0.02 ## nominal ucret buyumesi (YILLIK)
var kontrol: int = 0               ## fiyat kontrolu sayaci (DONEM)
var bastirilmis_pi: float = 0.0
var stagflasyon: int = 0

# ---------------------------------------------------------------------------
# KRIZ TESCILI
# ---------------------------------------------------------------------------
var Y_ort: float = 0.0
var Y_trend: float = 0.0
var Y_zirve: float = 0.0
var y_buyume: float = 0.02
var talep_acigi: float = 0.0
var kriz: int = 0
var au_ici: int = 0
var au_bekle: int = 0
var res_ici: int = 0
var res_bekle: int = 0
var bun_ici: int = 0
var deger_carpani: float = 1.0
## Parasallastirilan kamu acigi (hasilaya oran). `_kamu_maliyesi` yazar,
## `_phillips` okur.
var parasallasma: float = 0.0
## AMORTISMAN FONU. Tuketilen sabit sermayenin degeri burada para olarak
## bekler: satis olmus, karsit alis henuz olmamistir. Bir STOKtur.
var amortisman: float = 0.0
## Cag ici teknolojik doyum carpani (tani icin; `_uretkenlik` yazar).
var q_doyum: float = 1.0
var asiri_uretim_krizleri: Array = []
var resesyonlar: Array = []
var bunalimlar: Array = []
var temerrutler: Array = []

# ---------------------------------------------------------------------------
# SINIF VE SIYASET
# ---------------------------------------------------------------------------
var org: float = 0.08              ## sendikal orgutlenme
var parti: float = 0.0             ## Marksist politik ozne
var orgutlu: float = 0.08          ## org + parti*(1-org)
var Omega: float = 0.05            ## siyasi ofke
var PC: float = 1.0                ## siyasi sermaye
var PR: float = 0.0                ## protesto riski (cikti)
var pr_sayac: int = 0
var IR: float = 0.0
var baski_egilimi: float = 0.4
var parti_iktidari: bool = false
var devrim_yil: float = -1.0       ## devrim olduysa yili, yoksa -1

# ---------------------------------------------------------------------------
# KARANLIK DEVLET  (B3 -- otoritesi `KaranlikDevlet`tedir, bkz. karanlik.gd)
#
# Katman TAKILI DEGILKEN bu alanlarin hepsi baslangic degerinde kalir ve
# cekirdegin butun carpanlari OZDESLIKLE 1.0 olur. B1/B2 olcumleri bu yuzden
# gecerliligini korur; `--v2-bolunme` bunu 1e-12 toleransla olcer.
# ---------------------------------------------------------------------------
var uyusturucu_orani: float = 0.0
var cezaevi_orani: float = 0.0
var lumpen_pay: float = 0.0
var gasp: float = 0.0

## EMEKCI SINIFIN KENDI ICINE BOLUNMUSLUGU [0,1] -- §4.1'in yeni degiskeni.
##
## Karanlik devletin amaci ofkeyi (`Omega`) azaltmak DEGIL, onun sinifsal
## orgutlenmeye (`org`) donusmesini kirmaktir. Ofke yerinde kalir, hedefi
## degisir: siniftan komsuya. Uc kanaldan is gorur (S, Q, T bloklari).
var bolunme: float = 0.0

## TAKTIKLER [0,1] -- oyuncu ya da AI yazar, `KaranlikDevlet` OKUR.
##
## TEK BIR "KARANLIK DEVLET KADRANI" YOKTUR, ve bu §4.6'nin geregi:
## "bunlar oyunda NE ISELER O OLARAK gorunur -- magdurlari adlandirilmis,
## bedelleri sayilmis politikalar; 'etkinlik' kolu gibi sunulmaz."
##
## Her taktigin KENDI kanali vardir (bkz. karanlik.gd'deki tablo). Sekiz
## taktik tek bir olcege indirgenseydi hepsi ayni sekilde davranirdi ve
## "hangi bedeli kim oduyor" sorusu motorda tanimsiz kalirdi.
##
## RIZA -- ucuz, yavas, sinsi:
var t_uyusturucu: float = 0.0      ## uyusturucu ekonomisine goz yumma
var t_cemaat: float = 0.0          ## dini cemaat/tarikat aglarinin onunu acma
var t_mistisizm: float = 0.0       ## astroloji, evrim karsitligi, duz dunyacilik
var t_milliyetcilik: float = 0.0   ## ic etnik gruplara dusmanlik, multeci dusmanligi, irkcilik
var t_cinsiyet: float = 0.0        ## LGBT dusmanligi, kadinlara karsi baskici politikalar
## ZOR -- hizli, pahali, iz birakir:
var t_sendika_baskisi: float = 0.0 ## sendikal harekete baski, grev kirma
var t_tutuklama: float = 0.0       ## muhalif siyasi karakterlerin tutuklanmasi
var t_paramiliter: float = 0.0     ## paramiliter fasist gruplar, siyasi cinayet

## Iki aygitin BILESKESI. `KaranlikDevlet` taktiklerden TURETIR, elle
## yazilmaz -- tani ve kapi denetimleri bunlari okur.
var riza_kolu: float = 0.0
var zor_kolu: float = 0.0

## SEHIT STOGU. Siyasi cinayet kisa vadede orgutlenmeyi kirar ama `Omega`yi
## yukseltir -- ve bu ikisi AYNI ANDA olmaz. Gecikmeyi tasiyan sey bu stoktur;
## bir akimla yazilsaydi "sehitler radikallestirir" cumlesi kurulamazdi
## (B2c'nin dersi: bir mekanizmanin hafizasi olmaliysa onu akimla kurma).
var sehit: float = 0.0

## Uyusturucu ekonomisine goz yumma [0,1]. v4.4'te `mafya_tolerans`.
var mafya_tolerans: float = 0.0
var kd_hedef: float = 0.0              ## tani icin: toleransin hedef degeri

## NITELIKLI EMEK CARPANI -- egitim ve uyusturucunun `q` buyumesine etkisi.
## GOLGE CAPAYA gore normalize edilir (bkz. karanlik.gd, "capa ozdesligi"),
## yani taktikler kapaliyken 1.0'dir -- yaklasik degil, BIREBIR.
var nitelik: float = 1.0

## GOLGE CAPA -- "taktikler hic acilmasaydi ne olurdu" referansi.
##
## Dort golge degisken, gercekleriyle AYNI denklemleri kosar; tek fark
## taktik terimlerinin sifirlanmasidir. Boylece `nitelik` bir DUZEY degil
## bir SAPMA olcer: karanlik devletin nitelikli emege verdigi zarar.
##
## NEDEN GEREKLI. Tasinan egitim denklemi kendi dengesine gider (0.3'ten
## ~0.09'a) ve ham `nitelik` bu yuzden taktikler KAPALIYKEN bile 0.90'a
## duserdi -- yani katmani takmak tek basina q buyumesini %10 yavaslatirdi.
## Ve q yalnizca uretkenlik degil CAG TABLOSUNUN TETIKLEYICISIDIR, yani bu
## sessiz yavaslama devrimin takvimini kaydirirdi. B2a'da tam olarak bu
## yasandi (devrim 1923'ten 1903'e). Golge capa onu yapisal olarak keser.
var tolerans_capa: float = 0.0
var uo_capa: float = 0.0
var cezaevi_capa: float = 0.0
var egitim_capa: float = 0.3

## KATILIM BASKISI [0,1] -- cinsiyet baskisi taktiginin KENDI kanali.
##
## Kadinlari isgucunun disina iten bir politika emek arzini daraltir:
## `l_etkin()` kuculur, yani CANLI EMEK, yani YENI DEGERIN KAYNAGI daralir.
## Zor aygitinin `cezaevi_orani` kanaliyla ayni mekanik, farkli magdur --
## ve ikisi de bu kollarin bedava OLMADIGININ kanitidir.
var katilim_baski: float = 0.0

## TANI -- bolunme yarisinin iki tarafi (§4.4). Kapi "mekanizma canli mi"
## denetimini bunlar uzerinden yapar; yon dogru cikip mekanizma olu olabilir.
var bolunme_itki: float = 0.0
var bolunme_geri: float = 0.0

## KARSI HAREKETIN BILESKE GUCU -- tani (§4.4). Sendika, parti, parti
## iktidari ve dayanisma kazanimlarinin toplami.
var karsi_hareket: float = 0.0

## TOPLULUKLAR ARASI SIDDET -- bolunmenin sinifsal kanaldan CEKTIGI enerji.
##
## §4.1: "Protestoyu sinifsal olmaktan cikarir, topluluklar arasi siddete
## cevirir." Ofke yok olmaz, hedef degistirir: siniftan komsuya -- ic etnik
## gruplara, multecilere, kadinlara, LGBT'ye.
##
## §4.6 geregi GORUNUR bir metriktir, gizli bir carpan degil: oyun bu
## politikalari bir yonetim teknigi olarak degil sinif egemenliginin araci
## olarak modeller ve MALIYETINI KIMIN ODEDIGINI sayar.
var topluluk_siddeti: float = 0.0

## SINIFSAL BASINC -- protesto riskinin bolunme UYGULANMADAN onceki hali.
##
## `PR` bu basincin SINIFSAL ifadesidir, `topluluk_siddeti` ise komsuya
## yonelmis hali; ikisinin toplami basinca esittir (OZDESLIK).
##
## Ayri bir alan olarak durmasi gerekli, cunku §4.1'in iddiasi tam olarak
## bu buyukluk uzerinden kurulur: karanlik devlet basinci AZALTMAZ, onu
## sinifsal kanaldan baska bir kanala aktarir. Yalnizca `Omega`ya bakarak
## bu iddia sinanamaz -- `Omega` bir STOKtur ve orgutlulukle CARPILARAK
## birikir, dolayisiyla bolunmus bir sinifta daha yavas birikir. Basincin
## kendisi ise yerinde durur.
var sinif_basinci: float = 0.0

# ---------------------------------------------------------------------------
# EVRENSEL TEMEL GELIR
# ---------------------------------------------------------------------------
var etg_hedef: float = 0.0
var etg: float = 0.0
var etg_metasiz: float = 0.0
var etg_vergi_sermaye_o: float = 0.0
var etg_vergi_ucret_o: float = 0.0
var katilim_etg: float = 0.0

# ---------------------------------------------------------------------------
# CIKTILAR  (cekirdek yazar, arayuz/testler okur)
# ---------------------------------------------------------------------------
var cv: float = 1.0                ## organik bilesim
var kv: float = 11.0               ## sermaye/hasila katsayisi
var Y_yil: float = 0.0             ## fiziksel hasila (YILLIK)
var Y_pot_yil: float = 0.0         ## potansiyel hasila (YILLIK)
var V_yil: float = 0.0             ## yeni deger (YILLIK)
var s_yil: float = 0.0             ## arti deger (YILLIK)
var r_yil: float = 0.0             ## KAR ORANI (YILLIK)
var g_yil: float = 0.0             ## net birikim orani (YILLIK)
var vergi_geliri_yil: float = 0.0
## Talep bilesenleri -- teshis icin (hangi kalem hasilayi asiyor?).
var C_yil: float = 0.0
var I_yil: float = 0.0
var G_yil: float = 0.0
var D_yil: float = 0.0
## Yenileme yatiriminin karliliga gore olcegi [taban, 1]. 1 = tam yenileme,
## taban = karlilik yok, yalnizca zorunlu bakim.
var yenileme_orani: float = 1.0

# ---------------------------------------------------------------------------
# DEPARTMAN I / II  --  Marx'in yeniden uretim semalari
# ---------------------------------------------------------------------------
## Sermayenin Departman I'de (uretim araci) duran payi. YAVAS degisir.
var pay_I: float = 0.35
var Y_I_yil: float = 0.0           ## Dept I gerceklesen hasila
var Y_II_yil: float = 0.0          ## Dept II gerceklesen hasila
var satilamayan_I: float = 0.0     ## satilamayan uretim araci
var satilamayan_II: float = 0.0    ## satilamayan tuketim mali

## EMEK GERGINLIGI -- istihdam oraninin 1.0'da doydugu yerde ucret baskisini
## tasiyan buyukluk. 1.0'i ASABILIR: sermaye kapasitesi emek arzini astiginda
## karsilanmamis emek talebi olusur ve bu, tam istihdamda bile ucretleri
## yukari iter. `e` bunu tasiyamaz cunku tanimi geregi tavanlidir.
var emek_gerginlik: float = 0.9


## ETKIN EMEK GUCU -- karanlik devletin iki magduru dusulmus.
##
## Zor aygitinin bedeli (`cezaevi_orani`) v4.4'ten gelir; riza aygitinin
## `katilim_baski` kanali B3'un eklemesidir (§4.3). Ikisi de AYNI mekanik
## uzerinden oder: canli emek daralir, yani YENI DEGERIN KAYNAGI daralir.
## Marx'ta arti deger yalnizca canli emekten dogar, dolayisiyla emekcileri
## isgucunun disina itmek arti degerin kendisini kesmektir.
func l_etkin() -> float:
	return (L_etkin * katilim * (1.0 - clampf(katilim_baski, 0.0, 0.90))
			* (1.0 - minf(0.90, cezaevi_orani)))


## ETG'ye gore duzeltilmis issizlik. ETG gonullu cekilmeyle olculen istihdami
## MEKANIK olarak yukseltir; bu duzeltme onu gorunur birakir.
func iss_duzeltilmis() -> float:
	if katilim_etg <= 0.0:
		return 1.0 - e
	return 1.0 - e * katilim / maxf(katilim + katilim_etg, 1e-9)


func kopya() -> KrizDurumu:
	var y := KrizDurumu.new()
	for pr in get_property_list():
		var ad: String = pr["name"]
		if pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var d: Variant = get(ad)
			y.set(ad, d.duplicate() if d is Array else d)
	return y
