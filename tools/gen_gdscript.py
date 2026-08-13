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


if __name__ == "__main__":
    print(f"kaynak : {MOTOR_KAYNAK}")
    print(f"model  : {M.SURUM}\n")
    karma = param_set_yaz()
    tablolar_yaz()
    if karma != "7ac8c1e1":
        print(f"\nUYARI: parametre karmasi {karma}, belgede yayimlanan 7ac8c1e1 degil.")
        print("Kaynak belge degismis olabilir; port hedefi kaymis demektir.")
    else:
        print("\nparametre karmasi belgeyle uyusuyor (7ac8c1e1).")
