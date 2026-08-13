"""PARITE DOKUMLERI -- Python (kahin) tarafi.

`godot/scripts/harness/parity.gd` ile SATIR SATIR ayni ciktiyi uretir.
Karsilastirma `tools/compare_dump.py` ile yapilir.

FLOAT'LAR ONDALIK DEGIL IEEE754 BIT DESENI OLARAK BASILIR. Ondalik
bicimlendirme iki dilde ayni yuvarlamayi garanti etmez ve "esit mi degil mi"
sorusunu bicimlendirme sorusuna cevirir; bit deseni bu belirsizligi tamamen
ortadan kaldirir.

Kullanim:
    python python/tools/dump_trace.py --rng
    python python/tools/dump_trace.py --crc32
    python python/tools/dump_trace.py --params
    python python/tools/dump_trace.py --formulas
"""

import dataclasses
import math
import os
import random
import struct
import sys
import zlib

KOK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(KOK, "python"))

import hayalet_ekonomi_motoru_v43 as M  # noqa: E402


def f64(x):
    """Little-endian IEEE754 bit deseni. GDScript karsiligi:
    PackedByteArray.encode_double() + hex_encode()."""
    return struct.pack("<d", float(x)).hex()


# ---------------------------------------------------------------------------
# KATMAN 1 -- RNG akisi. SERT KAPI.
# ---------------------------------------------------------------------------
def dump_rng(tohum=42):
    print(f"# rng tohum={tohum}")

    r = random.Random(tohum)
    for i in range(10000):
        print(f"random {i} {f64(r.random())}")

    # randint ve choice AYRI bir ornekten cekilir -- GDScript tarafinda da oyle.
    r2 = random.Random(tohum)
    for i in range(1000):
        print(f"randint {i} {r2.randint(0, 99)}")

    r3 = random.Random(tohum)
    dizi = [i * 7 for i in range(20)]
    for i in range(1000):
        print(f"choice {i} {r3.choice(dizi)}")

    r4 = random.Random(tohum)
    for k in (1, 2, 3, 7, 8, 15, 16, 31, 32):
        for i in range(50):
            print(f"getrandbits {k} {i} {r4.getrandbits(k)}")


# ---------------------------------------------------------------------------
# KATMAN 2 -- crc32 (politika AI zamanlamasi).
# ---------------------------------------------------------------------------
def dump_crc32():
    p = M.Params()
    print(f"# crc32 ai_periyot={p.ai_periyot}")
    # Ulke adlari motorun kendi tohum tablosundan alinir.
    e = M.GhostEconomyEngine.__new__(M.GhostEconomyEngine)
    for c in M.GhostEconomyEngine.dunya_kur(e):
        crc = zlib.crc32(c.ad.encode("utf-8"))
        print(f"crc32 {c.ad} {crc} {crc % p.ai_periyot}")
    for ad in ("", "a", "abc", "Türkiye", "Çin", "0123456789"):
        print(f"crc32x {ad} {zlib.crc32(ad.encode('utf-8'))}")


# ---------------------------------------------------------------------------
# KATMAN 2 -- 355 kalibrasyon sabiti.
# ---------------------------------------------------------------------------
def dump_params():
    ornek = M.Params()
    alanlar = sorted(f.name for f in dataclasses.fields(M.Params))
    pars = sorted((k, getattr(ornek, k)) for k in alanlar)
    imza = ";".join(f"{k}={v}" for k, v in pars)
    karma = f"{zlib.crc32(imza.encode('utf-8')):08x}"
    print(f"# params alan_sayisi={len(alanlar)} karma={karma}")
    for ad in alanlar:
        v = getattr(ornek, ad)
        if isinstance(v, bool):
            print(f"param {ad} bool {'1' if v else '0'}")
        elif isinstance(v, int):
            print(f"param {ad} int {v}")
        elif isinstance(v, float):
            print(f"param {ad} float {f64(v)}")
        elif isinstance(v, str):
            print(f"param {ad} str {v}")
        elif isinstance(v, (tuple, list)):
            print(f"param {ad} array " + " ".join(f64(x) for x in v))
        else:
            print(f"param {ad} ??? {v}")


# ---------------------------------------------------------------------------
# KATMAN 2 -- saf fonksiyonlar sabit girdi izgarasinda.
# ---------------------------------------------------------------------------
def dump_formulas():
    print(f"# formulas TUR_YIL={f64(M.TUR_YIL)} KAMPANYA_TURU={M.KAMPANYA_TURU}")
    dogru = M.KAMPANYA_TURU == int(round((M.BITIS_YILI - M.BASLANGIC_YILI) / M.TUR_YIL))
    print(f"# kampanya_turu_dogru={'1' if dogru else '0'}")

    qlar = [1e-6, 0.001, 0.1, 0.5, 0.9, 1.0, 2.6, 5.2, 10.5, 21.0, 42.0,
            60.0, 100.0, 158.3281, 200.0, 500.0]
    for q in qlar:
        print(f"organik_bilesim {f64(q)} {f64(M.organik_bilesim(q))}")

    for x in (-0.05, -0.001, 0.0, 0.0045, 0.008, 0.0205, 0.16, 0.42, 1.0):
        print(f"yillik {f64(x)} {f64(M.yillik(x))}")

    # `sg` motorda GhostEconomyEngine metodu; saf oldugu icin bagimsiz cagrilir.
    def sg(x):
        return 1.0 / (1.0 + math.exp(-max(-60, min(60, x))))

    for x in (-100.0, -60.0, -10.0, -1.0, -0.5, 0.0, 0.5, 1.0, 10.0, 60.0, 100.0):
        print(f"sg {f64(x)} {f64(sg(x))}")

    for a, b in M.CV_CAPALARI:
        print(f"cv_capa {f64(a)} {f64(b)}")


# ---------------------------------------------------------------------------
# KATMAN 3a -- DUNYA KURULUMU. Motor portunun ilk kontrol noktasi.
# ---------------------------------------------------------------------------
def _deger(v):
    """Sayisal degerler DAIMA f64; int/float ayrimi yapilmaz.

    Neden: `L_max` kurulusta int 110, birkac tur sonra float 110.37. Tipe gore
    bicimlendirmek, deger ayni olsa bile sahte fark uretirdi.
    """
    if v is None:
        return "null"
    if isinstance(v, bool):          # bool, int'in altsinifi -- once bakilmali
        return "bool " + ("1" if v else "0")
    if isinstance(v, (int, float)):
        return "num " + f64(v)
    if isinstance(v, str):
        return "str " + v
    if isinstance(v, dict):
        return "dict " + " ".join(f"{k}={_skaler(v[k])}" for k in sorted(v, key=str))
    if isinstance(v, (list, tuple, set)):
        gerekli = sorted(v, key=str) if isinstance(v, set) else list(v)
        return "array " + " ".join(_skaler(x) for x in gerekli)
    return "??? " + str(v)


def _skaler(x):
    """Ic ice yapilarin ogeleri. `pol_kuyruk` gibi alanlar sozluk icinde tuple
    tasiyor (deger, etkinlesme_turu); sayisal olmayan ogeler metin olarak
    basilir ki dokum patlamasin."""
    if x is None:
        return "null"
    if isinstance(x, bool):
        return "1" if x else "0"
    if isinstance(x, (int, float)):
        return f64(x)
    if isinstance(x, (list, tuple)):
        return "(" + ",".join(_skaler(y) for y in x) + ")"
    if isinstance(x, dict):
        return "{" + ",".join(f"{k}:{_skaler(x[k])}" for k in sorted(x, key=str)) + "}"
    return str(x)


def _dump_dunya(e):
    print(f"motor K_olcek num {f64(e.K_olcek)}")
    print(f"motor K_carpani num {f64(e.K_carpani)}")
    print(f"motor hedef_istihdam num {f64(e.hedef_istihdam)}")
    print(f"motor t num {f64(e.t)}")
    print(f"motor dunya_devrimi bool {'1' if e.dunya_devrimi else '0'}")
    print(f"motor dd_sayac num {f64(e.dd_sayac)}")
    print(f"motor pakt_uyumu num {f64(e.pakt_uyumu)}")
    print(f"motor kap_kriz_payi num {f64(e.kap_kriz_payi)}")
    print(f"motor log_sayisi num {f64(len(e.log))}")

    for c in e.D:
        for ad in sorted(vars(c)):
            if ad == "tarih":
                continue
            print(f"ulke {c.ad} {ad} {_deger(getattr(c, ad))}")


def dump_init(tohum=42):
    e = M.GhostEconomyEngine(tohum)
    print(f"# init tohum={tohum} ulke={len(e.D)}")
    _dump_dunya(e)


# ---------------------------------------------------------------------------
# KATMAN 3b -- TUR-TUR IZ. Portun asil sinavi.
# ---------------------------------------------------------------------------
# GDScript tarafinda `tarih` bir SUTUN DEPOSUDUR ve yalnizca sayisal alanlari
# float sutununda tutar; rej/kurum metin sutunundadir. Ayni ayrimi burada da
# yapmak gerekiyor, yoksa satirlar hizalanmaz.
TARIH_METIN = {"rej", "kurum"}


def dump_turn(tur, tohum=42):
    e = M.GhostEconomyEngine(tohum)
    for _ in range(tur):
        e.step()
    print(f"# turn tur={tur} tohum={tohum}")
    _dump_dunya(e)

    for c in e.D:
        son = c.tarih[-1] if c.tarih else {}
        for ad in sorted(k for k in son if k not in TARIH_METIN):
            v = son[ad]
            print(f"tarih {c.ad} {ad} num {f64(float(v))}")
        print(f"tarih {c.ad} rej str {son.get('rej', '')}")
        print(f"tarih {c.ad} kurum str {son.get('kurum', '')}")

    for _t, tip, mesaj in e.log:
        print(f"log {_t} {tip} {mesaj}")


KOMUTLAR = {
    "--rng": dump_rng,
    "--crc32": dump_crc32,
    "--params": dump_params,
    "--formulas": dump_formulas,
    "--init": dump_init,
}


# ---------------------------------------------------------------------------
# TANI -- step() icindeki dunya toplamlari (float toplama sirasi).
# ---------------------------------------------------------------------------
def dump_agg(tohum=42):
    e = M.GhostEconomyEngine(tohum)
    print(f"# agg tohum={tohum}")

    Yv = {c.ad: min(c.K / e.kappa_v(M.organik_bilesim(c.q) * c.deger_carpani, c.q),
                    c.q * c.L_etkin) for c in e.D}
    for c in e.D:
        print(f"Yv {c.ad} {f64(Yv[c.ad])}")

    top = sum(Yv.values()) or 1e-6
    print(f"top {f64(top)}")

    ort_cv_ham = sum(M.organik_bilesim(c.q) * c.deger_carpani * Yv[c.ad] for c in e.D)
    ort_sv_ham = sum((1 / max(c.pay, .05) - 1) * Yv[c.ad] for c in e.D)
    ort_q_ham = sum(c.q * Yv[c.ad] for c in e.D)
    print(f"ort_cv_ham {f64(ort_cv_ham)}")
    print(f"ort_sv_ham {f64(ort_sv_ham)}")
    print(f"ort_q_ham {f64(ort_q_ham)}")
    print(f"ort_cv {f64(ort_cv_ham / top)}")
    print(f"ort_sv {f64(ort_sv_ham / top)}")
    print(f"ort_q {f64(ort_q_ham / top)}")

    cek = {c.ad: c.pay * c.q * c.e for c in e.D}
    print(f"cek_toplam {f64(sum(cek.values()))}")
    print(f"ort_cek {f64(sum(cek.values()) / len(cek))}")
    print(f"tot_L {f64(sum(c.L_max for c in e.D))}")


KOMUTLAR["--agg"] = dump_agg


# ---------------------------------------------------------------------------
# TANI -- libm mutabakati (exp/log/pow son bitte ayrisiyor mu?).
# ---------------------------------------------------------------------------
def dump_libm():
    print("# libm")
    r = random.Random(12345)
    for i in range(4000):
        x = (r.random() - 0.5) * 40.0
        print(f"exp {i} {f64(x)} {f64(math.exp(x))}")
    for i in range(2000):
        x = r.random() * 200.0 + 1e-9
        print(f"log {i} {f64(x)} {f64(math.log(x))}")
    for i in range(2000):
        b = r.random() * 20.0 + 0.01
        e2 = (r.random() - 0.5) * 6.0
        print(f"pow {i} {f64(b)} {f64(e2)} {f64(b ** e2)}")


KOMUTLAR["--libm"] = dump_libm

if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("kullanim: dump_trace.py [" + " | ".join(KOMUTLAR)
                         + " | --turn N ]")
    if sys.argv[1] == "--turn":
        dump_turn(int(sys.argv[2]) if len(sys.argv) > 2 else 1)
    elif sys.argv[1] in KOMUTLAR:
        KOMUTLAR[sys.argv[1]]()
    else:
        raise SystemExit(f"bilinmeyen komut: {sys.argv[1]}")
