"""Kabul olcutlerini TOHUM BASINA basar -- GDScript harness'i ile ayni bicimde.

Neden gerekli: tur 408'den sonra bit-birebir parite libm yuzunden ulasilamaz
(bkz. CLAUDE.md), dolayisiyla "ayni tohum ayni sonucu veriyor mu" diye
sorulamaz. Sorulabilecek dogru soru: iki motor AYNI DAGILIMI mi uretiyor?
Tohum basina yan yana bakmak, medyanin gizledigi sistematik kaymayi gorunur
kilar -- ozellikle devrim sayisi gibi tohuma cok duyarli olculerde.

Kullanim:
    python python/tools/kabul_tohum.py [tohum_sayisi] [tur] [ilk_tohum]
"""

import os
import statistics as st
import sys

KOK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(KOK, "python"))

from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine, TUR_YIL  # noqa: E402


def olc(tohum, turlar):
    e = GhostEconomyEngine(tohum)
    e.run_simulation(turlar)
    n = len(e.D)
    yil = turlar * TUR_YIL
    basla = int(turlar * 0.875)

    son = [x for c in e.D for x in c.tarih[basla:]]
    son_kap = [x for c in e.D for x in c.tarih[basla:]
               if x.get("rej", "kapitalist") == "kapitalist"] or son

    tr = e.kar_orani_trendi(max(turlar // 4, 1))
    ltrpf = tr[-1]["r"] / tr[0]["r"] - 1 if tr and tr[0]["r"] else float("nan")

    res = sum(len(c.resesyonlar) for c in e.D)
    minsky = sum(1 for _, k, m in e.log if k == "COKME" and "MINSKY" in m.upper())
    gecis = sum(len(c.kurum_gecmis) for c in e.D)
    devrim = sum(1 for c in e.D if c.devrim_t is not None)

    ileri = sum(1 for c in e.D for (_, a, b) in c.kurum_gecmis
                if a == "duzenli" and b == "neoliberal")
    geri = sum(1 for c in e.D for (_, a, b) in c.kurum_gecmis
               if a == "neoliberal" and b == "duzenli")
    lib = sum(1 for c in e.D for (_, _a, b) in c.kurum_gecmis if b == "liberal")

    return {
        "ltrpf": ltrpf,
        "iss": 1 - st.mean([x["e"] for x in son_kap]),
        "res_yil": yil / (res / n) if res else float("inf"),
        "minsky_yil": yil / (minsky / n) if minsky else float("inf"),
        "gecis": gecis, "devrim": devrim,
        "oto": st.mean([x["oto"] for x in son]),
        "canli": st.mean([x["canli_pay"] for x in son]),
        "ileri": ileri, "geri": geri, "liberal": lib,
    }


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 6
    turlar = int(sys.argv[2]) if len(sys.argv) > 2 else 1259
    ilk = int(sys.argv[3]) if len(sys.argv) > 3 else 101

    print(f"# kabul tohum={ilk}..{ilk+n-1} tur={turlar}")
    for s in range(ilk, ilk + n):
        d = olc(s, turlar)
        print(f"tohum {s} ltrpf {d['ltrpf']:.4f} iss {d['iss']:.4f} "
              f"res_yil {d['res_yil']:.2f} minsky_yil {d['minsky_yil']:.2f} "
              f"gecis {d['gecis']} devrim {d['devrim']} "
              f"oto {d['oto']:.4f} canli {d['canli']:.4f} "
              f"ileri {d['ileri']} geri {d['geri']} liberal {d['liberal']}")
