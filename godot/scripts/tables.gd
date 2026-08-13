extends Node

# =============================================================
# BU DOSYA URETILMISTIR -- ELLE DUZENLEMEYIN.
# Kaynak : docs/hayalet_ekonomisi_v44_frozen.md (tek dogruluk kaynagi)
#          -> python/hayalet_ekonomi_motoru_v43.py
# Ureten : tools/gen_gdscript.py
# Yeniden uretmek icin: python tools/gen_gdscript.py
# =============================================================

## Motorun veri tablolari: teknolojik caglar, kurumsal rejimler, plan
## profilleri ve dunya tohum tablosu. Otoload sirasinda Params'tan sonra,
## Save'den once gelir.

## Teknolojik caglar. `yil_alt`/`yil_ust` TARIHSEL BANTTIR: cag atlama
## icseldir (q > q_esik) ama banda cakilidir -- hizli gelisen bir oyuncu
## 1900'de tam otomasyona varamaz, geri kalan dunya da 2100'de buhar
## caginda kalmaz.
const ERAS := {1: {"name": "1.0 Buhar", "cv": 1.0, "qg": 0.0045, "pke": 0.2, "q_esik": 0.0, "q_tavan": 4.0, "kent": 0.15, "yil_alt": 1760, "yil_ust": 1760}, 2: {"name": "2.0 Elektrik", "cv": 2.2, "qg": 0.0075, "pke": 0.35, "q_esik": 2.6, "q_tavan": 8.0, "kent": 0.45, "yil_alt": 1840, "yil_ust": 1905}, 3: {"name": "3.0 Otomasyon", "cv": 3.8, "qg": 0.0095, "pke": 0.5, "q_esik": 5.2, "q_tavan": 17.0, "kent": 0.65, "yil_alt": 1925, "yil_ust": 1975}, 4: {"name": "4.0 Siber-fiz.", "cv": 6.0, "qg": 0.012, "pke": 0.75, "q_esik": 10.5, "q_tavan": 36.0, "kent": 0.78, "yil_alt": 1980, "yil_ust": 2015}, 5: {"name": "5.0 Insan-YZ", "cv": 9.5, "qg": 0.0145, "pke": 0.9, "q_esik": 21.0, "q_tavan": 80.0, "kent": 0.86, "yil_alt": 2000, "yil_ust": 2030}, 6: {"name": "6.0 Tam otom.", "cv": 15.0, "qg": 0.0175, "pke": 0.98, "q_esik": 42.0, "q_tavan": 200.0, "kent": 0.92, "yil_alt": 2072, "yil_ust": 2088}}

## Kurumsal rejimler. `hizlandirici` ve `kars_dongusel` ulkelerin krize
## farkli tepki vermesini saglayan asgari mekanizmadir.
const KURUMLAR := {"liberal": {"devlet": 0.45, "kredi": 0.55, "finans": 0.85, "org_eroz": 1.0, "emek_pay": 0.45, "sermaye_hareketi": 1.25, "vt_baris": 0.6, "v_ucret": 0.05, "v_kar": 0.08, "kamu_hedef": 0.05, "egitim_pay": 0.04, "hizlandirici": 0.1, "kars_dongusel": 0.6}, "duzenli": {"devlet": 1.15, "kredi": 0.45, "finans": 0.35, "org_eroz": 0.35, "emek_pay": 0.85, "sermaye_hareketi": 0.45, "vt_baris": 1.25, "v_ucret": 0.22, "v_kar": 0.42, "kamu_hedef": 0.28, "egitim_pay": 0.13, "hizlandirici": 0.045, "kars_dongusel": 1.7}, "neoliberal": {"devlet": 0.8, "kredi": 1.35, "finans": 1.3, "org_eroz": 1.85, "emek_pay": 0.4, "sermaye_hareketi": 1.35, "vt_baris": 0.85, "v_ucret": 0.2, "v_kar": 0.24, "kamu_hedef": 0.08, "egitim_pay": 0.1, "hizlandirici": 0.2, "kars_dongusel": 0.25}}

## Sosyalist plan profilleri (paylar RAKIP kullanimlardir: biri artarsa
## digeri azalir).
const PLAN_PROFILLERI := {"sanayilesmeci": {"yatirim": 0.46, "tuketim": 0.32, "arge": 0.14, "savunma": 0.08}, "tuketimci": {"yatirim": 0.18, "tuketim": 0.72, "arge": 0.06, "savunma": 0.04}, "dengeli": {"yatirim": 0.3, "tuketim": 0.55, "arge": 0.1, "savunma": 0.05}}

## Dunya tohum tablosu: ad, tip, K, L_max, q, pay, IR, baski_egilimi,
## saldirganlik. `dunya_kur()` bu satirlardan Country uretir.
const ULKE_ALANLARI := ["ad", "tip", "K", "L_max", "q", "pay", "IR", "baski_egilimi", "saldirganlik"]
const ULKELER := [["ABD", "merkez", 320, 110, 1.0, 0.52, 0.35, 0.4, 0.85], ["Almanya", "merkez", 210, 75, 0.98, 0.55, 0.42, 0.3, 0.55], ["Ingiltere", "merkez", 185, 62, 0.95, 0.54, 0.38, 0.45, 0.65], ["Fransa", "merkez", 175, 62, 0.94, 0.56, 0.48, 0.25, 0.5], ["Japonya", "merkez", 170, 72, 0.91, 0.5, 0.5, 0.45, 0.6], ["Italya", "yari", 130, 58, 0.83, 0.51, 0.52, 0.35, 0.45], ["Kanada", "merkez", 110, 38, 0.93, 0.55, 0.35, 0.3, 0.2], ["Avustralya", "merkez", 95, 33, 0.91, 0.55, 0.35, 0.3, 0.2], ["G.Kore", "yari", 100, 52, 0.81, 0.44, 0.42, 0.55, 0.35], ["Rusya", "yari", 130, 82, 0.7, 0.4, 0.6, 0.7, 0.8], ["Cin", "cevre", 140, 220, 0.58, 0.31, 0.55, 0.7, 0.6], ["Hindistan", "cevre", 85, 200, 0.42, 0.26, 0.58, 0.5, 0.45], ["Brezilya", "cevre", 85, 92, 0.55, 0.34, 0.52, 0.45, 0.25], ["Meksika", "cevre", 70, 78, 0.52, 0.32, 0.52, 0.45, 0.2], ["Endonezya", "cevre", 55, 98, 0.4, 0.25, 0.52, 0.5, 0.25], ["Turkiye", "cevre", 65, 62, 0.53, 0.339, 0.58, 0.6, 0.5], ["S.Arabistan", "cevre", 80, 28, 0.62, 0.35, 0.65, 0.75, 0.5], ["G.Afrika", "cevre", 50, 56, 0.45, 0.28, 0.52, 0.45, 0.25], ["Arjantin", "cevre", 55, 48, 0.52, 0.33, 0.58, 0.4, 0.25], ["AB-blok", "merkez", 145, 58, 0.94, 0.55, 0.48, 0.25, 0.4]]


## c/v capalari: her cagin c/v'si o caga giris esigindeki q ile eslesir.
## Python tarafinda ayni sekilde ERAS'tan TURETILIR, ayri yazilmaz --
## iki tablonun birbirinden kaymasi boylece imkansiz olur.
##
## BIR KEZ kurulup onbellege alinir. `organik_bilesim` bunu tur basina
## ~60 kez cagiriyor; her cagrida yeniden kurmak (sozluk anahtarlarini
## siralayip 6 dizi ayirmak) kampanya suresinin buyuk kismini yiyordu.
static var _cv_capalari_onbellek: Array = []

static func cv_capalari() -> Array:
	if not _cv_capalari_onbellek.is_empty():
		return _cv_capalari_onbellek
	var out := []
	var anahtarlar := ERAS.keys()
	anahtarlar.sort()
	for e in anahtarlar:
		out.append([maxf(ERAS[e]["q_esik"], 0.5), float(ERAS[e]["cv"])])
	_cv_capalari_onbellek = out
	return out
