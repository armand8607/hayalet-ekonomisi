"""B5'in harita geometrisini URETIR: Natural Earth -> GDScript veri dosyasi.

NEDEN URETILIYOR, ELLE YAZILMIYOR
---------------------------------
Tasarim belgesi §5.1 sifir-asset kuralini tam da bunun icin gevsetiyor:
".png yok (her sey `_draw()`), vektor geometri verisi VAR (sikistirilmis
poligon tablosu, URETILMIS veri dosyasi)". Elle cizilmis bir dunya haritasi
iki sebeple kabul edilemez: (1) 170 ulkenin sinirini elle koymak binlerce
sayidir ve tek basamak hatasi sessizce yanlis bir dunya verir, (2) elle
cizilen sey KAYNAKSIZDIR -- "bu sinir neden boyle" sorusunun cevabi olmaz.

Kaynak: Natural Earth 110m admin-0. KAMU MALI (public domain), atif
zorunlulugu yok; yine de uretilen dosyanin basligina yazilir.

NE TASINIR, NE TASINMAZ
-----------------------
Tasinan: sinir poligonlari, ISO kodu, TURKCE ad (`NAME_TR` -- kaynakta
zaten var, elle cevrilmez), kita.

Tasinmayan: nufus, GSYH, hicbir iktisadi buyukluk. Bunlar 2020'lerin
verisidir ve oyun 1836'da baslar; kaynaktan iktisadi bir sayi almak
anakronizmi VERI gibi gosterirdi. Baslangic kosullari B6'nin isidir.

ELLE YAZILAN TEK SEY KIMLIK TABLOSUDUR
--------------------------------------
Iki tablo asagida elle durur, cunku Natural Earth'te karsiliklari yok:
`OYNANABILIR` (§5.8b'nin G20 + 1836 onculleri) ve `KONUM` (dunya
sistemindeki 1836 konumu -- merkez / yari / cevre). Ikisi de KIMLIK
verisidir, kalibrasyon degil: `KONUM` yalnizca hangi merdiven basamagindan
baslanacagini secer, basamaklarin kendisi B1b'de olculmus degerlerdir.

KULLANIM
--------
    python tools/gen_harita.py            # yeniden uret
    python tools/gen_harita.py --check    # kaynakla ayni mi (ag ister)

`--check` CI'da KOSMAZ, ve bu bilincli: Natural Earth'un `master` dali
degisebilir, yani denetim bizim disimizdaki bir depoya baglanirdi. Uretilen
dosyanin dogrulugunu `--v2-harita` kapisi YAPISAL olarak sinar (halkalar
kapali mi, etiket noktasi poligonun icinde mi, isabet testi dogru ulkeyi mi
buluyor) -- kaynaga degil, veriye bakar.
"""

import argparse
import hashlib
import json
import math
import os
import sys
import urllib.request

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIKTI = os.path.join(KOK, "godot", "scripts", "v2", "data", "harita_verisi.gd")

KAYNAK_URL = (
    "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/"
    "geojson/ne_110m_admin_0_countries.geojson"
)

# ---------------------------------------------------------------------------
# BASITLESTIRME
# ---------------------------------------------------------------------------
# Ham veri 288 halka / 10 642 nokta. Oyun haritasi bunu istemez: 1280x720
# ekranda bir derece ~3.5 piksel, yani 0.05 derecelik ayrinti CIZILEMEZ bile.
#
# Iki adim var ve SIRASI onemli: once Douglas-Peucker (sekli koruyarak nokta
# atar), sonra kuantizasyon (kalanlari izgaraya oturtur). Ters sirada
# kuantizasyon once DP'nin olcegini bozar ve DP kirpilmis noktalari "gercek"
# sanip korur.
EPS = 0.25          # Douglas-Peucker toleransi (derece)
OLCEK = 16          # 1/16 derece izgara (~7 km) -- tam sayi olarak saklanir
MIN_HALKA_ALAN = 0.8  # derece^2; altindaki ada/enklav atilir
MAX_HALKA = 6       # ulke basina en buyuk N halka
MIN_ULKE_ALAN = 1.5   # derece^2; altindaki ulke haritaya girmez

# ---------------------------------------------------------------------------
# OYNANABILIR KUME -- §5.8b: G20 + 1836'daki tarihsel onculleri
# ---------------------------------------------------------------------------
# Belgenin tablosunun birebir karsiligi. ADLAR TAM TURKCE yazilir (depo
# kurali: yorumlar ASCII, KULLANICIYA GORUNEN METINLER tam Turkce) -- bu
# adlar haritada etiket olarak cizilir.
#
# 1836 adlari OYNANIR KIMLIKTIR:
# oyuncu "Turkiye"yi degil Osmanli Imparatorlugu'nu secer ve kampanya
# ilerledikce ad degisir (ad degisiminin kendisi B7'nin isi).
OYNANABILIR = {
    "TUR": "Osmanlı İmparatorluğu",
    "DEU": "Prusya / Alman Konfederasyonu",
    "RUS": "Rusya İmparatorluğu",
    "CHN": "Çing Hanedanı",
    "IND": "Babür / Britanya Hindistanı",
    "ITA": "Sardinya-Piemonte / İki Sicilya",
    "JPN": "Tokugawa Şogunluğu",
    "GBR": "Britanya İmparatorluğu",
    "USA": "Amerika Birleşik Devletleri",
    "FRA": "Fransa Krallığı",
    "BRA": "Brezilya İmparatorluğu",
    "MEX": "Meksika Cumhuriyeti",
    "ARG": "Arjantin Konfederasyonu",
    "CAN": "Britanya Kuzey Amerikası",
    "AUS": "Yeni Güney Galler (Britanya)",
    "ZAF": "Cape Kolonisi (Britanya)",
    "IDN": "Hollanda Doğu Hint Adaları",
    "SAU": "Necd Emirliği (Osmanlı)",
    "KOR": "Choson",
}

# ---------------------------------------------------------------------------
# 1836 KONUMU -- merkez / yari / cevre
# ---------------------------------------------------------------------------
# BU BIR KALIBRASYON DEGILDIR. Konum yalnizca `Harita.dunya_kur()`un hangi
# baslangic basamagini kullanacagini secer; basamaklarin kendisi B1b'nin
# olculmus merdivenidir (q0/egitim = 1.60/0.42, 1.00/0.30, 0.65/0.18).
#
# 1836'YA GORE, BUGUNE GORE DEGIL. Bu ayrim onemli: 1836'da Britanya,
# Fransa, Hollanda ve Belcika sanayi merkezidir; Prusya, Avusturya, Rusya,
# Isvec, Ispanya yari-cevredir; Cin, Hindistan, Osmanli ve butun Afrika
# cevredir. Bugunun G7'sini 1836'ya tasimak dunya sisteminin kendi tarihini
# silerdi -- ve oyunun tek zorluk ayari (§0) tam olarak bu konumdur.
#
# ABD 1836'da yari-cevredir: sanayilesme baslamistir ama Britanya'nin
# hammadde tedarikcisidir. Yukselisi oyunda OLCULMELIDIR, verilmemelidir.
KONUM = {
    # --- merkez ---
    "GBR": "merkez", "FRA": "merkez", "NLD": "merkez", "BEL": "merkez",
    # --- yari ---
    "USA": "yari", "DEU": "yari", "AUT": "yari", "RUS": "yari",
    "ITA": "yari", "ESP": "yari", "PRT": "yari", "SWE": "yari",
    "DNK": "yari", "CHE": "yari", "POL": "yari", "GRC": "yari",
    "NOR": "yari", "CAN": "yari", "AUS": "yari",
    # --- cevre ---
    "TUR": "cevre", "CHN": "cevre", "IND": "cevre", "JPN": "cevre",
    "KOR": "cevre", "IDN": "cevre", "SAU": "cevre", "IRN": "cevre",
    "EGY": "cevre", "MAR": "cevre", "DZA": "cevre", "ETH": "cevre",
    "NGA": "cevre", "COD": "cevre", "KEN": "cevre", "SDN": "cevre",
    "BRA": "cevre", "MEX": "cevre", "ARG": "cevre", "CHL": "cevre",
    "COL": "cevre", "PER": "cevre", "VEN": "cevre", "CUB": "cevre",
    "ZAF": "cevre", "THA": "cevre", "VNM": "cevre", "PHL": "cevre",
    "PAK": "cevre", "BGD": "cevre", "AFG": "cevre", "MMR": "cevre",
    "UKR": "cevre", "ROU": "cevre", "NZL": "cevre",
}

KITA_TR = {
    "Europe": "Avrupa",
    "Asia": "Asya",
    "Africa": "Afrika",
    "North America": "Kuzey Amerika",
    "South America": "Guney Amerika",
    "Oceania": "Okyanusya",
    "Seven seas (open ocean)": "Okyanus",
    "Antarctica": "Antarktika",
}

DISARIDA = {"ATA", "ATF"}   # Antarktika ve Fransiz Guney Topraklari: nufus yok

# Natural Earth'un `TYPE` alani duzensizdir: Kazakistan ve Kuba "Sovereignty",
# ABD/Fransa/Cin "Country", Israil "Disputed". Egemenligi bu alandan OKURUZ
# ama haritadan ATMAYIZ -- Gronland'i ya da Bati Sahra'yi cizmemek dunyada
# delik acar, ve bu oyunun egemenlik tartismasinda tarafi yok. Cizilir,
# simule edilmez: `dunya_kur()` zaten yalnizca `konum` dolu olanlari kurar.
EGEMEN_TIPLERI = {"Sovereign country", "Country", "Sovereignty"}

# Uretim sirasinda onarilan halkalar; uretilen dosyanin basligina yazilir.
ONARIMLAR = []


# ---------------------------------------------------------------------------
# GEOMETRI
# ---------------------------------------------------------------------------
def dp(noktalar, eps):
    """Douglas-Peucker. Kapali halkanin ilk/son noktasi korunur."""
    if len(noktalar) < 3:
        return list(noktalar)
    ilk, son = noktalar[0], noktalar[-1]
    en_uzak, en_i = -1.0, 0
    for i in range(1, len(noktalar) - 1):
        d = _dogruya_uzaklik(noktalar[i], ilk, son)
        if d > en_uzak:
            en_uzak, en_i = d, i
    if en_uzak <= eps:
        return [ilk, son]
    sol = dp(noktalar[:en_i + 1], eps)
    sag = dp(noktalar[en_i:], eps)
    return sol[:-1] + sag


def _dogruya_uzaklik(p, a, b):
    ax, ay = a
    bx, by = b
    px, py = p
    dx, dy = bx - ax, by - ay
    if dx == 0.0 and dy == 0.0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def alan(halka):
    """Isaretli alanin mutlak degeri (derece^2)."""
    t = 0.0
    n = len(halka)
    for i in range(n):
        x1, y1 = halka[i]
        x2, y2 = halka[(i + 1) % n]
        t += x1 * y2 - x2 * y1
    return abs(t) * 0.5


def icinde(nokta, halka):
    """Isin atma (even-odd). Godot tarafindaki `Harita.halkada` ile AYNI
    algoritma olmali, yoksa uretim ile isabet testi ayrisir."""
    x, y = nokta
    ic = False
    n = len(halka)
    j = n - 1
    for i in range(n):
        xi, yi = halka[i]
        xj, yj = halka[j]
        if (yi > y) != (yj > y):
            kesim = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < kesim:
                ic = not ic
        j = i
    return ic


def etiket_noktasi(halka):
    """Poligonun ICINDE, kenarlardan en uzak nokta (erisilemezlik kutbu).

    NEDEN AGIRLIK MERKEZI DEGIL: agirlik merkezi disari dusebilir. Hilal
    bicimli her ulke (Vietnam, Hirvatistan, Norvec) ve cok parcali her ulke
    bunu yapar. Etiket ve BAG cizgileri bu noktadan cikacagi icin disari
    dusen bir merkez, cizgiyi denizden baslatir.
    """
    xs = [p[0] for p in halka]
    ys = [p[1] for p in halka]
    x0, x1 = min(xs), max(xs)
    y0, y1 = min(ys), max(ys)
    en_iyi, en_iyi_d = None, -1.0
    N = 48
    for i in range(N + 1):
        for j in range(N + 1):
            p = (x0 + (x1 - x0) * i / N, y0 + (y1 - y0) * j / N)
            if not icinde(p, halka):
                continue
            d = min(_dogruya_uzaklik(p, halka[k], halka[(k + 1) % len(halka)])
                    for k in range(len(halka)))
            if d > en_iyi_d:
                en_iyi_d, en_iyi = d, p
    if en_iyi is None:                      # cok ince halka: izgara icine dusmedi
        en_iyi = (sum(xs) / len(xs), sum(ys) / len(ys))
    return en_iyi


# ---------------------------------------------------------------------------
# KENDINI KESEN HALKALAR
# ---------------------------------------------------------------------------
# Kendini kesen bir halka UCGENLENEMEZ: Godot'un `triangulate_polygon`u bos
# doner ve o ulke ekranda HIC gorunmez. Olculdu, iki halkada oldu ve iki
# sebebi vardi -- ayri ayri ele alinmalari gerekti:
#
#   SAH (Bati Sahra): kaynak halka TEMIZ, kesismeyi Douglas-Peucker'in
#       kendisi yaratti. Basitlestirme bir kosede iki kenari birbirinin
#       ustunden gecirdi. Cozumu toleransi kucultmek -- sekil korunur.
#
#   SDN (Sudan): kaynak halkanin KENDISI kendini kesiyor. Natural Earth'un
#       verisinin kusuru; hicbir tolerans duzeltmez. Cozumu 2-opt: kesisen
#       iki kenarin arasindaki alt yolu TERSINE CEVIRMEK dugumu cozer ve
#       cevre kisaldigi icin islem sonlanir. Olculdu: alan %0.2 degisti.
#
# SIRA ONEMLI. Once tolerans kucultulur (sekli korur), 2-opt ancak kaynak
# bozuksa devreye girer -- SAH'ta 2-opt once denenseydi alan %49 sismis
# olurdu (olculdu).
def _kesisir(p1, p2, p3, p4):
    def yon(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    d1, d2 = yon(p3, p4, p1), yon(p3, p4, p2)
    d3, d4 = yon(p1, p2, p3), yon(p1, p2, p4)
    return ((d1 > 0) != (d2 > 0)) and ((d3 > 0) != (d4 > 0))


def ilk_kesisme(halka):
    n = len(halka)
    for i in range(n):
        for j in range(i + 2, n):
            if i == 0 and j == n - 1:
                continue
            if _kesisir(halka[i], halka[(i + 1) % n], halka[j], halka[(j + 1) % n]):
                return (i, j)
    return None


def coz_dugum(halka, adim=200):
    """2-opt: kesisen kenarlarin arasindaki alt yolu ters cevirir."""
    r = list(halka)
    for _ in range(adim):
        k = ilk_kesisme(r)
        if k is None:
            return r, True
        i, j = k
        r[i + 1:j + 1] = list(reversed(r[i + 1:j + 1]))
    return r, ilk_kesisme(r) is None


def temiz_halka(noktalar, eps):
    """Basitlestirilmis, kuantize, KENDINI KESMEYEN halka.

    Doner: (halka, onarim) -- onarim: "" | "tolerans" | "2opt" | "dusuruldu"
    """
    r = kuantize(dp(noktalar, eps))
    if len(r) >= 3 and ilk_kesisme(r) is None:
        return r, ""
    for bolen in (2, 4, 8):
        aday = kuantize(dp(noktalar, eps / bolen))
        if len(aday) >= 3 and ilk_kesisme(aday) is None:
            return aday, "tolerans"
    onarik, tamam = coz_dugum(r)
    if tamam and len(onarik) >= 3:
        return onarik, "2opt"
    return [], "dusuruldu"


def kuantize(halka):
    """1/OLCEK derecelik izgaraya oturtur ve ardisik tekrarlari atar."""
    cikti = []
    for x, y in halka:
        q = (int(round(x * OLCEK)), int(round(y * OLCEK)))
        if not cikti or cikti[-1] != q:
            cikti.append(q)
    if len(cikti) > 1 and cikti[0] == cikti[-1]:
        cikti.pop()
    return cikti


# ---------------------------------------------------------------------------
# URETIM
# ---------------------------------------------------------------------------
def indir():
    with urllib.request.urlopen(KAYNAK_URL, timeout=120) as r:
        return r.read()


def ulkeleri_cikar(ham):
    veri = json.loads(ham)
    cikti = []
    for f in veri["features"]:
        p = f["properties"]
        kod = p.get("ADM0_A3") or p.get("ISO_A3")
        if not kod or kod in DISARIDA:
            continue

        g = f["geometry"]
        ham_halkalar = (g["coordinates"] if g["type"] == "MultiPolygon"
                        else [g["coordinates"]])
        halkalar = []
        for poly in ham_halkalar:
            # poly[0] dis halka; delikler (poly[1:]) ATILIR -- bir dunya
            # haritasinda tek delik Lesotho ve o zaten ayri bir ulke olarak
            # cizilir. Isabet testi KUCUKTEN BUYUGE bakar, yani ustteki
            # ulke kazanir.
            d = dp([tuple(c[:2]) for c in poly[0]], EPS)
            if len(d) < 4:
                continue
            a = alan(d)
            if a < MIN_HALKA_ALAN:
                continue
            halkalar.append((a, [tuple(c[:2]) for c in poly[0]]))
        if not halkalar:
            continue
        halkalar.sort(key=lambda h: -h[0])
        halkalar = halkalar[:MAX_HALKA]
        toplam_alan = sum(a for a, _ in halkalar)
        if toplam_alan < MIN_ULKE_ALAN:
            continue

        q_halkalar = []
        for _, ham_halka in halkalar:
            h, onarim = temiz_halka(ham_halka, EPS)
            if onarim:
                ONARIMLAR.append("%s:%s" % (kod, onarim))
            if len(h) >= 3:
                q_halkalar.append(h)
        if not q_halkalar:
            continue
        # Etiket noktasi ONARILMIS halkadan hesaplanir: onarim sekli
        # degistirdiyse eski merkez disari dusebilirdi.
        merkez = etiket_noktasi([(x / OLCEK, y / OLCEK) for x, y in q_halkalar[0]])

        xs = [x for h in q_halkalar for x, _ in h]
        ys = [y for h in q_halkalar for _, y in h]
        cikti.append({
            "kod": kod,
            "ad": p.get("NAME_TR") or p.get("ADMIN"),
            "ad_1836": OYNANABILIR.get(kod, ""),
            "kita": KITA_TR.get(p.get("CONTINENT"), p.get("CONTINENT") or ""),
            "egemen": p.get("TYPE") in EGEMEN_TIPLERI,
            "oynanabilir": kod in OYNANABILIR,
            "konum": KONUM.get(kod, ""),
            "alan": round(toplam_alan, 2),
            "kutu": [min(xs), min(ys), max(xs), max(ys)],
            "merkez": [int(round(merkez[0] * OLCEK)), int(round(merkez[1] * OLCEK))],
            "halkalar": q_halkalar,
        })
    # SIRA ALFABETIK, alana gore degil: uretim iki kez kosuldugunda ayni
    # dosyayi vermeli ve kod sirasi kaynaktan bagimsiz olmali.
    cikti.sort(key=lambda u: u["kod"])
    return cikti


def gd_yaz(ulkeler, kaynak_sha):
    halka_say = sum(len(u["halkalar"]) for u in ulkeler)
    nokta_say = sum(len(h) for u in ulkeler for h in u["halkalar"])
    sim_say = sum(1 for u in ulkeler if u["konum"])
    oyn_say = sum(1 for u in ulkeler if u["oynanabilir"])

    s = []
    A = s.append
    A("class_name HaritaVerisi")
    A("extends RefCounted")
    A("")
    A("# =============================================================")
    A("# BU DOSYA URETILMISTIR -- ELLE DUZENLEMEYIN.")
    A("# Kaynak : Natural Earth 110m admin-0 (kamu mali / public domain)")
    A("#          %s" % KAYNAK_URL)
    A("#          sha256 %s" % kaynak_sha)
    A("# Onarim : %s" % (", ".join(ONARIMLAR) if ONARIMLAR else "yok"))
    A("# Ureten : tools/gen_harita.py")
    A("# Yeniden uretmek icin: python tools/gen_harita.py")
    A("# =============================================================")
    A("")
    A("## B5'in harita geometrisi: %d ulke, %d halka, %d nokta."
      % (len(ulkeler), halka_say, nokta_say))
    A("##")
    A("## KOORDINAT BIRIMI 1/%d DERECEDIR, DERECE DEGIL. Tam sayi olarak" % OLCEK)
    A("## saklanir: metin gosterimi kisalir ve ayristirma bit-belirlenimli")
    A("## olur (ondalik metin -> double donusumu degil, dogrudan tam sayi).")
    A("## Dereceye cevirmek icin `OLCEK`e bolun; `Harita` bunu bir kez yapar.")
    A("##")
    A("## Halkalar KAPALI KABUL EDILIR: son nokta ilkine baglanir ama")
    A("## TEKRARLANMAZ. Cizim ve isabet testi ikisi de bunu varsayar.")
    A("##")
    A("## Delikler tasinmaz (bkz. ureticideki not), ada ve enklavlarin")
    A("## kuculeri atilir: %g derece^2 alti halka, %g derece^2 alti ulke."
      % (MIN_HALKA_ALAN, MIN_ULKE_ALAN))
    A("##")
    A("## `konum` DOLU olan %d ulke varsayilan simule dunyayi kurar;" % sim_say)
    A("## `oynanabilir` olan %d tanesi §5.8b'nin G20 kumesidir." % oyn_say)
    A("")
    A("const OLCEK := %d.0" % OLCEK)
    A("")
    A("## Basitlestirme toleransi (derece) -- tani icin saklanir.")
    A("const EPS := %r" % EPS)
    A("")
    A("## Alanlar: kod, ad, ad_1836, kita, egemen, oynanabilir, konum,")
    A("## alan (derece^2),")
    A("## kutu [x0,y0,x1,y1], merkez [x,y] (etiket ve BAG cizgisi burada baslar),")
    A("## halkalar (her biri duz [x0,y0,x1,y1,...] dizisi).")
    A("const ULKELER := [")
    for u in ulkeler:
        halkalar = ", ".join(
            "[" + ",".join(str(v) for p in h for v in p) + "]"
            for h in u["halkalar"])
        A('\t{"kod": "%s", "ad": "%s", "ad_1836": "%s", "kita": "%s", '
          '"egemen": %s, "oynanabilir": %s, "konum": "%s", "alan": %s, '
          '"kutu": %s, "merkez": %s, "halkalar": [%s]},'
          % (u["kod"], u["ad"], u["ad_1836"], u["kita"],
             "true" if u["egemen"] else "false",
             "true" if u["oynanabilir"] else "false", u["konum"],
             u["alan"], u["kutu"], u["merkez"], halkalar))
    A("]")
    A("")
    return "\n".join(s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="kaynagi indirip uretilen dosyayla karsilastir")
    ap.add_argument("--kaynak", default="",
                    help="yerel geojson yolu (ag yerine)")
    args = ap.parse_args()

    ham = (open(args.kaynak, "rb").read() if args.kaynak else indir())
    sha = hashlib.sha256(ham).hexdigest()
    metin = gd_yaz(ulkeleri_cikar(ham), sha)

    if args.check:
        if not os.path.exists(CIKTI):
            print("KALDI: %s yok" % CIKTI)
            return 1
        mevcut = open(CIKTI, encoding="utf-8").read()
        if mevcut == metin:
            print("gecti: harita_verisi.gd kaynakla ayni")
            return 0
        print("KALDI: harita_verisi.gd kaynaktan kaymis "
              "(yeniden uret: python tools/gen_harita.py)")
        return 1

    os.makedirs(os.path.dirname(CIKTI), exist_ok=True)
    with open(CIKTI, "w", encoding="utf-8") as f:
        f.write(metin)
    print("yazildi: %s (%d bayt)" % (CIKTI, len(metin)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
