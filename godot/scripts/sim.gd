extends Node

## Otoload 4 -- aktif koşunun sahibi ve arayüzün motora tek kapısı.
##
## Motorun kendisi (`GhostEngine`) otoload DEĞİLDİR; bu düğüm yalnızca
## OYUNCUNUN koşusuna ait örneği tutar. Monte Carlo, parite ve yön testleri
## kendi bağımsız örneklerini doğrudan yaratır, böylece bir test koşusu
## oyuncunun koşusunu bozamaz.
##
## Arayüz motora HİÇ dokunmaz: veriyi buradan okur, sinyalleri dinler,
## politikaları buradan ilan eder.
##
## POLİTİKALAR İLANDIR, ANLIK DEĞİŞİKLİK DEĞİL. `temel_gelir_ilan()` çağrısı
## motorun kuyruğuna girer, `pol_gecikme` (8 tur) sonra yürürlüğe başlar ve
## yerleşme hızı rejime göre değişir (neoliberal hızlı, düzenli yavaş).
## Arayüz bunu gizlemek yerine göstermelidir; oyunun anlattığı şeyin bir
## parçası budur.

signal kosu_basladi(bilgi: Dictionary)
signal tur_ilerledi(t: int)
signal olay_eklendi(tur: int, tip: String, mesaj: String)
signal rejim_degisti(kesinti: Dictionary)
signal kosu_bitti(rapor: Dictionary)

## OYUN BITTI DIYE BIR DURUM YOKTUR.
##
## Motorda bir ulke asla "olmez": temerrude duser, bunalima girer, savas
## kaybeder, rejim degistirir -- ama elenmez. Oyunun hedefi ayakta kalmaktir
## ve "dusmek" tek bir seydir: ELINDEKI REJIMIN EL DEGISTIRMESI (devrim ya da
## karsi-devrim). Bu bir KOPUSTUR, kayip degil -- kosu altindan devam eder,
## yalnizca elindeki politika seti degisir.
##
## Kopusun sebebi motorun o turdaki gunlugunden okunur; motor bu kavrami
## bilmez, oyun katmani turetir.
const KOPUS_TIPLERI := {
	"DEVRIM": "Sosyalist devrim",
	"KARSI-DEVRIM": "Karşı-devrim: kapitalizm zorla restore edildi",
	"RESTORASYON": "Restorasyon: kuşatma ve kıtlık altında rejim çöktü",
	"PIYASA SOS.": "Piyasa sosyalizmi: parti kaldı, birikim kapitalistleşti",
}

## Gösterge panelinin ekseni: belgenin kendi 12 çekirdek metriği
## (`python/hassasiyet.py` içindeki `olc()`). Panel bu listeyi okur, kendi
## listesini tutmaz -- iki yerin birbirinden kayması böylece imkânsız olur.
##
## `ters: true` olan metrik kayıtta istihdam olarak duruyor ama ekranda
## işsizlik gösterilir (1 - e).
const CEKIRDEK_METRIKLER := [
	{"anahtar": "r", "ad": "Kâr oranı", "bicim": "oran"},
	{"anahtar": "cv", "ad": "Organik bileşim c/v", "bicim": "sayi"},
	{"anahtar": "u", "ad": "Kapasite kullanımı", "bicim": "yuzde"},
	{"anahtar": "e", "ad": "İşsizlik", "bicim": "yuzde", "ters": true},
	{"anahtar": "pay", "ad": "Ücret payı", "bicim": "yuzde"},
	{"anahtar": "borc", "ad": "Hanehalkı borcu / Y", "bicim": "oran"},
	{"anahtar": "varlik", "ad": "Spekülatif varlık / Y", "bicim": "oran"},
	{"anahtar": "Om", "ad": "Siyasi öfke (Omega)", "bicim": "yuzde"},
	{"anahtar": "org", "ad": "Örgütlenme", "bicim": "yuzde"},
	{"anahtar": "oto", "ad": "Otomasyon payı", "bicim": "yuzde"},
	{"anahtar": "canli_pay", "ad": "Canlı emek payı", "bicim": "yuzde"},
	{"anahtar": "PR", "ad": "Protesto riski", "bicim": "yuzde"},
]

## Senaryo odalarının OYUN katmanı bilgisi. Motor `baslangic_yili`'nı senaryoya
## göre DEĞİŞTİRMEZ (hep 1760'tır), dolayısıyla ekranda gösterilecek takvim
## yılı buradan gelir -- konsol oyununun yaptığının aynısı.
const SENARYOLAR := {
	"": {
		"ad": "Tam Kampanya", "yil": 1760, "ufuk": 1259,
		"aciklama": "Sanayi Devrimi'nden 2100'e. Bütün çağlar, bütün geçişler.",
	},
	"golden_age_1950": {
		"ad": "Altın Çağ Refah Devleti", "yil": 1950, "ufuk": 120,
		"aciklama": "Güçlü sendikalar, yüksek ücret payı, sıfıra yakın finans.",
	},
	"neoliberal_1995": {
		"ad": "Neoliberal Küreselleşme", "yil": 1995, "ufuk": 120,
		"aciklama": "Ezilmiş sendikalar, borçla güdümlenen tüketim, balonlar.",
	},
	"turkey_2001": {
		"ad": "Türkiye 2001 Krizi", "yil": 2001, "ufuk": 120,
		"aciklama": "Dış borç limitte, rezerv tükenmiş, IMF kemer sıkması.",
	},
	"socialist_siege": {
		"ad": "Kuşatılmış Planlı Ekonomi", "yil": 2030, "ufuk": 400,
		"aciklama": "Rusya/Çin/Türkiye sosyalist, emperyalist müdahale zirvede.",
	},
}

var motor: GhostEngine = null
var oyuncu := ""                 ## oyuncunun ülkesi
var senaryo := ""
var ufuk := 1259
var baslangic_yili := 1760

var _log_islenen := 0            ## motor günlüğünde nereye kadar bildirildi
var _bitti := false

## Rejimin el değiştirdiği anlar. Koşuyu bitirmez; raporun omurgasıdır.
var kopuslar: Array = []
var _onceki_rejim := ""
var _onceki_parti_iktidari := false


func _ready() -> void:
	# Veri katmanını İLK AÇILIŞTA doğrula: üretim adımı atlanmış ya da yarım
	# kalmış bir ağacı motor kurulmadan önce yakalar.
	var sonuc: Dictionary = Params.dogrula()
	if not sonuc["gecti"]:
		for h in sonuc["hatalar"]:
			push_error("Veri katmanı doğrulaması: " + str(h))


# ===========================================================================
# KOŞU YAŞAM DÖNGÜSÜ
# ===========================================================================

## Yeni bir koşu kurar. `p_senaryo` boş ise tam kampanya.
func kosu_baslat(p_senaryo: String = "", tohum: int = 42,
		p_ulke: String = "Turkiye", p_ufuk: int = -1) -> void:
	assert(SENARYOLAR.has(p_senaryo), "Bilinmeyen senaryo: " + p_senaryo)
	var meta: Dictionary = SENARYOLAR[p_senaryo]

	motor = GhostEngine.new(tohum)
	if p_senaryo != "":
		motor.load_scenario(p_senaryo)
	motor.oyuncu_ulkesi(p_ulke)

	senaryo = p_senaryo
	oyuncu = p_ulke
	baslangic_yili = int(meta["yil"])
	ufuk = int(meta["ufuk"]) if p_ufuk < 0 else p_ufuk
	_log_islenen = 0
	_bitti = false
	kopuslar = []
	var c0 := ulke()
	_onceki_rejim = c0.rejim if c0 != null else ""
	_onceki_parti_iktidari = c0.parti_iktidari if c0 != null else false

	# Senaryo yüklemesi günlüğe satır ekler; onları da arayüze bildir.
	_olaylari_bildir()
	kosu_basladi.emit({
		"senaryo": senaryo, "ad": meta["ad"], "aciklama": meta["aciklama"],
		"tohum": tohum, "ulke": p_ulke, "ufuk": ufuk, "yil": baslangic_yili,
	})


## Turu ilerletir. Ufka varılınca `kosu_bitti` yayılır ve daha fazla ilerlemez.
func ilerle(tur_sayisi: int = 1) -> void:
	if motor == null or _bitti:
		return
	for _i in range(tur_sayisi):
		if motor.t >= ufuk:
			break
		motor.step()
		_olaylari_bildir()
		_kopus_denetle()
		tur_ilerledi.emit(motor.t)
		if motor.t >= ufuk:
			_bitir()
			return


## Elindeki rejim el degistirdi mi? Motor bu kavrami bilmez; oyun katmani
## rejim alanini tur tur izleyip turetir. Sebep, ayni turun gunlugunden okunur.
func _kopus_denetle() -> void:
	var c := ulke()
	if c == null:
		return
	if c.rejim == _onceki_rejim and c.parti_iktidari == _onceki_parti_iktidari:
		return

	var tip := ""
	for i in range(_log_islenen - 1, -1, -1):
		var k: Array = motor.log[i]
		if int(k[0]) != motor.t - 1:
			break
		if KOPUS_TIPLERI.has(String(k[1])) and String(k[2]).contains(c.ad):
			tip = String(k[1])
			break
	if tip == "":
		tip = "DEVRIM" if c.rejim == "sosyalist" else "KARSI-DEVRIM"

	var kesinti := {
		"tur": motor.t - 1,
		"yil": baslangic_yili + (motor.t - 1) * Formulas.TUR_YIL,
		"tip": tip,
		"aciklama": String(KOPUS_TIPLERI.get(tip, tip)),
		"eski_rejim": _onceki_rejim,
		"yeni_rejim": c.rejim,
		"parti_iktidari": c.parti_iktidari,
	}
	kopuslar.append(kesinti)
	_onceki_rejim = c.rejim
	_onceki_parti_iktidari = c.parti_iktidari
	rejim_degisti.emit(kesinti)


func _bitir() -> void:
	if _bitti:
		return
	_bitti = true
	# DILIM UFKA GORE SECILIR. Motorun varsayilani 150'dir; 120 turluk bir
	# senaryoda `ilk = h[:150]` ile `son = h[-150:]` AYNI diziye duser ve rapor
	# "baslangic 17.3 / bitis 17.3" gibi anlamsiz bir kesit gosterir. Dilim bir
	# SUNUM parametresidir, motor davranisi degil.
	var dilim: int = maxi(ufuk / 8, 5)
	var rapor := motor.tarihsel_rapor(oyuncu, dilim)
	# Ufka varmak AYAKTA KALMAKTIR. Kopuslar bunu gecersiz kilmaz; raporun ne
	# anlattigini belirler: rejim bozulmadan mi gelindi, yoksa kac kez el
	# degistirerek mi.
	rapor["kopuslar"] = kopuslar.duplicate(true)
	rapor["rejim_korundu"] = kopuslar.is_empty()
	rapor["ufuk"] = ufuk
	rapor["senaryo"] = senaryo
	rapor["baslangic_yili"] = baslangic_yili

	var gecmis: Array = Save.al("kosular", [])
	gecmis.append({
		"senaryo": senaryo, "ulke": oyuncu, "tur": motor.t,
		"son_rejim": rapor.get("son_rejim", ""), "son_kurum": rapor.get("son_kurum", ""),
		"kopus_sayisi": kopuslar.size(), "rejim_korundu": kopuslar.is_empty(),
	})
	Save.ayarla("kosular", gecmis)
	Save.kaydet()
	kosu_bitti.emit(rapor)


func bitti() -> bool:
	return _bitti


func tur() -> int:
	return motor.t if motor != null else 0


## Ekranda gösterilecek takvim yılı (senaryonun kendi başlangıcından).
func yil() -> float:
	return baslangic_yili + tur() * Formulas.TUR_YIL


func ilerleme() -> float:
	return clampf(float(tur()) / float(maxi(ufuk, 1)), 0.0, 1.0)


# ===========================================================================
# VERİ OKUMA
# ===========================================================================

func ulke(ad: String = "") -> Country:
	if motor == null:
		return null
	var hedef := ad if ad != "" else oyuncu
	for c in motor.D:
		if c.ad == hedef:
			return c
	return null


func ulke_adlari() -> PackedStringArray:
	var out := PackedStringArray()
	if motor != null:
		for c in motor.D:
			out.append(c.ad)
	return out


## Bir metriğin zaman serisi. `ters` işaretli metrikler (işsizlik) burada
## çevrilir, arayüzde değil -- iki yerde çevirmek kolayca birini unutturur.
func seri(anahtar: String, ulke_ad: String = "") -> PackedFloat64Array:
	var c := ulke(ulke_ad)
	if c == null:
		return PackedFloat64Array()
	var ham := c.tarih.seri(anahtar)
	if not _ters_mi(anahtar):
		return ham
	var out := PackedFloat64Array()
	out.resize(ham.size())
	for i in range(ham.size()):
		out[i] = 1.0 - ham[i]
	return out


func metrik(anahtar: String, ulke_ad: String = "") -> float:
	var c := ulke(ulke_ad)
	if c == null or c.tarih.tur_sayisi() == 0:
		return NAN
	var v := c.tarih.deger(anahtar, c.tarih.tur_sayisi() - 1)
	return (1.0 - v) if _ters_mi(anahtar) else v


func _ters_mi(anahtar: String) -> bool:
	for m in CEKIRDEK_METRIKLER:
		if m["anahtar"] == anahtar:
			return m.get("ters", false)
	return false


## Bir değeri metriğin biçimine göre metne çevirir.
static func bicimle(deger: float, bicim: String) -> String:
	if is_nan(deger):
		return "—"
	match bicim:
		"yuzde": return "%%%.1f" % (deger * 100.0)
		"oran": return "%.4f" % deger
		"sayi": return "%.2f" % deger
	return "%.3f" % deger


## Motor günlüğünün son N olayı (en yenisi sonda).
func olaylar(son_n: int = 40) -> Array:
	if motor == null:
		return []
	var bas: int = maxi(0, motor.log.size() - son_n)
	var out := []
	for i in range(bas, motor.log.size()):
		var k: Array = motor.log[i]
		out.append({"tur": int(k[0]), "tip": String(k[1]), "mesaj": String(k[2])})
	return out


func _olaylari_bildir() -> void:
	while _log_islenen < motor.log.size():
		var k: Array = motor.log[_log_islenen]
		olay_eklendi.emit(int(k[0]), String(k[1]), String(k[2]))
		_log_islenen += 1


# ===========================================================================
# POLİTİKA -- hepsi İLANDIR
# ===========================================================================

## Bekleyen ilanlar: arayüz "ne zaman yürürlüğe girecek" diye gösterebilsin.
func bekleyen_politikalar(ulke_ad: String = "") -> Array:
	var c := ulke(ulke_ad)
	if c == null:
		return []
	var out := []
	for ad in c.pol_kuyruk:
		var g: Array = c.pol_kuyruk[ad]
		out.append({"ad": ad, "deger": g[0], "etkin_t": int(g[1]),
				"kalan": maxi(0, int(g[1]) - motor.t)})
	return out


## ETG hedefi (hasıla oranı). Siyaseten bedavadır, iktisaden bedel öder:
## bütçe, kâr oranı, birikim.
func temel_gelir_ilan(oran: float) -> void:
	if motor != null:
		motor.set_temel_gelir(oran, oyuncu)


## ETG'nin ne kadarı sermaye vergisinden karşılanacak.
## 0.0 = tamamen ücretten (tüketimi kısar, gerçekleşme krizini derinleştirir)
## 1.0 = tamamen sermayeden (net kârlılığı düşürür, LTRPF'yi hızlandırır)
func etg_finansman_ilan(sermaye_payi: float) -> void:
	if motor != null:
		motor.set_etg_finansman(sermaye_payi, oyuncu)


## Sosyalist plan profili. Paylar RAKİP kullanımlardır.
func plan_profili_ilan(profil: String) -> void:
	if motor != null:
		motor.set_plan_profili(profil, oyuncu)


## Sosyalist pakt içindeki duruş: "ittifak" ya da "rekabet".
func pakt_durusu_ayarla(durus: String) -> void:
	if motor != null:
		motor.set_pakt_durusu(durus, oyuncu)


## Kasıtlı kurumsal inşa -- liberal rejime TEK erişim yolu.
## Endojen geçişten farkı: bu bir SİYASİ PROJEDİR, siyasi sermaye harcar.
func kurumsal_insa_ilan(kurum: String) -> void:
	if motor != null:
		motor.set_kurumsal_insa(kurum, oyuncu)


## Kurumsal inşa şu an mümkün mü, değilse neden.
##
## §9.8: siyasi sermaye YALNIZCA yapısal değişiklikleri kısıtlar. ETG düzeyi,
## ETG finansmanı ve plan payları siyaseten bedavadır -- onlar için bu kapı
## sorulmaz.
func kurumsal_insa_durumu() -> Dictionary:
	var c := ulke()
	if c == null:
		return {"mumkun": false, "sebep": "koşu yok"}
	var P := motor.P
	if c.rejim != "kapitalist":
		return {"mumkun": false, "sebep": "planlı ekonomide kurumsal rejim yok"}
	if motor.t - c.kurum_insa_t < P.ki_min_sure:
		return {"mumkun": false, "kalan": P.ki_min_sure - (motor.t - c.kurum_insa_t),
				"sebep": "son inşadan bu yana yeterli süre geçmedi"}
	if c.PC < P.ki_pc_esigi:
		return {"mumkun": false, "pc": c.PC, "esik": P.ki_pc_esigi,
				"sebep": "siyasi sermaye yetersiz"}
	return {"mumkun": true, "maliyet": P.ki_pc_maliyet}


## Karanlık devlet politikası. `null` bırakılırsa devlet kendi karar verir
## (endojen); bir sayıya çekilirse oyuncu devralır.
func mafya_kilidi_ayarla(deger) -> void:
	var c := ulke()
	if c != null:
		c.mafya_kilit = deger
