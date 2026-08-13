"""
HASSASIYET ANALIZI — hangi parametre yapisal, hangisi kalibrasyon dugmesi?

Bu projede onlarca parametre elle ayarlandi. Bir parametrenin YAPISAL olmasi,
kucuk bir degisiminin sonucu buyuk olcude degistirmesi demektir; KALIBRASYON
DUGMESI ise sonucu az etkileyen, rahatca oynatilabilen parametredir.

Her parametre -%20 / -%10 / 0 / +%10 / +%20 taranir ve on iki cekirdek metrikteki
GORELI degisim olculur. Duyarlilik = metriklerdeki ortalama mutlak esneklik
(|d(metrik)/metrik| / |d(par)/par|).

Yorum: esneklik > 1 ise parametre yapisal (kucuk degisim buyuk etki),
< 0.25 ise kalibrasyon dugmesi.
"""

import os
import statistics as st
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine, KAMPANYA_TURU, SURUM

# 12 cekirdek metrik (dosyanin dashboard onerisi)
def olc(e):
    son = [x for c in e.D if c.rejim == "kapitalist"
           for x in c.tarih[int(KAMPANYA_TURU * 0.875):]]
    if not son:
        son = [x for c in e.D for x in c.tarih[int(KAMPANYA_TURU * 0.875):]]
    tr = e.kar_orani_trendi(KAMPANYA_TURU // 4)
    g = lambda k: st.mean([x[k] for x in son])
    return {
        "r": g("r"), "cv": g("cv"), "u": g("u"),
        "iss": 1 - g("e"), "pay": g("pay"), "borc": g("borc"),
        "varlik": g("varlik"), "Omega": g("Om"), "org": g("org"),
        "oto": g("oto"), "canli": g("canli_pay"),
        "ltrpf": abs(tr[-1]["r"] / tr[0]["r"]),
    }


def kos(par, deger, tohumlar):
    birikim = []
    for t in tohumlar:
        e = GhostEconomyEngine(t)
        if par is not None:
            setattr(e.P, par, deger)
        e.run_simulation(KAMPANYA_TURU)
        birikim.append(olc(e))
    return {k: st.median([b[k] for b in birikim]) for k in birikim[0]}


# En kritik parametreler (dosyanin onerdigi liste + bu projede elle ayarlananlar)
PARAMETRELER = [
    "phi", "g_duy", "g_taban", "delta_K", "kredi_egilimi",
    "oto_verim", "oto_hiz", "ito_rekabet", "fin_stok",
    "parti_hiz", "pr_esik_omega", "kd_yenilgi_orani",
    "asiri_uretim", "vt_siddet", "sos_kitlik_agirlik",
]

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    tohumlar = list(range(1, n + 1))
    hedefler = sys.argv[2].split(",") if len(sys.argv) > 2 else PARAMETRELER

    e0 = GhostEconomyEngine(1)
    taban = kos(None, None, tohumlar)
    print(f"HASSASIYET ANALIZI — model {SURUM}, {n} tohum x {KAMPANYA_TURU} tur")
    print("=" * 78)
    print(f"{'parametre':<20}{'taban':>10}{'esneklik':>10}{'en duyarli metrik':>24}{'tip':>12}")
    print("-" * 78)
    t0 = time.time()
    sonuc = []
    for par in hedefler:
        if not hasattr(e0.P, par):
            print(f"{par:<20}{'YOK':>10}")
            continue
        v0 = getattr(e0.P, par)
        esnek = {k: [] for k in taban}
        for carpan in (0.80, 1.20):
            r = kos(par, v0 * carpan, tohumlar)
            for k in taban:
                if abs(taban[k]) > 1e-12:
                    d_m = (r[k] - taban[k]) / abs(taban[k])
                    esnek[k].append(abs(d_m / (carpan - 1.0)))
        ort = {k: st.mean(v) for k, v in esnek.items() if v}
        genel = st.mean(list(ort.values())) if ort else 0.0
        enb = max(ort, key=ort.get) if ort else "-"
        tip = "YAPISAL" if genel > 1.0 else ("dugme" if genel < 0.25 else "orta")
        sonuc.append((genel, par, enb, ort.get(enb, 0), tip))
        print(f"{par:<20}{v0:>10.4f}{genel:>10.3f}{enb + f' ({ort.get(enb,0):.2f})':>24}{tip:>12}")
    print("-" * 78)
    sonuc.sort(reverse=True)
    print(f"({time.time()-t0:.0f} sn)\n=== EN YAPISAL 5 ===")
    for g, par, enb, v, tip in sonuc[:5]:
        print(f"  {par:<20} esneklik={g:.3f}  en cok etkiledigi: {enb} ({v:.2f})")
    print("\n=== EN AZ ETKILI 5 (kalibrasyon dugmesi) ===")
    for g, par, enb, v, tip in sonuc[-5:]:
        print(f"  {par:<20} esneklik={g:.3f}")
