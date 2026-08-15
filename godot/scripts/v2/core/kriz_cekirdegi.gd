class_name KrizCekirdegi
extends RefCounted

## v2'nin DEGER KATMANI -- LTRPF omurgasi.
##
## v4.4-Frozen'in `step()` fonksiyonundan ayiklandi. Oradan taşınan tek şey
## denklemlerdir; 20 ulke, 1259 tur, senaryo odalari ve kalibrasyon
## taşınmadi (bkz. docs/oyun_tasarimi_v2.md §1).
##
## OMURGA:
##     c/v  = organik_bilesim(q)          -- TAVANSIZ, egilimin yakiti
##     kv   = kv0 * c/v^us / (1+ucuzlama)
##     Y    = min(K/kv, q * emek_esdeger) -- arz kapasitesi
##     V    = Y * canli_pay               -- YENI DEGER yalnizca canli emekten
##     s    = V * (1 - pay)               -- arti deger
##     r    = s / K                       -- KAR ORANI
##     g    = g_taban + g_duy*(r - i) + hizlandirici*(u - u_normal)
##     K   *= (1 + g)
##     q   *= (1 + qg)
##
## Dongu buradan kapanir: q yukselir -> c/v yukselir -> kv yukselir ve
## otomasyon canli_pay'i dusurur -> V kuculur -> s kuculur -> r duser -> g
## duser. Oyuncunun her "iyilestirmesi" kendi kar oranini asindirir.
##
## DONEM UZUNLUGU. `adim()` bir `donem_yil` alir ve hesabin TAMAMINI YILLIK
## yapar; donem uzunlugu yalnizca EN SONDA, stok guncellemesinde devreye
## girer. Bu sayede haftalik, aylik ya da turluk kosu ayni yorungeyi verir
## (bkz. `OlcekTesti`) ve v4.4'ten taşımanın en olası sessiz hatası --
## parametreleri 14 kat hizli kosturmak -- yapisal olarak imkansizlasir.
##
## B0 KAPSAMI: omurga + Tonak deger gasbi + Minsky balonu. Kalan bloklar
## (talep, dis ticaret, para, kriz tescili, orgutlenme, devrim) B2'de gelir.

var P: KrizParam


func _init(p_param: KrizParam = null) -> void:
	P = p_param if p_param != null else KrizParam.new()


## Sermaye/hasila katsayisi. v4.4 `kappa_v` ile ayni; ucuzlama makinelerin
## ucuzlamasidir ve sermaye yogunlasmasinin bir kismini geri alir.
func kappa_v(cv: float, q: float) -> float:
	var L := maxf(0.0, log(maxf(q, 0.05) / 0.5))
	var ucuz := P.ucuzlama_max * L / (L + P.ucuzlama_h)
	return P.kv0 * pow(cv, P.kv_us) / (1.0 + ucuz)


## Bir donem ilerletir. `donem_yil`: 1/52 haftalik, 0.27 v4.4 turu, 1.0 yillik.
func adim(d: KrizDurumu, donem_yil: float) -> void:
	P.cag_uygula(d.era)

	# --- Deger bilesimi ---------------------------------------------------
	# c/v'nin TAVANI YOKTUR. Egilimin yakiti budur: q buyudukce c/v buyur ve
	# geri donmez.
	d.cv = Formulas.organik_bilesim(d.q)
	d.kv = kappa_v(d.cv, d.q)

	# --- Otomasyon --------------------------------------------------------
	# Bu bir POLITIKA degil, rekabetin zorlayici yasasinin sonucudur: duran
	# geride kalir. Bu yuzden oyuncunun kapatabilecegi bir kol degildir.
	if d.era >= P.oto_esik_era:
		var hedef := P.oto_tavan * minf(1.0, d.ito / P.ito_tavan) * minf(
				1.0, float(d.era - P.oto_esik_era + 1) / 2.0)
		d.oto += Oran.donem_uyum(P.oto_hiz_yil, donem_yil) * (hedef - d.oto)
	d.oto = clampf(d.oto, 0.0, P.oto_tavan)

	# --- Arz kapasitesi ---------------------------------------------------
	# Robotlar FIZIKSEL uretime katilir ve emek esdegeri olarak olculur; ama
	# DEGER uretmezler. Ayrim bu oyunun butun tezidir.
	var canli_emek := d.L_etkin * d.e * d.hafta_saati
	var robot_esdeger := P.oto_verim * d.oto * d.K / maxf(d.q, 1e-6)
	var emek_esdeger := canli_emek + robot_esdeger
	d.canli_pay = maxf(P.oto_canli_taban, canli_emek / maxf(emek_esdeger, 1e-9))

	var Y_K := d.K / maxf(d.kv, 1e-9)
	var Y_L := d.q * emek_esdeger
	d.Y_yil = minf(Y_K, Y_L) * d.u

	# --- Tonak deger gasbi ------------------------------------------------
	# YENI DEGER yalnizca canli emekten gelir. Fiziksel hasila Y devasa
	# olabilir; deger buyuklugu V bundan bagimsiz olarak buzulur.
	d.V_yil = d.Y_yil * d.canli_pay
	var s_ham := d.V_yil * (1.0 - d.pay)
	d.lumpen_pay = minf(P.lumpen_tavan, P.lumpen_carpani * d.uyusturucu_orani)
	# Illegal sektor payinin OTESINDE deger ceker (illegalite primi).
	d.gasp = s_ham * d.lumpen_pay * P.illegalite_primi
	d.s_yil = s_ham * (1.0 - d.lumpen_pay)
	# Gasbedilen deger uretken sermayeye DEGIL asalak/spekulatif stoka akar.
	d.varlik += Oran.donem_akim(P.gasp_varlik_yil * d.gasp, donem_yil)

	# --- KAR ORANI --------------------------------------------------------
	d.r_yil = d.s_yil / maxf(d.K, 1e-6)

	# --- Minsky: spekulatif balon ----------------------------------------
	_minsky(d, donem_yil)

	# --- Birikim ----------------------------------------------------------
	# Kar orani faizin altina dustukce birikim durur: LTRPF'nin yatirima
	# aktarildigi yer burasidir.
	d.g_yil = (P.g_taban_yil
			+ P.g_duy * (d.r_yil - d.i_yil)
			+ P.hizlandirici_yil * (d.u - P.u_normal))
	d.g_yil = clampf(d.g_yil, -P.g_daralma_tavani_yil, P.g_tavani_yil)

	# --- Stok guncellemesi -- DONEM UZUNLUGU YALNIZCA BURADA -------------
	d.K = maxf(1.0, d.K * (1.0 + Oran.donem_buyume(d.g_yil, donem_yil)))
	d.q *= (1.0 + Oran.donem_buyume(P.qg_yil, donem_yil))


func _minsky(d: KrizDurumu, donem_yil: float) -> void:
	var v_oran_onc := d.varlik / maxf(d.Y_yil, 1e-6)

	# (i) Kar sikismasi kanali: uretken alan spekulatif getiriyi yenemedigi
	#     olcude arti deger finansa kayar. Kayan sey yalnizca AKIM degil,
	#     atil duran SERMAYE STOKUDUR -- karlilik dustukce finansallasmanin
	#     ARTMASI beklenir.
	var makas := maxf(0.0, (d.i_spec_yil - d.r_yil) / maxf(d.i_spec_yil, 1e-6))
	var kayan := P.fin_pay_yil * maxf(d.s_yil, 0.0) * makas
	kayan += P.fin_stok_yil * d.K * makas
	# (ii) Kaldiracli spekulasyon: balon kendi beklentisini besler.
	kayan += P.spec_kredi_yil * d.varlik * maxf(0.0, d.varlik_beklenti)
	# (iii) Doygunluk: mutlak sinira yaklastikca akim soner.
	kayan *= maxf(0.0, 1.0 - v_oran_onc / P.balon_limiti)

	d.varlik += Oran.donem_akim(kayan, donem_yil)
	d.varlik *= (1.0 - Oran.donem_akim(P.balon_sonum_yil, donem_yil))

	# Varlik FIYATI (varlik/Y) uzerinden getiri beklentisi -- ekstrapolatif.
	# Ham stok yerine ORANI kullanmak gerekir: hasila buyurken sabit bir stok
	# reel olarak deger kaybediyor demektir.
	var v_oran_yeni := d.varlik / maxf(d.Y_yil, 1e-6)
	var getiri := (v_oran_yeni / v_oran_onc - 1.0) if v_oran_onc > 1e-9 else 0.0
	# Beklenti bir ORAN DEGISIMIDIR, yani donem uzunluguna baglidir: haftalik
	# olcumde ayni yillik egilim 14 kat kucuk gorunur. Yilliga cevriliyor.
	var getiri_yil := getiri / maxf(donem_yil, 1e-9)
	var uy := Oran.donem_uyum(P.beklenti_hiz_yil, donem_yil)
	d.varlik_beklenti = minf(P.beklenti_tavan,
			(1.0 - uy) * d.varlik_beklenti + uy * getiri_yil)

	if v_oran_yeni > P.minsky_esik and d.varlik_beklenti < d.i_spec_yil:
		d.minsky_sayac += 1
