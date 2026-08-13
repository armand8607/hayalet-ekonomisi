"""
HAYALET EKONOMİSİ OYUNU (v3.2) - Sınıf Çatışması, Karanlık Politika ve Demografik Kriz
Cedeplar-UFMG ve Ahmet Tonak Senteziyle Çok Ülkeli Tarihsel Senaryolar

v3.1 -> v3.2: motor v4.3'e bağlandı; kriz raporuna Minsky/balon ayrımı eklendi.

v3.0 -> v3.1 değişiklikleri:
  1. `sys.path.append("/workspace/scratch")` sabit yolu kaldırıldı; modül artık
     betiğin kendi dizininden yüklenir (taşınabilirlik).
  2. Mafya politikası `c.mafya_tolerans` yerine `c.mafya_kilit` üzerinden
     uygulanıyor. v4.1'de tolerans ENDOJEN bir değişken; doğrudan atama bir
     sonraki turda motor tarafından üzerine yazılırdı. `mafya_kilit=None`
     bırakılırsa devlet politikası içsel olarak belirlenir.
  3. Tohum artık komut satırından verilebilir ve gerçekten etkili
     (v4.0'da senaryo yükleyici tohumu yok sayıyordu).
  4. Yıl etiketi senaryonun kendi başlangıç yılından hesaplanıyor
     (v3.0 her senaryo için 1995'ten başlıyordu).
  5. KODEY metrik seti rapora eklendi.

Kullanım:
    python3 hayalet_ekonomisi_oyunu_v32.py [senaryo] [mafya_politikasi] [tohum] [tur]

    senaryo          : turkey_2001 | golden_age_1950 | neoliberal_1995 | socialist_siege
    mafya_politikasi : 0.0-1.0 arası sayı (kilit) veya "endojen"
    tohum            : tam sayı
    tur              : tam sayı (varsayılan 120 ~ 32 yıl)

Örnek:
    python3 hayalet_ekonomisi_oyunu_v32.py turkey_2001 endojen 42
    python3 hayalet_ekonomisi_oyunu_v32.py turkey_2001 0.85 42
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine, TUR_YIL

SENARYOLAR = {
    "turkey_2001":      {"yil": 2001, "ad": "Türkiye 2001 Krizi ve Neoliberal Geçiş"},
    "golden_age_1950":  {"yil": 1950, "ad": "Altın Çağ Refah Devleti"},
    "neoliberal_1995":  {"yil": 1995, "ad": "Neoliberal Küreselleşme ve Finansallaşma"},
    "socialist_siege":  {"yil": 2030, "ad": "Kuşatılmış Planlı Ekonomi"},
}

Y, B, R, G, S = "\033[93m", "\033[1m", "\033[91m", "\033[92m", "\033[0m"


class GhostEconomyGame:
    def __init__(self, tohum=42):
        self.tohum = tohum
        self.engine = GhostEconomyEngine(tohum=tohum)

    def banner(self, senaryo, politika, turlar):
        meta = SENARYOLAR[senaryo]
        pol = "ENDOJEN (devlet kendi karar veriyor)" if politika is None else f"%{politika*100:.0f} KİLİTLİ"
        print(f"{G}{B}" + "=" * 72 + S)
        print(f"{G}{B}     HAYALET EKONOMİSİ OYUNU v3.2 - KARANLIK POLİTİKALAR{S}")
        print(f"{G}{B}" + "=" * 72 + S)
        print("  Sentez  : Cedeplar-UFMG Makrodinamikleri & Ahmet Tonak Değer Analizi")
        print(f"  Senaryo : {Y}{B}{senaryo.upper()}{S} — {meta['ad']} ({meta['yil']})")
        print(f"  Türkiye mafya/uyuşturucu politikası: {R}{B}{pol}{S}")
        print(f"  Tohum   : {self.tohum}   |   Süre: {turlar} tur (~{turlar*TUR_YIL:.0f} yıl)")
        print("=" * 72 + "\n")

    def run(self, senaryo, politika=None, turlar=120):
        if senaryo not in SENARYOLAR:
            raise ValueError(f"Bilinmeyen senaryo: {senaryo}")
        e = self.engine
        e.load_scenario(senaryo)

        # v3.1: politika ENDOJEN güncellemeyi devralmak için mafya_kilit ile verilir.
        if politika is not None:
            for c in e.D:
                if c.ad == "Turkiye":
                    c.mafya_kilit = politika

        self.banner(senaryo, politika, turlar)
        baslangic_yili = SENARYOLAR[senaryo]["yil"]
        tr = next(c for c in e.D if c.ad == "Turkiye")

        for t in range(turlar):
            e.step()
            yil = baslangic_yili + int(t * TUR_YIL)
            if tr.bunalimlar and tr.bunalimlar[-1][0] == t:
                print(f"  {R}{B}[UYARI  {yil}]{S} Türkiye'de büyük {B}{tr.bunalimlar[-1][1]}{S} "
                      f"bunalımı patlak verdi (derinlik %{tr.bunalimlar[-1][2]*100:.1f})")
            if tr.fx_krizleri and tr.fx_krizleri[-1] == t:
                print(f"  {R}{B}[UYARI  {yil}]{S} Türkiye'de ödemeler dengesi / devalüasyon krizi")
            if tr.temerrutler and tr.temerrutler[-1] == t:
                print(f"  {R}{B}[UYARI  {yil}]{S} Türkiye kamu borçlarında temerrüde düştü")
            if tr.moratoryumlar and tr.moratoryumlar[-1] == t:
                print(f"  {R}{B}[UYARI  {yil}]{S} Türkiye dış borç moratoryumu ilan etti")
            if tr.devrim_t == t:
                print(f"  {G}{B}[DEVRİM {yil}]{S} Türkiye'de işçi sınıfı iktidara el koydu")

        self.rapor(senaryo)

    def rapor(self, senaryo):
        e = self.engine
        print(f"\n{G}{B}" + "=" * 72 + S)
        print(f"{G}{B}                      SİMÜLASYON SONU RAPORU{S}")
        print(f"{G}{B}" + "=" * 72 + S)
        for k, v in e.get_summary().items():
            print(f"  {k:26s}: {v}")

        print("\n=== LTRPF (Kâr Oranlarının Düşme Eğilimi) TARİHSEL DOĞRULAMASI ===")
        print(f"  {'tur':>10s} {'r(tur)':>8s} {'r(yıl)':>8s} {'c/v':>6s} {'K/Y':>7s} {'u':>6s}")
        for d in e.kar_orani_trendi(30):
            print(f"  {d['t0']:4d}-{d['t1']:4d} {d['r']:8.5f} {d['r_yillik']:8.4f} "
                  f"{d['cv']:6.2f} {d['K/Y']:7.2f} {d['u']:6.3f}")

        print("\n=== KODEY METRİK SETİ (El Kitabı Bölüm 6) ===")
        print(f"  {'tur':>10s} {'tolerans':>9s} {'uyuşt.':>8s} {'cezaevi':>8s} "
              f"{'lumpen':>8s} {'gasp':>8s} {'s/v':>7s} {'eps/pi':>7s} {'doğum':>8s}")
        for d in e.kodey_trendi(30):
            print(f"  {d['t0']:4d}-{d['t1']:4d} {d['tolerans']:9.4f} {d['uyusturucu']:8.4f} "
                  f"{d['cezaevi']:8.4f} {d['lumpen_pay']:8.4f} {d['gasp_orani']:8.4f} "
                  f"{d['s_v']:7.3f} {d['eps/pi']:7.3f} {d['dogum']:8.5f}")

        print("\n=== SEÇİLMİŞ ÜLKELER: DEMOGRAFİK VE SOSYAL REJİM DURUMU ===")
        print(f"  {'Ülke':11s} {'Sınıf':7s} {'Uyuşt.':>7s} {'Cezaevi':>8s} {'Tolerans':>9s} "
              f"{'Doğum':>7s} {'Ölüm':>7s} {'Nüfus':>8s} {'Omega':>6s}  Rejim/Kurum")
        for c in e.D:
            if c.ad in ("ABD", "Cin", "Almanya", "Turkiye"):
                print(f"  {c.ad:11s} {c.tip:7s} %{c.uyusturucu_orani*100:6.3f} "
                      f"%{c.cezaevi_orani*100:7.3f} {c.mafya_tolerans:9.3f} "
                      f"%{c.dogum_orani*100:6.3f} %{c.olum_orani*100:6.3f} "
                      f"{c.L_max:8.1f} {c.Omega:6.3f}  {c.rejim}/{c.kurum}")
        print("=" * 72 + "\n")


if __name__ == "__main__":
    senaryo = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in SENARYOLAR else "turkey_2001"

    politika = None
    if len(sys.argv) > 2 and sys.argv[2].lower() not in ("endojen", "endogenous", "auto"):
        try:
            politika = max(0.0, min(1.0, float(sys.argv[2])))
        except ValueError:
            politika = None

    tohum = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else 42
    turlar = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4].isdigit() else 120

    GhostEconomyGame(tohum=tohum).run(senaryo, politika, turlar)

