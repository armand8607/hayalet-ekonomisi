class_name KesitTesti
extends RefCounted

## KESIT TANISI -- dunyanin ULKELER ARASI ayrismasini olcer.
##
## Kapi DEGIL, tani. `--v2-*-tarama` ailesinin uyesi: bir sey iddia etmez,
## karar icin sayi uretir. Tam kampanya kosar (~3 dk), o yuzden CI'da yeri
## yok.
##
## NEDEN VAR: yol haritasinda duran iki acik kalem -- ekonomik tohumlama ve
## savas sikligi -- ayri yazilmisti, ama ikisi de AYNI seyi soruyor: bu
## dunyada ulkeler birbirinden ne kadar ayirt edilebilir. Tek kampanya
## ikisini birden olcer, ve ayni kosudan olcmek onemli: iki ayri kosu iki
## ayri kaotik yorunge demektir ve "fark mekanizmadan mi, ayrismadan mi"
## sorusu yine sorulamaz olurdu (belge §6c'nin dort kez ogrenilmis dersi).
##
## OLCTUKLERI
##
##   A) BUYUKLUK. `Harita._ulke()` her ulkeye ayni `L_etkin` verir; konum
##      merdiveni yalnizca `q0` ve `egitim` dagitir. Sorulan: bugun ne kadar
##      ayrisma VAR, ve ulke KIMLIGINE bagli mi.
##
##   B) SAVAS SECICILIGI. `savas_siklik` carpani bandi saglar ama §3.1'in
##      isaretini cevirir; belge bunu DOYUMA baglamisti. Sorulan: doyum
##      gercekten oluyor mu, ve kriz terimi ne zaman konusuyor.

const HAFTA := 1.0 / 52.0
const BAS := 1836.0
const SON := 2100.0

## Buyukluk kesitinin orneklendigi yillar.
const ORNEK := [1836.0, 1880.0, 1920.0, 1960.0, 2000.0, 2100.0]

## Kriz kanalinin canliligini toplayan kovalarin genisligi (yil).
const KOVA := 20


static func kos() -> int:
	print("=".repeat(78))
	print("KESIT TANISI -- 54 ulke, tohum 42, 1836-2100")
	print("=".repeat(78))

	var w := Harita.dunya_kur(Harita.kapi_kodlar(54), 42, BAS)
	var konumlar := _konumlar(w)
	var r_ref: float = w.P.v44.sv_r_ref

	var boyut: Array = []
	var secim: Array = []
	var kova := {}
	var kova_yillar: Array = []
	for y in range(1840, 2101, KOVA):
		kova_yillar.append(y)
		# [r<r_ref sayisi, ornek, r toplami, r_min, r_max, ilan]
		kova[y] = [0, 0, 0.0, INF, -INF, 0]

	var sonraki := 0
	var onceki_ilan := 0
	var son_yil := -1
	var tik := Oran.donem_sayisi(SON - BAS, HAFTA)
	for k in range(tik + 1):
		var yil := BAS + float(k) * HAFTA
		if sonraki < ORNEK.size() and yil + 1e-9 >= ORNEK[sonraki]:
			boyut.append(_boyut_olc(w, konumlar, ORNEK[sonraki]))
			secim.append(_secim_olc(w, ORNEK[sonraki]))
			sonraki += 1
		# YILDA BIR ornekle. Haftalik ornekleme orani degistirmez ama
		# `r_min`/`r_max`e 52 kat gurultu toplar.
		var ty := int(floor(yil + 1e-9))
		if ty != son_yil:
			son_yil = ty
			_kovaya_yaz(kova, kova_yillar, ty, w, r_ref, onceki_ilan)
			onceki_ilan = w.savas.ilan_sayisi
		if k < tik:
			w.adim(HAFTA)

	_boyut_yaz(boyut, w, konumlar)
	_canlilik_yaz(kova, kova_yillar, r_ref)
	_secim_yaz(secim)
	return 0


## Ulke kodlarini `HaritaVerisi`nin konum alanina cevirir. `Dunya.adlar`
## KOD tasir (`dunya_kur` `w.ekle(d, kod, ...)` cagirir), yani dogrudan
## `Harita.indeks()`e verilebilir.
static func _konumlar(w: Dunya) -> PackedStringArray:
	var kayit := Harita.kayit()
	var cikti := PackedStringArray()
	for kod in w.adlar:
		var i := Harita.indeks(kod)
		cikti.append(String(kayit[i]["konum"]) if i >= 0 else "?")
	return cikti


static func _kovaya_yaz(kova: Dictionary, yillar: Array, yil: int, w: Dunya,
		r_ref: float, onceki_ilan: int) -> void:
	var anahtar := -1
	for i in range(yillar.size() - 1, -1, -1):
		if yil >= yillar[i]:
			anahtar = yillar[i]
			break
	if anahtar < 0:
		return
	var b: Array = kova[anahtar]
	for d in w.ulkeler:
		if d.rejim == "sosyalist":
			continue
		b[1] += 1
		b[2] += d.r_yil
		b[3] = minf(b[3], d.r_yil)
		b[4] = maxf(b[4], d.r_yil)
		if d.r_yil < r_ref:
			b[0] += 1
	b[5] += w.savas.ilan_sayisi - onceki_ilan


# ===========================================================================
# A -- BUYUKLUK AYRISMASI
# ===========================================================================

static func _boyut_olc(w: Dunya, konumlar: PackedStringArray,
		yil: float) -> Dictionary:
	var L := PackedFloat64Array()
	var Y := PackedFloat64Array()
	var konum_Y := {"merkez": [0.0, 0], "yari": [0.0, 0], "cevre": [0.0, 0]}
	for i in range(w.ulkeler.size()):
		var d := w.ulkeler[i]
		L.append(d.L_etkin)
		Y.append(d.Y_yil)
		var kn := konumlar[i]
		if konum_Y.has(kn):
			konum_Y[kn][0] += d.Y_yil
			konum_Y[kn][1] += 1
	for kn in konum_Y:
		konum_Y[kn] = konum_Y[kn][0] / maxf(float(konum_Y[kn][1]), 1.0)
	return {
		"yil": yil,
		"L_min": _min(L), "L_max": _max(L), "L_cv": _cv(L),
		"Y_min": _min(Y), "Y_max": _max(Y), "Y_cv": _cv(Y),
		"konum_Y": konum_Y,
	}


static func _boyut_yaz(satirlar: Array, w: Dunya,
		konumlar: PackedStringArray) -> void:
	print("")
	print("-".repeat(78))
	print("A) BUYUKLUK -- ne kadar ayrisma var, ve KIMLIGE bagli mi")
	print("-".repeat(78))
	print("  yil     L_max/min   L_cv     Y_min      Y_max   Y_max/min   Y_cv")
	for s in satirlar:
		print("  %4d %11.2f %6.3f %9.2f %10.2f %11.2f %6.3f" % [
			int(s["yil"]), s["L_max"] / maxf(s["L_min"], 1e-12), s["L_cv"],
			s["Y_min"], s["Y_max"],
			s["Y_max"] / maxf(s["Y_min"], 1e-12), s["Y_cv"]])

	print("")
	print("  Ortalama Y_yil, dunya sistemindeki konuma gore:")
	print("  yil       merkez        yari       cevre   merkez/cevre")
	for s in satirlar:
		var k: Dictionary = s["konum_Y"]
		print("  %4d %12.2f %11.2f %11.2f %14.2f" % [
			int(s["yil"]), k["merkez"], k["yari"], k["cevre"],
			k["merkez"] / maxf(k["cevre"], 1e-12)])

	# HIYERARSI OKUNUR MU. Toplam yayilim buyuk olabilir ve yine de hicbir
	# sey anlatmayabilir; ayrismanin ulke kimligine oturup oturmadigi ancak
	# uclara BAKARAK gorulur.
	var sira: Array = []
	for i in range(w.ulkeler.size()):
		sira.append([w.ulkeler[i].Y_yil, w.adlar[i], konumlar[i]])
	sira.sort_custom(func(a, b): return a[0] > b[0])
	print("")
	print("  2100'de en buyuk 5 / en kucuk 5 (Y_yil):")
	for i in range(5):
		print("    %-4s %-7s %10.2f" % [sira[i][1], sira[i][2], sira[i][0]])
	print("    ...")
	for i in range(sira.size() - 5, sira.size()):
		print("    %-4s %-7s %10.2f" % [sira[i][1], sira[i][2], sira[i][0]])


# ===========================================================================
# B -- SAVAS SECICILIGI
# ===========================================================================

## `savas.gd::_savas_karari`nin (2) kanali AYNEN yeniden hesaplanir, motor
## surulmeden. Kopyalanmis olmasi bilincli: motora bir olcum kancasi takmak
## `--v2-savas`in olctugu kurulumu degistirirdi.
static func _secim_olc(w: Dunya, yil: float) -> Dictionary:
	var P := w.P
	var sikismalar := PackedFloat64Array()
	var kriz_paylari := PackedFloat64Array()
	var p5 := PackedFloat64Array()
	var p38 := PackedFloat64Array()
	var taban := 0
	for d in w.ulkeler:
		if d.rejim == "sosyalist":
			continue
		var sikisma: float = maxf(0.0,
				(P.v44.sv_r_ref - d.r_yil) / P.v44.sv_r_ref)
		var kaynak: float = P.v44.sv_kaynak if d.era >= 3 else 0.0
		var ic: float = (P.v44.sv_taban + P.v44.sv_kar_baskisi * sikisma
				+ kaynak + P.v44.sv_doktrin * d.saldirganlik)
		var p: float = ic * d.saldirganlik
		sikismalar.append(sikisma)
		kriz_paylari.append(P.v44.sv_kar_baskisi * sikisma / maxf(ic, 1e-12))
		p5.append(_tehlike(p * 0.06 * P.v44.sv_carpan * 5.0))
		p38.append(_tehlike(p * 0.06 * P.v44.sv_carpan * 38.0))
		if sikisma <= 0.0:
			taban += 1
	return {
		"yil": yil, "n": sikismalar.size(), "taban": taban,
		"sikisma_ort": _ort(sikismalar), "kriz_pay": _ort(kriz_paylari),
		"p5_ort": _ort(p5), "p5_cv": _cv(p5),
		"p38_ort": _ort(p38), "p38_cv": _cv(p38),
	}


## `savas.gd::_tehlike` ile AYNI, yillik donem icin.
static func _tehlike(tur_basina: float) -> float:
	var yillik := clampf(
			Oran.yillik_akim(tur_basina, Oran.V44_TUR_YIL), 0.0, 0.999999)
	return 1.0 - pow(1.0 - yillik, 1.0)


static func _canlilik_yaz(kova: Dictionary, yillar: Array,
		r_ref: float) -> void:
	print("")
	print("-".repeat(78))
	print("B1) KRIZ KANALI NE ZAMAN CANLI")
	print("-".repeat(78))
	print("  `sikisma` = max(0, (r_ref - r)/r_ref), r_ref = %.3f -- MUTLAK esik." % r_ref)
	print("  r esigin ustundeyken terim SIFIRDIR: kriz savasa itmez.")
	print("")
	print("  donem        r_ort     r_min     r_max   r<r_ref   ilan")
	var canli := 0
	var olu := 0
	for y in yillar:
		var b: Array = kova[y]
		if b[1] == 0:
			continue
		var oran := float(b[0]) / float(b[1])
		print("  %4d-%4d %9.4f %9.4f %9.4f %8.1f%% %6d" % [
			y, y + KOVA - 1, b[2] / float(b[1]), b[3], b[4],
			oran * 100.0, b[5]])
		if oran >= 0.5:
			canli += b[5]
		else:
			olu += b[5]
	var toplam := canli + olu
	print("")
	print("  Toplam ilan: %d" % toplam)
	print("  Kanal CANLI donemlerde (ulkelerin >=%%50'si esigin altinda): %d (%%%.1f)"
			% [canli, 100.0 * float(canli) / maxf(float(toplam), 1.0)])
	print("  Kanal OLU donemlerde:                                       %d (%%%.1f)"
			% [olu, 100.0 * float(olu) / maxf(float(toplam), 1.0)])


static func _secim_yaz(satirlar: Array) -> void:
	print("")
	print("-".repeat(78))
	print("B2) CARPAN DOYURUYOR MU -- ilan olasiligi, `_tehlike`den SONRA")
	print("-".repeat(78))
	print("  yil    sikisma_ort  esikte  kriz_pay | siklik=5 ort/cv | siklik=38 ort/cv")
	for s in satirlar:
		print("  %4d %12.3f %7d %9.3f | %7.5f %5.3f | %8.5f %5.3f" % [
			int(s["yil"]), s["sikisma_ort"], s["taban"], s["kriz_pay"],
			s["p5_ort"], s["p5_cv"], s["p38_ort"], s["p38_cv"]])
	print("")
	print("  CV iki carpanda AYNI kalirsa doyum YOKTUR: bu bolgede `_tehlike`")
	print("  fiilen dogrusaldir ve carpan kesiti oldugu gibi olceklendirir.")


# ===========================================================================
# ISTATISTIK
# ===========================================================================

static func _ort(a: PackedFloat64Array) -> float:
	if a.is_empty():
		return 0.0
	var t := 0.0
	for x in a:
		t += x
	return t / float(a.size())


static func _cv(a: PackedFloat64Array) -> float:
	if a.size() < 2:
		return 0.0
	var m := _ort(a)
	if absf(m) < 1e-12:
		return 0.0
	var v := 0.0
	for x in a:
		v += (x - m) * (x - m)
	return sqrt(v / float(a.size())) / absf(m)


static func _min(a: PackedFloat64Array) -> float:
	var m := INF
	for x in a:
		m = minf(m, x)
	return m if m != INF else 0.0


static func _max(a: PackedFloat64Array) -> float:
	var m := -INF
	for x in a:
		m = maxf(m, x)
	return m if m != -INF else 0.0
