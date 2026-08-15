class_name KrizParam
extends RefCounted

## Kriz cekirdeginin parametreleri -- HEPSI YILLIK.
##
## Kaynak v4.4-Frozen'in `ParamSet`'idir, ama oradaki degerler TUR BASINAydi
## (1 tur = 0.27 yil). Burada her biri BIR KEZ yilliga cevrilir ve donusum
## TURU yaninda yazilir. Tur yazilmamis parametre, dusunulmemis parametredir.
##
## Neden yillik: donem uzunlugu (haftalik, aylik, turluk) artik yalnizca
## `KrizCekirdegi.adim()`'a verilen bir sayidir. Parametrelerin donem
## uzunlugundan haberi yoktur, dolayisiyla "haftaliga cevirmeyi unutmak"
## diye bir hata sinifi ortadan kalkar. Bkz. `Oran`.
##
## `const` DEGIL `var`: yon testleri parametreleri ORNEK BAZINDA degistirir
## (`p.fin_stok = 0.0` gibi). v4.4'te de boyleydi ve sebebi aynidir.

# ---------------------------------------------------------------------------
# SERMAYE/HASILA KATSAYISI  --  kappa_v(cv, q)
# Hepsi DUZEY: us, katsayi ve doyum parametreleri, zamanla olceklenmezler.
# ---------------------------------------------------------------------------
var kv0: float = 11.0                  ## duzey  (v4.4: 11.0)
var kv_us: float = 0.42                ## duzey  (v4.4: 0.42)
var ucuzlama_max: float = 0.4          ## duzey  (v4.4: 0.4)
var ucuzlama_h: float = 3.5            ## duzey  (v4.4: 3.5)

# ---------------------------------------------------------------------------
# KAPASITE
# ---------------------------------------------------------------------------
var u_normal: float = 0.82             ## duzey  (v4.4: 0.82)

# ---------------------------------------------------------------------------
# OTOMASYON
# `oto_hiz` bir UYUM katsayisidir: oto += hiz * (hedef - oto).
# ---------------------------------------------------------------------------
var oto_esik_era: int = 5              ## duzey  (v4.4: 5)
var oto_tavan: float = 0.8             ## duzey  (v4.4: 0.8)
var oto_canli_taban: float = 0.02      ## duzey  (v4.4: 0.02)
var oto_verim: float = 0.11            ## duzey  (v4.4: 0.11)
var oto_hiz_yil: float = 0.0           ## UYUM   (v4.4 tur: 0.03)
var ito_tavan: float = 1.6             ## duzey  (v4.4: 1.6)

# ---------------------------------------------------------------------------
# BIRIKIM  --  g = g_taban + g_duy*(r - i) + hizlandirici*(u - u_normal)
#
# g_taban : per-donem buyume orani            -> BUYUME
# g_duy   : oran farkini orana cevirir, BOYUTSUZ -> duzey
# hizlandirici : boyutsuz acikligi orana cevirir, birimi [1/donem] -> AKIM
# tavanlar: yillik buyume tavanlari           -> BUYUME
# ---------------------------------------------------------------------------
var g_taban_yil: float = 0.0           ## BUYUME (v4.4 tur: 0.008)
var g_duy: float = 0.42                ## duzey  (v4.4: 0.42)
var hizlandirici_yil: float = 0.0      ## AKIM   (v4.4 tur: 0.09)
var g_tavani_yil: float = 0.0          ## BUYUME (v4.4 tur: 0.04)
var g_daralma_tavani_yil: float = 0.0  ## BUYUME (v4.4 tur: 0.03)

# ---------------------------------------------------------------------------
# TONAK DEGER GASBI
# lumpen/illegalite paylari DUZEY; gasp_varlik bir AKIM katsayisidir.
# ---------------------------------------------------------------------------
var lumpen_carpani: float = 6.0        ## duzey  (v4.4: 6.0)
var lumpen_tavan: float = 0.2          ## duzey  (v4.4: 0.2)
var illegalite_primi: float = 1.8      ## duzey  (v4.4: 1.8)
var gasp_varlik_yil: float = 0.0       ## AKIM   (v4.4 tur: 0.12)

# ---------------------------------------------------------------------------
# MINSKY / SPEKULATIF BALON
# fin_pay, fin_stok, spec_kredi, balon_sonum: donem basina AKIM katsayilari.
# balon_limiti, minsky_esik, beklenti_tavan: DUZEY (esik).
# beklenti_hiz: UYUM.
# ---------------------------------------------------------------------------
var fin_pay_yil: float = 0.0           ## AKIM   (v4.4 tur: 0.55)
var fin_stok_yil: float = 0.0          ## AKIM   (v4.4 tur: 0.045)
var spec_kredi_yil: float = 0.0        ## AKIM   (v4.4 tur: 0.03)
var balon_sonum_yil: float = 0.0       ## AKIM   (v4.4 tur: 0.02)
var balon_limiti: float = 2.2          ## duzey  (v4.4: 2.2)
var minsky_esik: float = 1.55          ## duzey  (v4.4: 1.55)
var beklenti_hiz_yil: float = 0.0      ## UYUM   (v4.4 tur: 0.08)
var beklenti_tavan: float = 0.12       ## duzey  (v4.4: 0.12)

# ---------------------------------------------------------------------------
# URETKENLIK
# ---------------------------------------------------------------------------
var qg_yil: float = 0.0                ## BUYUME (cag tablosundan, tur -> yil)


func _init() -> void:
	# --- v4.4 TUR parametrelerinin yilliga cevrimi. Tek yer, tek sefer. ---
	oto_hiz_yil = Oran.v44_uyum(0.03)

	g_taban_yil = Oran.v44_buyume(0.008)
	hizlandirici_yil = Oran.v44_akim(0.09)
	g_tavani_yil = Oran.v44_buyume(0.04)
	g_daralma_tavani_yil = Oran.v44_buyume(0.03)

	gasp_varlik_yil = Oran.v44_akim(0.12)

	fin_pay_yil = Oran.v44_akim(0.55)
	fin_stok_yil = Oran.v44_akim(0.045)
	spec_kredi_yil = Oran.v44_akim(0.03)
	balon_sonum_yil = Oran.v44_akim(0.02)
	beklenti_hiz_yil = Oran.v44_uyum(0.08)


## Cag tablosundaki tur basina uretkenlik buyumesini yilliga cevirip yazar.
func cag_uygula(era: int) -> void:
	var e: Dictionary = Tables.ERAS[clampi(era, 1, 6)]
	qg_yil = Oran.v44_buyume(float(e["qg"]))
