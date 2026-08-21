class_name NufusTesti
extends RefCounted

## B2b KAPISI -- sinif kohortlari.
##
## ------------------------------------------------------------------------
## YINE OLCUT SORUNU -- ucuncu kez
## ------------------------------------------------------------------------
## §6'nin tablosu B2b icin "Goodwin otoritesi pop katmanina gecer, salinim
## olmez" diyordu. Bu da AYIRT ETMEZ: salinim su anda, B2b hic yokken de
## olmuyor degil. B1b ve B2a'da ogrenilen kural burada da geciyor -- bir kapi
## her iki durumda da yesilse kapi degildir.
##
## Kohortlar OLMADAN kurulamayan iddia sudur:
##
##   > Ucret payi pazarlanan bir skaler degildir. Pazarlik hic olmasa bile
##   > SINIF BILESIMI degistiginde ucret payi degisir.
##
## `pay` bir skalerken bu cumle telaffuz edilemez: bilesim diye bir sey yok.
## B2b'nin kapisi budur ve tasarim B1b'den devralindi: KARSI-OLGUSAL, ayni
## tohum, kanal acik ve kapali.
##
## ------------------------------------------------------------------------
## DORT KADEME
## ------------------------------------------------------------------------
##   1. OZDESLIK  -- kurulusta `pay` ve emek arzi cekirdekle ayni; nufus
##      kampanya boyunca korunur (gecisler cift uzerinde tanimli)
##   2. BILESIM   -- pazarlik dondurulunca `pay` HALA hareket ediyor (asil kapi)
##   3. YEDEK ORDU-- issiz kutlesi ucreti baskiliyor (karsi-olgusal)
##   4. PROLETERLESME -- kucuk burjuva payi duser, emek gucu payi yukselir

const HAFTA := 1.0 / 52.0
const BAS := 1825.0
const BITIS := 2023.0

## Yedek ordu kanalinin TEST agirligi. Kanal modelde adopte EDILMEDI (kod
## varsayilani 0.0, gerekcesi `nufus.gd`de: cekirdegin Goodwin terimiyle cifte
## sayim). Bu sabit yalnizca kanalin YONUNU olcmek icin var -- bir kalibrasyon
## degeri degil, bir sinama kolu.
const TEST_YEDEK_ORDU := 0.60

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


## `--v2-tarih` ile AYNI baslangic. Ayri yazilmadi ki bir kapi kirildiginda
## sebep baslangic farki olmasin.
static func _baslangic() -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = 1.0
	d.yil = BAS
	d.varlik = 0.5
	return d


## Bir kampanya kosar.
##   `mikro`      : uretim katmani da takili mi (B2a ile birlikte)
##   `bilesim`    : kohort gecisleri acik mi (karsi-olgusal kol)
##   `yedek_ordu` : yedek sanayi ordusu kanali acik mi (karsi-olgusal kol)
##   `pazarlik`   : Goodwin pazarligi acik mi (kapaliysa yalnizca bilesim kalir)
## `yedek_ordu` VARSAYILAN OLARAK KAPALIDIR -- kod varsayilaniyla ayni.
## Kanal olculmeye devam ediyor (5. kademe onu acik/kapali karsilastirir) ama
## modelin varsayilan kurulumuna girmiyor; gerekcesi `nufus.gd`de.
static func _kos(mikro := false, bilesim := true, yedek_ordu := false,
		pazarlik := true, tohum := 42) -> Dictionary:
	var d := _baslangic()
	var c := KrizCekirdegi.new(null, tohum)
	c.baslat(d)

	var n_kat := NufusKatmani.new()
	n_kat.baslat(d)
	if not bilesim:
		# Gecisler kapali: bilesim 1825'teki dagilimda DONAR. Nufus yine
		# buyur, yalnizca kohortlar arasi akim durur.
		n_kat.tasfiye_hiz_yil = 0.0
		n_kat.kentlesme_hiz_yil = 0.0
	# Kanal varsayilanda KAPALI (kod varsayilani 0.0), dolayisiyla acik kol
	# ACIKCA bir agirlik vermek zorundadir. Vermezse iki kol ayni olur ve
	# karsilastirma sessizce anlamini yitirir -- bir kez oyle yazildi ve
	# 5. kademe "+0.0000" ile kaldi.
	n_kat.yedek_ordu_etkisi = TEST_YEDEK_ORDU if yedek_ordu else 0.0
	c.nufus = n_kat

	if mikro:
		var m := UretimKatmani.new()
		m.baslat(d)
		c.mikro = m

	c.pazarlik_sabit = not pazarlik

	var pay_ilk := d.pay
	var paylar_ilk := n_kat.paylar()
	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var nufus_hata := 0.0
	var beklenen := n_kat.toplam_nufus()
	var artis := Oran.v44_buyume(c.P.v44.nufus_artis)
	var pay_top := 0.0
	var w_top := 0.0
	var iss_top := 0.0
	var taban_sure := 0.0

	for _i in range(n):
		c.adim(d, HAFTA)
		beklenen *= (1.0 + Oran.donem_buyume(artis, HAFTA))
		nufus_hata = maxf(nufus_hata, absf(n_kat.toplam_nufus() - beklenen)
				/ maxf(beklenen, 1e-12))
		pay_top += d.pay * HAFTA
		w_top += n_kat.w * HAFTA
		iss_top += n_kat.issiz(d) / maxf(n_kat.emek_arzi(), 1e-9) * HAFTA
		# `pay` TABANA/TAVANA CAKILDI MI. Kirpma devreye girdiyse o adimda
		# bilesim kanali HIC etkili degildir -- olcum orada mekanizmayi degil
		# kirpmayi olcer.
		if absf(n_kat.son_ham_pay - d.pay) > 1e-9:
			taban_sure += HAFTA

	var agirlik := maxf(float(n) * HAFTA, 1e-9)
	return {
		"d": d, "n": n_kat,
		"pay_ilk": pay_ilk, "pay_son": d.pay,
		"pay_ort": pay_top / agirlik,
		"w_ort": w_top / agirlik,
		"iss_ort": iss_top / agirlik,
		"taban_pay": taban_sure / agirlik,
		"paylar_ilk": paylar_ilk, "paylar_son": n_kat.paylar(),
		"nufus_hata": nufus_hata,
		"devrim": d.devrim_yil,
	}


## CAPA -- nufus katmani TAKILI DEGIL. Kalibrasyonun oturtulacagi olcum:
## cekirdegin kendi istihdam ve ucret payi ortalamalari.
static func _capa(tohum := 42) -> Dictionary:
	var d := _baslangic()
	var c := KrizCekirdegi.new(null, tohum)
	c.baslat(d)
	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var e_top := 0.0
	var pay_top := 0.0
	for _i in range(n):
		c.adim(d, HAFTA)
		e_top += d.e * HAFTA
		pay_top += d.pay * HAFTA
	var agirlik := maxf(float(n) * HAFTA, 1e-9)
	return {"e_ort": e_top / agirlik, "pay_ort": pay_top / agirlik,
			"devrim": d.devrim_yil}


static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("=".repeat(70))
	print("v2 SINIF KOHORTLARI  (B2b)   %d-%d, haftalik" % [int(BAS), int(BITIS)])
	print("=".repeat(70))

	# -----------------------------------------------------------------
	print("\n--- 1. kurulus ozdesligi ---")
	var d0 := _baslangic()
	var c0 := KrizCekirdegi.new()
	c0.baslat(d0)
	var pay_cekirdek := d0.pay
	var L_cekirdek := d0.L_etkin
	var n0 := NufusKatmani.new()
	n0.baslat(d0)

	var h_pay := absf(n0.pay_hesapla(d0) - pay_cekirdek) / maxf(pay_cekirdek, 1e-12)
	var h_L := absf(n0.emek_arzi() - L_cekirdek) / maxf(L_cekirdek, 1e-12)
	print("  emek arzi   : kohortlar %.10f   cekirdek %.10f" % [
			n0.emek_arzi(), L_cekirdek])
	print("  ucret payi  : kohortlar %.10f   cekirdek %.10f" % [
			n0.pay_hesapla(d0), pay_cekirdek])
	print("  toplam nufus: %.2f   kohort paylari: %s" % [
			n0.toplam_nufus(), str(n0.paylar())])
	_dogrula(h_L < 1e-12, "emek arzi OZDES", "(bagil hata %s)" % _bil(h_L))
	_dogrula(h_pay < 1e-12, "ucret payi OZDES", "(bagil hata %s)" % _bil(h_pay))

	# -----------------------------------------------------------------
	print("\n--- 2. nufus korunumu (gecisler cift uzerinde) ---")
	var tam := _kos()
	print("  toplam nufus beklenenden en buyuk bagil sapma: %s"
			% _bil(float(tam["nufus_hata"])))
	_dogrula(float(tam["nufus_hata"]) < 1e-9,
			"nufus KORUNUYOR -- gecisler kutle yaratmiyor/yok etmiyor",
			"(%s)" % _bil(float(tam["nufus_hata"])))

	# -----------------------------------------------------------------
	print("\n--- 3. PROLETERLESME (kohort paylari, 1825 -> 2023) ---")
	var pi: Dictionary = tam["paylar_ilk"]
	var ps: Dictionary = tam["paylar_son"]
	print("  kohort              1825      2023    degisim")
	for k in ["sermayedar", "kucuk_burjuva", "kir_emegi", "emek_gucu"]:
		print("    %-16s %7.4f %9.4f %+9.4f" % [
				k, float(pi[k]), float(ps[k]), float(ps[k]) - float(pi[k])])
	_dogrula(float(ps["kucuk_burjuva"]) < float(pi["kucuk_burjuva"]),
			"kucuk burjuva payi DUSTU -- tasfiye",
			"(%+.4f)" % (float(ps["kucuk_burjuva"]) - float(pi["kucuk_burjuva"])))
	_dogrula(float(ps["kir_emegi"]) < float(pi["kir_emegi"]),
			"kir emegi payi DUSTU -- kentlesme",
			"(%+.4f)" % (float(ps["kir_emegi"]) - float(pi["kir_emegi"])))
	_dogrula(float(ps["emek_gucu"]) > float(pi["emek_gucu"]),
			"emek gucu payi YUKSELDI -- proleterlesme",
			"(%+.4f)" % (float(ps["emek_gucu"]) - float(pi["emek_gucu"])))

	# -----------------------------------------------------------------
	print("\n--- 4. BILESIM KANALI: pazarlik dondurulunca `pay` hala oynuyor mu ---")
	print("  (asil kapi -- skaler bir `pay` ile TANIMSIZ)")
	# Iki kolda da YEDEK ORDU KAPALI: aksi halde iki kanal birden acik olur
	# ve olculen fark bilesimin mi yedek ordunun mu oldugu belirsiz kalir.
	# Karsi-olgusal tasarimin kurali -- tek seferde tek kol.
	var don_acik := _kos(false, true, false, false)
	var don_kapali := _kos(false, false, false, false)
	print("                          bilesim ACIK   bilesim KAPALI")
	print("  pay (1825)           %14.6f %16.6f" % [
			float(don_acik["pay_ilk"]), float(don_kapali["pay_ilk"])])
	print("  pay (2023)           %14.6f %16.6f" % [
			float(don_acik["pay_son"]), float(don_kapali["pay_son"])])
	print("  ort. pay             %14.6f %16.6f" % [
			float(don_acik["pay_ort"]), float(don_kapali["pay_ort"])])
	var d_bilesim := float(don_acik["pay_ort"]) - float(don_kapali["pay_ort"])
	print("  BILESIM ETKISI       %+14.6f" % d_bilesim)
	_dogrula(absf(d_bilesim) > 1e-6,
			"BILESIM KANALI VAR -- pazarlik yokken de `pay` ayrisiyor",
			"(%+.6f)" % d_bilesim)
	_dogrula(d_bilesim > 0.0,
			"ve YONU dogru: ucret bicimi yayildikca ucret payi yukseliyor",
			"(%+.6f)" % d_bilesim)

	# -----------------------------------------------------------------
	print("\n--- 5. YEDEK SANAYI ORDUSU (karsi-olgusal; ADOPTE EDILMEDI) ---")
	var yo_acik := _kos(false, true, true, true)
	print("                          kanal ACIK     kanal KAPALI (varsayilan)")
	print("  ort. issizlik        %14.4f %16.4f" % [
			float(yo_acik["iss_ort"]), float(tam["iss_ort"])])
	print("  ort. ucret duzeyi w  %14.4f %16.4f" % [
			float(yo_acik["w_ort"]), float(tam["w_ort"])])
	print("  ort. ucret payi      %14.6f %16.6f" % [
			float(yo_acik["pay_ort"]), float(tam["pay_ort"])])
	var d_w := float(yo_acik["w_ort"]) - float(tam["w_ort"])
	_dogrula(d_w < 0.0,
			"yonu dogru: kanal acikken ucret duzeyi DAHA DUSUK",
			"(%+.4f)" % d_w)
	print("  NOT: kanal varsayilanda KAPALI. Capaya karsi taranınca her pozitif")
	print("       agirlik ucret payini capadan uzaklastiriyor, cunku cekirdegin")
	print("       Goodwin terimi issizlik kanalini ZATEN tasiyor -- cifte sayim.")
	print("       Gerekce ve tablo `nufus.gd`de; ozgun kanal B3'te tanimlanacak.")

	# -----------------------------------------------------------------
	print("\n--- 6. iki katman birlikte (B2a + B2b) ---")
	var ikisi := _kos(true)
	print("  yalniz nufus : devrim %.0f, ort pay %.4f, ort issizlik %.4f" % [
			float(tam["devrim"]), float(tam["pay_ort"]), float(tam["iss_ort"])])
	print("  nufus+uretim : devrim %.0f, ort pay %.4f, ort issizlik %.4f" % [
			float(ikisi["devrim"]), float(ikisi["pay_ort"]), float(ikisi["iss_ort"])])
	_dogrula(float(ikisi["nufus_hata"]) < 1e-9,
			"iki katman birlikte de nufus KORUNUYOR",
			"(%s)" % _bil(float(ikisi["nufus_hata"])))
	# -----------------------------------------------------------------
	# YOZLASMA DENETIMLERI -- kapinin ilk hali bunlar OLMADAN yazilmisti ve
	# BOZUK BIR YORUNGEDE YESIL GECTI: ortalama issizlik %32.7, `pay` ise
	# kampanyanin buyuk kismini `pay_taban`a CAKILMIS gecirmisti. Bilesim
	# etkisi o tabanda olculdugu icin teknik olarak pozitifti ama iktisadi
	# olarak anlamsizdi.
	#
	# Bir mekanizmanin YONU dogru cikabilir ve mekanizma yine de olu olabilir.
	# Yon denetimleri bunu yakalamaz; bant denetimleri yakalar. B1b'nin
	# "yesile boyamak icin ne esik gevsetildi ne mekanizma zorlandi" kurali
	# ancak kapi yozlasmayi gorebiliyorsa anlam tasir.
	print("\n--- 7. yozlasma denetimleri (kapi bozuk yorungede yesil vermesin) ---")
	var capa := _capa()
	print("  CAPA (nufus katmani yok): ort e %.4f, ort pay %.4f" % [
			float(capa["e_ort"]), float(capa["pay_ort"])])
	print("  nufus+uretim            : ort e %.4f, ort pay %.4f" % [
			1.0 - float(ikisi["iss_ort"]), float(ikisi["pay_ort"])])
	# BANT CAPAYA GORE, MUTLAK DEGIL -- ve bu bir gevsetme degil duzeltme.
	#
	# Ilk yazimda esik `< 0.25` idi ve o gun gecerliydi. B2a'nin merdiven
	# kalibrasyonu (cag kuplaji) acilinca dustu: 0.2248 -> 0.3815. Once
	# "kalibrasyon yanlis" diye bakildi, sonra CAPALAR olculdu:
	#
	#     cekirdegin kendi kapali formu (capa) : 0.3169
	#     yalniz nufus katmani                 : 0.3015
	#     nufus+uretim, YAVAS merdiven         : 0.2248
	#     nufus+uretim, kalibre merdiven       : 0.3815
	#
	# Yani `< 0.25`i saglayan TEK kol yavas merdivenli koldu; capanin
	# kendisi de, nufus katmaninin kendisi de bandin disindaydi. Bant
	# bagimsiz bir olcut degil, YAVAS MERDIVENIN PARMAK IZIYDI.
	#
	# Deponun dort kez tekrarlanan dersi burada da gecerli: bir DUZEY
	# karsilastirmasi trendi olcer, mekanizmayi degil. Dogru soru "issizlik
	# mutlak olarak kucuk mu" degil, "katmanlari takmak cekirdegin KENDI
	# issizligini ne kadar asiyor" -- ve o soru capaya gore sorulur.
	#
	# Yon de teorik olarak beklenen yon: hizlanan teknik degisme YEDEK
	# SANAYI ORDUSUNU buyutur. Eski davranista uretim katmani issizligi
	# nufus-tek koluna gore 6 puan DUSURUYORDU; anomali o taraftaydi.
	#
	# Pay 0.10 keyfi degil ayirt edici secildi: kalibre merdiven 0.3815 ile
	# geciyor (payi 0.035), esneklik 1.5'lik asiri kol 0.4706 ile KALIYOR.
	# Bandin hala bir sey iddia ettigi boyle dogrulandi.
	var capa_iss := 1.0 - float(capa["e_ort"])
	_dogrula(float(ikisi["iss_ort"]) < capa_iss + 0.10,
			"issizlik cekirdegin kendi capasini asmiyor (capa + 0.10)",
			"(%.4f, capa %.4f)" % [float(ikisi["iss_ort"]), capa_iss])
	_dogrula(float(ikisi["taban_pay"]) < 0.50,
			"`pay` kampanyanin yarisindan fazlasini TABANDA gecirmiyor",
			"(tabanda gecen sure %.2f)" % float(ikisi["taban_pay"]))
	_dogrula(float(ikisi["pay_ort"]) > 0.10 and float(ikisi["pay_ort"]) < 0.90,
			"ucret payi anlamli bantta kaliyor",
			"(%.4f)" % float(ikisi["pay_ort"]))

	print("\n" + "-".repeat(70))
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


static func _bil(x: float) -> String:
	return String.num_scientific(x)


## YEDEK ORDU ETKISININ KALIBRASYONU.
##
## Capa yine cekirdegin kapali formu: onun ortalama ucret payi ve istihdami
## `--v2-olcek` ve `--v2-tarih` kapilarindan gecmis durumda. Yedek ordu ayri
## bir kanal oldugu icin capaya EKLENMEZ, capayi BOZMAMALI -- kanalin isareti
## dogru olsun ama agirligi `pay`i tabana cakmasin.
##
## B2a'nin dersi burada uygulaniyor: karar verilen kurulumda (`--v2-tarih`
## baslangici) ve tek noktadan degil ORTALAMA uzerinden olculuyor.
static func tarama() -> int:
	print("=".repeat(72))
	print("YEDEK ORDU ETKISI TARAMASI   (capa: kapali form, --v2-tarih kurulumu)")
	print("=".repeat(72))
	var capa := _capa()
	print("\n  CAPA (nufus yok): ort e %.4f, ort pay %.4f, devrim %.0f\n" % [
			float(capa["e_ort"]), float(capa["pay_ort"]), float(capa["devrim"])])
	print("  etki    ort pay   pay/capa   tabanda   ort issizlik   ort w   devrim")
	print("  " + "-".repeat(66))
	var en_iyi := 0.0
	var en_iyi_fark := INF
	for etki in [0.00, 0.02, 0.05, 0.10, 0.20, 0.40, 0.60]:
		var kol := _kos_etki(float(etki))
		var fark := absf(float(kol["pay_ort"]) - float(capa["pay_ort"]))
		if fark < en_iyi_fark:
			en_iyi_fark = fark
			en_iyi = float(etki)
		print("  %5.2f %10.4f %10.2f %9.2f %14.4f %7.3f %8.0f" % [
				float(etki), float(kol["pay_ort"]),
				float(kol["pay_ort"]) / maxf(float(capa["pay_ort"]), 1e-9),
				float(kol["taban_pay"]), float(kol["iss_ort"]),
				float(kol["n"].w), float(kol["devrim"])])
	print("\n  capaya en yakin: %.2f  (ort pay farki %.4f)" % [en_iyi, en_iyi_fark])
	print("\n  NOT: bu bir kapi degil TANIDIR. Secim tasarim belgesine yazilir.")
	return 0


## Yedek ordu etkisi verilen bir kolu kosar (B2a + B2b birlikte).
static func _kos_etki(etki: float, tohum := 42) -> Dictionary:
	var d := _baslangic()
	var c := KrizCekirdegi.new(null, tohum)
	c.baslat(d)
	var n_kat := NufusKatmani.new()
	n_kat.baslat(d)
	n_kat.yedek_ordu_etkisi = etki
	c.nufus = n_kat
	var m := UretimKatmani.new()
	m.baslat(d)
	c.mikro = m
	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	var pay_top := 0.0
	var iss_top := 0.0
	var taban_sure := 0.0
	for _i in range(n):
		c.adim(d, HAFTA)
		pay_top += d.pay * HAFTA
		iss_top += n_kat.issiz(d) / maxf(n_kat.emek_arzi(), 1e-9) * HAFTA
		if absf(n_kat.son_ham_pay - d.pay) > 1e-9:
			taban_sure += HAFTA
	var agirlik := maxf(float(n) * HAFTA, 1e-9)
	return {"n": n_kat, "pay_ort": pay_top / agirlik,
			"iss_ort": iss_top / agirlik, "taban_pay": taban_sure / agirlik,
			"devrim": d.devrim_yil}
