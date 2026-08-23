class_name Kayit
extends RefCounted

## B7d -- oturumun serilestirilmesi.
##
## ------------------------------------------------------------------------
## ISKELET NORMAL YOLDAN KURULUR, USTUNE DURUM YAZILIR
## ------------------------------------------------------------------------
## Nesne grafigini (113 ulke x kriz cekirdegi x dort katman x iki RNG) elle
## yeniden insa etmek hem uzun hem kirilgan olurdu: bir alan unutuldugunda
## yukleme sessizce baska bir dunya uretirdi. Bunun yerine dunya
## `Harita.dunya_kur()` ile HER ZAMANKI gibi kurulur -- kodlar ve tohum
## kayittan gelir -- ve sonra butun durum uzerine yazilir. Boylece yeni bir
## alan eklendiginde iskelet zaten dogru, geriye yalnizca alanin kopyalanmasi
## kalir, o da alan listesinden OTOMATIK gelir.
##
## ------------------------------------------------------------------------
## RNG DURUMU DA KAYDEDILIR, VE BU ZORUNLU
## ------------------------------------------------------------------------
## Uc ayri RNG var: her ulkenin cekirdeginde bir `PyRandom`, savas
## katmaninda bir `PyRandom`, `Dunya`da bir `RandomNumberGenerator`. Yalnizca
## tohumu kaydetmek YETMEZ -- tohum baslangici verir, oyuncu ise ortasindan
## devam eder. Kaydedilmezse yuklenen oyun ayni dunyadan BASKA bir gelecege
## gider, ve bu ekranda "kaydettigim yerden devam ettim" gibi gorunur.
##
## Kapi bunu iki kademede sinar: yukleme SONRASI dunya alan alan ayni mi, ve
## ikisi N tik daha SURULDUKTEN sonra hala ayni mi. Ikincisi olmadan RNG
## durumu sessizce kaybolabilir.
##
## ------------------------------------------------------------------------
## BICIM: IKILI, JSON DEGIL
## ------------------------------------------------------------------------
## Tam kadroda gecmis deposu tek basina 113 x 264 x 19 = 566 000 kayan
## noktadir. JSON'da her sayi ondalik metne cevrilir ve dosya on megabaytlari
## bulur; `var_to_bytes` ayni veriyi ikili tutar. `Save` yine tek `user://`
## kapisidir -- bu sinif dosya sistemine DOKUNMAZ, yalnizca sozluk uretir.

const SURUM := 1

## Serilestirilmeyen alanlar: ya nesnedir (ayri ele alinir) ya da
## parametredir (kurulumdan gelir, kaydin isi degil).
const ATLA := ["P", "rng", "mikro", "nufus", "mal", "karanlik", "savas",
		"aktor", "ulkeler", "cekirdekler", "binalar"]


# ===========================================================================
# GENEL NESNE SERILESTIRME
# ===========================================================================

## Bir nesnenin butun SCRIPT alanlarini sozluge yazar.
##
## `get_property_list()` kullanilmasi bilincli: alan listesi ELLE tutulsaydi
## motora eklenen her yeni alan kayitta sessizce eksik kalirdi -- ve eksik bir
## alan, yuklenen oyunda "biraz farkli" bir dunya demektir, hata degil.
static func nesne_sozluge(o: Object) -> Dictionary:
	var c := {}
	for pr in o.get_property_list():
		if not (pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var ad: String = pr["name"]
		if ATLA.has(ad):
			continue
		var v: Variant = o.get(ad)
		if v is Object:
			continue
		c[ad] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return c


static func nesne_yukle(o: Object, c: Dictionary) -> void:
	for ad in c.keys():
		var v: Variant = c[ad]
		o.set(String(ad), v.duplicate(true) if (v is Array or v is Dictionary)
				else v)


## MT19937 durumu: 624 kelime + indeks. Tohum DEGIL DURUM kaydedilir.
static func rng_sozluge(r: PyRandom) -> Dictionary:
	return {"mt": r._mt.duplicate(), "index": r._index}


static func rng_yukle(r: PyRandom, c: Dictionary) -> void:
	r._mt = (c["mt"] as PackedInt64Array).duplicate()
	r._index = int(c["index"])


# ===========================================================================
# DUNYA
# ===========================================================================

static func dunya_sozluge(w: Dunya, kodlar: PackedStringArray,
		tohum: int) -> Dictionary:
	var ulkeler := []
	var cekirdekler := []
	for i in range(w.ulkeler.size()):
		ulkeler.append(nesne_sozluge(w.ulkeler[i]))
		cekirdekler.append(_cekirdek_sozluge(w.cekirdekler[i]))

	var c := {
		"surum": SURUM,
		"kodlar": kodlar.duplicate(),
		"tohum": tohum,
		"dunya": nesne_sozluge(w),
		"ulkeler": ulkeler,
		"cekirdekler": cekirdekler,
		"rng": {"seed": w.rng.seed, "state": w.rng.state},
	}
	if w.savas != null:
		c["savas"] = nesne_sozluge(w.savas)
		c["savas_rng"] = rng_sozluge(w.savas.rng)
	if w.aktor != null:
		c["aktor"] = nesne_sozluge(w.aktor)
	return c


static func _cekirdek_sozluge(k: KrizCekirdegi) -> Dictionary:
	var c := {"cekirdek": nesne_sozluge(k), "rng": rng_sozluge(k.rng)}
	if k.mikro != null:
		c["mikro"] = nesne_sozluge(k.mikro)
		var binalar := []
		for b in k.mikro.binalar:
			binalar.append(nesne_sozluge(b))
		c["binalar"] = binalar
	if k.nufus != null:
		c["nufus"] = nesne_sozluge(k.nufus)
	if k.mal != null:
		c["mal"] = nesne_sozluge(k.mal)
	if k.karanlik != null:
		c["karanlik"] = nesne_sozluge(k.karanlik)
	return c


## Kayittan dunya kurar. `null` doner ve uyarir: bozuk bir kayit oyunu
## acilmaz yapmamali (v4.4'un `Save` sozlesmesiyle ayni ilke).
static func dunya_yukle(c: Dictionary) -> Dunya:
	if int(c.get("surum", 0)) != SURUM:
		push_warning("Kayit surumu uyusmuyor: %s" % str(c.get("surum")))
		return null
	var kodlar: PackedStringArray = c["kodlar"]
	var w := Harita.dunya_kur(kodlar, int(c["tohum"]), Oyun.BAS_YIL)
	if w.ulkeler.size() != (c["ulkeler"] as Array).size():
		push_warning("Kayittaki ulke sayisi kadroyla uyusmuyor.")
		return null

	nesne_yukle(w, c["dunya"])
	w.rng.seed = int(c["rng"]["seed"])
	w.rng.state = int(c["rng"]["state"])

	for i in range(w.ulkeler.size()):
		nesne_yukle(w.ulkeler[i], (c["ulkeler"] as Array)[i])
		_cekirdek_yukle(w.cekirdekler[i], (c["cekirdekler"] as Array)[i])

	if w.savas != null and c.has("savas"):
		nesne_yukle(w.savas, c["savas"])
		rng_yukle(w.savas.rng, c["savas_rng"])
	if w.aktor != null and c.has("aktor"):
		nesne_yukle(w.aktor, c["aktor"])
	return w


static func _cekirdek_yukle(k: KrizCekirdegi, c: Dictionary) -> void:
	nesne_yukle(k, c["cekirdek"])
	rng_yukle(k.rng, c["rng"])
	if k.mikro != null and c.has("mikro"):
		nesne_yukle(k.mikro, c["mikro"])
		# BINALAR SAYICA DEGISEBILIR mi? Su an hayir -- sektor basina bir bina
		# kuruluyor ve yeni bina eklenmiyor. Yine de sayiya GUVENILMEZ:
		# kayittaki sayi esas alinir, iskeletteki fazlalik kirpilir.
		var kayitli: Array = c.get("binalar", [])
		for b in range(mini(kayitli.size(), k.mikro.binalar.size())):
			nesne_yukle(k.mikro.binalar[b], kayitli[b])
	if k.nufus != null and c.has("nufus"):
		nesne_yukle(k.nufus, c["nufus"])
	if k.mal != null and c.has("mal"):
		nesne_yukle(k.mal, c["mal"])
	if k.karanlik != null and c.has("karanlik"):
		nesne_yukle(k.karanlik, c["karanlik"])


# ===========================================================================
# OTURUM
# ===========================================================================

static func oturum_sozluge(o: Oyun, kodlar: PackedStringArray) -> Dictionary:
	var gecmis := {"yillar": o.gecmis.yillar, "ulke_sayisi": o.gecmis.ulke_sayisi,
			"sutun": {}}
	for m in o.gecmis.metrikler:
		var anahtar := String(m["anahtar"])
		gecmis["sutun"][anahtar] = o.gecmis.seri_ham(anahtar)
	return {
		"surum": SURUM,
		"dunya": dunya_sozluge(o.dunya, kodlar, o.tohum),
		"oyuncu": o.oyuncu,
		"tik": o.tik(),
		"gecmis": gecmis,
		"gunce": {"girdiler": o.gunce.girdiler.duplicate(true),
				"sayac": o.gunce.sayac.duplicate(true)},
	}
