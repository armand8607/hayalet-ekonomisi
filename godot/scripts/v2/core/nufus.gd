class_name NufusKatmani
extends RefCounted

## v2'nin SINIF KOHORTLARI -- B2b.
##
## Tasarim belgesi §5.9. Victoria'nin tip x kultur x din x konum carpimi YOK;
## ulke basina bir avuc SINIF KOHORTU var. Yuz ulkede yuzlerce nesne yerine
## birkac yuz.
##
## ------------------------------------------------------------------------
## SAKLANAN DORT, TURETILEN IKI
## ------------------------------------------------------------------------
## §5.9 alti kohort sayiyor. Burada dordu SAKLANIR, ikisi TUREIR:
##
##   saklanan : sermayedar, kucuk_burjuva, kir_emegi, emek_gucu
##   turetilen: issiz  = emek_gucu * (1 - e)
##              hapis  = emek_gucu * cezaevi_orani
##
## Issizi saklamak bir DONGU kurardi: issizlik istihdam oranindan gelir,
## istihdam orani emek arzindan, emek arzi da issizi iceren emek gucunden.
## Turetmek o dongoyu yapisal olarak imkansiz kilar. Ayni sekilde `hapis`
## cekirdegin `cezaevi_orani`sindan gelir -- o kol B3'un isi (karanlik
## devlet) ve otoritesi orada kalir.
##
## ------------------------------------------------------------------------
## KORUNUM: GECISLER CIFT UZERINDE TANIMLI
## ------------------------------------------------------------------------
## `Dunya`nin kuralinin aynisi: birinden eksilen digerine gider. Bir gecis
## tek bir yerde hesaplanir ve iki kohorta TERS ISARETLE yazilir, dolayisiyla
##
##     sum(kohort) == toplam_nufus
##
## bir kalibrasyon degil OZDESLIKTIR. B1b'de v4.4'un L blogunun bozulma
## sebebi tam olarak buydu: transfer her uc icin bagimsiz hesaplaniyordu ve
## korunum hatasi %57'ye cikiyordu. Nufus akimlarinda ayni hatanin bicimi
## "proleterlesme" olurdu: kucuk burjuva erir, kimse ucretli olmaz.
##
## ------------------------------------------------------------------------
## OTORITE TABLOSU  (B2a'nin tablosuyla birlikte okunmali)
## ------------------------------------------------------------------------
##   ALAN              OTORITE   GEREKCE
##   L_etkin           nufus     emek arzi kohortlarin toplami (OZDESLIK)
##   e                 nufus     emek TALEBI (mikro) / emek ARZI (nufus)
##   emek_gerginlik    nufus     ayni iki tarafli piyasadan
##   pay               nufus     ucret kutlesi / V  -- BILESIM x DUZEY
##   pay taban/tavan   CEKIRDEK  `pay_sinirla()` -- nufus turetir, cekirdek kirpar
##   katilim           CEKIRDEK  henuz kohort bazli degil; B3'te org ile birlikte
##   w_nom_buyume_yil  CEKIRDEK  Goodwin blogu kalibre; pazarlik ORANI orada
##   org, parti        CEKIRDEK  B3'e kadar; nufus onlari YALNIZCA OKUR
##   cezaevi_orani     CEKIRDEK  B3 (karanlik devlet)
##
## PAZARLIK ORANI CEKIRDEKTE KALIYOR, VE BU BILEREKTIR. Goodwin blogu
## kalibre edilmis bir mekanizmadir (`--v2-olcek`, `--v2-tarih`); onu kohort
## bazina yeniden yazmak B2b'nin olcmek istedigi seyi -- BILESIM etkisini --
## pazarlik yeniden yaziminin gurultusuyla karistirirdi. Bu katman oranı
## OKUR, bir ucret DUZEYINE uygular, ve `pay`i bilesimden turetir. Boylece
## yeni kanal tek basina olculebilir kalir.

## §5.9'un kohortlari. `pay0` 1836 baslangic dagilimi: sanayi oncesi bir
## ekonomide nufusun buyuk kismi kirda ve kucuk uretici konumunda.
enum {SERMAYEDAR, KUCUK_BURJUVA, KIR_EMEGI, EMEK_GUCU}

const KOHORTLAR: Array[Dictionary] = [
	{"ad": "sermayedar",    "pay0": 0.03},
	{"ad": "kucuk_burjuva", "pay0": 0.22},
	{"ad": "kir_emegi",     "pay0": 0.55},
	{"ad": "emek_gucu",     "pay0": 0.20},
]

## Kir emeginin ucreti, kent ucretine oran olarak. Birden kucuk olmasi
## kalibrasyon degil tanim: kirda ucretin bir kismi ayni olarak odenir ve
## yedek ordu orada daha buyuktur.
var kir_ucret_orani: float = 0.55

## PROLETERLESME HIZLARI (YILLIK).
##
## Marx'in kendi ongorusu: sermayenin yogunlasmasi kucuk ureticiyi tasfiye
## eder, ve kentlesme kir emegini ucretli emege cevirir. Ikisi de gecistir,
## yok olma degil -- geldigi yerden eksilir, gittigi yere eklenir.
##
## Kucuk burjuvanin tasfiye hizi `c/v`ye baglidir: uretim olcegi buyudukce
## kucuk uretici rekabet edemez. Sabit bir oran olsaydi tasfiye tarihin
## degil takvimin fonksiyonu olurdu.
var tasfiye_hiz_yil: float = 0.010

## Kirdan kente gecis. Cagin `kent` degeri HEDEFTIR, hiz ona yaklasmayi
## belirler; cekirdek `d.kent`i cag tablosundan okuyor.
var kentlesme_hiz_yil: float = 0.020

## YEDEK SANAYI ORDUSUNUN UCRET DUZEYINE ETKISI.
##
## Marx'ta ucreti disipline eden sey istihdam DUZEYI degil ISSIZ KUTLESIDIR:
## "sanayi yedek ordusu ... ucretlerin genel hareketini duzenler" (Kapital I,
## bol. 25). Cekirdegin Goodwin terimi emek gerginligine bakiyor; bu ise
## AYRI bir kanal ve yalnizca issiz bir KOHORT varken tanimlanabilir.
##
## VARSAYILAN SIFIRDIR VE BU BIR OLCUM SONUCUDUR, ihmal degil.
##
## `--v2-nufus-tarama`, capa olarak cekirdegin kapali formunu alarak:
##
##   CAPA (nufus yok): ort pay 0.4433
##   etki   ort pay   pay/capa   tabanda   devrim
##   0.00    0.3802       0.86      0.23     1926
##   0.02    0.3674       0.83      0.25     1926
##   0.05    0.3525       0.80      0.29     1924
##   0.10    0.3367       0.76      0.35     1925
##   0.20    0.3071       0.69      0.43     1924
##   0.40    0.2675       0.60      0.46     1924
##   0.60    0.2564       0.58      0.54     1925
##
## Capaya EN YAKIN olan 0.00; her pozitif deger ucret payini capadan
## uzaklastiriyor ve `pay`in tabanda gecirdigi sureyi buyutuyor.
##
## SEBEP: CIFTE SAYIM -- B2a'da yasanan hatanin yeni kiligi. Cekirdegin
## Goodwin terimi `bos_e = emek_gerginlik - e_norm` uzerinden ZATEN issizlik
## kanalini tasiyor. Bunun UZERINE ikinci bir issizlik terimi eklemek ayni
## kuvveti iki kez saymaktir; B2a'da "sermaye yogunlugu iki kez yazilmaz"
## diye kayda gecen kuralin aynisi.
##
## Kanal SILINMEDI, ADOPTE EDILMEDI. Yonu dogru (kapali/acik karsi-olgusalinda
## ucreti baskiliyor) ve `--v2-nufus` bunu olcmeye devam ediyor. Ama modelin
## VARSAYILAN kurulumunda kapali, cunku Goodwin'in kendi terimiyle yer
## degistirmesi gerekir -- ve pazarlik blogunu yeniden yazmak B2b'nin degil,
## §4'un kollarini kuran B3'un isi. Ozgun kanal orada tanimlanabilir hale
## gelecek (orgutlu/orgutsuz ayrimi, bolunme).
var yedek_ordu_etkisi: float = 0.0

## Issizlik NORMU -- ve HAREKETLIDIR, sabit degil.
##
## SABIT NORM BIR KEZ DENENDI VE MOTORU BOZDU. 0.08 sabit yazilmisti; olculen
## ortalama issizlik ise 0.21 cikti, yani baski her yil
## `0.6 * (0.21 - 0.08) = 0.078` -- %7.8'lik bir REEL UCRET KESINTISI, ve
## bilesikleniyor. Sonucu: `w` cokuyor, `pay` kampanyanin %74'unu `pay_taban`a
## cakilmis geciriyor ve BILESIM KANALI OLU KALIYOR. Kapi yine de yesil
## veriyordu (yon dogruydu, mekanizma oluydu) -- yozlasma denetimleri tam
## bunun icin eklendi.
##
## Cozum cekirdegin kendi cozumu. `_goodwin`in notu: "Goodwin terimi SABIT bir
## hedefe degil ulkenin kendi HAREKETLI istihdam normuna gore calisir." Ayni
## gerekce burada da gecerli: yedek ordu ucreti issizligin DUZEYIYLE degil,
## alisilmis duzeyden SAPMASIYLA disipline eder. Kalici bir yuksek issizlik
## kalici bir ucret kesintisi degil, YENI BIR NORMAL uretir.
var issiz_norm: float = 0.08

## Normun uyum hizi (YILLIK). Cekirdegin `e_norm_hiz_yil`i ile ayni islevde.
var issiz_norm_hiz_yil: float = 0.12


# ---------------------------------------------------------------------------
# DURUM
# ---------------------------------------------------------------------------

## Kohort kutleleri (kisi). Saklanan dort.
var kutle: PackedFloat64Array = PackedFloat64Array()

## Kent ucret duzeyi. `pay` bunun kohort bilesimiyle carpimindan TUREIR.
var w: float = 1.0

## TANI -- test ve arayuz okur, mekanizma okumaz.
var son_emek_talebi: float = 0.0
var son_emek_arzi: float = 0.0

## `pay_hesapla`nin KIRPILMAMIS sonucu. Cekirdegin `pay_sinirla()`si tabani
## ya da tavani uygulamissa bu deger `d.pay`den ayrisir -- yani o adimda
## bilesim kanali etkisiz kalmistir. Kapinin yozlasma denetimi buna bakar:
## mekanizmanin yonu dogru cikip mekanizmanin kendisi olu olabilir.
var son_ham_pay: float = 0.0


# ===========================================================================
# KURULUS
# ===========================================================================

## Cekirdegin `baslat()`indan SONRA cagrilir. `d.L_etkin` orada kalibre
## edilir; bu katman onu BOLUSTURUR, degistirmez.
##
## `L_etkin` cekirdekte EMEK ARZIDIR, toplam nufus degil. Dolayisiyla toplam
## nufus emek gucu payindan geri hesaplanir; boylece kurulustan sonra
## `emek_arzi()` tam olarak eski `L_etkin`i doner ve ozdeslik kurulur.
func baslat(d: KrizDurumu) -> void:
	kutle.resize(KOHORTLAR.size())
	var emek_pay := float(KOHORTLAR[EMEK_GUCU]["pay0"])
	var kir_pay := float(KOHORTLAR[KIR_EMEGI]["pay0"])
	# Emek arzi = emek_gucu + kir_emegi (ikisi de ucretli emek sunar).
	var toplam := d.L_etkin / maxf(emek_pay + kir_pay, 1e-9)
	var toplam_pay := 0.0
	for k in KOHORTLAR:
		toplam_pay += float(k["pay0"])
	for i in range(KOHORTLAR.size()):
		kutle[i] = toplam * float(KOHORTLAR[i]["pay0"]) / toplam_pay
	# Baslangic ucret duzeyi: eski `pay` ile ayni sonucu verecek duzey.
	# Kurulusta bilesim degismedigi icin bu, `pay` ozdesligini kurar.
	w = 1.0
	w = _ucret_duzeyi_esitle(d)


## Baslangicta `pay`i BOZMAMAK icin goreli ucreti geri cozer.
##
## Yeni katman eskisini OZEL DURUM olarak icermelidir: kurulus aninda
## `pay_hesapla()` tam olarak `d.pay` dondurmelidir, yoksa aradaki fark bir
## mekanizma degil bir baslangic sicramasidir ve butun yorungeyi kaydirir.
func _ucret_duzeyi_esitle(d: KrizDurumu) -> float:
	var c := bilesim_carpani()
	if c <= 1e-12:
		return 1.0
	return d.pay / c


## BILESIM CARPANI -- emek gucunun ne kadarinin TAM (kent) ucreti aldigi.
##
##     carpan = (emek_gucu + kir_emegi*kir_orani) / (emek_gucu + kir_emegi)
##
## Kir emegi ucretin bir kismini ayni olarak aldigi icin ortalamayi asagi
## ceker; kentlesme ve tasfiye ilerledikce carpan YUKSELIR. B2b'nin butun
## iddiasi bu carpanda yasar: pazarlik hic olmasa bile bu sayi degistiginde
## ucret payi degisir.
##
## BIRIM YOK, ORAN VAR -- ve bu bir duzeltmenin sonucudur. Ilk yazimda
## `pay` bir ucret DUZEYI ile kutlenin carpimindan hesaplaniyordu
## (`pay = w * kutle / V`). Cebirsel olarak `pay ~ w/q` ediyordu, cunku `V`
## uretkenlikle buyuyor ama bir DUZEY olarak `w` onu takip etmiyor. Olculdu:
## `pay` kampanyanin %74'unu `pay_taban`a cakilmis geciriyor, bilesim kanali
## olu kaliyor ve kapi yine de yesil veriyordu (yon dogru, mekanizma olu).
##
## Dogrusu: `w` bir DUZEY degil GORELI ucret (uretkenlige oran). O zaman
## dinamigi cekirdegin kendi `d_pay`i olur ve `pay = w_goreli * carpan`
## bilesim dondurulunca cekirdege TAM INDIRGENIR -- port disiplininin
## "yeni katman eskisini ozel durum olarak icerir" kurali.
func bilesim_carpani() -> float:
	var toplam := kutle[EMEK_GUCU] + kutle[KIR_EMEGI]
	if toplam <= 1e-12:
		return 1.0
	return (kutle[EMEK_GUCU] + kutle[KIR_EMEGI] * kir_ucret_orani) / toplam


# ===========================================================================
# TOPLAMLAR  --  nufus -> makro
# ===========================================================================

func toplam_nufus() -> float:
	var t := 0.0
	for x in kutle:
		t += x
	return t


## EMEK ARZI. Kohortlarin toplami -- ozdeslik. Sermayedar ve kucuk burjuva
## ucretli emek SUNMAZ; onlar `pay`in paydasina (V) girer, payina girmez.
func emek_arzi() -> float:
	return kutle[EMEK_GUCU] + kutle[KIR_EMEGI]


## ISSIZ KUTLESI -- turetilir, saklanmaz (bkz. dosya basi).
func issiz(d: KrizDurumu) -> float:
	return emek_arzi() * maxf(0.0, 1.0 - clampf(d.e, 0.0, 1.0))


## UCRET PAYI -- BILESIM carpi DUZEY.
##
## B2b'nin butun iddiasi bu satirda: `pay` artik pazarlanan bir skaler degil,
## kohort BILESIMI ile ucret DUZEYININ carpimi. Pazarlik hic olmasa bile
## bilesim degistiginde `pay` degisir -- ucret bicimi yayildikca urunun daha
## buyuk bir kismi ucret olarak odenir. Bu, skaler bir `pay` ile
## TANIMLANAMAZ ve B2b'nin ayirt edici olcutu odur.
func pay_hesapla(_d: KrizDurumu) -> float:
	son_ham_pay = clampf(w * bilesim_carpani(), 0.0, 1.0)
	return son_ham_pay


## Kohort paylari -- tani ve arayuz icin.
func paylar() -> Dictionary:
	var t := maxf(toplam_nufus(), 1e-9)
	var s := {}
	for i in range(KOHORTLAR.size()):
		s[str(KOHORTLAR[i]["ad"])] = kutle[i] / t
	return s


# ===========================================================================
# ADIM
# ===========================================================================

## EMEK PIYASASI. Talebi mikro katman verir (bina basina emek ihtiyaci),
## arzi bu katman. `e` artik `Y/Y_L` degil, iki tarafli bir piyasanin sonucu.
##
## `mikro` null ise talep cekirdegin eski bicimiyle hesaplanir; iki katman
## bagimsiz takilabilir olmali, yoksa B2a ve B2b'nin etkileri ayri ayri
## olculemez.
func emek_piyasasi(d: KrizDurumu, mikro: UretimKatmani) -> void:
	var arz := emek_arzi() * d.katilim * (1.0 - minf(0.90, d.cezaevi_orani))
	arz *= d.hafta_saati
	son_emek_arzi = arz

	var talep := 0.0
	if mikro != null:
		for b in mikro.binalar:
			talep += mikro.emek_ihtiyaci(b, d.kv)
	else:
		# Mikro katman yoksa talep hasiladan geri okunur: ayni tanim, daha
		# kaba kaynak.
		talep = d.Y_yil * Oran.V44_TUR_YIL / maxf(d.q, 1e-9)
	son_emek_talebi = talep

	d.L_etkin = emek_arzi()
	if arz <= 1e-12:
		return
	# `e` ISTIHDAM ORANIDIR ve 1.0'da doyar. Doyma noktasinin USTUNDEKI
	# karsilanmamis talep `emek_gerginlik`e gider -- cekirdegin kendi notu:
	# tam istihdam ucret baskisinin bittigi yer degil, en siddetli oldugu yer.
	d.e = clampf(talep / arz, 0.05, 1.0)
	d.emek_gerginlik = clampf(talep / arz, 0.2, 1.6)


## BOLUSUM. Cekirdegin Goodwin blogu pazarlik oranini hesapladiktan SONRA
## cagrilir. `d_pay` cekirdekten GELIR (kirpilmis hali) -- bu katman onu
## goreli ucrete uygular, uzerine yedek ordu baskisini ekler ve `pay`i
## bilesimden turetir.
##
## `d_pay`in cekirdekte hesaplanmasi bilerektir: Goodwin blogu kalibre
## edilmis bir mekanizmadir ve onu kohort bazina yeniden yazmak B2b'nin
## olcmek istedigi BILESIM etkisini pazarlik yeniden yaziminin gurultusuyle
## karistirirdi.
func bolusum(d: KrizDurumu, donem_yil: float, d_pay: float) -> void:
	if d.rejim == "sosyalist":
		# Planli ekonomide ucret pazarlikla degil planla belirlenir; goreli
		# ucret dogrudan hedefe cekilir ve bilesim kanali etkisini yitirir.
		var c := bilesim_carpani()
		if c > 1e-12:
			w += Oran.donem_uyum(0.30, donem_yil) * (d.pay / c - w)
		return

	# YEDEK SANAYI ORDUSU -- ayri bir kanal, yalnizca issiz kohort varken
	# tanimli. Issizlik NORMUN uzerindeyse ucret baskilanir; norm hareketli
	# oldugu icin kalici bir issizlik kalici bir kesinti degil YENI BIR
	# NORMAL uretir.
	var iss_pay := issiz(d) / maxf(emek_arzi(), 1e-9)
	var baski := yedek_ordu_etkisi * (iss_pay - issiz_norm)
	issiz_norm += Oran.donem_uyum(issiz_norm_hiz_yil, donem_yil) * (
			iss_pay - issiz_norm)

	w *= (1.0 + Oran.donem_akim(d_pay - baski, donem_yil))
	w = maxf(w, 1e-9)


## NUFUS VE GECISLER. Cekirdegin `_nufus`u yerine gecer.
##
## Buyume butun kohortlara ORANTILI dagitilir (dogurganlik farki B3'un
## konusu), gecisler ise CIFT uzerinde tanimlidir.
func nufus_adim(d: KrizDurumu, donem_yil: float, artis_yil: float) -> void:
	var g := Oran.donem_buyume(artis_yil, donem_yil)
	for i in range(kutle.size()):
		kutle[i] *= (1.0 + g)

	# --- TASFIYE: kucuk burjuva -> emek gucu ---
	# Hiz `c/v`ye baglidir: uretim olcegi buyudukce kucuk uretici rekabet
	# edemez. Takvime bagli sabit bir oran olsaydi proleterlesme tarihin
	# degil kronolojinin fonksiyonu olurdu.
	var olcek := clampf(d.cv / maxf(P_CV_REF, 1e-9), 0.0, 4.0)
	var akim := kutle[KUCUK_BURJUVA] * Oran.donem_uyum(
			tasfiye_hiz_yil * olcek, donem_yil)
	kutle[KUCUK_BURJUVA] -= akim
	kutle[EMEK_GUCU] += akim

	# --- KENTLESME: kir emegi -> emek gucu ---
	# Cagin `kent` degeri hedeftir. Hedefin ALTINDA kalan kadar akar; ustune
	# cikilmis ise akim durur (geri gocu bu asama modellemez).
	var toplam := maxf(toplam_nufus(), 1e-9)
	var kentli := (kutle[EMEK_GUCU] + kutle[SERMAYEDAR]
			+ kutle[KUCUK_BURJUVA]) / toplam
	if kentli < d.kent:
		var acik := (d.kent - kentli) * toplam
		var akim2 := minf(kutle[KIR_EMEGI],
				acik * Oran.donem_uyum(kentlesme_hiz_yil, donem_yil))
		kutle[KIR_EMEGI] -= akim2
		kutle[EMEK_GUCU] += akim2

	d.L_etkin = emek_arzi()


## Tasfiye hizinin olcek referansi: cag 2'nin c/v capasi. Bir sabit degil,
## tablodan okunan bir baslangic noktasi -- "sanayi olcegi kucuk uretici
## icin ne zaman baglayici hale gelir" sorusunun tablodaki karsiligi.
const P_CV_REF := 2.2
