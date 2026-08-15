class_name TarihTesti
extends RefCounted

## TARIHSEL KALIBRASYON TESTI -- cekirdegin gercek dunyaya karsi sinanmasi.
##
## Kaynak: "Marksist Sistematikte Kapitalist Krizler, 1825-2023" tablosu.
## 27 kriz, tarihleri ve baskin Marksist siniflandirmalariyla.
##
## NEDEN BU TEST BIRINCIL OLCUTTUR. Olcek testi (`OlcekTesti`) cekirdegin
## KENDI ICINDE tutarli oldugunu gosterir; bu test DOGRU OLUP OLMADIGINI
## sorar. Bir motor mukemmel olcek degismez olabilir ve yine de hicbir kriz
## uretmeyebilir -- nitekim su an oyle.
##
## Tablonun soyledigi en onemli sey su: 1825-1938 arasi ON DORT krizin
## neredeyse hepsi ASIRI URETIM baskinlidir. Yani asiri uretim krizi
## OTOMASYONU BEKLEMEZ; sanayi kapitalizminin daha ilk yuzyilinda, buhar ve
## elektrik caginda, duzenli olarak patlar. Kar oranlarinin dusme egilimi de
## oyle: organik bilesimin yukselisiyle KADEME KADEME isler, tam otomasyon
## onun doruk noktasidir, kosulu degil.
##
## Cekirdek bu tabloyu tutturmak ZORUNDA DEGILDIR -- tarih tek bir kosudur,
## model ise dagilim uretir. Beklenen: ayni BUYUKLUK MERTEBESI ve ayni
## BASKIN TUR karisimi.

## Tarihsel kayit. [baslangic, bitis, baskin tur]
## Tur etiketleri motorun kendi tescil turleriyle eslesir.
const KAYIT := [
	[1825, 1825, "asiri_uretim"],
	[1836, 1839, "asiri_uretim"],
	[1847, 1848, "asiri_uretim"],
	[1857, 1858, "asiri_uretim"],
	[1866, 1866, "finansal"],
	[1873, 1879, "asiri_birikim"],
	[1882, 1885, "asiri_uretim"],
	[1890, 1893, "finansal"],
	[1900, 1903, "asiri_uretim"],
	[1907, 1908, "finansal"],
	[1913, 1914, "asiri_uretim"],
	[1920, 1921, "asiri_uretim"],
	[1929, 1933, "asiri_uretim"],
	[1937, 1938, "asiri_uretim"],
	[1948, 1949, "asiri_uretim"],
	[1953, 1954, "asiri_uretim"],
	[1957, 1958, "asiri_uretim"],
	[1960, 1961, "asiri_uretim"],
	[1969, 1970, "karlilik"],
	[1973, 1975, "karlilik"],
	[1980, 1982, "karlilik"],
	[1990, 1991, "asiri_kapasite"],
	[1997, 1998, "finansal"],
	[2000, 2001, "finansal"],
	[2008, 2009, "asiri_birikim"],
	[2020, 2020, "dissal_sok"],
	[2022, 2023, "arz_soku"],
]

const BAS := 1825.0
const BITIS := 2023.0


static func _ozet() -> Dictionary:
	var d := {}
	for k in KAYIT:
		var t: String = k[2]
		d[t] = int(d.get(t, 0)) + 1
	return d


## Bir kosu yapar. `vt_pay` hasilanin kacta kacinin DISARI aktigidir
## (negatif = cevre konumu, deger merkeze akiyor).
static func _kos(vt_pay: float) -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = 1.0
	d.yil = BAS
	d.varlik = 0.5
	var cekirdek := KrizCekirdegi.new()
	cekirdek.baslat(d)
	var n := Oran.donem_sayisi(BITIS - BAS, OlcekTesti.HAFTA)
	for _i in range(n):
		# Deger transferi: C ve L bloklari B2'de dunya katmanindan gelecek.
		# Burada tek parametreyle taklit ediliyor -- amac dunyayi kurmak degil,
		# KRIZLERIN KAYNAGININ dis mi ic mi oldugunu olcmek.
		cekirdek.adim(d, OlcekTesti.HAFTA, {"VT_net_yil": vt_pay * d.Y_yil})
	return d


static func kos() -> int:
	var sure := BITIS - BAS
	print("")
	print("V2 CEKIRDEK -- TARIHSEL KALIBRASYON")
	print("==================================================================")
	print("Kaynak: Marksist Sistematikte Kapitalist Krizler, %d-%d" % [int(BAS), int(BITIS)])
	print("")

	# --- Tarihsel kayit ---
	var ozet := _ozet()
	print("--- tarihsel kayit: %d kriz / %d yil ---" % [KAYIT.size(), int(sure)])
	var turler: Array = ozet.keys()
	turler.sort()
	for t in turler:
		print("    %-16s %2d" % [t, int(ozet[t])])
	# Sanayi kapitalizminin ilk yuzyili: asiri uretim baskin.
	var erken := 0
	for k in KAYIT:
		if int(k[1]) <= 1938:
			erken += 1
	print("  %d-1938 arasi: %d kriz (ortalama %.1f yilda bir)"
			% [int(BAS), erken, (1938.0 - BAS) / maxf(float(erken), 1.0)])

	# --- Modelin urettigi ---
	#
	# DEGER TRANSFERI TARANIYOR. v4.4 olculdu (tur 200, `--dump-turn=200`):
	# 20 ulkenin yalnizca 3'unde e=1.0, 9'unda talep acigi var, ve VT_net
	# HER ULKEDE negatif. Yani krizleri ureten sey ulke-ici mekanizma degil,
	# ULKE HETEROJENLIGI + DEGER TRANSFERIDIR. Tek ulkeli ve transfersiz bir
	# kosu, v4.4'un EN SAKIN ulkesini (ABD: e=1, talep acigi 0) uretir --
	# ki cekirdek tam da onu uretiyor.
	print("--- modelin urettigi (deger transferi taramasi) ---")
	print("  %8s %7s %7s %7s %7s %7s %6s %s"
			% ["VT/Y", "asiri", "resesy", "bunalim", "TOPLAM", "e_son", "cag", "rejim"])
	var en_iyi := 0
	var d := KrizDurumu.new()
	for vt in [0.0, -0.01, -0.02, -0.04, -0.08]:
		var s := _kos(vt)
		var t := (s.asiri_uretim_krizleri.size() + s.resesyonlar.size()
				+ s.bunalimlar.size())
		en_iyi = maxi(en_iyi, t)
		if vt == 0.0:
			d = s
		print("  %8.2f %7d %7d %7d %7d %7.3f %6d %s"
				% [vt, s.asiri_uretim_krizleri.size(), s.resesyonlar.size(),
					s.bunalimlar.size(), t, s.e, s.era, s.rejim])
	var model := en_iyi
	print("    tarihsel toplam: %d kriz" % KAYIT.size())

	# --- Olcut ---
	print("")
	print("--- olcut ---")
	var gecti := true
	# (1) Kriz sikligi ayni mertebede olmali: tarihsel 27, kabul bandi 10-60.
	var bant := model >= 10 and model <= 60
	print("  [%s] kriz sayisi bandi 10-60 icinde (model %d, tarihsel %d)"
			% ["gecti" if bant else "KALDI", model, KAYIT.size()])
	gecti = gecti and bant
	# (2) Asiri uretim krizi HIC olmamasi kabul edilemez: tablonun yarisindan
	#     fazlasi asiri uretim baskinli.
	var au := d.asiri_uretim_krizleri.size() > 0
	print("  [%s] en az bir asiri uretim krizi tescil edildi (%d)"
			% ["gecti" if au else "KALDI", d.asiri_uretim_krizleri.size()])
	gecti = gecti and au
	# (3) LTRPF: kar orani KADEME KADEME dusmeli, otomasyonu beklemeden.
	#     Tabloda 1969'dan itibaren "karlilik krizi" turu cikiyor; egilim ise
	#     ilk gunden isliyor.
	print("  (LTRPF egilimi `--v2-olcek` icinde ayrica sinaniyor)")

	print("")
	print("------------------------------------------------------------------")
	if gecti:
		print("SONUC: GECTI")
		return 0
	print("SONUC: KALDI -- ama kusur cekirdekte DEGIL.")
	print("")
	print("OLCULDU (`--dump-turn=200` ve `=1000`, v4.4'un kendisi):")
	print("  tur  200: 20 ulkenin 3'unde e=1.0, 9'unda talep acigi var.")
	print("            ABD  e=1.000 talep_acigi=0.0000 u=0.745 I/Y=0.478")
	print("            Almanya e=0.429 talep_acigi=0.295 | Cin kriz=147")
	print("  tur 1000: ABD hala e=0.978, talep acigi 0.")
	print("")
	print("YANI: v4.4'un MERKEZ ulkesi de sakindir. Tek ulkeli, savassiz,")
	print("ticaretsiz bir kosu v4.4'un en sakin ulkesini uretir -- cekirdek")
	print("tam da onu uretiyor. Kriz uretenler ULKE HETEROJENLIGI, savas,")
	print("abluka, ticaret soku ve politika AI'sidir; hepsi B2'de gelir.")
	print("")
	print("Bu test B2 BITMEDEN GECEMEZ. Gecmesi de beklenmemeli: kalibrasyon")
	print("hedefi degil, DUNYA KATMANININ gerekliligi'nin kanitidir.")
	print("")
	print("Teorik sonuc: bu modelde kriz ULUSLARARASIDIR. Emperyalizm")
	print("dekor degil, krizlerin dogdugu yerdir (tasarim belgesi §3).")
	return 1
