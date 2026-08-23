class_name PolitikaAktoru
extends RefCounted

## B7b -- §4.5'in AI tarafi: yapay zekâ yonetimindeki ulkeler karanlik devletin
## kollarini KENDI KRIZLERINE gore kullanir.
##
## ------------------------------------------------------------------------
## NEDEN GEREKLIYDI
## ------------------------------------------------------------------------
## B3 mekanizmayi kurdu, B7a oyuncunun kollarini bagladi -- ama dunyada
## taktikleri YAZAN kimse yoktu. `KaranlikDevlet.otomatik` yalnizca
## `mafya_tolerans`i suruyor; sekiz `t_*` alanindan yedisi 198 yil boyunca
## 0.0'da duruyordu. B5 bunu olcup kapisina yazmisti ("bolunme surucusuz") ve
## o kaydi BILEREK ters yonde birakmisti: surucu gelince kapi dussun diye.
##
## ------------------------------------------------------------------------
## KARISIM UYDURULMAZ, MEKANIZMANIN KENDI TABLOSUNDAN OKUNUR
## ------------------------------------------------------------------------
## "Hangi taktige ne kadar agirlik verilir" sorusuna yeni sabitlerle cevap
## vermek, `bol_*_yil` tablosunu ikinci bir yerde TEKRARLAMAK olurdu -- ve o
## iki yer sessizce ayrisirdi. Bu, deponun `q_tavan` ve `cag_esneklik`te iki
## kez ogrendigi ders: TABLO TEKRARLANMAZ, OKUNUR.
##
## Aktorun amaci BOLUNME SATIN ALMAKTIR (§4.1: ofkeyi azaltmak degil, ofkenin
## sinifsal orgutlenmeye donusmesini kirmak). Dolayisiyla cabayi her taktigin
## KENDI bolunme katsayisiyla orantili dagitir: milliyetcilik 0.075 ile en
## agir, mistisizm 0.015 ile en hafif. Agirliklar aygit icinde normalize
## edilir, yani her aygitin en guclu taktigi 1.0 alir.
##
## ------------------------------------------------------------------------
## MIYOP, VE BU BILEREK
## ------------------------------------------------------------------------
## Aktor §4.3'un bedellerini HESABA KATMAZ: egitim tabanini yedigini,
## `l_etkin`i daralttigini, mesruiyet kaybettigini bilmez. Bu bir eksiklik
## degil mekanizmanin kendi iddiasi -- "karanlik devlet toplumsal barisi kendi
## gelecekteki birikimini yiyerek satin alir." Ileriyi goren bir aktor o
## cumleyi yanlislardi.
##
## ------------------------------------------------------------------------
## RNG TUKETMEZ
## ------------------------------------------------------------------------
## Tek bir rastgele sayi cekmez. Cekseydi `Dunya.rng` ve `SavasKatmani`nin
## akislari kayar, B1b'den B6'ya kadar butun olculmus sayilar degisirdi --
## ve bu, mekanizmanin degil kurulumun eseri olurdu. Karar tamamen ulkenin
## kendi durumundan turer.

## RIZA -- ucuz, yavas, sinsi (§4.2).
const RIZA := ["t_milliyetcilik", "t_cinsiyet", "t_uyusturucu", "t_cemaat",
		"t_mistisizm"]
## ZOR -- hizli, pahali, iz birakir. Riza yetmediginde devreye girer.
const ZOR := ["t_paramiliter", "t_sendika_baskisi", "t_tutuklama"]

## `t_*` alanindan `bol_*_yil` parametre adina. Agirliklarin tek kaynagi.
const BOL_ADI := {
	"t_milliyetcilik": "bol_milliyetcilik_yil",
	"t_cinsiyet": "bol_cinsiyet_yil",
	"t_uyusturucu": "bol_uyusturucu_yil",
	"t_cemaat": "bol_cemaat_yil",
	"t_mistisizm": "bol_mistisizm_yil",
	"t_paramiliter": "bol_paramiliter_yil",
	"t_sendika_baskisi": "bol_sendika_yil",
	"t_tutuklama": "bol_tutuklama_yil",
}

var P: KrizParam

## Oyuncunun ulkesi -- aktor ONA DOKUNMAZ. -1 = hepsi AI.
var oyuncu: int = -1

# ---------------------------------------------------------------------------
# KALIBRASYON
# ---------------------------------------------------------------------------
# Katmanlarin kendi sabitlerini tasimasi v2'nin deyimi (`UretimKatmani`nin
# `yukseltme_maliyeti`si gibi): `var`dir, cunku tarama ornek bazinda degistirir.

## ORGUTLU OFKE (`Omega * orgutlu`) bu degerde tehdit 1.0 sayilir.
##
## ILK YAZIMDA `PR` KULLANILDI VE OLCUM ONU CURUTTU. `PR` kampanya boyunca
## 0.4501-0.5050 arasinda duruyor -- aralik 0.055 -- ve `tehdit_olcek = 0.35`
## ile HER ULKEDE HER TIK 1.0'a kirpiliyordu. Surucu bir sabit olmustu; B6'nin
## savas sabitinde olculen doygunluk hatasinin aynisi.
##
## Yerine gecen buyukluk §4.1'in kendi hedefi: "amac ofkeyi azaltmak degil,
## ofkenin SINIFSAL ORGUTLENMEYE donusmesini kirmak." Olculdu -- `Omega`
## 0.0-1.0, `orgutlu` 0.34-0.44, carpimlari 0.0-0.380 (medyan 0.086). Yani
## carpim gercekten ayirt ediyor, `PR` etmiyordu.
var tehdit_olcek: float = 0.75

var tehdit_agirlik: float = 0.80
## Birikim tikanmasi -- `(i - r)`. `_tolerans`in endojen kolu da bunu okur.
##
## OLCULDU: bu terim gec kampanyada DOYAR (medyan 1.0), cunku LTRPF `r`yi
## faizin altina indirir. Yani ayirt edici DEGIL, bir TABANDIR: "kar orani
## cokmus bir ekonomide devlet zaten karanlik araca yakindir". Agirligi bu
## yuzden kucuk tutulur; ayirt etmeyi tehdit terimi yapar.
var tikanma_agirlik: float = 0.20
## Mesruiyet: rizasi yerinde bir devletin karanlik araca ihtiyaci azdir.
##
## ILK YAZIMDA BU TERIM OLCUMU TERSINE CEVIRMISTI. Uc bilesenin ucu de doygun
## olunca ayakta kalan tek varyans `PC`ninkiydi (0.0005-0.1865) ve eksi
## isaretle girdigi icin kesit "tehdidi yuksek ulke daha AZ uzaniyor" diye
## okundu. Olculen sey tehdidin degil mesruiyetin iliskisiydi.
var mesruiyet_agirlik: float = 0.20

## ZOR BU ESIGIN USTUNDE DEVREYE GIRER (§4.2: "riza yetmediginde").
var zor_esigi: float = 0.45
## Baskici karakter esigi asagi ceker: boyle bir devlet zora daha erken uzanir.
var zor_egilim: float = 0.50

## Taktiklerin hedefe yaklasma hizi (YILLIK). Anlik degil: bir devlet aygitini
## tehdit gecti diye ertesi hafta sokmez.
var hiz_yil: float = 0.25

## Ust sinir -- kolun toplam siddeti.
##
## KALIBRE EDILDI (`--v2-aktor-tarama`, 10 ulke x 150 yil, tohum 42). Dort
## olcut birden okundu, cunku bu kolun iki ayri sessiz bozulma yolu var
## (B3'un uyarisi): fazla guclu olursa devrimi IMKANSIZ kilar, fazla zayif
## olursa ETKISIZ kalir.
##
## PENCERE TAM UFUKTUR (1836-2100). Ilk tarama 150 yilda bitiyordu ve secilen
## kol (0.30/0.70) 200 yila uzatilinca devrimi SIFIRLADI -- deponun iki kez
## kaydettigi ders, zaman ekseninde: yarim pencerede eslestirmek eslestirmez.
##
##   olcek/tavan   yayilim   riza    zor   riza_yil zor_yil  devrim  kesit(son)
##   0.30 / 0.70    0.504   0.327  0.341    1936     1942      1     +0.0001
##   0.50 / 1.00    0.528   0.387  0.386    1937     1944      2     +0.0188
##   0.75 / 0.70    0.353   0.206  0.164    1972     1995      2     +0.0069
##   (aktorsuz taban: yayilim 0.000, devrim 3 -- 1945, 1989, 2010)
##
## `olcek = 0.30` REDDEDILDI: gec kampanyada `Omega` 1.0'a doyuyor, tehdit
## terimi herkeste tavana dayaniyor ve KESIT SIFIRA COKUYOR (+0.0001) --
## yani surucu yine ayirt etmez hale geliyor, sadece daha gec. Ayni satirda
## `zor` rizayi GECIYOR (0.341 > 0.327), yani §4.2'nin "riza yetmediginde zor"
## sirasi kampanya sonunda tersine donuyor.
##
## `0.75 / 0.70` alindi: riza kampanya boyunca baskin kalir (0.206 > 0.164),
## zor rizadan YIRMI UC YIL sonra acilir (1972 -> 1995), yayilim harita
## modunu canli tutar, ve devrim TABANDAN AZ AMA SIFIR DEGIL (3 -> 2) --
## cekirdegin kendi yorumu bu: "bolunme devrimi ONLEMEZ, ERTELER".
var tavan: float = 0.70

var _riza_agirlik: Dictionary = {}
var _zor_agirlik: Dictionary = {}


func _init(p_param: KrizParam = null) -> void:
	P = p_param if p_param != null else KrizParam.new()
	_riza_agirlik = _agirliklar(RIZA)
	_zor_agirlik = _agirliklar(ZOR)


## Aygit icinde normalize edilmis bolunme katsayilari. En guclu taktik 1.0.
##
## AYGIT ICINDE normalize edilir, ikisi birden degil: yoksa zor aygiti riza
## aygitinin golgesinde kalirdi (en agir zor taktigi 0.040, en agir riza
## taktigi 0.075) ve "riza yetmeyince zora gecilir" kurali sayisal olarak
## kendini gosteremezdi.
func _agirliklar(alanlar: Array) -> Dictionary:
	var en_buyuk := 0.0
	for alan in alanlar:
		en_buyuk = maxf(en_buyuk, float(P.get(String(BOL_ADI[alan]))))
	var c := {}
	for alan in alanlar:
		c[alan] = float(P.get(String(BOL_ADI[alan]))) / maxf(en_buyuk, 1e-9)
	return c


## Bir tikin politika karari. SALT `t_*` alanlarina yazar.
func adim(ulkeler: Array[KrizDurumu], donem_yil: float) -> void:
	var hiz := Oran.donem_uyum(hiz_yil, donem_yil)
	for i in range(ulkeler.size()):
		if i == oyuncu:
			continue
		var d := ulkeler[i]
		if d.rejim != "kapitalist":
			# §4.5: "Sosyalist parti iktidara gelirse kollar TERSINE doner --
			# bolunmeyi cozmek, orgutlenmeyi derinlestirmek senin isin olur."
			# Aygit bir anda kaybolmaz, ayni hizla sonumlenir.
			for alan in RIZA:
				d.set(alan, maxf(0.0, float(d.get(alan)) * (1.0 - hiz)))
			for alan in ZOR:
				d.set(alan, maxf(0.0, float(d.get(alan)) * (1.0 - hiz)))
			continue

		var istek := _istek(d)
		# RIZA HER ZAMAN ACIK, ZOR ESIK USTUNDE (§4.2).
		var esik := clampf(zor_esigi * (1.0 - zor_egilim * d.baski_egilimi),
				0.0, 0.99)
		var zor := maxf(0.0, istek - esik) / maxf(1e-9, 1.0 - esik)
		_yaklas(d, RIZA, _riza_agirlik, istek * tavan, hiz)
		_yaklas(d, ZOR, _zor_agirlik, zor * tavan, hiz)


## Karanlik devlete uzanma istegi [0,1].
##
## Terimler `_tolerans`in endojen kolundan tanidik olmali: orada da tikanma,
## ofke, baski egilimi ve mesruiyet vardi. Fark, orada olcunun `mafya_tolerans`
## olmasi; burada olcu SEKIZ TAKTIGIN TAMAMI.
func _istek(d: KrizDurumu) -> float:
	# TEHDIT = ORGUTLU OFKE. Ofke tek basina bir devrim tehdidi degildir ve
	# orgutlenme tek basina da degil; tehlikeli olan ikisinin CARPIMIDIR, ve
	# karanlik devletin kirmaya calistigi sey tam olarak o carpimin
	# buyumesidir (§4.1).
	var tehdit := clampf(d.Omega * d.orgutlu / maxf(tehdit_olcek, 1e-9),
			0.0, 1.0)
	var tikanma := clampf((d.i_yil - d.r_yil)
			/ maxf(P.v44.kd_tikanma_olcek, 1e-9), 0.0, 1.0)
	var istek := (tehdit_agirlik * tehdit
			+ tikanma_agirlik * tikanma
			- mesruiyet_agirlik * minf(d.PC, 1.0))
	return clampf(istek, 0.0, 1.0)


func _yaklas(d: KrizDurumu, alanlar: Array, agirlik: Dictionary,
		duzey: float, hiz: float) -> void:
	for alan in alanlar:
		var hedef := clampf(duzey * float(agirlik[alan]), 0.0, 1.0)
		var simdi := float(d.get(alan))
		d.set(alan, clampf(simdi + hiz * (hedef - simdi), 0.0, 1.0))
