"""Country alanlarinin GERCEKTE hangi tipleri aldigini olcer.

NEDEN: Python'da `self.kontrol = 0` yazan bir alan yuz tur sonra 0.37 olabilir;
dilin int/float ayrimi akiskandir. GDScript'te oyle degil -- alani `int` diye
tiplersem atanan float SESSIZCE kirpilir ve motor yanlis calisir, ustelik
hicbir hata vermez.

Bu yuzden tip karari TAHMINLE degil OLCUMLE verilir: tam kampanya kosulur, her
turda her ulkenin her alani incelenir ve gorulen tipler biriktirilir.

Cikti GDScript tip onerisidir:
    int    -> kosu boyunca yalnizca int gorulmus
    float  -> en az bir kez float gorulmus  (int gorulse bile float secilmeli)
    bool / String / Dictionary / Array / null-mumkun -> ozel islem

Kullanim:
    python tools/probe_types.py [tur] [tohum]
"""

import os
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(KOK, "python"))

from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine  # noqa: E402

ATLA = {"tarih"}  # cok buyuk, ayri ele aliniyor


def tipler(turlar, tohum):
    gorulen = {}
    e = GhostEconomyEngine(tohum)

    def tara():
        for c in e.D:
            for ad, v in vars(c).items():
                if ad in ATLA:
                    continue
                gorulen.setdefault(ad, set()).add(type(v).__name__)

    tara()
    for _ in range(turlar):
        e.step()
        tara()
    return gorulen


def gd_oneri(tipler_kumesi):
    t = set(tipler_kumesi)
    bos = "NoneType" in t
    t.discard("NoneType")
    if t == {"bool"}:
        return "bool", bos
    if t == {"int"}:
        return "int", bos
    if t <= {"int", "float"}:
        # float gorulduyse (ya da ikisi birden) GDScript'te float olmali.
        return "float", bos
    if t == {"str"}:
        return "String", bos
    if t == {"dict"}:
        return "Dictionary", bos
    if t <= {"list", "set", "tuple"}:
        return "Array", bos
    return "/".join(sorted(t)) or "null", bos


def kontrol_et(g):
    """Olculen tipleri gen_gdscript.py'deki ACIK tabloya karsi dogrular.

    Tablo elle bakimlidir (uretimin girdisi odur), bu yuzden canli kosuyla
    uyusmadigi an yakalanmali: bir alan ilk kez float almaya baslarsa
    GDScript tarafinda sessiz kirpma dogar.
    """
    sys.path.insert(0, os.path.join(KOK, "tools"))
    import gen_gdscript as G

    hatalar = []
    for ad in sorted(g):
        t = set(g[ad])
        bos = "NoneType" in t
        t.discard("NoneType")

        if bos and ad not in G.ULKE_NULL:
            hatalar.append(f"{ad}: kosuda None goruldu ama ULKE_NULL icinde degil")
        if ad in G.ULKE_INT and "float" in t:
            hatalar.append(f"{ad}: ULKE_INT'te ama kosuda float goruldu "
                           f"-> GDScript'te SESSIZ KIRPMA")
        if ad in G.ULKE_BOOL and t - {"bool"}:
            hatalar.append(f"{ad}: ULKE_BOOL'da ama {sorted(t)} goruldu")
        if ad in G.ULKE_STRING and t - {"str"}:
            hatalar.append(f"{ad}: ULKE_STRING'de ama {sorted(t)} goruldu")
        if (ad not in G.ULKE_INT and ad not in G.ULKE_BOOL
                and ad not in G.ULKE_STRING and ad not in G.ULKE_DICT
                and ad not in G.ULKE_ARRAY and ad not in G.ULKE_NULL
                and ad not in G.ULKE_FLOAT_ZORLA
                and t and not t <= {"int", "float"}):
            hatalar.append(f"{ad}: hicbir tabloda yok ve sayisal degil ({sorted(t)})")

    print(f"\n{'='*70}")
    if not hatalar:
        print(f"TIP TABLOSU: GECTI ({len(g)} alan tabloyla uyusuyor)")
        return 0
    print(f"TIP TABLOSU: {len(hatalar)} UYUSMAZLIK")
    for h in hatalar:
        print(f"  {h}")
    print("\ngen_gdscript.py icindeki tablolari duzeltip yeniden uretin.")
    return 1


if __name__ == "__main__":
    kontrol = "--check" in sys.argv
    arg = [a for a in sys.argv[1:] if not a.startswith("--")]
    turlar = int(arg[0]) if len(arg) > 0 else 400
    tohum = int(arg[1]) if len(arg) > 1 else 42

    g = tipler(turlar, tohum)

    if kontrol:
        print(f"# tip kontrolu -- {turlar} tur, tohum {tohum}, {len(g)} alan")
        sys.exit(kontrol_et(g))

    print(f"# Country alan tipleri -- {turlar} tur, tohum {tohum}, 20 ulke")
    print(f"# {len(g)} alan\n")

    # En riskli grup: kaynakta int gorunup kosuda float olanlar.
    riskli = []
    for ad in sorted(g):
        gd, bos = gd_oneri(g[ad])
        etiket = gd + ("  (null olabilir)" if bos else "")
        ham = ",".join(sorted(g[ad]))
        print(f"{ad:26s} {etiket:26s} gorulen: {ham}")
        if gd == "float" and "int" in g[ad] and "float" in g[ad]:
            riskli.append(ad)

    print(f"\n# DIKKAT -- kosuda hem int hem float goruldu ({len(riskli)} alan).")
    print("# Bunlari GDScript'te int diye tiplemek sessiz kirpma uretir:")
    for ad in riskli:
        print(f"#   {ad}")
