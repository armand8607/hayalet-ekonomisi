class_name Oyun
extends RefCounted

## B7 -- oyun oturumu. Arayuzun v2 motoruna TEK kapisi.
##
## v4.4 tarafindaki `Sim`in karsiligidir, ama otoload DEGILDIR. Sebep ayni:
## kapilar ve tarama koslari ayni anda birden cok bagimsiz oturum kurar, ve
## tek bir kuresel oturum olsaydi bir kapinin kurulumu digerininkini ezerdi.
##
## ------------------------------------------------------------------------
## KABUK MOTORU DEGISTIRMEZ
## ------------------------------------------------------------------------
## GOZLEMCI KIPINDE (`oyuncu < 0`) bu sinif motora hicbir sey yazmaz: yalnizca
## `dunya.adim()` cagirir ve okur. `--v2-oyun`un birinci kademesi tam olarak
## bunu sinar -- gozlemci kipinde surulen bir dunya, dogrudan `Dunya.adim()`
## ile surulen dunyayla ALAN ALAN ayni cikmali. Haritanin B5'te verdigi
## sozun ayni: gorunum motora dokunmaz.
##
## Oyuncu secildiginde DEGISEN TEK SEY, o ulkenin `KaranlikDevlet.otomatik`
## kolunun kapanmasidir -- taktikleri artik AI degil oyuncu yazar (§4.5).
## Bu bir kabuk yan etkisi degil, oyunun tanimi.
##
## ------------------------------------------------------------------------
## POLITIKA ANINDA ETKI ETMEZ AMA KUYRUKTA DA BEKLEMEZ
## ------------------------------------------------------------------------
## v4.4'un 8 turluk `pol_gecikme` kuyrugu v2'ye TASINMADI. v2'de kollarin
## kendi yerlesme hizi zaten denklemin icinde: `etg` hedefe
## `etg_yerlesme_yil` ile yaklasir, taktikler `bolunme` STOKUNU besler,
## merdiven yatirim butcesiyle sinirlidir. Ikinci bir gecikme eklemek ayni
## seyi iki kez modellemek olurdu.

const HAFTA := 1.0 / 52.0
const BAS_YIL := 1836.0
const BITIS_YIL := 2100.0

## Yilda kac tik. `Gecmis.YILDA_TIK` ile AYNI olmak zorunda; ornekleme onu
## sayiyor.
const YILDA_TIK := Gecmis.YILDA_TIK

## §5.5: "12 cekirdek metrik grafigi panele tasinir -- SILINMEZ." v4.4'un
## `Sim.CEKIRDEK_METRIKLER` listesinin v2 alan adlariyla karsiligi.
##
## PANEL KENDI LISTESINI TUTMAZ, bunu okur. Iki yerin birbirinden kaymasi
## boylece imkansiz olur.
const CEKIRDEK_METRIKLER: Array[Dictionary] = [
	{"anahtar": "r_yil", "ad": "Kâr oranı", "bicim": "oran3"},
	{"anahtar": "cv", "ad": "Organik bileşim c/v", "bicim": "oran2"},
	{"anahtar": "u", "ad": "Kapasite kullanımı", "bicim": "yuzde"},
	# Issizlik bir ALAN degil ISLEVDIR: ETG duzeltmesi olmadan gonullu
	# cekilme istihdam gibi okunur. Haritanin `issizlik` modu de ayni
	# islevi cagirir -- panel ile harita ayni ulke icin farkli sayi
	# gosterirse hangisinin dogru oldugu ekranda cevaplanamaz.
	{"anahtar": "issizlik", "ad": "İşsizlik", "bicim": "yuzde",
			"islev": "iss_duzeltilmis"},
	{"anahtar": "pay", "ad": "Ücret payı", "bicim": "yuzde"},
	# IKISI DE STOK, ve `Y_yil`e BOLUNEREK gosterilir. Ham stok gosterilseydi
	# eksen adi ("/ Y") ile sayi ayri seyler anlatirdi; cekirdek de bu iki
	# buyuklugu her kullandigi yerde hasilaya boluyor.
	{"anahtar": "borc", "payda": "Y_yil", "ad": "Hanehalkı borcu / Y",
			"bicim": "oran2"},
	{"anahtar": "varlik", "payda": "Y_yil", "ad": "Spekülatif varlık / Y",
			"bicim": "oran2"},
	{"anahtar": "Omega", "ad": "Siyasi öfke", "bicim": "yuzde"},
	{"anahtar": "org", "ad": "Örgütlenme", "bicim": "yuzde"},
	{"anahtar": "oto", "ad": "Otomasyon payı", "bicim": "yuzde"},
	{"anahtar": "canli_pay", "ad": "Canlı emek payı", "bicim": "yuzde"},
	{"anahtar": "PR", "ad": "Protesto riski", "bicim": "yuzde"},
]

## §4.6'nin temsil ilkesi: "cezaevi orani, siyasi cinayet sayisi ve egitim
## tabanindaki cokus GORUNUR METRIKLERDIR, gizli carpanlar degil." Bu liste
## o cumlenin ekrandaki karsiligidir; karanlik devlet acildiginda bedeli
## ayni panelde sayilir.
const KARANLIK_METRIKLER: Array[Dictionary] = [
	{"anahtar": "bolunme", "ad": "Bölünme", "bicim": "oran2"},
	{"anahtar": "cezaevi_orani", "ad": "Cezaevi oranı", "bicim": "yuzde"},
	{"anahtar": "uyusturucu_orani", "ad": "Uyuşturucu yaygınlığı", "bicim": "yuzde"},
	{"anahtar": "egitim", "ad": "Eğitim düzeyi", "bicim": "oran2"},
	{"anahtar": "sehit", "ad": "Şehit stoku", "bicim": "oran2"},
	{"anahtar": "karsi_hareket", "ad": "Karşı hareket", "bicim": "oran2"},
]

## KANONIK 12'YE DAHIL DEGIL, ama kaydedilir. §5.5 on iki metrigi sayiyor ve
## o liste degistirilmez; `q` yine de tutulmali cunku oyuncunun asil kolu
## (merdiven) dogrudan ONU yazar ve §2.4'un tuzak zinciri -- `q`↑ -> `c/v`↑
## -> `r`↓ -- ortadaki halka olmadan ekranda okunamaz.
const EK_METRIKLER: Array[Dictionary] = [
	{"anahtar": "q", "ad": "Verimlilik", "bicim": "oran2"},
]

## Sekiz adlandirilmis taktik (§4.6). Adlar ve bedeller `KaranlikDevlet`in
## kendi tablosundan alinmistir -- orada mekanizma, burada ekran; ikisinin
## ayrismamasi icin metin TEK yerden turetilmeli, ve o yer mekanizmadir.
##
## "ETKINLIK KOLU" GIBI SUNULMAZ. Her satirda magdur adlandirilir ve bedeli
## yazilir; oyuncunun gormedigi gizli bir carpan yoktur.
const TAKTIKLER: Array[Dictionary] = [
	{"alan": "t_uyusturucu", "aygit": "rıza",
			"ad": "Uyuşturucu ekonomisine göz yumma",
			"bedel": "mafya toleransı → lümpenleşme → gasp → spekülatif stok (Minsky'yi besler)"},
	{"alan": "t_cemaat", "aygit": "rıza",
			"ad": "Dini cemaat ve tarikat ağlarının önünü açma",
			"bedel": "eğitim tabanı aşınır"},
	{"alan": "t_mistisizm", "aygit": "rıza",
			"ad": "Mistisizm: astroloji, evrim karşıtlığı, düz dünyacılık",
			"bedel": "eğitim ve bilimde en ağır aşınma → verimlilik büyümesi düşer"},
	{"alan": "t_milliyetcilik", "aygit": "rıza",
			"ad": "Milliyetçilik: etnik gruplara ve mültecilere düşmanlık, ırkçılık",
			"bedel": "topluluklar arası şiddet → protesto sönümü. EN YÜKSEK bölünme itkisi"},
	{"alan": "t_cinsiyet", "aygit": "rıza",
			"ad": "Cinsiyet baskısı: LGBT düşmanlığı, kadınlara baskıcı politikalar",
			"bedel": "katılım düşer → canlı emek → yeni değer düşer"},
	{"alan": "t_sendika_baskisi", "aygit": "zor",
			"ad": "Sendikal harekete baskı, grev kırma",
			"bedel": "örgütlenme doğrudan kırılır"},
	{"alan": "t_tutuklama", "aygit": "zor",
			"ad": "Muhalif siyasi karakterlerin tutuklanması",
			"bedel": "cezaevi oranı → etkin emek, siyasi sermaye, eğitim"},
	{"alan": "t_paramiliter", "aygit": "zor",
			"ad": "Paramiliter faşist gruplar, siyasi cinayet",
			"bedel": "şehit stoku → örgütlenme kısa vadede düşer, öfke orta vadede yükselir"},
]

var dunya: Dunya = null
## Oyuncunun `dunya` icindeki indeksi. -1 = GOZLEMCI (motor hic degismez).
var oyuncu: int = -1
var tohum: int = 42
var gecmis: Gecmis = null
var gunce: Gunce = null

var _tik: int = 0


## Dunyayi kurar. `oyuncu_kod` bos ise gozlemci kipi.
##
## `kodlar` bos ise haritanin simule edilen tam kadrosu kullanilir; kapilar
## kucuk bir alt kume verir cunku tam kadroda bir kampanya ~10 dakikadir.
func kur(oyuncu_kod: String = "", p_tohum: int = 42,
		kodlar: PackedStringArray = PackedStringArray()) -> void:
	tohum = p_tohum
	dunya = Harita.dunya_kur(kodlar, p_tohum, BAS_YIL)
	oyuncu = -1
	if oyuncu_kod != "":
		oyuncu = _dunya_indeksi(oyuncu_kod)
		if oyuncu < 0:
			push_warning("Oyuncu ulkesi simule edilen dunyada yok: " + oyuncu_kod)
		else:
			# TAKTIKLERI ARTIK OYUNCU YAZAR (§4.5). `Harita.dunya_kur`
			# butun ulkelerde `otomatik = true` kurar; oyuncununki burada
			# kapanir. Kapanmasaydi oyuncunun kolu ile AI'nin kolu ayni
			# alana yazar ve hangisinin etkisi olculdugu TANIMSIZ kalirdi.
			dunya.cekirdekler[oyuncu].karanlik.otomatik = false
			# AI POLITIKA AKTORU DE OYUNCUYA DOKUNMAZ. Dokunsaydi oyuncunun
			# kaydiricisi ile aktor ayni alana yazar, ve ekranda gorulen deger
			# ile motordaki deger her tik birbirini ezerdi.
			if dunya.aktor != null:
				dunya.aktor.oyuncu = oyuncu

	_tik = 0
	gecmis = Gecmis.new()
	var hepsi: Array[Dictionary] = []
	hepsi.append_array(CEKIRDEK_METRIKLER)
	hepsi.append_array(KARANLIK_METRIKLER)
	hepsi.append_array(EK_METRIKLER)
	gecmis.kur(hepsi, dunya.ulkeler.size())
	# BASLANGIC SATIRI ALINMAZ, ve bu bir eksiklik degil duzeltme.
	#
	# Olculdu: `t=0`da orneklenirse `r_yil` 0.0 kaydedilir, cunku kar orani
	# bir ALAN degil cekirdegin CIKTISIDIR ve ilk `adim()` kosmadan once
	# hesaplanmamistir. Grafikler o zaman 1836'da sifirdan baslayip 1837'de
	# 0.10'a sicrar -- her kar orani grafiginin sol ucunda olmayan bir cokus
	# ve toparlanma. Ayni sey `u`, `PR`, `Omega` ve butun turetilmis
	# metrikler icin gecerli; `pay` ve `q` gibi baslangic ALANLARI icin
	# degil, yani hata metrigin turune gore SESSIZCE degisirdi.
	#
	# Ilk ornek bu yuzden ilk yilin SONUNDA alinir: seri 1837'de baslar.
	gunce = Gunce.new()
	gunce.kur(dunya)


func _dunya_indeksi(kod: String) -> int:
	for i in range(dunya.adlar.size()):
		if dunya.adlar[i] == kod:
			return i
	return -1


## `n` hafta ilerletir. Ufku asan tikler ATILMAZ, hic kosulmaz: kampanya
## 2100'de biter ve orada durur.
func ilerle(n: int = 1) -> void:
	for _k in range(n):
		if bitti():
			return
		dunya.adim(HAFTA)
		_tik += 1
		gunce.topla(dunya)
		if _tik % YILDA_TIK == 0:
			# Takvim yili TIKTEN turetilir, `dunya.yil`den degil: birikmis
			# kayan nokta hatasi yil etiketini bir yil geri kaydiriyordu.
			gecmis.ornekle(dunya, BAS_YIL + float(_tik / YILDA_TIK))


func bitti() -> bool:
	return dunya == null or dunya.yil >= BITIS_YIL


func yil() -> float:
	return dunya.yil if dunya != null else BAS_YIL


func tik() -> int:
	return _tik


## Ekranda yazilacak takvim yili. `int(yil())` DOGRUDAN KULLANILMAZ: birikmis
## kayan nokta hatasi yil sinirinda bir yil geri gosterir (1836.9999... ->
## 1836). Epsilon toleransi bunu yutar, yil ortasini yukari yuvarlamadan.
func takvim_yili() -> int:
	return floori(yil() + 1e-6)


## [0,1] -- ust seritteki ilerleme cubugu.
func ilerleme() -> float:
	return clampf((yil() - BAS_YIL) / (BITIS_YIL - BAS_YIL), 0.0, 1.0)


func oyuncu_durumu() -> KrizDurumu:
	if dunya == null or oyuncu < 0:
		return null
	return dunya.ulkeler[oyuncu]


## Ulkenin ekranda gorunen adi. Kampanya 1836'da basladigi icin oynanabilir
## ulkeler tarihsel adiyla anilir (§5.8b).
func ad(i: int) -> String:
	if dunya == null or i < 0 or i >= dunya.adlar.size():
		return "?"
	var ki := Harita.indeks(dunya.adlar[i])
	if ki < 0:
		return dunya.adlar[i]
	var u := Harita.kayit()[ki]
	var t := String(u["ad_1836"])
	return t if t != "" else String(u["ad"])


# ===========================================================================
# OYUNCUNUN KOLLARI
# ===========================================================================
# Hepsi gozlemci kipinde SESSIZCE ISLEMSIZDIR ve `false` doner. Kapinin
# birinci kademesi buna dayaniyor: gozlemci bir oturum motoru degistiremez.

## Sekiz taktikten biri. `deger` [0,1].
##
## §4.6: bu bir "etkinlik" kolu degildir. Ekranda magduru adlandirilir,
## bedeli `KARANLIK_METRIKLER` ile ayni panelde sayilir.
func taktik_ayarla(alan: String, deger: float) -> bool:
	var d := oyuncu_durumu()
	if d == null:
		return false
	for t in TAKTIKLER:
		if String(t["alan"]) == alan:
			d.set(alan, clampf(deger, 0.0, 1.0))
			return true
	push_warning("Bilinmeyen taktik: " + alan)
	return false


func taktik_degeri(alan: String) -> float:
	var d := oyuncu_durumu()
	return float(d.get(alan)) if d != null else 0.0


## §2.4'un MERKEZI TUZAGI, ve oyuncunun asil kolu (§5.11): yatirimin ne
## kadari uretim yontemi merdivenine harcanacak.
##
## Yukseltmek `q`yu yukseltir -> `c/v` yukselir -> `r` DUSER. Bina defterinde
## karli gorunen yukseltme toplam kar oranini asagi ceker; kol cikarilamaz
## cunku oyunun anlattigi sey tam olarak budur.
func yukseltme_payi_ayarla(pay: float) -> bool:
	if dunya == null or oyuncu < 0:
		return false
	var m: UretimKatmani = dunya.cekirdekler[oyuncu].mikro
	if m == null:
		return false
	m.yukseltme_payi = clampf(pay, 0.0, 1.0)
	return true


func yukseltme_payi() -> float:
	if dunya == null or oyuncu < 0:
		return 0.0
	var m: UretimKatmani = dunya.cekirdekler[oyuncu].mikro
	return m.yukseltme_payi if m != null else 0.0


## Temel gelir hedefi (hasilanin payi). YALNIZCA KAPITALIST REJIMDE
## tanimlidir -- planli ekonomide ucret zaten planla belirlenir, ve cekirdek
## sosyalist rejimde bu alani her tik sifirlar. Arayuz bunu gizlemek yerine
## soylemeli.
func etg_ayarla(oran: float) -> bool:
	var d := oyuncu_durumu()
	if d == null:
		return false
	d.etg_hedef = clampf(oran, 0.0, 0.40)
	return true


func etg_hedefi() -> float:
	var d := oyuncu_durumu()
	return d.etg_hedef if d != null else 0.0


## Savas ilan etme egilimi (§3.2). Kriz cikisi olarak savasin oyuncu tarafi.
func saldirganlik_ayarla(deger: float) -> bool:
	var d := oyuncu_durumu()
	if d == null:
		return false
	d.saldirganlik = clampf(deger, 0.0, 1.0)
	return true


func saldirganlik() -> float:
	var d := oyuncu_durumu()
	return d.saldirganlik if d != null else 0.0


## Dis ticarete aciklik. Cevre icin bu bir tuzak koludur: aciklik hem pazar
## hem de deger transferi kanalidir (§C, §L).
func aciklik_ayarla(deger: float) -> bool:
	if dunya == null or oyuncu < 0:
		return false
	dunya.aciklik[oyuncu] = clampf(deger, 0.0, 2.0)
	return true


func aciklik() -> float:
	if dunya == null or oyuncu < 0:
		return 0.0
	return dunya.aciklik[oyuncu]


static func bicimle(v: float, bicim: String) -> String:
	return HaritaModu.bicimle(v, bicim)
