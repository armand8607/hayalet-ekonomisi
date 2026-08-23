class_name UretimTesti
extends RefCounted

## B2a KAPISI -- mikro uretim katmani.
##
## ------------------------------------------------------------------------
## NEDEN YENI BIR OLCUT GEREKTI
## ------------------------------------------------------------------------
## Tasarim belgesi §6, B2'nin olcutunu soyle yaziyordu: "Mikro toplamlar
## deger katmanini besler; `--v2-tarih` hala gecer." Bu olcut AYIRT ETMEZ --
## ve bunu daha once bir kez yasadik. B1b'nin olcutu de `--v2-tarih` idi ve
## §6'da soyle kapatildi:
##
##   "O test B1b baslamadan geciyor, dolayisiyla B1b'nin bittigini
##    soyleyemez. Bir kapi her iki durumda da yesilse kapi degildir."
##
## `--v2-tarih` su anda, mikro katman hic yokken geciyor. Dolayisiyla B2'nin
## bittigini de soyleyemez. Regresyon olarak degerlidir, KAPI olarak degil.
##
## ------------------------------------------------------------------------
## AYIRT EDEN OLCUT: §2.4'un tersine cevrilen mantigi
## ------------------------------------------------------------------------
## Mikro katman OLMADAN TANIMSIZ olan tek iddia sudur:
##
##   > Tek tek binalar karli gorunurken toplam kar orani duser.
##
## Bu, oyunun merkezi tuzagidir (§2.4) ve iki katman birden gerektirir:
## "bina karliligi" bir mikro buyukluk, "toplam kar orani" bir makro
## buyukluk. Tek katmanli bir motorda cumle KURULAMAZ bile. B1b'nin ucuncu
## maddesi ("tek ulkede tanimsizdir") ile ayni turden bir olcuttur ve ayni
## sebeple gecerlidir.
##
## Tasarim B1b'den devralindi: KARSI-OLGUSAL. Ayni tohum, ayni dunya,
## yukseltme kolu acik ve kapali. Kesitsel karsilastirma mekanizmanin
## etkisiyle yapisal farki karistirir ve B1b'de bir kez yanlis sonuc verdi.
##
## ------------------------------------------------------------------------
## UC KADEME
## ------------------------------------------------------------------------
##   1. OZDESLIK -- mikro toplamlar cekirdegin kapali formunu ozel durum
##      olarak icerir; sermaye stoku kampanya boyunca ayrismaz
##   2. TUZAK    -- mikro marj YUKSELIRKEN makro r DUSER (asil kapi)
##   3. MERDIVEN -- basamaklar gercekten tirmanilir, cag kapilari baglar

const HAFTA := 1.0 / 52.0
const BAS := 1836.0
const BITIS := 2036.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


## `OlcekTesti._baslangic()` ile AYNI durum. Bilerek kopyalanmadi diye ayri
## yazilmadi: iki kapi ayni baslangictan kosmali ki biri kirildiginda sebep
## baslangic farki olmasin.
static func _baslangic() -> KrizDurumu:
	var d := KrizDurumu.new()
	d.K = 320.0
	d.L_etkin = 110.0
	d.hafta_saati = 1.0
	d.pay = 0.52
	d.e = 0.90
	d.u = 0.82
	d.era = 2
	d.ito = 1.0
	d.q = 1.0
	d.oto = 0.0
	d.varlik = 0.5
	d.i_yil = 0.04
	d.i_spec_yil = 0.05
	d.yil = BAS
	return d


## Bir kampanya kosar.
##
## `yukseltme` kapaliyken merdiven donar: butun binalar 0. basamakta kalir,
## yani TEKNIK DEGISME OLMAYAN dunya. Marx'in karsilastirmasi tam olarak
## budur ve LTRPF iddiasinin karsi-olgusal kolu odur.
static func _kos(yukseltme: bool, tohum: int = 42) -> Dictionary:
	var d := _baslangic()
	var cekirdek := KrizCekirdegi.new(null, tohum)
	cekirdek.baslat(d)

	var m := UretimKatmani.new()
	m.baslat(d)
	if not yukseltme:
		m.yukseltme_payi = 0.0
	cekirdek.mikro = m

	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var r_top := 0.0
	var marj_top := 0.0
	var cv_top := 0.0
	var agirlik := 0.0
	var ozdeslik_hata := 0.0
	var marj_ozdeslik_hata := 0.0

	for _i in range(n):
		cekirdek.adim(d, HAFTA)
		# SERMAYE OZDESLIGI her adimda olculur. Kampanya sonunda bakmak
		# yetmez: iki katman arada ayrisip sonra tesadufen yakinsayabilir,
		# ve o durumda hata "yok" gorunur. B1b'nin korunum olcumu de her
		# adimda aliniyor, ayni sebeple.
		ozdeslik_hata = maxf(ozdeslik_hata,
				absf(m.K_toplam() - d.K) / maxf(absf(d.K), 1e-12))
		var marj := _marj_ort(m, d)
		marj_ozdeslik_hata = maxf(marj_ozdeslik_hata,
				absf(marj - m.marj_ortalama(d)))
		r_top += d.r_yil * HAFTA
		cv_top += d.cv * HAFTA
		marj_top += marj * HAFTA
		agirlik += HAFTA

	var oncu := 0.0
	for f in m.oncu_farklari:
		oncu += f

	return {
		"d": d,
		"m": m,
		"r_ort": r_top / maxf(agirlik, 1e-9),
		"cv_ort": cv_top / maxf(agirlik, 1e-9),
		"marj_ort": marj_top / maxf(agirlik, 1e-9),
		"ozdeslik_hata": ozdeslik_hata,
		"marj_ozdeslik_hata": marj_ozdeslik_hata,
		"oncu_ort": oncu / maxf(float(m.oncu_farklari.size()), 1.0),
		"oncu_sayi": m.oncu_farklari.size(),
		"q_son": d.q,
		"cv_son": d.cv,
		"r_son": d.r_yil,
		"yukseltme": m.yukseltme_sayisi,
	}


## Binalarin SERMAYE AGIRLIKLI ortalama mikro marji -- BINALARDAN sayarak.
##
## `UretimKatmani.marj_ortalama()` bunun `1 - pay`e esit oldugunu iddia
## ediyor. O iddia cebirsel ama BU FONKSIYON onu bagimsiz olarak yeniden
## hesaplar, boylece ozdeslik varsayilmaz OLCULUR. Formulun kendisi degisirse
## (ornegin B2b'de sektor bazli ucret gelirse) test once kirilir, kod sonra.
##
## Agirlik sermayedir cunku kapitalistin gordugu sey budur: kucuk bir
## atolyenin yuksek marji, buyuk bir fabrikanin dusuk marjini telafi etmez.
static func _marj_ort(m: UretimKatmani, d: KrizDurumu) -> float:
	var ucret := m._birim_ucret(d)
	var t := 0.0
	var top_K := 0.0
	for b in m.binalar:
		t += b.K * m.mikro_marj(b, ucret)
		top_K += b.K
	if top_K <= 1e-12:
		return 0.0
	return t / top_K


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("=".repeat(66))
	print("v2 MIKRO URETIM KATMANI  (B2a)   %d-%d, haftalik" % [int(BAS), int(BITIS)])
	print("=".repeat(66))

	# -----------------------------------------------------------------
	print("\n--- 1. toplama ozdesligi (kurulus) ---")
	var d0 := _baslangic()
	var c0 := KrizCekirdegi.new()
	c0.baslat(d0)
	var m0 := UretimKatmani.new()
	m0.baslat(d0)

	var hK := absf(m0.K_toplam() - d0.K) / maxf(d0.K, 1e-12)
	var hq := absf(m0.q_toplam() - d0.q) / maxf(d0.q, 1e-12)
	var hkap := absf(m0.kapasite_toplam(d0.kv) - d0.K / d0.kv) / maxf(d0.K / d0.kv, 1e-12)
	print("  sum(bina.K)      = %.10f   d.K = %.10f" % [m0.K_toplam(), d0.K])
	print("  q_toplam()       = %.10f   d.q = %.10f" % [m0.q_toplam(), d0.q])
	print("  kapasite_toplam  = %.10f   K/kv = %.10f" % [
			m0.kapasite_toplam(d0.kv), d0.K / d0.kv])
	print("  bina sayisi      = %d,  pay_I = %.4f,  oto = %.4f" % [
			m0.binalar.size(), m0.pay_I_toplam(), m0.oto_toplam()])
	_dogrula(hK < 1e-12, "sermaye toplami OZDES", "(bagil hata %s)" % _bilimsel(hK))
	_dogrula(hq < 1e-12, "duz merdivende q OZDES", "(bagil hata %s)" % _bilimsel(hq))
	_dogrula(hkap < 1e-12, "kapasite toplami OZDES", "(bagil hata %s)" % _bilimsel(hkap))
	_dogrula(m0.oto_toplam() == 0.0, "duz merdivende otomasyon sifir", "")

	# -----------------------------------------------------------------
	print("\n--- 2. sermaye ozdesligi kampanya boyunca ---")
	var acik := _kos(true)
	var kapali := _kos(false)
	print("  yukseltme ACIK   : en buyuk bagil sapma %s" % _bilimsel(acik["ozdeslik_hata"]))
	print("  yukseltme KAPALI : en buyuk bagil sapma %s" % _bilimsel(kapali["ozdeslik_hata"]))
	_dogrula(float(acik["ozdeslik_hata"]) < 1e-9,
			"sermaye stoku kampanya boyunca ayrismiyor (acik)",
			"(%s)" % _bilimsel(acik["ozdeslik_hata"]))
	_dogrula(float(kapali["ozdeslik_hata"]) < 1e-9,
			"sermaye stoku kampanya boyunca ayrismiyor (kapali)",
			"(%s)" % _bilimsel(kapali["ozdeslik_hata"]))

	# -----------------------------------------------------------------
	print("\n--- 3. merdiven tirmaniliyor mu ---")
	var mm: UretimKatmani = acik["m"]
	print("  yukseltme sayisi : %d" % int(acik["yukseltme"]))
	print("  q  : %.4f -> %.4f" % [1.0, float(acik["q_son"])])
	print("  sektor        basamak       q         sermaye")
	for satir in mm.basamak_dagilimi():
		print("      %-10s %5d %9.3f %13.1f" % [
				satir["sektor"], int(satir["basamak"]),
				float(satir["q"]), float(satir["K"])])
	_dogrula(int(acik["yukseltme"]) > 0, "yukseltme atesleniyor",
			"(%d kez)" % int(acik["yukseltme"]))
	_dogrula(int(kapali["yukseltme"]) == 0, "kol kapaliyken hic yukseltme yok", "")
	_dogrula(float(acik["q_son"]) > 1.0, "q merdivenden yukseldi",
			"(%.3f)" % float(acik["q_son"]))
	_dogrula(absf(float(kapali["q_son"]) - 1.0) < 1e-12,
			"kol kapaliyken q SABIT (teknik degisme yok)",
			"(%.6f)" % float(kapali["q_son"]))

	# -----------------------------------------------------------------
	print("\n--- 4. ONCU KARI: kazanc once davranana ve GECICI ---")
	print("  yukseltme sayisi        : %d" % int(acik["oncu_sayi"]))
	print("  ort. oncu farki         : %+.6f  (marj - ulke ortalamasi)" % float(acik["oncu_ort"]))
	_dogrula(float(acik["oncu_ort"]) > 0.0,
			"ONCU KARI POZITIF -- yukselten bina ortalamanin USTUNE cikiyor",
			"(%+.6f)" % float(acik["oncu_ort"]))

	# -----------------------------------------------------------------
	print("\n--- 5. ORTALAMA MARJ TEKNIKTEN BAGIMSIZ (ozdeslik) ---")
	print("  ort(marj) ile (1 - pay) arasindaki en buyuk sapma:")
	print("    yukseltme ACIK   : %s" % _bilimsel(float(acik["marj_ozdeslik_hata"])))
	print("    yukseltme KAPALI : %s" % _bilimsel(float(kapali["marj_ozdeslik_hata"])))
	_dogrula(float(acik["marj_ozdeslik_hata"]) < 1e-12,
			"ort(marj) == 1-pay OZDES (acik)",
			"(%s)" % _bilimsel(float(acik["marj_ozdeslik_hata"])))
	_dogrula(float(kapali["marj_ozdeslik_hata"]) < 1e-12,
			"ort(marj) == 1-pay OZDES (kapali)",
			"(%s)" % _bilimsel(float(kapali["marj_ozdeslik_hata"])))

	# -----------------------------------------------------------------
	print("\n--- 6. §2.4 TUZAGI (karsi-olgusal: ayni tohum, kol acik/kapali) ---")
	print("                        KAPALI      ACIK      degisim")
	print("  ort. mikro marj   %10.6f %10.6f %+10.6f" % [
			float(kapali["marj_ort"]), float(acik["marj_ort"]),
			float(acik["marj_ort"]) - float(kapali["marj_ort"])])
	print("  ort. kar orani r  %10.6f %10.6f %+10.6f" % [
			float(kapali["r_ort"]), float(acik["r_ort"]),
			float(acik["r_ort"]) - float(kapali["r_ort"])])
	print("  ort. c/v          %10.6f %10.6f %+10.6f" % [
			float(kapali["cv_ort"]), float(acik["cv_ort"]),
			float(acik["cv_ort"]) - float(kapali["cv_ort"])])

	var d_marj := float(acik["marj_ort"]) - float(kapali["marj_ort"])
	var d_r := float(acik["r_ort"]) - float(kapali["r_ort"])
	var d_cv := float(acik["cv_ort"]) - float(kapali["cv_ort"])

	_dogrula(d_cv > 0.0, "yukseltme c/v'yi YUKSELTIYOR", "(%+.4f)" % d_cv)
	_dogrula(d_r < 0.0,
			"MAKRO: yukseltme toplam kar oranini DUSURUYOR", "(%+.6f)" % d_r)
	# Asil iddia: kayip makro defterde var, mikro defterde YOK. Marj farki
	# r farkinin yaninda kaybolmali -- olcut oran cinsindendir cunku ikisi
	# ayni birimde degil ve mutlak esik ikisini kiyaslayamaz.
	var gorunmezlik := absf(d_marj) / maxf(absf(d_r), 1e-12)
	_dogrula(gorunmezlik < 0.5,
			"MIKRO: ayni kayip bina defterinde GORUNMUYOR",
			"(|marj|/|r| = %.3f)" % gorunmezlik)
	_dogrula(d_r < 0.0 and float(acik["oncu_ort"]) > 0.0 and gorunmezlik < 0.5,
			"§2.4 TUZAGI OLCULDU -- kazanc oncunun, kayip herkesin, "
			+ "ve kayip karar defterinde yazmiyor", "")

	# -----------------------------------------------------------------
	print("\n" + "-".repeat(66))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


static func _bilimsel(x: float) -> String:
	return String.num_scientific(x)


# ===========================================================================
# TESHIS IZI  --  mikro kolu ile kapali form yan yana
# ===========================================================================

## Devrim mikro katmanla ~20 yil erken geliyor. Sebebini ARAMAK icin, iddia
## etmek icin degil.
##
## Devrim `PR = sg(kappa*(b_pay*(1-pay) + b_iss*iss - theta))` uzerinden
## gelir, yani YALNIZCA `pay` ve `e`'ye bakar. Ikisi de hala cekirdekte;
## mikro katman onlari dogrudan yazmiyor. O halde etki dolayli olmali:
## `q` -> `Y_L` -> `e` -> Goodwin -> `pay`. Bu iz o zinciri gorunur kilar.
##
## `--v2-tarih` ile ayni baslangici kullanir (cag 1, 1825), yoksa olculen
## sey devrim tarihi degil baslangic farki olur.
static func iz() -> int:
	print("=".repeat(78))
	print("MIKRO KOL ILE KAPALI FORM YAN YANA   (--v2-tarih baslangici, tohum 42)")
	print("=".repeat(78))

	var kollar := {}
	for mikro_acik in [false, true]:
		var d := KrizDurumu.new()
		d.L_etkin = 110.0
		d.pay = 0.52
		d.era = 1
		d.q = 1.0
		d.yil = 1825.0
		d.varlik = 0.5
		var c := KrizCekirdegi.new(null, 42)
		c.baslat(d)
		if mikro_acik:
			var m := UretimKatmani.new()
			m.baslat(d)
			c.mikro = m
		var satirlar := []
		var n := Oran.donem_sayisi(198.0, HAFTA)
		var sonraki := 1825.0
		for _i in range(n):
			c.adim(d, HAFTA)
			if d.yil >= sonraki:
				satirlar.append({
					"yil": d.yil, "q": d.q, "e": d.e, "pay": d.pay,
					"r": d.r_yil, "Omega": d.Omega, "PR": d.PR,
					"era": d.era, "org": d.org, "gerg": d.emek_gerginlik,
					"devrim": d.devrim_yil,
				})
				sonraki += 20.0
		kollar[mikro_acik] = {"satirlar": satirlar, "devrim": d.devrim_yil}

	print("\n  yil |          KAPALI FORM              |         MIKRO KATMAN")
	print("      |   q     e    pay    r    PR  cag |   q     e    pay    r    PR  cag")
	print("  " + "-".repeat(74))
	var a: Array = kollar[false]["satirlar"]
	var b: Array = kollar[true]["satirlar"]
	for i in range(mini(a.size(), b.size())):
		var x: Dictionary = a[i]
		var y: Dictionary = b[i]
		print("  %4d | %5.2f %5.3f %5.3f %6.4f %5.3f %2d | %5.2f %5.3f %5.3f %6.4f %5.3f %2d" % [
				int(x["yil"]),
				x["q"], x["e"], x["pay"], x["r"], x["PR"], int(x["era"]),
				y["q"], y["e"], y["pay"], y["r"], y["PR"], int(y["era"])])

	print("\n  devrim yili : kapali form %.0f,  mikro katman %.0f"
			% [float(kollar[false]["devrim"]), float(kollar[true]["devrim"])])
	print("\n  OKUMA. PR yalnizca `pay` ve `e`'ye bakar. Iki kolda hangisinin")
	print("  once ayristigi, etkinin hangi zincirden geldigini soyler:")
	print("    `e` once ayrisiyorsa  -> q -> Y_L -> istihdam kanali")
	print("    `pay` once ayrisiyorsa -> Goodwin/emek gerginligi kanali")
	return 0


# ===========================================================================
# KALIBRASYON TARAMASI  --  ayri kapi, ana testten yavas
# ===========================================================================

## `yukseltme_maliyeti` ne olmali?
##
## CAPA. Elimizdeki tek ampirik capa cekirdegin KAPALI FORMUDUR: o
## kalibrasyon `--v2-olcek` (23/23) ve `--v2-tarih` kapilarindan geciyor,
## yani uretkenligin buyume hizi bu motorda zaten sinanmis durumda. Mikro
## katman onu YENIDEN URETMELI -- daha hizli olursa LTRPF erken doyar, daha
## yavas olursa kriz makinesi hic olgunlasmaz.
##
## Bu, B1b'de `vt_siddet` icin kullanilan gerekcenin aynisidir: yeni
## mekanizmanin agirligi keyfi secilemez, var olan ve sinanmis bir olcume
## oturtulur.
##
## ------------------------------------------------------------------------
## IKI KEZ DUZELTILDI -- ilk tasarim yanlis seyi olcuyordu
## ------------------------------------------------------------------------
## 1. YANLIS KONFIGURASYON. Tarama once bu dosyanin kendi baslangicindan
##    (1836, cag 2) kosuyordu; oysa uzerinde karar verilen olcut
##    `--v2-tarih`tir ve o 1825'te CAG 1'den baslar. Cag 1'in `q_tavan`i 4.0,
##    cag 2'ninki 8.0 -- yani merdivenin tavani bastan farkli. Baska bir
##    kurulumda kalibre edilen sabit, karar verilen kurulumda gecerli degildir.
##
## 2. YANLIS OLCU. Yalnizca UC NOKTA (q(2036)) karsilastiriliyordu. Olculdu
##    (`--v2-uretim-iz`): uc nokta 0.88 oraniyla capaya yakin cikarken
##    YORUNGE tamamen ayrisiyordu -- mikro kol 1865'te 2.59'a, kapali form
##    1.58'e varmisti, yani erken on yillarda IKI KAT hizli. Sonucu devrimin
##    20 yil erkene kaymasiydi: q erken buyuyunce cagin `q_esik`i erken
##    asiliyor, cag gecisi erken oluyor, her gecis `Omega`yi zipliyor.
##    Bir egriyi tek noktadan eslestirmek onu eslestirmez.
##
## Olcu artik yirmi yillik orneklerin ORTALAMA LOG SAPMASIDIR.
static func tarama() -> int:
	print("=".repeat(72))
	print("MERDIVEN TARAMASI   (capa: kapali form, --v2-tarih kurulumu, 1825-2100)")
	print("=".repeat(72))

	# PENCERE 2100'E UZATILDI. Onceki tarama 1985'te bitiyordu ve tam da bu
	# yuzden asil sapmayi GOREMIYORDU: iki kol erken on yillarda yakin
	# duruyor, ayrisma gec kampanyada aciliyor. Oyunun ufku 2100 oldugu
	# icin olcut de oraya kadar bakmali (B5'in harita kapisi bunu bir
	# "otomasyon hic baslamiyor" bulgusu olarak yakaladi).
	var ornek_yillari := [1845.0, 1865.0, 1885.0, 1905.0, 1925.0, 1945.0,
			1965.0, 1985.0, 2005.0, 2025.0, 2045.0, 2065.0, 2085.0]

	var capa := _yorunge(-1.0, ornek_yillari)
	print("\n  CAPA (mikro yok): devrim %.0f, ort r %.5f, q(2085) %.1f, oto %.3f, iss %.3f" % [
			float(capa["devrim"]), float(capa["r_ort"]),
			float(capa["q"][capa["q"].size() - 1]), float(capa["oto"]),
			float(capa["iss"])])
	print("  q yorungesi:  " + _yorunge_yaz(capa["q"]))

	print("\n  --- 1. BEDEL (cag kuplaji KAPALI) ---")
	print("  maliyet  yukselt   log-sapma   devrim   ort r   q(1885)  q(2085)   oto")
	print("  " + "-".repeat(72))
	for maliyet in [0.05, 0.10, 0.20, 0.35]:
		_tarama_satiri(capa, float(maliyet), 0.0, ornek_yillari)

	print("\n  --- 2. CAG KUPLAJI (bedel 0.10 sabit) ---")
	print("  esneklik yukselt   log-sapma   devrim   ort r   q(1885)  q(2085)   oto   iss")
	print("  " + "-".repeat(80))
	var en_iyi := 0.0
	var en_iyi_fark := INF
	for esneklik in [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.2, 1.5]:
		var sapma := _tarama_satiri(capa, 0.10, float(esneklik), ornek_yillari)
		if sapma < en_iyi_fark:
			en_iyi_fark = sapma
			en_iyi = float(esneklik)

	print("\n  capaya en yakin esneklik: %.2f  (ortalama log sapma %.3f)"
			% [en_iyi, en_iyi_fark])

	# ORTAK TARAMA. Iki dial ayni egrinin FARKLI ucunu tutuyor: bedel erken
	# on yillari, esneklik gec kampanyayi. Ayri ayri tarandiklarinda ikisi
	# de "iyi" gorunur ama birlikte en iyi noktayi kaciririz.
	print("\n  --- 3. ORTAK (bedel x esneklik) ---")
	print("  bedel  esnek  yukselt  log-sapma  devrim   ort r   q(1885) q(2085)   oto")
	print("  " + "-".repeat(74))
	var en_b := 0.0
	var en_e := 0.0
	var en_f := INF
	for maliyet in [0.08, 0.10, 0.13, 0.17]:
		for esneklik in [0.8, 1.0, 1.2]:
			var kol := _yorunge(float(maliyet), ornek_yillari, float(esneklik))
			var q: Array = kol["q"]
			var q0: Array = capa["q"]
			var sapma := 0.0
			for i in range(mini(q.size(), q0.size())):
				sapma += absf(log(maxf(float(q[i]), 1e-9) / maxf(float(q0[i]), 1e-9)))
			sapma /= maxf(float(q.size()), 1.0)
			if sapma < en_f:
				en_f = sapma
				en_b = float(maliyet)
				en_e = float(esneklik)
			print("  %5.2f %6.2f %8d %10.3f %7.0f %8.5f %8.2f %7.1f %6.3f" % [
					float(maliyet), float(esneklik), int(kol["yukseltme"]),
					sapma, float(kol["devrim"]), float(kol["r_ort"]),
					float(q[2]), float(q[q.size() - 1]), float(kol["oto"])])
	print("\n  ORTAK EN IYI: bedel %.2f, esneklik %.2f (log sapma %.3f)"
			% [en_b, en_e, en_f])
	print("\n  NOT: bu bir kapi degil TANIDIR. Secim tasarim belgesine yazilir;")
	print("       kod varsayilani elle guncellenir, tarama otomatik degistirmez.")
	return 0


## Tarama tablosunun bir satiri. Doner: ortalama log sapma.
static func _tarama_satiri(capa: Dictionary, maliyet: float, esneklik: float,
		ornek_yillari: Array) -> float:
	var kol := _yorunge(maliyet, ornek_yillari, esneklik)
	var q: Array = kol["q"]
	var q0: Array = capa["q"]
	# LOGARITMIK: q bilesik buyudugu icin "iki kat hizli" ile "yari hizli"
	# ayni uzaklikta olmali. Dogrusal fark alsaydik tarama sistematik
	# olarak yavas adaylari secerdi.
	var sapma := 0.0
	for i in range(mini(q.size(), q0.size())):
		sapma += absf(log(maxf(float(q[i]), 1e-9) / maxf(float(q0[i]), 1e-9)))
	sapma /= maxf(float(q.size()), 1.0)
	print("  %7.2f %8d %11.3f %8.0f %8.5f %8.2f %8.1f %6.3f %5.3f" % [
			esneklik if esneklik > 0.0 or maliyet == 0.10 else maliyet,
			int(kol["yukseltme"]), sapma, float(kol["devrim"]),
			float(kol["r_ort"]),
			float(q[2]) if q.size() > 2 else 0.0,
			float(q[q.size() - 1]) if q.size() > 0 else 0.0,
			float(kol["oto"]), float(kol["iss"])])
	return sapma


## `--v2-tarih` kurulumunda bir kampanya kosar ve q yorungesini ornekler.
## `maliyet < 0` ise mikro katman TAKILMAZ (capa kolu).
static func _yorunge(maliyet: float, ornek_yillari: Array,
		esneklik: float = 0.0) -> Dictionary:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = 1.0
	d.yil = 1825.0
	d.varlik = 0.5
	var c := KrizCekirdegi.new(null, 42)
	c.baslat(d)
	var m: UretimKatmani = null
	if maliyet >= 0.0:
		m = UretimKatmani.new()
		m.baslat(d)
		m.yukseltme_maliyeti = maliyet
		m.cag_esneklik = esneklik
		c.mikro = m
	var n := Oran.donem_sayisi(2100.0 - 1825.0, HAFTA)
	var q_ornek: Array = []
	var sonraki := 0
	var r_top := 0.0
	# ISSIZLIK, TARIHSEL PENCEREDE. B2b'nin yozlasma bandi (`iss_ort < 0.25`)
	# 1825-2023'te olculur; merdiveni hizlandirmak orada issizligi ittigi
	# icin iki olcut AYNI TARAMADA gorunmeli. Ayri ayri bakildiginda biri
	# duzelirken otekinin bozuldugu fark edilmez.
	var iss_top := 0.0
	var iss_agirlik := 0.0
	for _i in range(n):
		c.adim(d, HAFTA)
		r_top += d.r_yil * HAFTA
		if d.yil <= 2023.0:
			iss_top += (1.0 - d.e) * HAFTA
			iss_agirlik += HAFTA
		if sonraki < ornek_yillari.size() and d.yil >= float(ornek_yillari[sonraki]):
			q_ornek.append(d.q)
			sonraki += 1
	return {
		"q": q_ornek,
		"devrim": d.devrim_yil,
		"oto": d.oto,
		"iss": iss_top / maxf(iss_agirlik, 1e-9),
		"r_ort": r_top / maxf(float(n) * HAFTA, 1e-9),
		"yukseltme": m.yukseltme_sayisi if m != null else 0,
	}


static func _yorunge_yaz(q: Array) -> String:
	var s := ""
	for x in q:
		s += "%6.2f" % float(x)
	return s
