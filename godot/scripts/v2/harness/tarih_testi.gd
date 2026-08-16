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
static func _kos(vt_pay: float, tohum: int = 42) -> KrizDurumu:
	var d := KrizDurumu.new()
	d.L_etkin = 110.0
	d.pay = 0.52
	d.era = 1
	d.q = 1.0
	d.yil = BAS
	d.varlik = 0.5
	var cekirdek := KrizCekirdegi.new(null, tohum)
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

	# --- TOHUM TARAMASI ---
	#
	# Belgenin kendi uyarisi (§10): "devrim sayisi tohuma duyarli, en az uc
	# tohum gerekir". Tek kosudan okunan bir sayi ornekten ibarettir.
	#
	# DIKKAT -- v2 cekirdeginin RASTGELELIK YUZEYI COK DARDIR: `rng` motorda
	# TEK yerde kullanilir, kamu temerrudu olasiliginda. v4.4'teki savas,
	# ittifak ve politika AI'si burada yok. Dolayisiyla tohumlar arasi sacilim
	# KUCUK cikarsa bu modelin kararli oldugunu degil, stokastik kanalinin dar
	# oldugunu gosterir; asil degisken hala deger transferidir.
	print("")
	print("--- tohum taramasi (VT/Y = 0, kapali ekonomi) ---")
	print("  %6s %7s %7s %7s %7s %7s %s"
			% ["tohum", "asiri", "resesy", "bunalim", "TOPLAM", "temerrut", "rejim"])
	var sayimlar: Array[int] = []
	for tohum in [1, 2, 3, 4, 5, 6]:
		var s := _kos(0.0, tohum)
		var t := (s.asiri_uretim_krizleri.size() + s.resesyonlar.size()
				+ s.bunalimlar.size())
		sayimlar.append(t)
		print("  %6d %7d %7d %7d %7d %7d %s"
				% [tohum, s.asiri_uretim_krizleri.size(), s.resesyonlar.size(),
					s.bunalimlar.size(), t, s.temerrutler.size(), s.rejim])
	var sirali := sayimlar.duplicate()
	sirali.sort()
	var medyan := 0.5 * float(sirali[2] + sirali[3])
	print("  aralik %d-%d, medyan %.1f  (tarihsel %d)"
			% [sirali[0], sirali[5], medyan, KAYIT.size()])

	# --- Olcut ---
	print("")
	print("--- olcut ---")
	var gecti := true
	# (1) Kriz sikligi ayni mertebede olmali: tarihsel 27, kabul bandi 10-60.
	#
	# OLCUT TOHUM MEDYANIDIR, VT taramasinin EN IYISI DEGIL. Onceki hali
	# `maxi()` ile taramanin en yuksek degerini aliyordu; bu, bes VT
	# degerinden HERHANGI BIRI banda dustugunde testi gecirir, yani en iyi
	# ornegi secer. Belgenin kendi kurali da (§10) tek kosudan okumaya karsi:
	# "en az uc tohum gerekir".
	var bant := medyan >= 10.0 and medyan <= 60.0
	# TEK dize: GDScript'te `%` operatoru `+`'dan once baglar, yani parcali
	# yazilirsa bicimlendirme yalnizca SON parcaya uygulanir ve argumanlar kayar.
	print("  [%s] kriz sayisi bandi 10-60 icinde (tohum medyani %.1f, VT en yuksek %d, tarihsel %d)"
			% ["gecti" if bant else "KALDI", medyan, model, KAYIT.size()])
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
	print("SONUC: KALDI")
	print("")
	print("TESTIN TARIHI -- bu blok bir kez YANLIS teshis tasidi.")
	print("Onceki hali 'kusur cekirdekte DEGIL' diyor, krizlerin kaynaginin")
	print("ULUSLARARASI oldugunu ve testin B2 bitmeden gecemeyecegini savunuyordu.")
	print("O teshis, iki mekanizmasi EKSIK bir cekirdek uzerinde konmustu:")
	print("  - `deger_carpani` yaziliyor ama hic OKUNMUYORDU (kriz onarmiyordu)")
	print("  - `q_doyum` hic tasinmamisti (c/v 112'ye kaciyordu)")
	print("Ikisi baglanip satinalma gucu deger bilesimine oturtulunca test")
	print("ULKE-ICI mekanizmayla GECTI. Deger transferi taramasi da bunu")
	print("dogruluyor: VT/Y 0 ile -0.08 arasinda kriz sayisi neredeyse sabit.")
	print("")
	print("Yani bugun bu test kalirsa sebebi BASKA bir yerdedir; yukaridaki")
	print("tabloya bakin -- hangi kriz turu sifir, hangi olcut disarida?")
	return 1
