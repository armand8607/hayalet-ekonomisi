class_name SavasKatmani
extends RefCounted

## v2'nin SAVAS KATMANI -- B4.
##
## Tasarim belgesi §3. Savas ayri bir strateji katmani DEGIL, iktisadi krizin
## dis politikadaki gorunumudur:
##
##   > Kar orani sikistikca sermaye ulusal sinirlarin disina tasar; pazar
##   > arayisi, sermaye ihraci ve cevre uzerindeki rekabet ayni sikismanin
##   > yuzleridir.
##
## Ve §3.2'nin acimasiz muhasebesi:
##
##   > SAVAS SERMAYEYI IMHA EDER, SERMAYENIN IMHASI KAR ORANINI YUKSELTIR.
##
## Yani savas "birak yansin" cikisinin ulusal olcekli ve silahli bicimidir.
## Oyun bunu bir zafer olarak degil BIR MUHASEBE olarak gosterir: kar orani
## grafigi savastan sonra yukari doner, nufus grafigi asagi. B4'un ilan
## edilmis olcutu tam olarak budur.
##
## ------------------------------------------------------------------------
## KAPSAM DURUSTLUGU (§3.4)
## ------------------------------------------------------------------------
## TAKTIK SAVAS YOKTUR. Cephe yonetimi, birlik hareketi, muharebe cozumu
## olmayacak. Savasin sonucunu `guc() = K*q`, yipranma, abluka ve ic cephe
## (ofke, orgutlenme) belirler. Hedeflenen sey askeri derinlik degil, savasin
## ekonomiden CIKMASI ve ekonomiye DONMESIDIR.
##
## ------------------------------------------------------------------------
## NE TASINDI
## ------------------------------------------------------------------------
## v4.4'un savas blogu (`motor.py:2953-3016`, `2212-2217`, `1747`, `1931`,
## `1948`, `2060`) denklem kaynagi olarak alindi. Tasinanlar:
##
##   savas karari      -- karlilik sikismasi + saldirganlik + kaynak + doktrin
##   emperyalist mudahale -- devrim olan ulkeye, blok tehdidi carpaniyla
##   seferberlik       -- `u` yukselir (atil kapasite savasa kosulur)
##   savas talebi      -- `D_talep >= Y_pot*0.95` (asiri uretimi EMER)
##   sermaye yikimi    -- `K *= (1 - sv_yikim*(0.5+oran))`
##   savas tuketimi    -- `pay` baskilanir
##   savas yorgunlugu  -- `Omega` yukselir
##   olum orani        -- nufus artisi savasta duser
##   deger devaluasyonu-- `deger_carpani *= (1 - dev_savas)`
##   yenilgi           -- `Omega` sicrar, `K *= 0.94`
##   karsi-devrim      -- yenilen sosyalist rejimde kapitalizm zorla restore
##
## MUTTEFIK KUSURU DEVRALINMADI. v4.4'te `muttefik` bir `set`ti ve
## `rng.choice(list(muttefik))` sira'ya bakiyordu; `PYTHONHASHSEED` yuzunden
## ayni tohum ayri sureclerde ayri sonuc veriyordu (CLAUDE.md'de motorun kendi
## kusuru olarak kayitli). v2'de dizi SIRALI tutulur, yani belirlenimlidir.
##
## ------------------------------------------------------------------------
## BIRIMLER -- ve buradaki tuzak en buyugu
## ------------------------------------------------------------------------
## v4.4'un savas sabitlerinin HEPSI tur (0.27 yil) cinsindendir ve uc ayri
## turdedir:
##
##   sv_min_sure / sv_max_sure -> SAYAC. `Oran.v44_sayac` ile donem sayisina.
##                                Kopyalanirsa savaslar 14 kat KISA surer.
##   sv_yikim / sv_tuketim     -> tur basina CARPAN. Yillik orana cevrilir,
##                                sonra doneme. Kopyalanirsa yikim 14 kat hizli.
##   ilan olasiligi            -> tur basina TEHLIKE. Yillik tehlikeye, sonra
##                                `1-(1-h)^dt` ile doneme. Kopyalanirsa savas
##                                salgin haline gelir -- `fx_baski` ile bir kez
##                                yasandi (198 yilda ulke basina 22 kriz).
##
## Ucu de ayri ayri cevrilir; TOPLU CARPAN YOKTUR.

## Parametreler.
var P: KrizParam

## Savas kapisi. Kapatilinca hicbir savas ilan edilmez ama suren savaslar
## isler -- karsi-olgusal olcum icin (B1b'nin dersi: mekanizmanin etkisi
## ancak ayni tohumla acik/kapali kosularak olculebilir).
var ilan_acik: bool = true

## EMPERYALIST MUDAHALE ayri kapatilabilir. §3.1'in "bir yerde devrim oldu ->
## kusatma, mudahale" satiri ile "rakip ayni cevreyi istiyor -> emperyalistler
## arasi savas" satirini ayirmak icin: ikisi ayni kapidan gecerse hangi
## kanalin olctugumuz sonucu urettigi bilinemez.
var mudahale_acik: bool = true

## Savasin RNG'si. Ulke cekirdeklerininkinden ve `Dunya`nInkinden AYRI:
## savas ilani ayrik bir olaydir ve baska bir kapiyi acip kapatmak savas
## cekilisini kaydirmamali.
var rng: PyRandom

## Kampanya boyunca ilan edilen savas sayisi (tani).
var ilan_sayisi: int = 0
## Emperyalist mudahale sayisi (tani).
var mudahale_sayisi: int = 0
## Karsi-devrim sayisi (tani).
var karsi_devrim_sayisi: int = 0


func _init(p_ornek: KrizParam = null, tohum: int = 4242) -> void:
	P = p_ornek if p_ornek != null else KrizParam.new()
	rng = PyRandom.new(tohum)


## Bir donem ilerletir. `Dunya.adim()` icinden, ULKE CEKIRDEKLERI
## KOSMADAN ONCE cagrilir: savas durumu bu donemin uretim ve talep
## hesabina girmeli, bir donem geriden degil.
func adim(ulkeler: Array[KrizDurumu], adlar: PackedStringArray,
		donem_yil: float) -> void:
	if ilan_acik:
		_savas_karari(ulkeler, adlar, donem_yil)
	_yikim_ve_cozum(ulkeler, adlar, donem_yil)


# ===========================================================================
# ILAN  --  krizin dis politikaya tasmasi
# ===========================================================================

## SAVAS KARARI (v4.4 `motor.py:2953-2984`).
##
## Iki ayri kanal, ve §3.1'in tablosunda ayri satirlar:
##
##   (1) EMPERYALIST MUDAHALE -- "bir yerde devrim oldu" satiri. Merkez
##       ulkeler, devrimden sonraki pencerede sosyalist ulkeye saldirir.
##       Sosyalist blok buyudukce mudahale istegi buyur: tehdit algisi
##       topyekun savasi davet eder.
##
##   (2) KARLILIK SIKISMASI -- "rakip ayni cevreyi istiyor" satiri.
##       `sikisma = (sv_r_ref - r)/sv_r_ref`, yani kar orani referansin
##       altina dustukce savas olasiligi buyur. Emperyalist savasin motordaki
##       tanimi budur: bir doktrin degil, bir KAR ORANI fonksiyonu.
func _savas_karari(ulkeler: Array[KrizDurumu], adlar: PackedStringArray,
		donem_yil: float) -> void:
	var n := ulkeler.size()
	var sos: Array[int] = []
	var kap: Array[int] = []
	for i in range(n):
		if ulkeler[i].rejim == "sosyalist":
			sos.append(i)
		else:
			kap.append(i)

	# --- (1) EMPERYALIST MUDAHALE ---
	if mudahale_acik and not sos.is_empty():
		var blok_pay := float(sos.size()) / maxf(float(n), 1.0)
		var tehdit := 1.0 + P.v44.sv_blok_tehdidi * blok_pay
		var pencere := Oran.yillik_sure(P.v44.sv_mudahale_pencere, Oran.V44_TUR_YIL)
		for s in sos:
			var d_s := ulkeler[s]
			if d_s.devrim_yil < 0.0 or d_s.savasta():
				continue
			if not (d_s.yil - d_s.devrim_yil > 0.0 and d_s.yil - d_s.devrim_yil <= pencere):
				continue
			for m in kap:
				var d_m := ulkeler[m]
				if d_m.savasta():
					continue
				var istek := (P.v44.sv_mudahale * d_m.saldirganlik * tehdit
						* (1.0 if d_m.guc() > d_s.guc() * 0.8 else 0.3))
				if rng.random() < _tehlike(istek * P.v44.sv_carpan * 0.10, donem_yil):
					_ilan(ulkeler, adlar, m, s, donem_yil)
					mudahale_sayisi += 1
					break

	# --- (2) KARLILIK SIKISMASI ---
	for i in kap:
		var c := ulkeler[i]
		if c.savasta():
			continue
		# KAR ORANI REFERANSIN ALTINA DUSTUKCE SAVAS OLASILIGI BUYUR.
		var sikisma := maxf(0.0, (P.v44.sv_r_ref - c.r_yil) / P.v44.sv_r_ref)
		# Kaynak arayisi ancak sanayilesmis bir ekonomide savas sebebidir.
		var kaynak := P.v44.sv_kaynak if c.era >= 3 else 0.0
		var p := (P.v44.sv_taban + P.v44.sv_kar_baskisi * sikisma + kaynak
				+ P.v44.sv_doktrin * c.saldirganlik) * c.saldirganlik
		if rng.random() >= _tehlike(p * 0.06 * P.v44.sv_carpan, donem_yil):
			continue
		# HEDEF SECIMI: muttefik olmayan, savasta olmayan, ve gucu bizden
		# cok ustun OLMAYAN bir ulke. Zayifi secme egilimi rastgelelikle
		# yumusatilir, yoksa hep ayni ulke hedef olur.
		var en_iyi := -1
		var en_iyi_skor := -INF
		for j in range(n):
			if j == i:
				continue
			var h := ulkeler[j]
			if h.savasta() or adlar[j] in c.muttefik:
				continue
			if h.guc() >= c.guc() * 1.15:
				continue
			var skor := (h.L_etkin * h.q) / maxf(h.guc(), 1.0) + rng.random() * 0.4
			if skor > en_iyi_skor:
				en_iyi_skor = skor
				en_iyi = j
		if en_iyi >= 0:
			_ilan(ulkeler, adlar, i, en_iyi, donem_yil)


## Tur basina bir TEHLIKE oranini bu donemin olasiligina cevirir.
##
## `h * dt` ile DEGIL `1 - (1-h_yil)^dt` ile: kucuk dt'de ikisi yakindir ama
## dogrusal yaklasim olcek degismezligini kirar ve `--v2-olcek`te gorunur.
func _tehlike(tur_basina: float, donem_yil: float) -> float:
	var yillik := clampf(Oran.yillik_akim(tur_basina, Oran.V44_TUR_YIL), 0.0, 0.999999)
	return 1.0 - pow(1.0 - yillik, donem_yil)


## Savas ilan eder. CIFT UZERINDE tanimlidir -- iki tarafa da ayni sure
## yazilir, yoksa biri savasta digeri baris icinde olurdu.
func _ilan(ulkeler: Array[KrizDurumu], adlar: PackedStringArray,
		i: int, j: int, donem_yil: float) -> void:
	# SURE v2'NIN KENDI KALIBRASYONUDUR, v4.4'un `sv_min_sure`/`sv_max_sure`si
	# DEGIL: o ikisi 5.4-18.9 yil verir ve olculdugunde savas basina %31.8
	# nufus kaybina cikti -- tarihsel capanin (buyuk savaslarda %4-13) iki
	# katindan fazlasi. Gerekce `KrizParam.savas_sure_*_yil`da.
	var alt := KrizParam.sure_donem(P.savas_sure_alt_yil, donem_yil)
	var ust := KrizParam.sure_donem(P.savas_sure_ust_yil, donem_yil)
	var sure := rng.randint(alt, ust)
	ulkeler[i].savas[adlar[j]] = sure
	ulkeler[j].savas[adlar[i]] = sure
	ilan_sayisi += 1


# ===========================================================================
# YIKIM VE COZUM  --  §3.2'nin muhasebesi
# ===========================================================================

## Suren savaslarin yikimini isler ve suresi dolanlari cozer.
##
## YIKIM CEKIRDEKTE DEGIL BURADA. `K` cekirdegin `_birikim` blogunda
## buyutulur; savas yikimi ondan SONRA uygulanir, tipki v4.4'teki gibi
## (`motor.py:2210-2215`: once `K = K*(1+g)`, sonra savas carpani). Sira
## onemli -- tersi olsaydi yikilan sermaye ayni donemde geri buyurdu.
func _yikim_ve_cozum(ulkeler: Array[KrizDurumu], adlar: PackedStringArray,
		donem_yil: float) -> void:
	var ad_indeks := {}
	for i in range(adlar.size()):
		ad_indeks[adlar[i]] = i

	for i in range(ulkeler.size()):
		var c := ulkeler[i]
		if not c.savasta():
			continue
		c.savas_toplam += 1

		# --- YIKIM (v4.4 `motor.py:2212-2217`) ---
		# Rakiplerin toplam gucune gore olceklenir: guclu bir dusmana karsi
		# savas daha cok yikar.
		var rakip_guc := 0.0
		for rk in c.savas:
			var j: int = ad_indeks.get(rk, -1)
			if j >= 0:
				rakip_guc += ulkeler[j].guc()
		var oran := rakip_guc / maxf(c.guc() + rakip_guc, 1e-6)

		var K_once := c.K
		var yikim_yil := Oran.v44_akim(P.v44.sv_yikim * (0.5 + oran))
		c.K = maxf(1.0, c.K * (1.0 - Oran.donem_akim(yikim_yil, donem_yil)))
		c.savas_yikimi += K_once - c.K

		# SAVAS TUKETIMI: ucret payi baskilanir -- top ve tereyagi.
		var tuketim_yil := Oran.v44_akim(P.v44.sv_tuketim)
		c.pay = maxf(0.12, c.pay * (1.0 - Oran.donem_akim(tuketim_yil, donem_yil)))
		# SAVAS YORGUNLUGU: ofke birikir.
		c.Omega = minf(1.0, c.Omega + Oran.donem_akim(
				Oran.v44_akim(P.v44.sv_yorgunluk * 0.8), donem_yil))
		# DEGER DEVALUASYONU: savas sermayenin deger duzeyini de dusurur.
		c.deger_carpani = maxf(P.v44.dev_taban,
				c.deger_carpani * (1.0 - Oran.donem_akim(
					Oran.v44_akim(P.v44.dev_savas), donem_yil)))

		# --- NUFUS KAYBI (v4.4 `motor.py:2060`) ---
		# v4.4'te olum orani savasta 0.008 artiyordu. B4'un olcutunun ikinci
		# yarisi budur: nufus grafigi asagi.
		var L_once := c.L_etkin
		c.L_etkin = maxf(1.0, c.L_etkin * (1.0 - Oran.donem_akim(
				P.savas_olum_yil, donem_yil)))
		c.savas_nufus_kaybi += L_once - c.L_etkin

		# --- COZUM ---
		for rk in c.savas.keys():
			c.savas[rk] = int(c.savas[rk]) - 1
			if int(c.savas[rk]) > 0:
				continue
			var j: int = ad_indeks.get(rk, -1)
			if j >= 0:
				_cozum(c, ulkeler[j], oran)
			c.savas.erase(rk)


## Savasin sonucu. §3.4 geregi tek belirleyici GUC ORANIDIR.
##
## Kaybeden taraf iki bedel oder: `Omega` sicrar (toplumsal gerilim patlar)
## ve sermayesinin bir kismini daha kaybeder. Ve yenilen bir SOSYALIST rejimde
## kapitalizm zorla restore edilebilir -- §3.1'in "kusatma, abluka, mudahale"
## satirinin en sert ucu.
func _cozum(c: KrizDurumu, rakip: KrizDurumu, oran: float) -> void:
	# `oran` rakibin gucunun payidir; kendi payimiz 1-oran.
	var kendi_pay := 1.0 - oran
	if kendi_pay >= 0.42:
		return

	c.Omega = minf(1.0, c.Omega + P.v44.sv_yenilgi_omega)
	c.K = maxf(1.0, c.K * 0.94)
	c.yenilgi_sayisi += 1

	# KARSI-DEVRIM. Askeri ezilme ya da ic cokus, ikisi de kapi.
	var ezildi := kendi_pay < P.v44.kd_yenilgi_orani
	if (c.rejim == "sosyalist" and rakip.rejim == "kapitalist" and ezildi
			and rng.random() < P.v44.kd_askeri_olasilik):
		c.rejim = "kapitalist"
		c.Omega = 0.10
		c.org *= 0.5
		c.devrim_yil = -1.0
		c.parti_iktidari = false
		c.pay = maxf(0.15, c.pay * 0.75)
		c.IR = 0.75
		c.muttefik = PackedStringArray()
		karsi_devrim_sayisi += 1
