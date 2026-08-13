"""Iki parite dokumunu karsilastirir (Python kahini <-> Godot portu).

Satirlar birebir esit olmali. Float alanlari IEEE754 bit deseni olarak
basildigi icin "yaklasik esit" diye bir sey yoktur: ya ayni bit, ya degil.

Bir fark bulununca ONDALIK KARSILIGI DA basilir -- "0x3fd0000000000000 !=
0x3fd0000000000001" tek basina okunmaz, "0.25 != 0.2500000000000001
(goreli 4.4e-16)" okunur.

Kullanim:
    python tools/compare_dump.py <python_dosyasi> <godot_dosyasi> [--max N]
"""

import struct
import sys


def coz(h):
    """16 haneli hex bit desenini float'a cevirir; degilse None.

    Jetonlar `cv=6c4240f25e06f53f` gibi anahtarli da olabiliyor; bas kisim
    ayiklanir, yoksa 1 ulp'lik fark "metin farki" gibi gorunup tolerans
    disinda kalir.
    """
    if "=" in h:
        h = h.rsplit("=", 1)[1]
    if len(h) == 16:
        try:
            return struct.unpack("<d", bytes.fromhex(h))[0]
        except ValueError:
            return None
    return None


def aciklama(a, b):
    """Iki jetonun farkini insan okunur hale getirir."""
    fa, fb = coz(a), coz(b)
    if fa is None or fb is None:
        return f"{a!r} != {b!r}"
    if fa == fb:
        return ""
    olcek = max(abs(fa), abs(fb))
    goreli = abs(fa - fb) / olcek if olcek else abs(fa - fb)
    return f"{fa!r} != {fb!r}  (goreli fark {goreli:.3e})"


def oku(yol):
    with open(yol, "r", encoding="utf-8") as f:
        # Godot bazi platformlarda CR birakabilir; satir sonu farki gercek
        # bir sapma degildir, temizlenir.
        return [s.rstrip("\r\n") for s in f if s.strip() != ""]


def tolere_edilir(a, b, tol):
    """Satirlar yalnizca float jetonlarinda ve `tol` goreli farkin altinda mi
    ayrisiyor? Raporlama katmani icin kullanilir: orada kaynak
    `statistics.mean` (tam rasyonel toplama) kullaniyor ve GDScript'te birebir
    uretmenin karsiligi yok -- ama sapmanin BUYUKLUGU sinirlanmali."""
    ja, jb = a.split(), b.split()
    if len(ja) != len(jb):
        return False
    for x, y in zip(ja, jb):
        if x == y:
            continue
        fa, fb = coz(x), coz(y)
        if fa is None or fb is None:
            return False
        olcek = max(abs(fa), abs(fb))
        if (abs(fa - fb) / olcek if olcek else abs(fa - fb)) > tol:
            return False
    return True


def main():
    if len(sys.argv) < 3:
        raise SystemExit("kullanim: compare_dump.py <python> <godot> "
                         "[--max N] [--tol X]")
    py_yol, gd_yol = sys.argv[1], sys.argv[2]
    en_fazla = 20
    if "--max" in sys.argv:
        en_fazla = int(sys.argv[sys.argv.index("--max") + 1])
    # Varsayilan 0.0: BIT-BIREBIR. Tolerans yalnizca acikca istenirse devreye
    # girer, boylece motor katmaninda kazara gevseme olmaz.
    tol = 0.0
    if "--tol" in sys.argv:
        tol = float(sys.argv[sys.argv.index("--tol") + 1])

    a, b = oku(py_yol), oku(gd_yol)
    print(f"python : {py_yol}  ({len(a)} satir)")
    print(f"godot  : {gd_yol}  ({len(b)} satir)")

    if len(a) != len(b):
        print(f"\nUYARI: satir sayilari farkli ({len(a)} vs {len(b)}). "
              "Ortak on ek karsilastiriliyor.")

    fark = 0
    tolere = 0
    for i in range(min(len(a), len(b))):
        if a[i] == b[i]:
            continue
        if tol > 0.0 and tolere_edilir(a[i], b[i], tol):
            tolere += 1
            continue
        fark += 1
        if fark <= en_fazla:
            print(f"\n  satir {i+1}:")
            print(f"    python: {a[i]}")
            print(f"    godot : {b[i]}")
            ja, jb = a[i].split(), b[i].split()
            if len(ja) == len(jb):
                for k in range(len(ja)):
                    if ja[k] != jb[k]:
                        aciklik = aciklama(ja[k], jb[k])
                        if aciklik:
                            print(f"    jeton {k}: {aciklik}")

    ortak = min(len(a), len(b))
    print(f"\n{'='*60}")
    if tolere:
        print(f"NOT: {tolere} satir yalnizca <= {tol:.0e} goreli farkla ayristi "
              f"(tolere edildi).")
    if fark == 0 and len(a) == len(b):
        if tolere:
            print(f"SONUC: TOLERANS ICINDE ({ortak} satir, {tolere} yakin)")
        else:
            print(f"SONUC: BIREBIR AYNI ({ortak} satir)")
        return 0
    print(f"SONUC: {fark} satir farkli ({ortak} satirda)")
    if fark > en_fazla:
        print(f"       (ilk {en_fazla} tanesi gosterildi; --max ile artirin)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
