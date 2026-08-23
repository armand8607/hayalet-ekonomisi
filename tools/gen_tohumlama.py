"""1836 EKONOMIK TOHUMLAMASINI URETIR: Maddison -> GDScript veri dosyasi.

NEDEN URETILIYOR, ELLE YAZILMIYOR
---------------------------------
`gen_harita.py` bu isi acikca disarida birakmisti ve sebebini de yazmisti:
"Tasinmayan: nufus, GSYH, hicbir iktisadi buyukluk. Bunlar 2020'lerin
verisidir ve oyun 1836'da baslar; kaynaktan iktisadi bir sayi almak
anakronizmi VERI gibi gosterirdi."

Bu dosya o bosluğu TARIHSEL bir kaynakla doldurur. Elle yazilmasi iki
sebeple kabul edilemez: 113 sayi elle kopyalanamaz (`param_set.gd`in 355
sabiti icin verilmis olan gerekcenin aynisi), ve elle yazilan sey
KAYNAKSIZDIR -- "Rusya neden bu buyuklukte" sorusunun cevabi olmaz.

KAYNAK
------
Maddison Project Database 2020 (Bolt & van Zanden 2020), Our World in Data
aynasindan. CC BY 4.0; atif uretilen dosyanin basligina yazilir.
ISO 3166-1 alpha-3 eslemesi icin `datasets/country-codes` (PDDL, kamu malı).

NE TOHUMLANIR -- YALNIZCA `L_etkin`
-----------------------------------
Olculdu (`--v2-kesit`): `L_etkin` butun ulkelerde 110.0 ve kampanya boyunca
duz kaliyor (max/min 1.01 @ 2100). Ayrisan tek sey `Y_yil` ve o da ulke
KIMLIGINE oturmuyor -- 2100'de Bulgaristan dunyanin en buyuk ekonomisi.

Tohumlanan tek alan `L_etkin`tir, ve bu YETER:

  * `K` cekirdegin `baslat()`inda `L_etkin`ten TURETILIR
    (`d.K = d.kv * d.q * emek * hedef_istihdam / u_normal`), yani sermaye
    yogunlugu kendiliginde korunur. Ayrica tohumlamak cifte sayim olurdu.
  * `NufusKatmani.baslat()` `L_etkin`i BOZMAZ; toplam nufusu ondan geri
    hesaplar, boylece `emek_arzi()` tam olarak ayni sayiyi doner.
  * `q` (uretkenlik) tohumlanmaz. Onu konum merdiveni verir ve o merdiven
    B1b'de OLCULMUS bir kalibrasyondur; ustune GSYH/kisi yazmak olculmus bir
    degeri kaynakla ezmek olurdu. Ikisi dogru bileisiyor: Cin/Britanya
    hasila orani bu kurulumda ~7 cikiyor, Maddison'in kendi 1820 orani 6.3.

1836'DA DEVLET OLMAYAN TOPRAKLAR -- MIRAS KURALI
------------------------------------------------
Oyun BUGUNKU 113 toprağı simule eder (§3.4: devlet olusumu modellenmez).
Bunlarin 34'unun Maddison'da kendi serisi 1950'de baslar, cunku 1836'da ayri
devlet degillerdi: Ukrayna Rus Imparatorlugu'nda, Bangladeş Britanya
Hindistani'nda, Nijerya somurge oncesi.

O 34 icin 1950 rakamini almak TAM DA yukarida reddedilen anakronizmdir --
Rusya'nin 1836 nufusu 101.9 milyon cikardi (gercegi ~36). Kural bunun yerine
sudur:

    toprak_1836 = tarihsel_butun_1836 x (toprak_1950 / butun_1950)

Iki ucu da kaynaklidir; varsayim ACIKTIR ve tektir: butunun ICINDEKI dagilim
1836 ile 1950 arasinda kabaca sabit kalmistir. Sonuclari tarihsel tahminlerle
tutuyor -- Rusya 36.4M (~35-40M), Nijerya 11.1M (~10-13M).

`MIRAS` tablosu asagida ELLE durur ve bu bilinclidir: hangi toprağin 1836'da
hangi butune ait oldugu KIMLIK verisidir, kalibrasyon degil -- `KONUM` ve
`OYNANABILIR` tablolariyla ayni statude.

NORMALIZASYON: MEDYAN 110'DA TUTULUR
------------------------------------
Ham nufus dogrudan yazilamaz; motor 110.0 civarinda kalibre edilmistir.
Bolen MEDYANDIR, ortalama degil, ve bu olculerek secildi:

  ortalama=110 -> L_etkin araligi 0.29 .. 4411, DORT ulke `savas.gd`in
                  mutlak 1.0 nufus tabaninin altinda kalir
  medyan=110   -> L_etkin araligi 1.37 .. 20853, tabanin altinda kimse yok

Medyan ayrica dogru degismezi korur: kalibrasyon ULKE BASINA yapilmistir
(kapali form yorungeler, LTRPF), yani korunmasi gereken TIPIK ulkenin
calisma noktasidir. Dunya toplami kalibre edilmis bir buyukluk degildir --
`Dunya`nin akimlari cift uzerinde tanimli ve olcekten bagimsiz korunur.

KULLANIM
--------
    python tools/gen_tohumlama.py            # yeniden uret
    python tools/gen_tohumlama.py --check    # kaynakla ayni mi (ag ister)

`--check` CI'da KOSMAZ -- `gen_harita.py` ile ayni gerekce: denetim bizim
disimizdaki bir deponun dalina baglanirdi. Uretilen verinin dogrulugunu
`--v2-tohumlama` kapisi YAPISAL olarak sinar.
"""

import argparse
import csv
import hashlib
import io
import math
import os
import re
import sys
import unicodedata
import urllib.request

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIKTI = os.path.join(KOK, "godot", "scripts", "v2", "data", "tohum_verisi.gd")
HARITA = os.path.join(KOK, "godot", "scripts", "v2", "data", "harita_verisi.gd")

MADDISON_URL = (
    "https://raw.githubusercontent.com/owid/owid-datasets/master/datasets/"
    "Maddison%20Project%20Database%202020%20(Bolt%20and%20van%20Zanden%20(2020))/"
    "Maddison%20Project%20Database%202020%20(Bolt%20and%20van%20Zanden%20(2020)).csv"
)
KOD_URL = (
    "https://raw.githubusercontent.com/datasets/country-codes/main/data/"
    "country-codes.csv"
)

## Oyunun basladigi yil. Tohum bu yila cekilir.
HEDEF = 1836

## Motorun kalibre edildigi `L_etkin`. Medyan ulke burada tutulur.
MEDYAN_L = 110.0

## Koprulenemeyen bir gozlem en fazla bu kadar uzaktan tasinir. 1850'de
## baslayan bir seri 1836 icin kabul edilir (14 yil); 1950'de baslayan
## EDILMEZ -- onun yolu `MIRAS`tir.
TASIMA_PENCERESI = 40

# ---------------------------------------------------------------------------
# ELLE YAZILAN TEK TABLO: 1836'DA HANGI BUTUNUN PARCASI
# ---------------------------------------------------------------------------
# KIMLIK verisidir, kalibrasyon degil. Deger tasimaz -- yalnizca hangi
# Maddison serisinin bolusturulecegini secer.
#
# Degerler Maddison'in KENDI toplam adlaridir; ikisi ulke adidir ("India"
# 1946'ya kadar Britanya Hindistani'dir -- seri 1947'de 415.2M'den 346M'ye
# duser, yani bolunme kaynagin icinde gorunur).
MIRAS = {}
for _k in "RUS UKR BLR KAZ UZB AZE GEO EST LVA LTU TKM".split():
    MIRAS[_k] = "Former USSR"
for _k in "IND PAK BGD".split():
    MIRAS[_k] = "India"
for _k in "CZE SVK".split():
    MIRAS[_k] = "Czechoslovakia"
for _k in "HRV SRB".split():
    MIRAS[_k] = "Former Yugoslavia"
for _k in "AGO CIV CMR COD KEN MLI MRT NAM NER NGA TCD TZA ZMB ZWE".split():
    MIRAS[_k] = "Sub-Sahara Africa"
for _k in "ARE ISR".split():
    MIRAS[_k] = "Middle East"
MIRAS["DOM"] = "Latin America"

## `India` butunu bir BOLGE degil bir ulkedir: paydasi kendi ardillarinin
## 1950 toplamidir, bolgenin degil.
MIRAS_PAYDA_UYELERI = {"India": ("IND", "PAK", "BGD")}

## Maddison entity adi -> ISO3, ad normalizasyonunun tutmadigi yerler.
AD_ELLE = {
    "United Kingdom": "GBR",
    "United States": "USA",
    "Turkey": "TUR",
    "Democratic Republic of Congo": "COD",
}


def indir(url):
    istek = urllib.request.Request(url, headers={"User-Agent": "hayalet-ekonomisi"})
    with urllib.request.urlopen(istek, timeout=120) as y:
        ham = y.read()
    return ham, hashlib.sha256(ham).hexdigest()


def ad_normalize(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    s = re.sub(
        r"\b(the|of|and|republic|democratic|people|s|federal|kingdom|state|"
        r"states|islamic|arab)\b",
        " ",
        s,
    )
    return re.sub(r"[^a-z]", "", s)


def simule_ulkeler():
    """`harita_verisi.gd`den `konum` alani DOLU olanlari okur.

    Uretilen bir dosyadan okumak bilincli: iki tablo ayni ulke kumesini
    tekrar etseydi biri digerinden sessizce ayrilirdi.
    """
    ham = open(HARITA, encoding="utf-8").read()
    cikti = []
    desen = r'\{"kod": "(\w+)", "ad": "([^"]*)", "ad_1836": "[^"]*", "kita": "([^"]*)".*?"konum": "([^"]*)"'
    for m in re.finditer(desen, ham):
        if m.group(4):
            cikti.append((m.group(1), m.group(2), m.group(3), m.group(4)))
    return cikti


def seriler(maddison_ham):
    """Maddison'i iki sozluge cevirir: ISO3 bazli ve entity-adi bazli."""
    okuyucu = csv.DictReader(io.StringIO(maddison_ham.decode("utf-8")))
    ad2iso = {}
    kod_ham, _ = KOD_HAM
    for r in csv.DictReader(io.StringIO(kod_ham.decode("utf-8"))):
        iso = r["ISO3166-1-Alpha-3"].strip()
        if not iso:
            continue
        for c in ("UNTERM English Short", "official_name_en", "CLDR display name"):
            if r[c].strip():
                ad2iso.setdefault(ad_normalize(r[c].strip()), iso)

    iso_seri, entity_seri = {}, {}
    for r in okuyucu:
        if not r["Population"].strip():
            continue
        yil = int(r["Year"])
        deger = float(r["Population"])
        entity_seri.setdefault(r["Entity"], {})[yil] = deger
        iso = AD_ELLE.get(r["Entity"]) or ad2iso.get(ad_normalize(r["Entity"]))
        if iso:
            iso_seri.setdefault(iso, {})[yil] = deger
    return iso_seri, entity_seri


def hedefe_cek(seri):
    """Bir seriyi HEDEF yilina ceker. Doner: (deger, nasil) ya da (None, sebep).

    Ara deger LOG uzayinda alinir: bunlar buyume buyuklukleridir ve dogrusal
    ara deger 50 yillik bir araliktia sistematik olarak yuksek cikar.
    """
    if not seri:
        return None, "kaynakta yok"
    if HEDEF in seri:
        return seri[HEDEF], "dogrudan"
    yillar = sorted(seri)
    alt = [y for y in yillar if y < HEDEF]
    ust = [y for y in yillar if y > HEDEF]
    if alt and ust:
        a, u = alt[-1], ust[0]
        t = (HEDEF - a) / (u - a)
        v = math.exp(math.log(seri[a]) * (1 - t) + math.log(seri[u]) * t)
        return v, "ara %d-%d" % (a, u)
    yakin = alt[-1] if alt else ust[0]
    if abs(yakin - HEDEF) <= TASIMA_PENCERESI:
        return seri[yakin], "en yakin %d" % yakin
    return None, "en yakin %d, pencere disi" % yakin


def tohumla(iso_seri, entity_seri, ulkeler):
    nufus, kaynak, tohumsuz = {}, {}, []
    for kod, ad, _kita, _konum in ulkeler:
        if kod in MIRAS:
            butun_ad = MIRAS[kod]
            butun, nasil = hedefe_cek(entity_seri.get(butun_ad, {}))
            uyeler = MIRAS_PAYDA_UYELERI.get(butun_ad)
            if uyeler:
                payda = sum(iso_seri.get(u, {}).get(1950, 0.0) for u in uyeler)
            else:
                payda = entity_seri.get(butun_ad, {}).get(1950, 0.0)
            pay = iso_seri.get(kod, {}).get(1950, 0.0)
            if butun and pay and payda:
                nufus[kod] = butun * pay / payda
                kaynak[kod] = "%s %s, pay %.4f" % (butun_ad, nasil, pay / payda)
                continue
        deger, nasil = hedefe_cek(iso_seri.get(kod, {}))
        if deger:
            nufus[kod] = deger
            kaynak[kod] = nasil
        else:
            tohumsuz.append(kod)
            kaynak[kod] = nasil
    return nufus, kaynak, tohumsuz


def medyan(degerler):
    s = sorted(degerler)
    n = len(s)
    return s[n // 2] if n % 2 else 0.5 * (s[n // 2 - 1] + s[n // 2])


def uret(nufus, kaynak, tohumsuz, ulkeler, ozetler):
    # MEDYAN YAZILAN SAYILARDAN HESAPLANIR, ham float'lardan DEGIL.
    # `NUFUS` tam sayi olarak yazilir; medyan yuvarlanmamis degerlerden
    # alinsaydi medyan ulkenin `110.0 * n / MEDYAN_NUFUS`si tam 110.0
    # ETMEZDI -- ve fark ondalik gosterimde "110.0000" diye gizlenirdi.
    # Kapinin yakaladigi hata tam olarak buydu.
    yazilan = {k: float(round(v)) for k, v in nufus.items()}
    med = medyan(yazilan.values())
    ad = {k: a for k, a, _, _ in ulkeler}
    sat = []
    sat.append("class_name TohumVerisi")
    sat.append("extends RefCounted")
    sat.append("")
    sat.append("# =============================================================")
    sat.append("# BU DOSYA URETILMISTIR -- ELLE DUZENLEMEYIN.")
    sat.append("# Kaynak : Maddison Project Database 2020")
    sat.append("#          (Bolt & van Zanden 2020), CC BY 4.0")
    sat.append("#          Our World in Data aynasindan")
    sat.append("#          sha256 %s" % ozetler["maddison"])
    sat.append("#          ISO3 eslemesi: datasets/country-codes (PDDL)")
    sat.append("#          sha256 %s" % ozetler["kod"])
    sat.append("# Ureten : tools/gen_tohumlama.py")
    sat.append("# Yeniden uretmek icin: python tools/gen_tohumlama.py")
    sat.append("# =============================================================")
    sat.append("")
    sat.append("## 1836'nin nufus tohumu: %d toprak." % len(nufus))
    sat.append("##")
    sat.append("## NEDEN VAR: olculdu ki `L_etkin` butun ulkelerde 110.0 ve")
    sat.append("## kampanya boyunca duz kaliyor -- ABD ile Bolivya ayni boyda,")
    sat.append("## ve 2100'de dunyanin en buyuk ekonomisi Bulgaristan cikiyor.")
    sat.append("## Ayrisma vardi ama ulke KIMLIGINE oturmuyordu.")
    sat.append("##")
    sat.append("## TOHUMLANAN TEK ALAN `L_etkin`. `K` cekirdekte ondan turetilir,")
    sat.append("## `NufusKatmani` onu bozmaz, `q`yu konum merdiveni verir.")
    sat.append("##")
    sat.append("## 1836'da ayri devlet olmayan topraklar tarihsel butunun 1950")
    sat.append("## payiyla bolusturulur (bkz. ureticideki MIRAS notu); hangi")
    sat.append("## topragin nereden geldigi `KAYNAK`ta yazilidir.")
    sat.append("")
    sat.append("## Tohumun cekildigi yil.")
    sat.append("const YIL := %d" % HEDEF)
    sat.append("")
    sat.append("## Medyan ulkenin `L_etkin`i. Motorun kalibre edildigi deger.")
    sat.append("const MEDYAN_L := %.1f" % MEDYAN_L)
    sat.append("")
    sat.append("## Ham nufusun medyani -- normalizasyon boleni. SAKLANIR,")
    sat.append("## yeniden hesaplanmaz: `NUFUS` bir kez duzenlense (ki")
    sat.append("## duzenlenmemeli) bolen sessizce kayardi.")
    sat.append("const MEDYAN_NUFUS := %.1f" % med)
    sat.append("")
    sat.append("## Maddison'da karsiligi olmayan topraklar. Bunlar medyan")
    sat.append("## buyuklukte baslar ve bu bir EKSIKLIK olarak kayda gecer.")
    sat.append("const TOHUMSUZ := %s" % gdscript_dizi(tohumsuz))
    sat.append("")
    sat.append("## kod -> 1836 nufusu (kisi).")
    sat.append("const NUFUS := {")
    for kod in sorted(nufus):
        sat.append('\t"%s": %d,  # %s' % (kod, int(yazilan[kod]), ad.get(kod, "")))
    sat.append("}")
    sat.append("")
    sat.append("## kod -> tohumun NEREDEN geldigi. Tani icin saklanir: bir")
    sat.append("## sayinin dogrudan mi bolusturulerek mi geldigi, o sayiya")
    sat.append("## ne kadar guvenilecegini belirler.")
    sat.append("const KAYNAK := {")
    for kod in sorted(kaynak):
        sat.append('\t"%s": "%s",' % (kod, kaynak[kod]))
    sat.append("}")
    sat.append("")
    sat.append("")
    sat.append("## Bir topragin baslangic `L_etkin`i. Tohumsuzlar medyani alir.")
    sat.append("static func l_etkin(kod: String) -> float:")
    sat.append("\tif not NUFUS.has(kod):")
    sat.append("\t\treturn MEDYAN_L")
    sat.append("\treturn MEDYAN_L * float(NUFUS[kod]) / MEDYAN_NUFUS")
    sat.append("")
    return "\n".join(sat) + "\n"


def gdscript_dizi(dizi):
    # DUZ DIZI LITERALI, `PackedStringArray(...)` DEGIL: ikincisi bir
    # yapici cagrisidir ve GDScript onu sabit ifade saymaz --
    # "Assigned value for constant isn't a constant expression".
    return "[%s]" % ", ".join('"%s"' % x for x in sorted(dizi))


def main():
    global KOD_HAM
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="kaynagi yeniden indirip uretileni karsilastirir")
    args = ap.parse_args()

    maddison_ham, maddison_ozet = indir(MADDISON_URL)
    KOD_HAM = indir(KOD_URL)
    ozetler = {"maddison": maddison_ozet, "kod": KOD_HAM[1]}

    ulkeler = simule_ulkeler()
    iso_seri, entity_seri = seriler(maddison_ham)
    nufus, kaynak, tohumsuz = tohumla(iso_seri, entity_seri, ulkeler)
    metin = uret(nufus, kaynak, tohumsuz, ulkeler, ozetler)

    if args.check:
        mevcut = open(CIKTI, encoding="utf-8").read() if os.path.exists(CIKTI) else ""
        if mevcut == metin:
            print("SONUC: uretilen dosya kaynakla ayni")
            return 0
        print("SONUC: FARKLI -- `python tools/gen_tohumlama.py` ile yeniden uret")
        return 1

    os.makedirs(os.path.dirname(CIKTI), exist_ok=True)
    open(CIKTI, "w", encoding="utf-8", newline="\n").write(metin)
    med = medyan([float(round(v)) for v in nufus.values()])
    L = [MEDYAN_L * float(round(v)) / med for v in nufus.values()]
    print("yazildi: %s" % os.path.relpath(CIKTI, KOK))
    print("  tohumlanan   : %d / %d" % (len(nufus), len(ulkeler)))
    print("  tohumsuz     : %s" % (", ".join(tohumsuz) or "-"))
    print("  1836 toplami : %,d kisi".replace("%,", "%") % round(sum(nufus.values())))
    print("  medyan nufus : %d" % round(med))
    print("  L_etkin      : %.2f .. %.0f  (medyan %.1f)" % (min(L), max(L), MEDYAN_L))
    return 0


if __name__ == "__main__":
    sys.exit(main())
