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
static func tarama() -> int:
	print("=".repeat(66))
	print("YUKSELTME MALIYETI TARAMASI   (capa: cekirdegin kapali formu)")
	print("=".repeat(66))

	# Capa: mikro katman TAKILI DEGIL. Cekirdegin kendi q yorungesi.
	var d_ref := _baslangic()
	var c_ref := KrizCekirdegi.new()
	c_ref.baslat(d_ref)
	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var r_ref := 0.0
	for _i in range(n):
		c_ref.adim(d_ref, HAFTA)
		r_ref += d_ref.r_yil * HAFTA
	r_ref /= maxf(float(n) * HAFTA, 1e-9)
	print("\n  CAPA (mikro yok, kapali form): q = %.3f, ort r = %.5f, c/v = %.3f\n"
			% [d_ref.q, r_ref, d_ref.cv])

	print("  maliyet   yukseltme    q(2036)   q/capa    ort r     ort c/v")
	print("  " + "-".repeat(58))
	var adaylar := [0.45, 0.20, 0.10, 0.05, 0.02, 0.01, 0.005, 0.002]
	var en_iyi := 0.0
	var en_iyi_fark := INF
	for maliyet in adaylar:
		var d := _baslangic()
		var c := KrizCekirdegi.new()
		c.baslat(d)
		var m := UretimKatmani.new()
		m.baslat(d)
		m.yukseltme_maliyeti = float(maliyet)
		c.mikro = m
		var r_top := 0.0
		var cv_top := 0.0
		for _i in range(n):
			c.adim(d, HAFTA)
			r_top += d.r_yil * HAFTA
			cv_top += d.cv * HAFTA
		var oran := d.q / maxf(d_ref.q, 1e-9)
		# Karsilastirma LOGARITMIKTIR: q bilesik buyudugu icin "iki kat hizli"
		# ile "yari hizli" ayni uzaklikta olmalidir. Dogrusal fark alsaydik
		# tarama sistematik olarak yavas adaylari secerdi.
		var fark := absf(log(maxf(oran, 1e-9)))
		if fark < en_iyi_fark:
			en_iyi_fark = fark
			en_iyi = float(maliyet)
		print("  %7.3f   %9d   %8.3f   %6.2f   %8.5f   %8.3f" % [
				float(maliyet), m.yukseltme_sayisi, d.q, oran,
				r_top / maxf(float(n) * HAFTA, 1e-9),
				cv_top / maxf(float(n) * HAFTA, 1e-9)])

	print("\n  capaya en yakin: %.3f  (q orani log-uzakligi %.3f)" % [en_iyi, en_iyi_fark])
	print("\n  NOT: bu bir kapi degil TANIDIR. Secim tasarim belgesine yazilir;")
	print("       kod varsayilani elle guncellenir, tarama otomatik degistirmez.")
	return 0
