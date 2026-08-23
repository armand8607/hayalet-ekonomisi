class_name BolunmeTesti
extends RefCounted

## B3 KAPISI -- karanlik devlet, bolunme ve karsi hareket.
##
## ------------------------------------------------------------------------
## OLCUT
## ------------------------------------------------------------------------
## §7 B3 icin ALTI YON TESTI sayiyor ve bu, oncekilerin aksine bastan ayirt
## ediyor: altisi da `bolunme` olmadan TANIMSIZdir. B1b/B2a/B2b/B2c'de olcut
## dort kez duzeltilmek zorunda kalmisti cunku eski kapilar mekanizma
## eklenmeden de yesil veriyordu; burada oyle bir risk yok.
##
## Ama §7'nin listesi YON iddialaridir ve B2b'nin dersi tam da buydu:
##
##   > Bir mekanizmanin YONU dogru cikabilir ve mekanizma yine de OLU olabilir.
##   > `pay` kampanyanin %74'unu tabana cakilmis geciriyordu, bileşim kanali
##   > hic is gormuyordu, ve kapi yon denetimleriyle YESIL veriyordu.
##
## Bu yuzden kapi UC kademedir:
##
##   1. OZDESLIK  -- katman takili degilken cekirdek ZERRE degismez. Bu bir
##      formalite degil: B3 uc ayri bloga (S, Q, T) dokunuyor, yani yanlis
##      yazilirsa B1/B2'nin butun olcumlerini sessizce gecersiz kilar.
##   2. YON       -- §7'nin alti testi, hepsi KARSI-OLGUSAL (ayni tohum,
##      taktik acik/kapali). Kesitsel karsilastirma yapilmaz; B1b'de bir kez
##      yanlis sonuc verdi.
##   3. CANLILIK  -- mekanizma gercekten IS GORUYOR mu: bolunme tabana ya da
##      tavana cakilmiyor, karsi hareket gercekten geri cekebiliyor, ve
##      §8.4'un riski gerceklesmiyor (devrim IMKANSIZ hale gelmiyor).
##
## ------------------------------------------------------------------------
## NEDEN SEKIZ TAKTIK AYRI OLCULUR
## ------------------------------------------------------------------------
## Testler taktikleri TEK TEK acar, "karanlik devlet aciktir" diye toplu bir
## kol cevirmez. Sebep §4.6'nin temsil ilkesi kadar mekaniktir de: her
## taktigin kendi kanali var ve toplu acilsalardi hangi bedelin hangi koldan
## ciktigi olculemezdi. Ornegin 2. test (ucret duser, kar KORUNUR) yalnizca
## uretkenlik bedeli OLMAYAN bir taktikle kurulabilir; 3. test (kar DAHA COK
## duser) ise tam tersini ister. Ikisi ayni kolda olsaydi celisirlerdi --
## ayri kollarda oldugu icin ikisi birlikte §4.3'un asil tezini kurar:
##
##   > Karanlik devlet toplumsal barisi, kendi gelecekteki birikimini
##   > yiyerek satin alir. Bugun devrimi oteler, yarin kar oranini daha da
##   > dusurur.

const HAFTA := 1.0 / 52.0
const BAS := 1825.0
const BITIS := 2023.0

static var _gecen := 0
static var _kalan := 0


static func _dogrula(kosul: bool, ad: String, ayrinti: String = "") -> void:
	if kosul:
		_gecen += 1
		print("  [gecti] %s %s" % [ad, ayrinti])
	else:
		_kalan += 1
		print("  [KALDI] %s %s" % [ad, ayrinti])


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
##
## `taktik`  : {"t_milliyetcilik": 1.0, ...} -- yalnizca verilenler acilir
## `devrim`  : mekanizma testlerinde KAPALI. Rejim degisimi ayrik bir olaydir
##             ve ortalamalari domine eder; olculen sey mekanizmanin kendisi
##             olsun diye kapatilir. §8.4 bandi ise devrim ACIKKEN kosar.
## `karsi`   : karsi hareket acik mi (kapaliyken bolunmeyi eriten dort kuvvet
##             de sifirlanir -- B2c'nin `yigin_kisma = 0` kolunun karsiligi)
## `kanallar`: [org, pazarlik, protesto] -- tek tek kapatilabilir
static func _kos(taktik: Dictionary = {}, tohum := 42, devrim := false,
		karsi := true, kanallar := [true, true, true], bitis := BITIS,
		p_ayar: Dictionary = {}) -> Dictionary:
	var d := _baslangic()
	var c := KrizCekirdegi.new(null, tohum)
	c.P.v44.devrim_acik = devrim
	c.baslat(d)

	var kd := KaranlikDevlet.new(c.P)
	kd.kanal_org = bool(kanallar[0])
	kd.kanal_pazarlik = bool(kanallar[1])
	kd.kanal_protesto = bool(kanallar[2])
	kd.baslat(d)
	c.karanlik = kd

	# Parametre ustyazimi -- MEKANIZMA acik/kapali karsi-olgusallari icin.
	for anahtar in p_ayar:
		c.P.set(anahtar, float(p_ayar[anahtar]))

	if not karsi:
		c.P.bol_org_yil = 0.0
		c.P.bol_parti_yil = 0.0
		c.P.bol_iktidar_yil = 0.0
		c.P.bol_dayanisma_yil = 0.0

	for ad in taktik:
		d.set(ad, float(taktik[ad]))

	var n := Oran.donem_sayisi(bitis - BAS, HAFTA)
	var erken_n := Oran.donem_sayisi(15.0, HAFTA)
	var gec_bas := Oran.donem_sayisi(30.0, HAFTA)
	var son_ucte_bir := n - n / 3

	var top := {
		"org": 0.0, "pay": 0.0, "r": 0.0, "Omega": 0.0, "PR": 0.0,
		"bolunme": 0.0, "cezaevi": 0.0, "uo": 0.0, "V": 0.0, "egitim": 0.0,
		"l_etkin": 0.0, "karsi": 0.0, "itki": 0.0,
		"Y": 0.0, "varlik": 0.0, "emek_carpani": 0.0, "siddet": 0.0,
		"basinc": 0.0,
	}
	var org_erken := 0.0
	var omega_gec := 0.0
	var r_gec := 0.0
	var bolunme_zirve := 0.0
	var bolunme_dip := INF
	# CANLILIK izleri: tabana/tavana cakilma ve GERI CEKILME sayisi.
	var taban_donem := 0
	var tavan_donem := 0
	var geri_donem := 0
	var onceki_bolunme := d.bolunme

	for i in range(n):
		c.adim(d, HAFTA)
		top["org"] += d.org
		top["pay"] += d.pay
		top["r"] += d.r_yil
		top["Omega"] += d.Omega
		top["PR"] += d.PR
		top["bolunme"] += d.bolunme
		top["cezaevi"] += d.cezaevi_orani
		top["uo"] += d.uyusturucu_orani
		top["V"] += d.V_yil
		top["egitim"] += d.egitim
		top["l_etkin"] += d.l_etkin()
		top["karsi"] += d.karsi_hareket
		top["itki"] += d.bolunme_itki
		top["Y"] += d.Y_yil
		top["varlik"] += d.varlik
		# EMEK CARPANI -- `l_etkin / L_etkin`. Karanlik devletin emek arzina
		# etkisini NUFUS SURUKLENMESINDEN ayirir: 198 yillik bir kampanyada
		# `L_etkin`in kendisi endojen olarak degistigi icin ham `l_etkin`
		# karsilastirmasi mekanizmayi demografiyle karistirir.
		top["emek_carpani"] += d.l_etkin() / maxf(d.L_etkin, 1e-9)
		top["siddet"] += d.topluluk_siddeti
		top["basinc"] += d.sinif_basinci

		if i < erken_n:
			org_erken += d.org
		if i >= gec_bas:
			omega_gec += d.Omega
		if i >= son_ucte_bir:
			r_gec += d.r_yil

		bolunme_zirve = maxf(bolunme_zirve, d.bolunme)
		bolunme_dip = minf(bolunme_dip, d.bolunme)
		if d.bolunme <= 1e-9:
			taban_donem += 1
		if d.bolunme >= 0.999:
			tavan_donem += 1
		if d.bolunme < onceki_bolunme - 1e-12:
			geri_donem += 1
		onceki_bolunme = d.bolunme

	var s := {}
	for k in top:
		s["ort_" + k] = float(top[k]) / float(n)
	s["org_erken"] = org_erken / float(erken_n)
	s["omega_gec"] = omega_gec / float(n - gec_bas)
	s["r_gec"] = r_gec / float(n - son_ucte_bir)
	s["son_q"] = d.q
	s["son_bolunme"] = d.bolunme
	s["son_nitelik"] = d.nitelik
	s["son_egitim"] = d.egitim
	s["bolunme_zirve"] = bolunme_zirve
	s["bolunme_dip"] = bolunme_dip
	s["taban_pay"] = float(taban_donem) / float(n)
	s["tavan_pay"] = float(tavan_donem) / float(n)
	s["geri_pay"] = float(geri_donem) / float(n)
	s["devrim_yil"] = d.devrim_yil
	s["ort_sehit"] = d.sehit
	return s


# ===========================================================================
# 1. OZDESLIK  --  katman takili degilken cekirdek zerre degismez
# ===========================================================================

## IKI AYRI SOZLESME, VE KARISTIRILMAMALARI ONEMLI.
##
##   (a) KATMAN TAKILI DEGIL -> cekirdek BIREBIR ayni. Deponun kurali budur
##       ("mikro katmanlar takili degilken cekirdek zerre degismez") ve B1/B2
##       olcumlerinin gecerliligi buna dayanir. B3 uc bloga birden dokundugu
##       icin en kritik denetim budur.
##
##   (b) KATMAN TAKILI, TAKTIKLER KAPALI -> `bolunme` ve `nitelik` OZDESLIKLE
##       notrdur, ama cekirdegin sayilari DEGISIR ve bu BEKLENENDIR: tasinan
##       egitim denklemi kosmaya baslar ve `egitim` 0.30'luk sabit yer
##       tutucudan kendi dengesine (~0.09) gider. `egitim` cekirdekte
##       `org` buyumesini besledigi icin (`egitim_org_yil * d.egitim`) yorunge
##       kayar. Bu bir sizinti degil, katmanin ISIDIR -- v4.4'te de oyleydi.
##
## Ilk yazimda (b) de "cekirdek degismesin" diye sinaniyordu ve KALDI. Dogru
## olan testi degil sozlesmeyi ayirmakti: notr olmasi gereken sey katmanin
## KENDI YENI kanallaridir, tasinan denklemin kendisi degil.
static func _ozdeslik() -> void:
	print("\n--- 1. OZDESLIK ---")

	# --- (a) KATMAN TAKILI DEGIL: birebir ayni ---------------------------
	var d1 := _baslangic()
	var c1 := KrizCekirdegi.new(null, 42)
	c1.P.v44.devrim_acik = false
	c1.baslat(d1)

	var d2 := _baslangic()
	var c2 := KrizCekirdegi.new(null, 42)
	c2.P.v44.devrim_acik = false
	c2.baslat(d2)

	var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
	for _i in range(n):
		c1.adim(d1, HAFTA)
		c2.adim(d2, HAFTA)

	# IEEE754 bit deseni uzerinden -- ondalik bicimlendirme uzerinden degil,
	# yoksa "esit mi" sorusu "nasil yazdirdin" sorusuna doner (depo kurali).
	var ayni := true
	for alan in ["K", "q", "pay", "r_yil", "org", "Omega", "e", "cv"]:
		if float(d1.get(alan)) != float(d2.get(alan)):
			ayni = false
	_dogrula(ayni, "(a) katman TAKILI DEGILKEN cekirdek BIREBIR ayni",
			"(8 alan, IEEE754 bit deseni)")

	# --- (b) KATMAN TAKILI, taktikler kapali: yeni kanallar NOTR ----------
	var d3 := _baslangic()
	var c3 := KrizCekirdegi.new(null, 42)
	c3.P.v44.devrim_acik = false
	c3.baslat(d3)
	var kd := KaranlikDevlet.new(c3.P)
	kd.baslat(d3)
	c3.karanlik = kd
	var nitelik_sapmasi := 0.0
	for _i in range(n):
		c3.adim(d3, HAFTA)
		nitelik_sapmasi = maxf(nitelik_sapmasi, absf(d3.nitelik - 1.0))

	_dogrula(d3.bolunme == 0.0,
			"(b) taktikler kapaliyken bolunme OZDESLIKLE 0.0",
			"(%.9f)" % d3.bolunme)
	_dogrula(nitelik_sapmasi == 0.0,
			"(b) capa ozdesligi: nitelik kampanya BOYUNCA birebir 1.0",
			"(en buyuk sapma %.3e)" % nitelik_sapmasi)
	_dogrula(d3.egitim != d1.egitim,
			"(b) ...ama egitim ARTIK DINAMIK -- katmanin isi bu",
			"(sabit %.3f -> denge %.4f)" % [d1.egitim, d3.egitim])


# ===========================================================================
# 2. YON TESTLERI  --  §7'nin alti iddiasi
# ===========================================================================

static func _yon() -> void:
	print("\n--- 2. YON TESTLERI (alti iddia, hepsi karsi-olgusal) ---")

	var kapali := _kos({})

	# --- (1) BOLUNME -> ORGUTLENME ---------------------------------------
	# Milliyetcilik secildi: en agir bolunme itkisi, ve KENDI kanali yok --
	# yani olculen fark yalnizca bolunmenin uc kanalindan gelir.
	var mil := _kos({"t_milliyetcilik": 1.0})
	_dogrula(mil["ort_org"] < kapali["ort_org"],
			"1. BOLUNME -> ORGUTLENME: org birikimi yavasliyor",
			"(%.4f -> %.4f)" % [kapali["ort_org"], mil["ort_org"]])
	# Ve bunu YAPAN kanalin S kanali oldugu ayrica gosterilir: ayni kosu,
	# yalnizca org kanali kapali.
	var mil_org_kapali := _kos({"t_milliyetcilik": 1.0}, 42, false, true,
			[false, true, true])
	_dogrula(mil_org_kapali["ort_org"] > mil["ort_org"],
			"    ...ve bunu yapan S kanali (kanal kapatilinca org geri geliyor)",
			"(%.4f -> %.4f)" % [mil["ort_org"], mil_org_kapali["ort_org"]])

	# --- (2) BOLUNME -> UCRET, KAR KORUNUR --------------------------------
	# §4.1'in vaadi: "ucret payi baskilanir, KAR ORANI KORUNUR".
	# Milliyetciligin uretkenlik bedeli YOKTUR, dolayisiyla bu iddia burada
	# saf haliyle sinanabilir.
	_dogrula(mil["ort_pay"] < kapali["ort_pay"],
			"2. BOLUNME -> UCRET: pay kazanimi dusuyor",
			"(%.4f -> %.4f)" % [kapali["ort_pay"], mil["ort_pay"]])
	_dogrula(mil["ort_r"] >= kapali["ort_r"],
			"    ...ve KAR ORANI KORUNUYOR (sermaye icin kazanc)",
			"(%.5f -> %.5f)" % [kapali["ort_r"], mil["ort_r"]])

	# --- (3) RIZA AYGITININ BEDELI ----------------------------------------
	# Mistisizm: bolunme itkisi DUSUK, egitim asindirmasi EN AGIR. Yani bu
	# kosuda olculen sey bolunme degil, `nitelik` -> `qg` kanalidir.
	var mis := _kos({"t_mistisizm": 1.0})
	_dogrula(mis["son_egitim"] < kapali["son_egitim"],
			"3. RIZA BEDELI: egitim tabani curuyor",
			"(%.4f -> %.4f)" % [kapali["son_egitim"], mis["son_egitim"]])
	_dogrula(mis["son_nitelik"] < 1.0,
			"    ...nitelikli emek carpani 1.0'in altina dusuyor",
			"(%.4f)" % mis["son_nitelik"])
	_dogrula(mis["son_q"] < kapali["son_q"],
			"    ...uretkenlik buyumesi yavasliyor (qg'ye vurdu)",
			"(%.3f -> %.3f)" % [kapali["son_q"], mis["son_q"]])
	# BEDEL HASILADADIR. §4.3'un "gelecegini yiyerek satin alir" tezinin
	# motorda TUTAN bicimi budur: toplum daha yoksul olur.
	_dogrula(mis["ort_Y"] < kapali["ort_Y"],
			"    ...ve HASILA kuculuyor -- bedel toplumun kendisine cikiyor",
			"(%.1f -> %.1f)" % [kapali["ort_Y"], mis["ort_Y"]])

	# ------------------------------------------------------------------
	# §4.3'UN KAR ORANI IDDIASI OLCULDU VE TERS CIKTI -- KAYDA GECIRILIYOR
	# ------------------------------------------------------------------
	# Belge soyle diyordu: "`qg`, LTRPF'ye karsi elindeki TEK karsi
	# egilimdir; karanlik devlet bugun devrimi oteler, YARIN KAR ORANINI
	# DAHA DA DUSURUR."
	#
	# Bu motorda YANLIS. `qg` LTRPF'nin karsi egilimi degil, SEBEBIDIR:
	# q yukselir -> c/v yukselir -> r DUSER (cekirdegin ana dongusu).
	# Dolayisiyla q buyumesini asindirmak kar oranini dusurmez, YUKSELTIR.
	#
	# Iddia duzeltildi, test ona gore yazildi: bedel kar oraninda DEGIL
	# uretkenlik ve hasilada. Ve ortaya cikan sey daha da carpicidir --
	# karanlik devlet, karliligi asindiran surecin KENDISINI yavaslatarak
	# kar oranini AYRICA korur; odenen bedel uretici guclerin gelisimidir.
	_dogrula(mis["r_gec"] > kapali["r_gec"],
			"    ...KAYIT: kar orani uzun vadede DUSMUYOR, YUKSELIYOR (§4.3 duzeltildi)",
			"(son ucte bir: %.5f -> %.5f -- qg LTRPF'nin sebebi, karsi egilimi degil)"
			% [kapali["r_gec"], mis["r_gec"]])

	# RIZA AYGITININ KAR ORANINA GIDEN ASIL KANALI BASKADIR: uyusturucu.
	# §4.3: "gasbedilen deger uretken sermayeye degil SPEKULATIF STOKA akar,
	# yani dogrudan Minsky balonunu besler." Bu kanal Tonak deger gasbi
	# uzerinden zaten kuruluydu; taktik onu ACIYOR.
	var uyu := _kos({"t_uyusturucu": 1.0})
	_dogrula(uyu["ort_uo"] > kapali["ort_uo"],
			"3b. UYUSTURUCU: goz yumma yayilimi buyutuyor",
			"(%.5f -> %.5f)" % [kapali["ort_uo"], uyu["ort_uo"]])
	_dogrula(uyu["ort_varlik"] > kapali["ort_varlik"],
			"    ...ve gasbedilen deger SPEKULATIF STOKA akiyor (Minsky'yi besler)",
			"(%.2f -> %.2f)" % [kapali["ort_varlik"], uyu["ort_varlik"]])

	# --- (4) ZOR AYGITININ BEDELI -----------------------------------------
	var tut := _kos({"t_tutuklama": 1.0})
	_dogrula(tut["ort_cezaevi"] > kapali["ort_cezaevi"],
			"4. ZOR BEDELI: cezaevi orani yukseliyor",
			"(%.5f -> %.5f)" % [kapali["ort_cezaevi"], tut["ort_cezaevi"]])
	# EMEK CARPANI olculur, ham `l_etkin` DEGIL. 198 yilda `L_etkin`in
	# kendisi endojen olarak degistigi icin ham karsilastirma mekanizmayi
	# demografiyle karistirir -- ilk yazimda tam da bu oldu ve test
	# "emek gucu BUYUDU" diye kaldi.
	_dogrula(tut["ort_emek_carpani"] < kapali["ort_emek_carpani"],
			"    ...emek arzindan HAPSEDILENLER dusuluyor (carpan daraliyor)",
			"(%.5f -> %.5f)" % [kapali["ort_emek_carpani"], tut["ort_emek_carpani"]])

	# CINSIYET BASKISI AYNI MEKANIGIN IKINCI MAGDURU (§4.3). Riza aygitinin
	# emek arzina etkisi zor aygitininkinden BUYUKTUR -- kadin isgucunun
	# bastirilmasi cezaevi oraninin bir mertebe ustundedir.
	var cin := _kos({"t_cinsiyet": 1.0})
	_dogrula(cin["ort_emek_carpani"] < tut["ort_emek_carpani"],
			"    ...ve cinsiyet baskisi emek arzini DAHA COK daraltiyor",
			"(tutuklama %.5f, cinsiyet %.5f)" % [
				tut["ort_emek_carpani"], cin["ort_emek_carpani"]])
	_dogrula(cin["ort_V"] < kapali["ort_V"],
			"    ...ve YENI DEGER kuculuyor -- baski arti degerin kaynagini kesiyor",
			"(%.2f -> %.2f)" % [kapali["ort_V"], cin["ort_V"]])

	# --- (5) SEHIT ETKISI --------------------------------------------------
	# Iki etki AYNI stoktan dogar ve ayni anda olmaz: kisa vadede orgutlenme
	# kirilir, orta vadede ofke yukselir.
	var par := _kos({"t_paramiliter": 1.0})
	_dogrula(par["org_erken"] < kapali["org_erken"],
			"5. SEHIT: KISA vadede orgutlenme kiriliyor (ilk 15 yil)",
			"(%.4f -> %.4f)" % [kapali["org_erken"], par["org_erken"]])
	# ORTA VADE MEKANIZMA ACIK/KAPALI ile olculur, taktik acik/kapali ile DEGIL.
	#
	# Sebep eleme yoluyla bulundu: paramiliter taktigi ayni anda `bolunme`yi
	# de itiyor, o da `org`u kiriyor, o da `Omega`nin birikim carpanini
	# (`0.4 + 1.6*orgutlu`) kucultuyor. Yani taktigi acip `Omega`ya bakmak
	# sehit etkisini DEGIL, uc kanalin bileskesini olcer -- ve bileske
	# negatif oldugu icin test yanlis sebeple kaliyordu (0.2800 -> 0.0183).
	#
	# Sehit kanalini yalitmanin tek yolu onu tek basina kapatmaktir; kalan
	# her sey ayni tohumda birebir ayni kalir.
	var par_sehitsiz := _kos({"t_paramiliter": 1.0}, 42, false, true,
			[true, true, true], BITIS, {"sehit_omega_yil": 0.0})
	_dogrula(par["omega_gec"] > par_sehitsiz["omega_gec"],
			"    ...ORTA vadede Omega YUKSELIYOR -- sehitler radikallestirir",
			"(kanal kapali %.5f -> acik %.5f)" % [
				par_sehitsiz["omega_gec"], par["omega_gec"]])

	# --- (6) KARSI HAREKET -------------------------------------------------
	# Ayni taktikler, karsi hareket kapali. B2c'nin `yigin_kisma = 0` kolunun
	# karsiligi: kuvvet YERINDE ama IS GORMUYOR.
	var tam := _tam_taktik()
	var acik := _kos(tam)
	var kapali_karsi := _kos(tam, 42, false, false)
	_dogrula(acik["son_bolunme"] < kapali_karsi["son_bolunme"],
			"6. KARSI HAREKET: sendika/parti bolunmeyi geri cekiyor",
			"(karsi kapali %.4f -> acik %.4f)" % [
				kapali_karsi["son_bolunme"], acik["son_bolunme"]])
	_dogrula(acik["geri_pay"] > 0.0,
			"    ...ve bolunme taktikler ACIKKEN bile geri cekilebiliyor",
			"(kampanyanin %.1f'inde geriliyor)" % (acik["geri_pay"] * 100.0))


# ===========================================================================
# 3. CANLILIK  --  yonu dogru bir mekanizma yine de olu olabilir
# ===========================================================================

static func _canlilik() -> void:
	print("\n--- 3. CANLILIK (B2b'nin dersi: yon yeter demek degildir) ---")

	var tam := _tam_taktik()
	var acik := _kos(tam)
	var kapali := _kos({})

	_dogrula(kapali["ort_bolunme"] < 1e-9,
			"taktikler kapaliyken bolunme OLU (kendiliginden dogmuyor)",
			"(%.9f)" % kapali["ort_bolunme"])
	_dogrula(acik["bolunme_zirve"] > 0.30,
			"taktikler acikken bolunme ANLAMLI bir duzeye cikiyor",
			"(zirve %.3f)" % acik["bolunme_zirve"])
	_dogrula(acik["tavan_pay"] < 0.50,
			"bolunme TAVANA cakili gecirmiyor (kol doymamis)",
			"(tavanda %.1f)" % (acik["tavan_pay"] * 100.0))
	_dogrula(acik["taban_pay"] < 0.50,
			"bolunme TABANA cakili gecirmiyor (kol olu degil)",
			"(tabanda %.1f)" % (acik["taban_pay"] * 100.0))
	_dogrula(acik["ort_karsi"] > 0.0,
			"karsi hareket kampanya boyunca FIILEN var (dekor degil)",
			"(ort geri cekme %.4f/yil, itki %.4f/yil)" % [
				acik["ort_karsi"], acik["ort_itki"]])

	# --- §4.1'in AYIRT EDICI IMZASI ----------------------------------------
	# Karanlik devlet ofkeyi AZALTMAZ, ofkenin orgutlenmeye donusumunu kirar.
	# Motordaki imzasi: `PR` soner ama `Omega` SONMEZ. Bu, mekanizmayi bir
	# "yatistirma" kolundan ayiran tek olcumdur -- ve ayni zamanda §8.4'un
	# sigortasidir: bolunme devrimi IMKANSIZ kilmaz, ERTELER.
	# IMZA SAF BOLUNME ILE OLCULUR, SEKIZ TAKTIK BIRDEN ILE DEGIL.
	#
	# OLCULDU VE AYRIM ZORUNLU CIKTI. Ilk yazimda tam kapasite kol
	# kullaniliyordu ve `Omega` 0.238'den 0.0018'e cokuyordu -- yani imza
	# TERSINE cikiyordu. Sebep bolunme DEGIL: uyusturucu ve hapsetme
	# v4.4'un KENDI yatistirma kanallaridir (`lumpen_sonum`,
	# `karseral_sonum`) ve uyusturulmus ya da hapsedilmis bir nufus
	# gercekten de ofkesini kaybeder. Onlar ofkeyi AZALTIR; bolunme ise
	# ofkeyi azaltmaz, HEDEFINI degistirir.
	#
	# §4.1'in iddiasi ozel olarak bolunme hakkindadir, dolayisiyla imza
	# yalnizca bolunme iten bir taktikle sinanabilir: milliyetcilik.
	var m := _kos({"t_milliyetcilik": 1.0})
	# IDDIA `Omega` UZERINDEN DEGIL `sinif_basinci` UZERINDEN KURULUR.
	#
	# `Omega` bir STOKtur ve orgutlulukle CARPILARAK birikir
	# (`(0.4 + 1.6*orgutlu)`), dolayisiyla bolunmus bir sinifta daha yavas
	# birikir -- ve tabanda doydugu icin ortalamasi bir esik etkisi olcer,
	# mekanizmayi degil. Ilk yazimda `ort_Omega` kullanildi ve test yanlis
	# sebeple kaldi.
	#
	# §4.1'in iddiasi BASINC hakkindadir: karanlik devlet sinifsal basinci
	# AZALTMAZ, onu sinifsal kanaldan baska bir kanala aktarir. Ozdeslik
	# motorda birebir kurulu: `sinif_basinci == PR + topluluk_siddeti`.
	_dogrula(m["ort_basinc"] >= kapali["ort_basinc"] * 0.95,
			"IMZA: sinifsal BASINC azalmiyor (bolunme ofkeyi yatistirmiyor)",
			"(%.4f -> %.4f)" % [kapali["ort_basinc"], m["ort_basinc"]])
	_dogrula(m["ort_PR"] < kapali["ort_PR"],
			"    ...ama basincin SINIFSAL ifadesi kiriliyor",
			"(%.4f -> %.4f)" % [kapali["ort_PR"], m["ort_PR"]])
	# Ofkenin nereye GITTIGI de olculur: sinifsal kanaldan cekilen enerji
	# topluluklar arasi siddete akar. §4.6 geregi bu gorunur bir metriktir.
	_dogrula(m["ort_siddet"] > kapali["ort_siddet"],
			"    ...ve cekilen enerji TOPLULUKLAR ARASI SIDDETE akiyor",
			"(%.5f -> %.5f)" % [kapali["ort_siddet"], m["ort_siddet"]])

	# --- §8.4: DEVRIM IMKANSIZ HALE GELMEDI --------------------------------
	# Riskin kendisi belgede yazili: "yanlis kalibre edilirse ya devrimi
	# imkansiz kilar ya da etkisiz kalir". Bu iki denetim ikisini de kapatir.
	# UFUK UZATILIR, VE BU ZORUNLU.
	#
	# Capa devrimi 1984'te oluyor, pencere ise 2023'te bitiyor -- arada 39
	# yil var. Yani ERTELEYEN her mekanizma devrimi pencerenin disina tasir
	# ve "ertelendi" ile "imkansiz kilindi" AYIRT EDILEMEZ hale gelir.
	# Olculdu: protesto sonumu 0.35'ten 0.05'e indirildiginde bile (PR 0.580
	# -> 0.728, yani capaya neredeyse esit) devrim hala "YOK" gorunuyordu.
	# §8.4'un sordugu soru tam olarak bu ayrimdir, dolayisiyla bant daha
	# uzun bir ufukta olculur.
	const UZUN := 2400.0
	var dev_kapali := _kos({}, 42, true, true, [true, true, true], UZUN)
	var d_k: float = dev_kapali["devrim_yil"]
	_dogrula(d_k > 0.0, "capa kosusunda devrim oluyor (karsilastirma tanimli)",
			"(%.0f)" % d_k)

	# BANT ORTA SIDDETTE OLCULUR. §8.4'un riski "kol yanlis kalibre edilirse
	# devrimi IMKANSIZ kilar"dir ve bunun dogru sinandigi yer otoriter bir
	# donemece giren SIRADAN bir devlettir -- 198 yil boyunca sekiz taktigi
	# birden tam kapasite kullanan bir devlet degil. Ikincisi bir kalibrasyon
	# sorusu degil, motorun verdigi bir CEVAPTIR (asagida ayrica raporlanir).
	# BANT SAF BOLUNME ILE OLCULUR. §8.4'un riski B3'un EKLEDIGI kolun
	# kalibrasyonu hakkindadir; uyusturucu ve hapsetme v4.4'un kendi
	# yatistirma kanallaridir ve onlarin sonucu ayri bir sorudur (asagida
	# kayda geciriliyor). Karistirilirsa "bolunme mi yapti, uyusturucu mu"
	# sorusu yanitsiz kalir -- B1b'nin dersi.
	var dev_bol := _kos({"t_milliyetcilik": 1.0}, 42, true, true, [true, true, true], UZUN)
	var d_o: float = dev_bol["devrim_yil"]
	if d_o > 0.0:
		_dogrula(d_o > d_k,
				"§8.4: bolunme devrimi ERTELIYOR, imkansiz KILMIYOR",
				"(%.0f -> %.0f, +%.0f yil)" % [d_k, d_o, d_o - d_k])
	else:
		_dogrula(false, "§8.4: bolunme tek basina devrimi IMKANSIZ kildi",
				"(capa %.0f)" % d_k)

	# TAM KAPASITE: kapi degil KAYIT. Motorun cevabi soyle -- sekiz taktigi
	# birden tam kapasite kullanan bir devlet devrimi gercekten onler, ve
	# bedelini uretici guclerin gelisiminden oder. §4.3'un tezi tam olarak
	# budur ve burada sayilarla goruluyor.
	var dev_tam := _kos(tam, 42, true, true, [true, true, true], UZUN)
	var tam_m := _kos(tam)
	print("  [kayit] TAM KAPASITE: devrim %s | q %.1f -> %.1f | hasila %.0f -> %.0f | V %.0f -> %.0f"
			% ["YOK" if dev_tam["devrim_yil"] < 0.0 else "%.0f" % dev_tam["devrim_yil"],
				kapali["son_q"], tam_m["son_q"],
				kapali["ort_Y"], tam_m["ort_Y"],
				kapali["ort_V"], tam_m["ort_V"]])


## Sekiz taktigin hepsi tam acik. "Karanlik devlet tam kapasite" kolu.
static func _tam_taktik() -> Dictionary:
	return {
		"t_uyusturucu": 1.0, "t_cemaat": 1.0, "t_mistisizm": 1.0,
		"t_milliyetcilik": 1.0, "t_cinsiyet": 1.0,
		"t_sendika_baskisi": 1.0, "t_tutuklama": 1.0, "t_paramiliter": 1.0,
	}


# ===========================================================================
# GIRIS
# ===========================================================================

static func kos() -> int:
	_gecen = 0
	_kalan = 0
	print("\nV2 KARANLIK DEVLET -- BOLUNME VE KARSI HAREKET (B3)")
	print("==================================================================")
	print("  pencere : %.0f-%.0f, haftalik" % [BAS, BITIS])

	_ozdeslik()
	_yon()
	_canlilik()

	print("------------------------------------------------------------------")
	print("SONUC: %d gecti, %d kaldi" % [_gecen, _kalan])
	return 0 if _kalan == 0 else 1


## KALIBRASYON TARAMASI -- tani, kapi degil.
##
## Bolunmenin uc kanalinin siddeti ve karsi hareketin agirligi burada secilir.
## Deponun kurali: kalibrasyon KARAR VERILEN kurulumda ve YORUNGE uzerinden
## yapilir; tek bir uc noktaya bakmak bir egriyi eslestirmez.
static func tarama() -> int:
	print("\nV2 BOLUNME -- KALIBRASYON TARAMASI (tani)")
	print("==================================================================")
	print("  SAF BOLUNME (milliyetcilik 1.0), devrim ACIK.")
	print("  Capa (taktiksiz) devrim: 1984. Aranan: ERTELENMIS ama OLAN devrim.")
	print("  org_kir  sonum_tav  ort_bolunme   ort_org  ort_Omega    ort_PR   devrim")
	for org_kir in [0.30]:
		for org_tavan in [0.05, 0.10, 0.15, 0.20, 0.30, 0.35]:
			var d := _baslangic()
			var c := KrizCekirdegi.new(null, 42)
			c.P.bolunme_org_kirilma = float(org_kir)
			c.P.bolunme_org_tavan = 0.20
			c.P.bolunme_sonum_tavan = float(org_tavan)
			c.baslat(d)
			var kd := KaranlikDevlet.new(c.P)
			kd.baslat(d)
			c.karanlik = kd
			d.t_milliyetcilik = 1.0
			var n := Oran.donem_sayisi(BITIS - BAS, HAFTA)
			var b := 0.0
			var o := 0.0
			var om := 0.0
			var pr := 0.0
			for _i in range(n):
				c.adim(d, HAFTA)
				b += d.bolunme
				o += d.org
				om += d.Omega
				pr += d.PR
			print("  %7.2f %10.2f %12.4f %9.4f %10.4f %9.4f %8s" % [
					float(org_kir), float(org_tavan), b / n, o / n, om / n, pr / n,
					"YOK" if d.devrim_yil < 0.0 else "%.0f" % d.devrim_yil])
	print("\n  NOT: bu bir kapi degil TANIDIR. Secim tasarim belgesine yazilir.")
	return 0
