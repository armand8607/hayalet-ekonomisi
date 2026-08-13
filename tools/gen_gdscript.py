"""Python motorundan GDScript veri katmanini URETIR.

NEDEN URETILIYOR, ELLE YAZILMIYOR: `Params` 344 alan, `ERAS`/`KURUMLAR`/
`PLAN_PROFILLERI`/ulke tohum tablosu toplam ~150 sayi daha. Bunlarin tamami
DONMUS KALIBRASYONDUR -- tek bir basamak hatasi motorun davranisini sessizce
degistirir ve oynayarak fark edilmez. Elle kopyalamak bu yuzden kabul edilemez
bir risk; uretim mekanik ve tekrarlanabilir olmali.

Kaynak degerler REGEX ile degil INTROSPEKSIYON ile alinir (modulu import edip
`dataclasses.fields` okur), boylece yorum satirlari, satir kaymalari ve
bicimlendirme farklari sonuca karisamaz. Yalnizca `dunya_kur()` icindeki yerel
`T` listesi introspekte edilemedigi icin `ast` ile literal olarak cikarilir.

Uretilenler:
    godot/scripts/core/param_set.gd   <- Params dataclass (344 alan)
    godot/scripts/tables.gd           <- ERAS, KURUMLAR, PLAN_PROFILLERI, ULKELER

Float degerler `repr()` ile yazilir: Python'un repr'i en kisa gidis-donus
temsilidir ve GDScript'in double ayristiricisi ayni degeri geri okur.

Kullanim:
    python tools/gen_gdscript.py
"""

import ast
import dataclasses
import os
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(KOK, "python"))

import hayalet_ekonomi_motoru_v43 as M  # noqa: E402

MOTOR_KAYNAK = os.path.join(KOK, "python", "hayalet_ekonomi_motoru_v43.py")
CIKTI_PARAM = os.path.join(KOK, "godot", "scripts", "core", "param_set.gd")
CIKTI_TABLO = os.path.join(KOK, "godot", "scripts", "tables.gd")
CIKTI_ULKE = os.path.join(KOK, "godot", "scripts", "core", "country.gd")


# ---------------------------------------------------------------------------
# COUNTRY ALAN TIPLERI -- ACIK, GOZDEN GECIRILEBILIR, SUREKLI DOGRULANAN
# ---------------------------------------------------------------------------
# Python'da int/float ayrimi akiskandir: `self.L_max = 110` diye baslayan alan
# demografi calisinca 110.37 olur. GDScript'te oyle DEGIL -- alani `int` diye
# tiplersem atanan float SESSIZCE kirpilir, hicbir hata cikmaz ve nufus her tur
# asagi yuvarlanir.
#
# Bu tablo bu yuzden TAHMINLE degil OLCUMLE kuruldu (`tools/probe_types.py`,
# 600 tur x 20 ulke). Tabloyu elle degistirmeyin; once probe'u kosturun.
# `python tools/probe_types.py --check` tabloyu canli kosuya karsi dogrular.

# Kosu boyunca YALNIZCA tamsayi degeri gorulen alanlar (sayaclar, sureler).
ULKE_INT = {
    "abluka", "au_bekle", "au_ici", "bun_ici", "cs_kisit", "delev", "era",
    "fx_baski", "fx_kriz", "gecis_sok", "heg_sayac", "izo_sayac", "kemer",
    "kontrol", "kriz", "kurum_insa_t", "kurum_t", "minsky_sayac", "mor_ceza",
    "pr_sayac", "res_bekle", "res_ici", "savas_sayisi", "savas_toplam",
    "stagflasyon",
}

ULKE_BOOL = {"ai_muaf", "ambargo", "hegemon", "parti_iktidari"}
ULKE_STRING = {"ad", "tip", "rejim", "kurum", "pakt_durusu"}
ULKE_DICT = {"savas", "plan", "olay_bayraklari", "pol_kuyruk"}
ULKE_ARRAY = {
    "asiri_uretim_krizleri", "bunalimlar", "fx_krizleri", "ito_bilesen",
    "kriz_gunlugu", "kurum_gecmis", "moratoryumlar", "muttefik",
    "resesyonlar", "temerrutler",
}

# None TASIYABILEN alanlar -> GDScript'te TIPSIZ `var` olmali. Tipli bir alana
# null atanamaz; motor "henuz olmadi" durumunu bu alanlarla anlatiyor
# (devrim_t is None == "bu ulkede devrim olmadi"), sifirla degil.
ULKE_NULL = {
    "devrim_t", "devrim_era", "restorasyon_t", "baslangic_rejimi_t",
    "birincil_kriz", "kurum_insa_hedef", "mafya_kilit", "plan_hedef",
}

# Kurucuya int literal olarak gelen ama surekli degisken olan alanlar.
ULKE_FLOAT_ZORLA = {"K", "L_max", "q", "pay", "IR", "baski_egilimi", "saldirganlik"}

# `tarih` GDScript'te History sinifidir (sutun deposu), duz liste degil.
ULKE_ATLA = {"tarih"}

UYARI = (
    "# =============================================================\n"
    "# BU DOSYA URETILMISTIR -- ELLE DUZENLEMEYIN.\n"
    "# Kaynak : docs/hayalet_ekonomisi_v44_frozen.md (tek dogruluk kaynagi)\n"
    "#          -> python/hayalet_ekonomi_motoru_v43.py\n"
    "# Ureten : tools/gen_gdscript.py\n"
    "# Yeniden uretmek icin: python tools/gen_gdscript.py\n"
    "# =============================================================\n"
)


def gd_deger(v):
    """Bir Python degerini GDScript literaline cevirir."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return repr(v)
    if isinstance(v, float):
        if v != v or v in (float("inf"), float("-inf")):
            raise SystemExit(f"HATA: GDScript'e tasinamayan float: {v!r}")
        r = repr(v)
        # GDScript'te float literali nokta ya da us icermeli; "5.0" repr'den
        # zaten boyle gelir ama "5e-05" gibi durumlar da gecerlidir.
        return r
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, (tuple, list)):
        return "[" + ", ".join(gd_deger(x) for x in v) + "]"
    if isinstance(v, set):
        # GDScript'te Set yok. `muttefik` bir isim kumesi; sirali Array olur.
        # Python set yinelemesi surece ozgu olabilir (PYTHONHASHSEED), ama
        # olculdu: 1259 turluk kosuda sonuc hash tohumundan BAGIMSIZ cikiyor,
        # yani sira burada davranisi belirlemiyor. Yine de sapma cikarsa ilk
        # supheli budur (bkz. CLAUDE.md).
        return "[" + ", ".join(gd_deger(x) for x in sorted(v)) + "]"
    if isinstance(v, dict):
        return "{" + ", ".join(f"{gd_deger(k)}: {gd_deger(x)}" for k, x in v.items()) + "}"
    raise SystemExit(f"HATA: bilinmeyen tip {type(v).__name__}: {v!r}")


def gd_tip(v):
    if isinstance(v, bool):
        return "bool"
    if isinstance(v, int):
        return "int"
    if isinstance(v, float):
        return "float"
    if isinstance(v, str):
        return "String"
    if isinstance(v, (tuple, list)):
        return "Array"
    if isinstance(v, dict):
        return "Dictionary"
    raise SystemExit(f"HATA: bilinmeyen tip {type(v).__name__}")


def ulke_tablosu():
    """`dunya_kur()` icindeki yerel `T` listesini ast ile cikarir."""
    with open(MOTOR_KAYNAK, "r", encoding="utf-8") as f:
        agac = ast.parse(f.read())
    for dugum in ast.walk(agac):
        if isinstance(dugum, ast.FunctionDef) and dugum.name == "dunya_kur":
            for st in dugum.body:
                if (isinstance(st, ast.Assign) and len(st.targets) == 1
                        and isinstance(st.targets[0], ast.Name)
                        and st.targets[0].id == "T"):
                    return ast.literal_eval(st.value)
    raise SystemExit("HATA: dunya_kur() icinde T listesi bulunamadi.")


def param_set_yaz():
    alanlar = list(dataclasses.fields(M.Params))
    ornek = M.Params()

    satirlar = [
        "class_name ParamSet",
        "extends RefCounted",
        "",
        UYARI.rstrip("\n"),
        "",
        "## Motorun donmus kalibrasyon sabitleri -- Python `Params` dataclass'inin",
        "## birebir karsiligi (v4.4-Frozen, %d alan)." % len(alanlar),
        "##",
        "## `const` DEGIL `var`: test kosulari parametreleri ORNEK BAZINDA degistirir",
        "## (`e.P.fin_stok = 0.0`, `e.P.ai_acik = false`), tipki Python'da her motorun",
        "## kendi `self.P = Params()` ornegine sahip olmasi gibi. Her GhostEngine",
        "## kendi ParamSet'ini alir; biri digerini etkilemez.",
        "",
    ]

    for f in alanlar:
        v = getattr(ornek, f.name)
        satirlar.append(f"var {f.name}: {gd_tip(v)} = {gd_deger(v)}")

    # Parametre imzasi: Python `deney_kimligi()` ile ayni siralama ve bicim.
    pars = sorted((f.name, getattr(ornek, f.name)) for f in alanlar)
    imza = ";".join(f"{k}={v}" for k, v in pars)
    import zlib
    karma = f"{zlib.crc32(imza.encode('utf-8')):08x}"

    satirlar += [
        "",
        "",
        "## Uretim aninda Python tarafinda olculen parametre karmasi.",
        "## Belgenin 9.18 bolumunde yayimlanan deger ile ayni olmali: 7ac8c1e1",
        "## (frozen.md'den cikarmanin sadakatini kanitlayan bagimsiz olcut).",
        f'const BEKLENEN_KARMA := "{karma}"',
        f"const ALAN_SAYISI := {len(alanlar)}",
        "",
        "",
        "## Butun alanlari ad sirasiyla dondurur -- parite dokumu bunu kullanir.",
        "func alanlar_sirali() -> Array:",
        "\tvar adlar := []",
        "\tfor p in get_property_list():",
        "\t\tif p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:",
        "\t\t\tadlar.append(p.name)",
        "\tadlar.sort()",
        "\treturn adlar",
        "",
    ]

    with open(CIKTI_PARAM, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(satirlar))
    print(f"  yazildi  param_set.gd   {len(alanlar)} alan   karma={karma}")
    return karma


def tablolar_yaz():
    eras = M.ERAS
    kurumlar = M.KURUMLAR
    planlar = M.GhostEconomyEngine.PLAN_PROFILLERI
    ulkeler = ulke_tablosu()

    satirlar = [
        "extends Node",
        "",
        UYARI.rstrip("\n"),
        "",
        "## Motorun veri tablolari: teknolojik caglar, kurumsal rejimler, plan",
        "## profilleri ve dunya tohum tablosu. Otoload sirasinda Params'tan sonra,",
        "## Save'den once gelir.",
        "",
        "## Teknolojik caglar. `yil_alt`/`yil_ust` TARIHSEL BANTTIR: cag atlama",
        "## icseldir (q > q_esik) ama banda cakilidir -- hizli gelisen bir oyuncu",
        "## 1900'de tam otomasyona varamaz, geri kalan dunya da 2100'de buhar",
        "## caginda kalmaz.",
        f"const ERAS := {gd_deger(eras)}",
        "",
        "## Kurumsal rejimler. `hizlandirici` ve `kars_dongusel` ulkelerin krize",
        "## farkli tepki vermesini saglayan asgari mekanizmadir.",
        f"const KURUMLAR := {gd_deger(kurumlar)}",
        "",
        "## Sosyalist plan profilleri (paylar RAKIP kullanimlardir: biri artarsa",
        "## digeri azalir).",
        f"const PLAN_PROFILLERI := {gd_deger(planlar)}",
        "",
        "## Dunya tohum tablosu: ad, tip, K, L_max, q, pay, IR, baski_egilimi,",
        "## saldirganlik. `dunya_kur()` bu satirlardan Country uretir.",
        "const ULKE_ALANLARI := [\"ad\", \"tip\", \"K\", \"L_max\", \"q\", \"pay\", \"IR\","
        " \"baski_egilimi\", \"saldirganlik\"]",
        f"const ULKELER := {gd_deger([list(x) for x in ulkeler])}",
        "",
        "",
        "## c/v capalari: her cagin c/v'si o caga giris esigindeki q ile eslesir.",
        "## Python tarafinda ayni sekilde ERAS'tan TURETILIR, ayri yazilmaz --",
        "## iki tablonun birbirinden kaymasi boylece imkansiz olur.",
        "static func cv_capalari() -> Array:",
        "\tvar out := []",
        "\tvar anahtarlar := ERAS.keys()",
        "\tanahtarlar.sort()",
        "\tfor e in anahtarlar:",
        "\t\tout.append([maxf(ERAS[e][\"q_esik\"], 0.5), float(ERAS[e][\"cv\"])])",
        "\treturn out",
        "",
    ]

    with open(CIKTI_TABLO, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(satirlar))
    print(f"  yazildi  tables.gd      {len(eras)} cag, {len(kurumlar)} kurum, "
          f"{len(planlar)} plan profili, {len(ulkeler)} ulke")


def ulke_alan_tipi(ad, v):
    """Bir Country alani icin (gdscript_tipi, tipsiz_mi) dondurur."""
    if ad in ULKE_NULL:
        return None, True          # tipsiz `var x = null`
    if ad in ULKE_BOOL:
        return "bool", False
    if ad in ULKE_STRING:
        return "String", False
    if ad in ULKE_DICT:
        return "Dictionary", False
    if ad in ULKE_ARRAY:
        return "Array", False
    if ad in ULKE_INT:
        return "int", False
    if ad in ULKE_FLOAT_ZORLA:
        return "float", False
    if isinstance(v, bool):
        return "bool", False
    if isinstance(v, (int, float)):
        return "float", False
    raise SystemExit(f"HATA: '{ad}' alani icin tip kararlastirilamadi ({type(v).__name__}). "
                     "gen_gdscript.py icindeki tablolara ekleyin.")


def country_yaz():
    # Kurucu argumanlari notr; gercek degerler _init icinde atanir.
    ornek = M.Country("", "merkez", 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0)
    alanlar = [(a, v) for a, v in vars(ornek).items() if a not in ULKE_ATLA]

    # tip'e bagli dogum/olum oranlari: uc tipin degerleri ayri ayri okunur.
    tip_oranlari = {}
    for tip in ("merkez", "yari", "cevre"):
        c = M.Country("", tip, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0)
        tip_oranlari[tip] = (c.dogum_orani, c.olum_orani)

    satirlar = [
        "class_name Country",
        "extends RefCounted",
        "",
        UYARI.rstrip("\n"),
        "",
        "## Bir egemen bolge -- Python `Country` sinifinin birebir karsiligi.",
        "##",
        "## TIPLER OLCUMLE BELIRLENDI, tahminle degil (`tools/probe_types.py`).",
        "## Python'da `self.L_max = 110` diye baslayan alan demografi calisinca",
        "## 110.37 olur; GDScript'te `int` diye tiplenirse bu SESSIZCE kirpilir ve",
        "## nufus her tur asagi yuvarlanir. Hicbir hata cikmaz, motor yanlis calisir.",
        "##",
        "## `null` tasiyabilen alanlar TIPSIZ birakildi: motor 'henuz olmadi'",
        "## durumunu null ile anlatiyor (devrim_t == null -> devrim olmadi),",
        "## sifirla degil. Tipli bir alana null atanamaz.",
        "",
    ]

    for ad, v in alanlar:
        tip, tipsiz = ulke_alan_tipi(ad, v)
        if ad in ("dogum_orani", "olum_orani"):
            satirlar.append(f"var {ad}: float = 0.0   # _init icinde tip'e gore atanir")
        elif tipsiz:
            satirlar.append(f"var {ad} = {gd_deger(v) if v is not None else 'null'}")
        elif tip == "float":
            satirlar.append(f"var {ad}: float = {gd_deger(float(v))}")
        else:
            satirlar.append(f"var {ad}: {tip} = {gd_deger(v)}")

    satirlar += [
        "",
        "## Tur-tur kayit. Python'da duz bir dict listesi; burada SUTUN DEPOSU",
        "## (bkz. history.gd) -- bir kampanya 20 ulke x 1259 tur x ~60 alan eder.",
        "var tarih := History.new()",
        "",
        "",
        "func _init(p_ad: String = \"\", p_tip: String = \"merkez\", p_K: float = 0.0,",
        "\t\tp_L_max: float = 0.0, p_q: float = 0.0, p_pay: float = 0.0,",
        "\t\tp_IR: float = 0.0, p_baski_egilimi: float = 0.0,",
        "\t\tp_saldirganlik: float = 0.0) -> void:",
        "\tad = p_ad",
        "\ttip = p_tip",
        "\tK = p_K",
        "\tL_max = p_L_max",
        "\tq = p_q",
        "\tpay = p_pay",
        "\tIR = p_IR",
        "\tbaski_egilimi = p_baski_egilimi",
        "\tsaldirganlik = p_saldirganlik",
        "",
        "\t# Referans tipler ornek basina TAZE olmali. GDScript'te `var d := {}`",
        "\t# alan varsayilani her ornek icin yeni bir sozluk uretir, ama plan gibi",
        "\t# ic ice yapilarda paylasim riskini tamamen kesmek icin burada",
        "\t# yeniden kuruluyor -- bir ulkenin planini degistirmek digerininkini",
        "\t# degistirmemeli.",
        "\tplan = %s" % gd_deger(ornek.plan),
        "\tsavas = {}",
        "\tmuttefik = []",
        "\tpol_kuyruk = {}",
        "\tolay_bayraklari = {}",
        "\tfor liste in [\"fx_krizleri\", \"moratoryumlar\", \"temerrutler\", \"bunalimlar\",",
        "\t\t\t\"resesyonlar\", \"asiri_uretim_krizleri\", \"kriz_gunlugu\", \"kurum_gecmis\"]:",
        "\t\tset(liste, [])",
        "\tito_bilesen = [0.0, 0.0, 0.0, 0.0]",
        "\ttarih = History.new()",
        "",
        "\tFX = 0.35 * Y",
        "",
        "\t# Baslangic kaba dogum/olum oranlari (tip ve gelismisliğe bagli).",
        "\tmatch tip:",
    ]
    for tip in ("merkez", "yari"):
        d, o = tip_oranlari[tip]
        satirlar += [
            f'\t\t"{tip}":',
            f"\t\t\tdogum_orani = {gd_deger(d)}",
            f"\t\t\tolum_orani = {gd_deger(o)}",
        ]
    d, o = tip_oranlari["cevre"]
    satirlar += [
        "\t\t_:   # cevre",
        f"\t\t\tdogum_orani = {gd_deger(d)}",
        f"\t\t\tolum_orani = {gd_deger(o)}",
        "",
        "",
        "## Is paylasimi marjinin alt siniri.",
        "func saat_tabani(P: ParamSet) -> float:",
        "\treturn P.saat_min",
        "",
        "",
        "## Fiili haftalik calisma suresi (cag normu x paylasim payi).",
        "## Raporlama icindir: 1.00 = 1760'in tam haftasi (~70 saat).",
        "func hafta_saati(P: ParamSet) -> float:",
        "\treturn float(P.hafta_norm[mini(era, 6) - 1]) * saat",
        "",
        "",
        "## Karseral nufus dusulmus ETKIN isgucu arzi.",
        "## Itoh: hapsedilen kitle artik arti-deger uretiminin oznesi degil,",
        "## \"atil sermaye\" yonetiminin nesnesidir; emek arzindan dusulur.",
        "func l_etkin() -> float:",
        "\treturn L_max * katilim * (1.0 - minf(0.90, cezaevi_orani))",
        "",
        "",
        "## ETG'nin gonullu cekilmesi geri eklenmis issizlik orani.",
        "## ETG katilimi dusurur, bu da OLCULEN istihdam oranini mekanik olarak",
        "## yukseltir -- gercek bir etki ama ETG'nin is yaratmasiyla karistirilmamali.",
        "func iss_duzeltilmis() -> float:",
        "\tif katilim_etg <= 0.0:",
        "\t\treturn 1.0 - e",
        "\treturn 1.0 - e * katilim / maxf(katilim + katilim_etg, 1e-9)",
        "",
        "",
        "## KODEY: karseral nufus / uretken emek gucu.",
        "func atil_endeks() -> float:",
        "\treturn cezaevi_orani / maxf(1.0 - cezaevi_orani, 1e-6)",
        "",
        "",
        "func savasta() -> bool:",
        "\treturn savas.size() > 0",
        "",
        "",
        "func guc() -> float:",
        "\treturn K * q",
        "",
    ]

    with open(CIKTI_ULKE, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(satirlar))
    print(f"  yazildi  country.gd     {len(alanlar)} alan "
          f"({len(ULKE_INT)} int, {len(ULKE_NULL)} tipsiz)")


if __name__ == "__main__":
    print(f"kaynak : {MOTOR_KAYNAK}")
    print(f"model  : {M.SURUM}\n")
    karma = param_set_yaz()
    tablolar_yaz()
    country_yaz()
    if karma != "7ac8c1e1":
        print(f"\nUYARI: parametre karmasi {karma}, belgede yayimlanan 7ac8c1e1 degil.")
        print("Kaynak belge degismis olabilir; port hedefi kaymis demektir.")
    else:
        print("\nparametre karmasi belgeyle uyusuyor (7ac8c1e1).")
