class_name KrizDurumu
extends RefCounted

## Kriz cekirdeginin uzerinde calistigi ulke durumu.
##
## v4.4'un `Country`'si ~120 alan tasiyordu; buna savas, ittifak, politika
## kuyrugu, diplomasi ve raporlama alanlari dahildi. Burada YALNIZCA deger
## katmaninin okudugu/yazdigi alanlar var. Geri kalan v2'de mikro katmanin
## (eyalet, pop, bina, mal piyasasi) isidir ve buraya toplam olarak girer.
##
## BIRIM SOZLESMESI -- v4.4'ten en onemli ayrilik:
##   Butun AKIM buyuklukleri YILLIKTIR (`Y_yil`, `V_yil`, `s_yil`, `r_yil`).
##   Butun STOK buyuklukleri duzeydir (`K`, `borc`, `varlik`).
## v4.4'te akimlar TUR basinaydi ve bu, donem uzunlugu degisince sessizce
## yanlislasan tek seydi. Yillik sabitlemek o hatayi imkansiz kilar.

# ---------------------------------------------------------------------------
# MIKRO KATMANDAN GELEN TOPLAMLAR  (v2'de bina/pop/piyasa uretir)
# B0'da elle verilir; B2'de kuplaj baglanir.
# ---------------------------------------------------------------------------
var K: float = 1.0                ## sermaye stoku (STOK)
var L_etkin: float = 1.0          ## etkin emek gucu (kisi)
var hafta_saati: float = 1.0      ## kisi basi haftalik emek-saati normu
var pay: float = 0.5              ## ucret payi [0,1]
var e: float = 0.9                ## istihdam orani [0,1]
var u: float = 0.82               ## kapasite kullanimi [0,1]
var era: int = 1                  ## cag (uretkenlik rejimi)
var ito: float = 1.0              ## mekanizasyon durtusu

# ---------------------------------------------------------------------------
# CEKIRDEGIN KENDI DURUMU
# ---------------------------------------------------------------------------
var q: float = 1.0                ## uretkenlik
var oto: float = 0.0              ## otomasyon payi [0, oto_tavan]
var canli_pay: float = 1.0        ## canli emegin fiziksel hasiladaki payi
var varlik: float = 0.0           ## spekulatif varlik stoku (STOK)
var varlik_beklenti: float = 0.0  ## ekstrapolatif getiri beklentisi
var minsky_sayac: int = 0
var uyusturucu_orani: float = 0.0 ## karanlik devlet kolu (B2b)
var i_yil: float = 0.04           ## efektif faiz (YILLIK)
var i_spec_yil: float = 0.04      ## spekulatif finansman maliyeti (YILLIK)

# ---------------------------------------------------------------------------
# CEKIRDEGIN URETTIKLERI  (salt okunur cikti)
# ---------------------------------------------------------------------------
var cv: float = 1.0               ## organik bilesim c/v
var kv: float = 11.0              ## sermaye/hasila katsayisi
var Y_yil: float = 0.0            ## fiziksel hasila (YILLIK AKIM)
var V_yil: float = 0.0            ## yeni deger (YILLIK AKIM)
var s_yil: float = 0.0            ## arti deger (YILLIK AKIM)
var r_yil: float = 0.0            ## KAR ORANI (YILLIK)
var g_yil: float = 0.0            ## net birikim orani (YILLIK)
var gasp: float = 0.0             ## Tonak deger gasbi (YILLIK AKIM)
var lumpen_pay: float = 0.0


## Kosu boyunca degismeyecek baslangic durumunun kopyasi -- olcek testi ayni
## noktadan iki farkli donem uzunluguyla kosabilsin diye.
func kopya() -> KrizDurumu:
	var y := KrizDurumu.new()
	for alan in [
		"K", "L_etkin", "hafta_saati", "pay", "e", "u", "era", "ito",
		"q", "oto", "canli_pay", "varlik", "varlik_beklenti", "minsky_sayac",
		"uyusturucu_orani", "i_yil", "i_spec_yil",
		"cv", "kv", "Y_yil", "V_yil", "s_yil", "r_yil", "g_yil", "gasp",
		"lumpen_pay",
	]:
		y.set(alan, get(alan))
	return y
