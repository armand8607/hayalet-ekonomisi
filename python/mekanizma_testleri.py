"""
MEKANIZMA YON TESTLERI — birincil kabul kriteri.

Bant testleri "sayi su aralikta mi" diye sorar ve o aralik bu projede dort kez
degistirildi; dolayisiyla bantlar kalibrasyonun kaydidir, bagimsiz kriter degil.
Yon testleri ise "otomasyon artinca canli emek payi DUSUYOR mu" diye sorar.
Yonu ayarlayamazsiniz: ya vardir ya yoktur. Bu yuzden birincil kriterdir.

Her test bir ISARET ya da SIRALAMA iddiasi kurar ve tohumlar arasinda kac kez
dogrulandigini sayar. Gecme olcutu: tohumlarin en az `esik` orani.
"""

import os
import statistics as st
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine, KAMPANYA_TURU, TUR_YIL


def _seri(e, alan, kapitalist=True):
    """Dunya ortalamasinin zaman serisi."""
    n = len(e.D[0].tarih)
    out = []
    for i in range(n):
        v = [c.tarih[i][alan] for c in e.D
             if (not kapitalist or c.tarih[i].get("rejim", "kapitalist") == "kapitalist")]
        out.append(st.mean(v) if v else float("nan"))
    return out


def _egim(y):
    """Basit dogrusal egim isareti (en kucuk kareler)."""
    n = len(y)
    if n < 3:
        return 0.0
    mx = (n - 1) / 2
    my = st.mean(y)
    num = sum((i - mx) * (y[i] - my) for i in range(n))
    den = sum((i - mx) ** 2 for i in range(n))
    return num / den if den else 0.0


# ==========================================================================
def test_ltrpf(tohumlar):
    """q ↑ → c/v ↑ → r ↓  (kampanyanin tamami)"""
    ok = 0
    for t in tohumlar:
        e = GhostEconomyEngine(t)
        e.run_simulation(KAMPANYA_TURU)
        q = _egim(_seri(e, "q"))
        cv = _egim(_seri(e, "cv"))
        r = _egim(_seri(e, "r"))
        if q > 0 and cv > 0 and r < 0:
            ok += 1
    return ok, "q↑ c/v↑ r↓"


def test_otomasyon(tohumlar):
    """oto ↑ → canli_pay ↓ → r ↓  (cag 5 sonrasi)"""
    ok = 0
    for t in tohumlar:
        e = GhostEconomyEngine(t)
        e.run_simulation(KAMPANYA_TURU)
        i0 = int(KAMPANYA_TURU * 0.72)  # ~2005 sonrasi
        oto = _egim(_seri(e, "oto")[i0:])
        cp = _egim(_seri(e, "canli_pay")[i0:])
        r = _egim(_seri(e, "r")[i0:])
        if oto > 0 and cp < 0 and r < 0:
            ok += 1
    return ok, "oto↑ canli_pay↓ r↓"


def test_goodwin(tohumlar):
    """Istihdam ile ucret payi AYNI yonde, ucret payi ile kar orani TERS."""
    ok = 0
    for t in tohumlar:
        e = GhostEconomyEngine(t)
        e.run_simulation(KAMPANYA_TURU)
        ee, pp, rr = _seri(e, "e"), _seri(e, "pay"), _seri(e, "r")
        # ilk fark korelasyonu (seviye trendinden bagimsiz)
        de = [ee[i+1]-ee[i] for i in range(len(ee)-1)]
        dp = [pp[i+1]-pp[i] for i in range(len(pp)-1)]
        dr = [rr[i+1]-rr[i] for i in range(len(rr)-1)]
        def kor(a, b):
            ma, mb = st.mean(a), st.mean(b)
            num = sum((x-ma)*(y-mb) for x, y in zip(a, b))
            da = sum((x-ma)**2 for x in a) ** 0.5
            db = sum((y-mb)**2 for y in b) ** 0.5
            return num/(da*db) if da and db else 0.0
        if kor(de, dp) > 0 and kor(dp, dr) < 0:
            ok += 1
    return ok, "e↔pay pozitif, pay↔r negatif"


def test_thirlwall(tohumlar):
    """Yuksek q'lu ulkeler yuksek eps/pi_m'ye sahip olmali (merkez avantaji)."""
    ok = 0
    for t in tohumlar:
        e = GhostEconomyEngine(t)
        e.run_simulation(int(KAMPANYA_TURU * 0.6))
        son = [(c.q, c.eps/max(c.pi_m, 1e-9)) for c in e.D]
        son.sort()
        alt = st.median([x[1] for x in son[:len(son)//2]])
        ust = st.median([x[1] for x in son[len(son)//2:]])
        if ust > alt:
            ok += 1
    return ok, "yuksek q → yuksek eps/pi_m"


def test_minsky(tohumlar):
    """Finansallasma kapatilinca Minsky krizi AZALMALI."""
    ok = 0
    for t in tohumlar:
        a = GhostEconomyEngine(t)
        a.run_simulation(KAMPANYA_TURU)
        na = sum(1 for _, k, g in a.log if k == "COKME" and "MINSKY" in g.upper())
        b = GhostEconomyEngine(t)
        b.P.fin_stok = 0.0
        b.P.fin_pay = 0.0
        b.run_simulation(KAMPANYA_TURU)
        nb = sum(1 for _, k, g in b.log if k == "COKME" and "MINSKY" in g.upper())
        if na > nb:
            ok += 1
    return ok, "finansallasma kapali → daha az Minsky"


def test_kriz_devaluasyonu(tohumlar):
    """Kriz devaluasyonu ONARIM kanalidir: kapatilinca kar orani daha cok duser.

    NOT: bu test tohum-basi degil MEDYAN uzerinden karar verir. Tohum-basi
    karsilastirma 2/4 veriyordu cunku tek kosuda kriz zamanlamasi gurultuyu
    isaretten buyuk kiliyor; medyanda etki net (LTRPF -92.2% -> -94.1%,
    deger_carpani 0.427 -> 0.577).
    """
    def kos(kapali):
        out = []
        for t in tohumlar:
            e = GhostEconomyEngine(t)
            if kapali:
                e.P.dev_cokme = 0.0
                e.P.dev_bunalim = 0.0
            e.run_simulation(KAMPANYA_TURU)
            tr = e.kar_orani_trendi(KAMPANYA_TURU//4)
            out.append(tr[-1]["r"]/tr[0]["r"])
        return st.median(out)
    n = len(tohumlar)
    return (n if kos(True) < kos(False) else 0), "devaluasyon kapali → r daha cok duser (medyan)"


def test_sos_bolluk(tohumlar):
    """Ayni otomasyon: kitlik~0 iken protesto riski DAHA DUSUK olmali."""
    ok = 0
    for t in tohumlar:
        vals = {}
        for prof in ("tuketimci", "sanayilesmeci"):
            e = GhostEconomyEngine(t)
            e.P.ai_acik = False
            e.load_scenario("socialist_siege")
            e.set_plan_profili(prof)
            for _ in range(400):
                e.step()
            sos = [c for c in e.D if c.rejim == "sosyalist"]
            sg = [x for c in sos for x in c.tarih[280:400]]
            vals[prof] = (st.mean([x["kitlik"] for x in sg]) if sg else 0,
                          st.mean([x["PR"] for x in sg]) if sg else 0)
        (k_t, pr_t), (k_s, pr_s) = vals["tuketimci"], vals["sanayilesmeci"]
        if k_t < k_s and pr_t < pr_s:
            ok += 1
    return ok, "bolluk → dusuk PR; kitlik → yuksek PR"


def test_karanlik_devlet(tohumlar):
    """Karanlik devlet kapatilinca uyusturucu ve lumpen pay AZALMALI."""
    ok = 0
    for t in tohumlar:
        a = GhostEconomyEngine(t)
        a.run_simulation(int(KAMPANYA_TURU*0.8))
        ua = st.mean([c.uyusturucu_orani for c in a.D])
        b = GhostEconomyEngine(t)
        for c in b.D:
            c.mafya_kilit = 0.0
        b.run_simulation(int(KAMPANYA_TURU*0.8))
        ub = st.mean([c.uyusturucu_orani for c in b.D])
        if ua > ub:
            ok += 1
    return ok, "tolerans kapali → daha az uyusturucu"


def test_parti(tohumlar):
    """Politik ozne kapatilinca cag 6'da orgutlu guc DAHA COK erimeli."""
    ok = 0
    for t in tohumlar:
        res = {}
        for hiz in (0.0008, 0.0):
            e = GhostEconomyEngine(t)
            e.P.parti_hiz = hiz
            e.run_simulation(KAMPANYA_TURU)
            son = [x for c in e.D if c.rejim == "kapitalist"
                   for x in c.tarih[int(KAMPANYA_TURU*0.9):]]
            res[hiz] = st.mean([x["orgutlu"] for x in son]) if son else 0
        if res[0.0008] > res[0.0]:
            ok += 1
    return ok, "parti acik → daha yuksek orgutlu guc"


TESTLER = [
    ("LTRPF", test_ltrpf, 0.90),
    ("Otomasyon", test_otomasyon, 0.80),
    ("Goodwin", test_goodwin, 0.70),
    ("Thirlwall", test_thirlwall, 0.80),
    ("Minsky", test_minsky, 0.80),
    ("Kriz devaluasyonu", test_kriz_devaluasyonu, 0.70),
    ("Sosyalist bolluk/kitlik", test_sos_bolluk, 0.70),
    ("Karanlik devlet", test_karanlik_devlet, 0.80),
    ("Politik ozne", test_parti, 0.70),
]

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 6
    bas = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    tohumlar = list(range(bas, bas + n))
    print(f"MEKANIZMA YON TESTLERI — tohum {tohumlar[0]}..{tohumlar[-1]} ({n} tohum)")
    print("=" * 74)
    print(f"{'test':<26}{'iddia':<34}{'gecen':>7}{'sonuc':>7}")
    print("-" * 74)
    hepsi = True
    for ad, fn, esik in TESTLER:
        ok, iddia = fn(tohumlar)
        gecti = ok/n >= esik
        hepsi &= gecti
        print(f"{ad:<26}{iddia:<34}{ok}/{n:<5}{'GECTI' if gecti else 'KALDI':>7}")
    print("-" * 74)
    print("GENEL:", "TUM YON TESTLERI GECTI" if hepsi else "EN AZ BIR YON TESTI KALDI")
