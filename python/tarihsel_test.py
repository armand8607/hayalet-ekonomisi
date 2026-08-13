"""TARIHSEL DONEM AYRIMI TESTI (elestirinin 17. maddesi).

Yuklenen kayit (27 kriz, 1825-2023) iki doneme bolunur:
  1825-1950 : 14 kriz / 125 yil = 8.9 yil    baskin tip: ASIRI URETIM
  1951-2023 : 13 kriz /  72 yil = 5.5 yil    baskin tip: FINANSAL / KARLILIK

DURUSTLUK NOTU: bu TAM out-of-sample DEGILDIR -- motorun parametreleri butun
kaydi gorerek ayarlandi. Ama kalibrasyon hedefleri TOPLAM metriklerdi (LTRPF,
issizlik, Minsky araligi); DONEM BAZINDA TIP BILESIMI hic hedeflenmedi.
Dolayisiyla tip bilesimindeki KAYMA gercek bir (zayif) tutarlilik sonucudur.
"""
import os, statistics as st, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine, KAMPANYA_TURU, TUR_YIL, SURUM

KAYIT = {"1825-1950": {"kriz": 14, "yil": 125, "baskin": "asiri uretim"},
         "1951-2023": {"kriz": 13, "yil": 72,  "baskin": "finansal/karlilik"}}
DONEM = [(1825,1950,"1825-1950"), (1951,2023,"1951-2023")]

def kos(tohumlar):
    agg = {d[2]: {} for d in DONEM}
    for t in tohumlar:
        e = GhostEconomyEngine(t); e.run_simulation(KAMPANYA_TURU)
        for c in e.D:
            for (tt, bir, _ik) in c.kriz_gunlugu:
                y = 1760 + tt*TUR_YIL
                for a, b, ad in DONEM:
                    if a <= y < b:
                        agg[ad][bir] = agg[ad].get(bir, 0) + 1
    return agg

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv)>1 else 20
    toh = list(range(101, 101+n))
    agg = kos(toh)
    print(f"TARIHSEL DONEM TESTI — {SURUM}, {n} tohum (dogrulama seti {toh[0]}..{toh[-1]})")
    print("="*76)
    ASIRI = ("ASIRI_URETIM","RESESYON","BUYUK_BUNALIM")
    FINANS = ("MINSKY","BORC_KRIZI","FX_KRIZI","MORATORYUM","DEVLET_COKUSU")
    for a,b,ad in DONEM:
        c = agg[ad]; uy = 20*n*(b-a)
        tot = sum(c.values()) or 1
        pa = 100*sum(c.get(k,0) for k in ASIRI)/tot
        pf = 100*sum(c.get(k,0) for k in FINANS)/tot
        onc = max(c, key=c.get) if c else "-"
        print(f"\n{ad}  (kayit: {KAYIT[ad]['kriz']} kriz/{KAYIT[ad]['yil']} yil "
              f"= {KAYIT[ad]['yil']/KAYIT[ad]['kriz']:.1f} yil, baskin: {KAYIT[ad]['baskin']})")
        print(f"  motor: asiri-uretim ailesi %{pa:.0f} | finansal aile %{pf:.0f} | en sik: {onc}")
        for k,v in sorted(c.items(), key=lambda x:-x[1])[:6]:
            print(f"     {k:<16} {v:6d}  ulke-yil araligi {uy/v:8.1f} yil")
    # KAYMA testi
    c1, c2 = agg["1825-1950"], agg["1951-2023"]
    t1 = sum(c1.values()) or 1; t2 = sum(c2.values()) or 1
    a1 = sum(c1.get(k,0) for k in ASIRI)/t1; a2 = sum(c2.get(k,0) for k in ASIRI)/t2
    f1 = sum(c1.get(k,0) for k in FINANS)/t1; f2 = sum(c2.get(k,0) for k in FINANS)/t2
    print("\n" + "="*76)
    print(f"KAYMA: asiri-uretim payi %{100*a1:.0f} -> %{100*a2:.0f}  "
          f"(beklenen: DUSMELI)   {'GECTI' if a2 < a1 else 'KALDI'}")
    print(f"       finansal payi   %{100*f1:.0f} -> %{100*f2:.0f}  "
          f"(beklenen: YUKSELMELI) {'GECTI' if f2 > f1 else 'KALDI'}")
