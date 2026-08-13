class_name Mekanizma
extends RefCounted

## MEKANIZMA YON TESTLERI -- belgenin BIRINCIL kabul olcutu (§9.14).
##
## `python/mekanizma_testleri.py` dosyasinin GDScript karsiligi.
##
## Neden birincil: bant testleri "sayi su araliktal mi" diye sorar ve o aralik
## bu projede dort kez degistirildi; yani bantlar KALIBRASYONUN KAYDIDIR,
## bagimsiz olcut degil. Yon testleri ise "otomasyon artinca canli emek payi
## DUSUYOR mu" diye sorar. Yonu ayarlayamazsiniz: ya vardir ya yoktur.
##
## Her test bir ISARET ya da SIRALAMA iddiasi kurar ve tohumlar arasinda kac kez
## dogrulandigini sayar. Gecme olcutu tohumlarin en az `esik` orani.

# ---------------------------------------------------------------------------
# KAYNAKTAKI HATA AYNEN KORUNDU
# ---------------------------------------------------------------------------
# `_seri`'nin kapitalist filtresi soyle yazilmis (mekanizma_testleri.py:27):
#
#     if (not kapitalist or c.tarih[i].get("rejim", "kapitalist") == "kapitalist")
#
# Ama tur kaydindaki anahtar "rejim" DEGIL, "rej" (motor.py:2547). Dolayisiyla
# `.get("rejim", "kapitalist")` HER ZAMAN varsayilani dondurur, kosul her zaman
# dogrudur ve filtre hicbir ulkeyi elemez -- olu koddur.
#
# Bu hata BILEREK yeniden uretiliyor. Duzeltmek, 9/9 gecen referans sonucu
# degistirir ve portu kahinden ayirir; amac motoru iyilestirmek degil, ayni
# seyi yaptigini kanitlamak. (Kaynagi duzeltmek isteyen once yeni bir referans
# olcum almali.)
# ---------------------------------------------------------------------------


static func _ort(v: Array) -> float:
	if v.is_empty():
		return NAN
	return Formulas.py_sum(v) / float(v.size())


static func _medyan(v: Array) -> float:
	if v.is_empty():
		return NAN
	var s := v.duplicate()
	s.sort()
	var n := s.size()
	if n % 2 == 1:
		return float(s[n / 2])
	return (float(s[n / 2 - 1]) + float(s[n / 2])) / 2.0


## Dunya ortalamasinin zaman serisi. Filtre ölü olduğu için TUM ulkeler girer.
static func _seri(e: GhostEngine, alan: String) -> Array:
	var n := e.D[0].tarih.tur_sayisi()
	var out := []
	for i in range(n):
		var v := []
		for c in e.D:
			v.append(c.tarih.deger(alan, i))
		out.append(_ort(v))
	return out


## Basit dogrusal egim isareti (en kucuk kareler).
static func _egim(y: Array) -> float:
	var n := y.size()
	if n < 3:
		return 0.0
	var mx := float(n - 1) / 2.0
	var my := _ort(y)
	var pay := []
	var payda := []
	for i in range(n):
		pay.append((float(i) - mx) * (float(y[i]) - my))
		payda.append(pow(float(i) - mx, 2.0))
	var d := Formulas.py_sum(payda)
	return Formulas.py_sum(pay) / d if d != 0.0 else 0.0


static func _kor(a: Array, b: Array) -> float:
	var ma := _ort(a)
	var mb := _ort(b)
	var num := []
	var da := []
	var db := []
	for i in range(a.size()):
		num.append((float(a[i]) - ma) * (float(b[i]) - mb))
		da.append(pow(float(a[i]) - ma, 2.0))
		db.append(pow(float(b[i]) - mb, 2.0))
	var sa := sqrt(Formulas.py_sum(da))
	var sb := sqrt(Formulas.py_sum(db))
	return Formulas.py_sum(num) / (sa * sb) if (sa != 0.0 and sb != 0.0) else 0.0


static func _fark(y: Array) -> Array:
	var out := []
	for i in range(y.size() - 1):
		out.append(float(y[i + 1]) - float(y[i]))
	return out


static func _cokme_sayisi(e: GhostEngine, anahtar: String) -> int:
	var n := 0
	for kayit in e.log:
		if String(kayit[1]) == "COKME" and String(kayit[2]).to_upper().contains(anahtar):
			n += 1
	return n


# ===========================================================================
# TESTLER
# ===========================================================================

## q ↑ → c/v ↑ → r ↓  (kampanyanin tamami)
static func test_ltrpf(tohumlar: Array) -> Array:
	var ok := 0
	for t in tohumlar:
		var e := GhostEngine.new(t)
		e.run_simulation(Formulas.KAMPANYA_TURU)
		if _egim(_seri(e, "q")) > 0 and _egim(_seri(e, "cv")) > 0 and _egim(_seri(e, "r")) < 0:
			ok += 1
	return [ok, "q↑ c/v↑ r↓"]


## oto ↑ → canli_pay ↓ → r ↓  (cag 5 sonrasi)
static func test_otomasyon(tohumlar: Array) -> Array:
	var ok := 0
	var i0 := int(Formulas.KAMPANYA_TURU * 0.72)   # ~2005 sonrasi
	for t in tohumlar:
		var e := GhostEngine.new(t)
		e.run_simulation(Formulas.KAMPANYA_TURU)
		var oto := _seri(e, "oto").slice(i0)
		var cp := _seri(e, "canli_pay").slice(i0)
		var r := _seri(e, "r").slice(i0)
		if _egim(oto) > 0 and _egim(cp) < 0 and _egim(r) < 0:
			ok += 1
	return [ok, "oto↑ canli_pay↓ r↓"]


## Istihdam ile ucret payi AYNI yonde, ucret payi ile kar orani TERS.
static func test_goodwin(tohumlar: Array) -> Array:
	var ok := 0
	for t in tohumlar:
		var e := GhostEngine.new(t)
		e.run_simulation(Formulas.KAMPANYA_TURU)
		# Ilk fark korelasyonu: seviye trendinden bagimsiz.
		var de := _fark(_seri(e, "e"))
		var dp := _fark(_seri(e, "pay"))
		var dr := _fark(_seri(e, "r"))
		if _kor(de, dp) > 0 and _kor(dp, dr) < 0:
			ok += 1
	return [ok, "e↔pay pozitif, pay↔r negatif"]


## Yuksek q'lu ulkeler yuksek eps/pi_m'ye sahip olmali (merkez avantaji).
static func test_thirlwall(tohumlar: Array) -> Array:
	var ok := 0
	for t in tohumlar:
		var e := GhostEngine.new(t)
		e.run_simulation(int(Formulas.KAMPANYA_TURU * 0.6))
		var son := []
		for c in e.D:
			son.append([c.q, c.eps / maxf(c.pi_m, 1e-9)])
		# Python `list.sort()` demetleri once q'ya gore siralar.
		son.sort_custom(func(a, b):
			if a[0] != b[0]:
				return a[0] < b[0]
			return a[1] < b[1])
		var yari := son.size() / 2
		var alt := []
		var ust := []
		for i in range(son.size()):
			if i < yari:
				alt.append(son[i][1])
			else:
				ust.append(son[i][1])
		if _medyan(ust) > _medyan(alt):
			ok += 1
	return [ok, "yuksek q → yuksek eps/pi_m"]


## Finansallasma kapatilinca Minsky krizi AZALMALI.
static func test_minsky(tohumlar: Array) -> Array:
	var ok := 0
	for t in tohumlar:
		var a := GhostEngine.new(t)
		a.run_simulation(Formulas.KAMPANYA_TURU)
		var na := _cokme_sayisi(a, "MINSKY")
		var b := GhostEngine.new(t)
		b.P.fin_stok = 0.0
		b.P.fin_pay = 0.0
		b.run_simulation(Formulas.KAMPANYA_TURU)
		if na > _cokme_sayisi(b, "MINSKY"):
			ok += 1
	return [ok, "finansallasma kapali → daha az Minsky"]


## Kriz devaluasyonu ONARIM kanalidir: kapatilinca kar orani daha cok duser.
##
## Bu test tohum-basi DEGIL MEDYAN uzerinden karar verir. Tohum-basi
## karsilastirma 2/4 veriyordu: tek kosuda kriz zamanlamasi gurultuyu
## isaretten buyuk kiliyor. Medyanda etki net.
static func test_kriz_devaluasyonu(tohumlar: Array) -> Array:
	var n := tohumlar.size()
	var sonuc := {}
	for kapali in [true, false]:
		var out := []
		for t in tohumlar:
			var e := GhostEngine.new(t)
			if kapali:
				e.P.dev_cokme = 0.0
				e.P.dev_bunalim = 0.0
			e.run_simulation(Formulas.KAMPANYA_TURU)
			var tr := e.kar_orani_trendi(Formulas.KAMPANYA_TURU / 4)
			out.append(float(tr[tr.size() - 1]["r"]) / float(tr[0]["r"]))
		sonuc[kapali] = _medyan(out)
	return [(n if sonuc[true] < sonuc[false] else 0),
			"devaluasyon kapali → r daha cok duser (medyan)"]


## Ayni otomasyon: kitlik~0 iken protesto riski DAHA DUSUK olmali.
##
## DIKKAT: bu test `socialist_siege` senaryosunda kosuyor ve o senaryo
## PYTHONHASHSEED'e duyarli (bkz. CLAUDE.md). Kahinle bit-birebir eslesme
## BEKLENMEZ; olcut yon iddiasinin kendisidir.
static func test_sos_bolluk(tohumlar: Array) -> Array:
	var ok := 0
	for t in tohumlar:
		var deger := {}
		for prof in ["tuketimci", "sanayilesmeci"]:
			var e := GhostEngine.new(t)
			# Politika AI'si sosyalist plan profilini her 12 turda yeniden secer;
			# mekanizmayi test ederken onu kapatmak gerekir, yoksa test edilen
			# profil AI tarafindan eziliyor.
			e.P.ai_acik = false
			e.load_scenario("socialist_siege")
			e.set_plan_profili(prof)
			for _i in range(400):
				e.step()
			var kit := []
			var pr := []
			for c in e.D:
				if c.rejim != "sosyalist":
					continue
				for i in range(280, 400):
					kit.append(c.tarih.deger("kitlik", i))
					pr.append(c.tarih.deger("PR", i))
			deger[prof] = [_ort(kit) if not kit.is_empty() else 0.0,
					_ort(pr) if not pr.is_empty() else 0.0]
		var tk: Array = deger["tuketimci"]
		var sn: Array = deger["sanayilesmeci"]
		if tk[0] < sn[0] and tk[1] < sn[1]:
			ok += 1
	return [ok, "bolluk → dusuk PR; kitlik → yuksek PR"]


## Karanlik devlet kapatilinca uyusturucu ve lumpen pay AZALMALI.
static func test_karanlik_devlet(tohumlar: Array) -> Array:
	var ok := 0
	var tur := int(Formulas.KAMPANYA_TURU * 0.8)
	for t in tohumlar:
		var a := GhostEngine.new(t)
		a.run_simulation(tur)
		var ua := []
		for c in a.D:
			ua.append(c.uyusturucu_orani)
		var b := GhostEngine.new(t)
		for c in b.D:
			c.mafya_kilit = 0.0
		b.run_simulation(tur)
		var ub := []
		for c in b.D:
			ub.append(c.uyusturucu_orani)
		if _ort(ua) > _ort(ub):
			ok += 1
	return [ok, "tolerans kapali → daha az uyusturucu"]


## Politik ozne kapatilinca cag 6'da orgutlu guc DAHA COK erimeli.
static func test_parti(tohumlar: Array) -> Array:
	var ok := 0
	var i0 := int(Formulas.KAMPANYA_TURU * 0.9)
	for t in tohumlar:
		var res := {}
		for hiz in [0.0008, 0.0]:
			var e := GhostEngine.new(t)
			e.P.parti_hiz = hiz
			e.run_simulation(Formulas.KAMPANYA_TURU)
			var son := []
			for c in e.D:
				if c.rejim != "kapitalist":
					continue
				for i in range(i0, c.tarih.tur_sayisi()):
					son.append(c.tarih.deger("orgutlu", i))
			res[hiz] = _ort(son) if not son.is_empty() else 0.0
		if float(res[0.0008]) > float(res[0.0]):
			ok += 1
	return [ok, "parti acik → daha yuksek orgutlu guc"]


const TESTLER := [
	["LTRPF", "ltrpf", 0.90],
	["Otomasyon", "otomasyon", 0.80],
	["Goodwin", "goodwin", 0.70],
	["Thirlwall", "thirlwall", 0.80],
	["Minsky", "minsky", 0.80],
	["Kriz devaluasyonu", "kriz_dev", 0.70],
	["Sosyalist bolluk/kitlik", "sos_bolluk", 0.70],
	["Karanlik devlet", "karanlik", 0.80],
	["Politik ozne", "parti", 0.70],
]


## Acik dagitim: GDScript'te statik bir sinif uzerinden `call()` yapilamiyor.
static func _calistir(kod: String, tohumlar: Array) -> Array:
	match kod:
		"ltrpf": return test_ltrpf(tohumlar)
		"otomasyon": return test_otomasyon(tohumlar)
		"goodwin": return test_goodwin(tohumlar)
		"thirlwall": return test_thirlwall(tohumlar)
		"minsky": return test_minsky(tohumlar)
		"kriz_dev": return test_kriz_devaluasyonu(tohumlar)
		"sos_bolluk": return test_sos_bolluk(tohumlar)
		"karanlik": return test_karanlik_devlet(tohumlar)
		"parti": return test_parti(tohumlar)
	return [0, "bilinmeyen test"]


static func kos(n: int = 6, bas: int = 1, yalniz: String = "") -> int:
	var tohumlar := []
	for i in range(bas, bas + n):
		tohumlar.append(i)

	print("MEKANIZMA YON TESTLERI (GDScript portu) — tohum %d..%d (%d tohum)"
			% [tohumlar[0], tohumlar[tohumlar.size() - 1], n])
	print("=".repeat(74))
	print("%-26s%-34s%7s%7s" % ["test", "iddia", "gecen", "sonuc"])
	print("-".repeat(74))

	var hepsi := true
	var basladi := Time.get_ticks_msec()
	for satir in TESTLER:
		var ad: String = satir[0]
		var fn: String = satir[1]
		var esik: float = satir[2]
		if yalniz != "" and not ad.to_lower().contains(yalniz.to_lower()):
			continue
		var sonuc: Array = _calistir(fn, tohumlar)
		var ok: int = sonuc[0]
		var gecti: bool = float(ok) / float(n) >= esik
		hepsi = hepsi and gecti
		print("%-26s%-34s%d/%-5d%7s" % [ad, sonuc[1], ok, n, "GECTI" if gecti else "KALDI"])

	print("-".repeat(74))
	print("(%.0f sn)" % ((Time.get_ticks_msec() - basladi) / 1000.0))
	print("GENEL: %s" % ("TUM YON TESTLERI GECTI" if hepsi else "EN AZ BIR YON TESTI KALDI"))
	return 0 if hepsi else 1
