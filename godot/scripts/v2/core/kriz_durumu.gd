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
var FX: float = 0.0                ## rezerv (STOK) -- D/E/F bunun uzerine kurulacak

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
# KARANLIK DEVLET  (B2b'de `bolunme` ile genisleyecek)
# ---------------------------------------------------------------------------
var uyusturucu_orani: float = 0.0
var cezaevi_orani: float = 0.0
var lumpen_pay: float = 0.0
var gasp: float = 0.0

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


## Etkin emek gucu -- hapsedilenler dusulmus.
func l_etkin() -> float:
	return L_etkin * katilim * (1.0 - minf(0.90, cezaevi_orani))


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
