"""
HAYALET EKONOMİSİ — MONTE CARLO KABUL SİSTEMİ (v4.3-R alan C)

Şartnamenin 48. bölümündeki kabul testlerini çok tohumlu olarak koşturur ve
her ölçüt için medyan + dağılım raporlar.

Neden gerekli: motorun bazı değişkenleri (özellikle uzun ufuk işsizliği ve
devrim sayısı) birden fazla çekim havzasına sahiptir. Tek koşuya bakan bir
kabul testi rasetgle geçer veya kalır. Her ölçüt bu yüzden "N tohumun
medyanı şu bantta" biçiminde tanımlanır.

Kullanım:
    python3 monte_carlo_kabul.py [tohum_sayisi] [tur]

    python3 monte_carlo_kabul.py 40 1200
"""

import os
import statistics as st
import sys
import time
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hayalet_ekonomi_motoru_v43 import GhostEconomyEngine, TUR_YIL, KAMPANYA_TURU


# --------------------------------------------------------------------------
# Kabul ölçütleri: (ad, çıkarıcı, alt, üst, biçim)
# Bant sınırları şartname §48'den; ülke-başına-aralık ölçütleri yıl cinsinden.
# --------------------------------------------------------------------------
# v4.3-R+otomasyon: bantlar YENIDEN KALIBRE EDILDI.
# Eski bantlar (LTRPF [-60,-25], issizlik [0.03,0.25]) otomasyon katmani
# OLMAYAN bir motora gore secilmisti. Canli emek tek deger kaynagi oldugu ve
# robotlar fiziksel kapasiteyi buyuttugu icin, tam otomasyon cagında yeni deger
# yapisal olarak buzulur: kar oraninin %70-90 dusmesi ve issizligin %25-50
# bandinda kalicilasmasi mekanizmanin DOGRU ciktisidir, sapma degil.
# Bantlar olculen dagilima gore degil, mekanizmanin calistigini dogrulayacak
# sekilde secildi: cok dar olursa gurultu, cok genis olursa test anlamsizlasir.
OLCUTLER = [
    # v4.3-R + cag-1 kampanyasi (1760-2100) + otomasyon icin kalibre edildi.
    # Onceki bantlar cag-4 baslangicli 1200 turluk kosuya gore secilmisti.
    ("LTRPF (r_son/r_ilk-1)",      "ltrpf",      -0.95, -0.55, "%+.1f%%", 100),
    # ISSIZLIK BANDI TEORIK GEREKCEYLE YENIDEN KURULDU.
    # Onceki [0.45, 0.80] olculen bir ortalamanin etrafina yerlestirilmisti ve
    # dort kez degistirildi; yani bagimsiz kriter degildi. Yeni bant bir NOKTA
    # TAHMINI degil, iki SINIR argumanindan turetilir:
    #   ALT: otomasyon artik nufus URETMELI. Cag 4'te (otomasyon oncesi) issizlik
    #        medyani 0.000, p90 0.426. Cag 6 issizligi cag 4'un p90'ini asmalidir,
    #        yoksa "otomasyon emegi yerinden ediyor" iddiasi bos kalir -> 0.30.
    #   UST: ucretli emek tamamen yok olursa yeni deger V coker ve sistem kendini
    #        uretemez hale gelir (dejenere durum). Model canli emegin fiziksel
    #        hasiladaki payini 0.20'nin altina indirmiyor; buna karsilik gelen
    #        issizlik ust siniri ~0.75'tir.
    # Bant GENISTIR ve bu kasitlidir: 2100 issizligi icin ampirik capa yoktur,
    # yalnizca kabul edilebilirlik araligi savunulabilir.
    ("işsizlik",                   "iss",         0.30,  0.75, "%.3f",      1),
    ("resesyon aralığı (yıl)",     "res_yil",     6.0,  15.0, "%.1f",      1),
    ("Minsky aralığı (yıl)",       "minsky_yil", 40.0, 110.0, "%.1f",      1),
    ("kurumsal geçiş sayısı",      "gecis",      40.0,  1e9,  "%.0f",      1),
    ("devrim sayısı",              "devrim",      0.0,   8.0, "%.1f",      1),
    ("otomasyon payı",             "oto",         0.40,  0.70, "%.3f",      1),
    ("canlı emek payı",            "canli",       0.20,  0.55, "%.3f",      1),
]


def tek_kosu(tohum, turlar):
    e = GhostEconomyEngine(tohum)
    ozet = e.run_simulation(turlar)
    yil = turlar * TUR_YIL
    n = len(e.D)
    tr = e.kar_orani_trendi(max(turlar // 4, 1))
    son = [x for c in e.D for x in c.tarih[int(turlar * 0.875):]]
    # Issizlik YALNIZCA KAPITALIST ulkelerde olculur. Planli ekonomiler plan
    # geregi tam istihdama yakin calisir; devrim sayisi arttikca dunya ortalamasi
    # bu yuzden duser ve olcut otomasyon issizligini degil devrim sayisini olcer
    # hale gelir. Otomasyonun artik nufus tezi kapitalizme dairdir.
    son_kap = [x for c in e.D if c.rejim == "kapitalist"
               for x in c.tarih[int(turlar * 0.875):]] or son

    res = sum(len(c.resesyonlar) for c in e.D)
    minsky = sum(1 for _, k, m in e.log if k == "COKME" and "MINSKY" in m.upper())
    borc = sum(1 for _, k, m in e.log if k == "COKME" and "BORC" in m.upper())

    kurum_son = Counter(c.kurum for c in e.D)
    yon = Counter()
    for c in e.D:
        for (_, a, b) in c.kurum_gecmis:
            yon[f"{a}->{b}"] += 1

    return {
        "oto": st.mean([x["oto"] for x in son]),
        "canli": st.mean([x["canli_pay"] for x in son]),
        "ltrpf": tr[-1]["r"] / tr[0]["r"] - 1 if tr and tr[0]["r"] else float("nan"),
        "iss": 1 - st.mean([x["e"] for x in son_kap]),
        "res_yil": yil / (res / n) if res else float("inf"),
        "minsky_yil": yil / (minsky / n) if minsky else float("inf"),
        "borc_yil": yil / (borc / n) if borc else float("inf"),
        "gecis": sum(len(c.kurum_gecmis) for c in e.D),
        "devrim": ozet["sosyalist_devrimler"],
        "cv_son": tr[-1]["cv"] if tr else float("nan"),
        "pay": st.mean([x["pay"] for x in son]),
        "kurum_son": kurum_son,
        "yon": yon,
    }


def kosu_seti(tohumlar, turlar):
    sonuc = []
    t0 = time.time()
    for i, s in enumerate(tohumlar, 1):
        sonuc.append(tek_kosu(s, turlar))
        gecen = time.time() - t0
        print(f"\r  {i}/{len(tohumlar)} tohum  ({gecen:.0f} sn, "
              f"tahmini kalan {gecen/i*(len(tohumlar)-i):.0f} sn)", end="", flush=True)
    print()
    return sonuc


def rapor(sonuc, turlar):
    n = len(sonuc)
    print(f"\n{'='*78}")
    print(f"MONTE CARLO KABUL RAPORU — {n} tohum × {turlar} tur "
          f"({turlar*TUR_YIL:.0f} yıl)")
    print("=" * 78)
    print(f"{'ölçüt':<28}{'medyan':>11}{'p10':>11}{'p90':>11}{'bant':>12}  sonuç")
    print("-" * 78)

    gecti_hepsi = True
    for ad, anahtar, alt, ust, bicim, olcek in OLCUTLER:
        v = sorted(x[anahtar] for x in sonuc if x[anahtar] == x[anahtar])
        v = [x for x in v if x != float("inf")]
        if not v:
            print(f"{ad:<28}{'—':>11}{'—':>11}{'—':>11}{'':>12}  VERİ YOK")
            continue
        med = st.median(v)
        p10 = v[max(0, int(0.10 * len(v)) - 1)]
        p90 = v[min(len(v) - 1, int(0.90 * len(v)))]
        gecti = alt <= med <= ust
        gecti_hepsi &= gecti
        bant = f"[{alt:g},{ust:g}]" if ust < 1e8 else f"≥{alt:g}"
        print(f"{ad:<28}{bicim % (med*olcek):>11}{bicim % (p10*olcek):>11}"
              f"{bicim % (p90*olcek):>11}{bant:>12}  {'GEÇTİ' if gecti else 'KALDI'}")

    # Polanyi çifte hareketi: her iki yönde de geçiş olmalı
    ileri = sum(x["yon"]["duzenli->neoliberal"] for x in sonuc)
    geri = sum(x["yon"]["neoliberal->duzenli"] for x in sonuc)
    cift = ileri > 0 and geri > 0
    gecti_hepsi &= cift
    print("-" * 78)
    print(f"{'çifte hareket (Polanyi)':<28}"
          f"{'düzenli→neoliberal ' + str(ileri):>33}"
          f"{'neoliberal→düzenli ' + str(geri):>25}")
    print(f"{'':<28}{'her iki yön de çalışıyor':>55}  {'GEÇTİ' if cift else 'KALDI'}")

    # Liberale endojen dönüş olmamalı (Clarke + Polanyi)
    # AI liberal insa etmedigi icin bu sayac saf endojen suruklenişi olcer.
    endojen_liberal = sum(v for x in sonuc for k, v in x["yon"].items()
                          if k.endswith("->liberal"))
    print(f"{'liberale endojen dönüş':<28}{endojen_liberal:>33}"
          f"{'(0 olmalı)':>25}  {'GEÇTİ' if endojen_liberal == 0 else 'KALDI'}")
    gecti_hepsi &= endojen_liberal == 0

    print("-" * 78)
    print(f"GENEL: {'TÜM ÖLÇÜTLER GEÇTİ' if gecti_hepsi else 'EN AZ BİR ÖLÇÜT KALDI'}")
    print("=" * 78)

    dag = Counter()
    for x in sonuc:
        dag.update(x["kurum_son"])
    print("\nSon kurum dağılımı (tüm tohumlar toplamı):", dict(dag))
    print(f"Ortalama c/v (son dilim): {st.mean([x['cv_son'] for x in sonuc]):.2f}")
    print(f"Ortalama ücret payı     : {st.mean([x['pay'] for x in sonuc]):.3f}")
    return gecti_hepsi


def sosyalist_ayrisma_testi(tohumlar, turlar=400):
    """Şartname §49: iki plan profili anlamlı biçimde farklı sonuç vermeli."""
    print(f"\n{'='*78}")
    print(f"SOSYALİST AYRIŞMA TESTİ — {len(tohumlar)} tohum × {turlar} tur")
    print("=" * 78)
    cikti = {}
    for prof in ("sanayilesmeci", "tuketimci"):
        satir = []
        for s in tohumlar:
            e = GhostEconomyEngine(s)
            # Politika AI'si sosyalist ulkelerin plan profilini her 12 turda bir
            # yeniden secer; mekanizmayi test ederken onu kapatmak gerekir,
            # yoksa test ettigimiz profil AI tarafindan eziliyor.
            e.P.ai_acik = False
            e.load_scenario("socialist_siege")
            e.set_plan_profili(prof)
            for _ in range(turlar):
                e.step()
            sos = [c for c in e.D if c.rejim == "sosyalist"]
            sg = [x for c in sos for x in c.tarih[int(turlar*0.7):]]
            if sg:
                satir.append([st.mean([x[k] for x in sg])
                              for k in ("Y", "q", "pay", "kitlik", "PKE", "g")])
        cikti[prof] = [st.median([r[i] for r in satir]) for i in range(6)]

    adlar = ("Y", "q", "ücret payı", "kıtlık", "PKE", "birikim g")
    print(f"{'değişken':<14}{'sanayileşmeci':>16}{'tüketimci':>14}{'fark':>14}")
    print("-" * 78)
    anlamli = 0
    for i, ad in enumerate(adlar):
        a, b = cikti["sanayilesmeci"][i], cikti["tuketimci"][i]
        fark = (a / b - 1) if b else float("inf")
        if abs(fark) > 0.05 or abs(a - b) > 0.05:
            anlamli += 1
        print(f"{ad:<14}{a:>16.4f}{b:>14.4f}{fark:>13.1%}")
    print("-" * 78)
    print(f"Anlamlı fark gösteren değişken: {anlamli}/6  "
          f"{'GEÇTİ' if anlamli >= 4 else 'KALDI'}")
    return anlamli >= 4


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    turlar = int(sys.argv[2]) if len(sys.argv) > 2 else KAMPANYA_TURU
    # KALIBRASYON / DOGRULAMA AYRIMI
    # Bu projede kabul bantlari defalarca olculen sonuca gore ayarlandi; bu
    # yuzden kalibrasyon tohumlariyla yapilan test DOGRULAMA DEGILDIR.
    #   set=kalibrasyon -> 1..100   (parametreler burada ayarlandi)
    #   set=dogrulama   -> 101..200 (parametreler DONDURULMUS, hic gorulmedi)
    # Onceden taahhut: dogrulama kalirsa en fazla IKI kez yeniden kalibre edilir
    # ve her seferinde YENI bir dogrulama araligi cekilir (201..300, 301..400).
    # Sinir olmadan yinelemek coklu hipotez testine doner.
    kume = sys.argv[3] if len(sys.argv) > 3 else "kalibrasyon"
    if kume == "dogrulama":
        tohumlar = list(range(101, 101 + n))
    else:
        tohumlar = [1, 7, 42, 99, 2024] + list(range(1000, 1000 + max(0, n - 5)))
        tohumlar = tohumlar[:n]
    print(f"[kume={kume}] tohumlar {tohumlar[0]}..{tohumlar[-1]}")

    print(f"Motor kabul testi koşuluyor: {n} tohum × {turlar} tur")
    sonuc = kosu_seti(tohumlar, turlar)
    a = rapor(sonuc, turlar)
    b = sosyalist_ayrisma_testi(tohumlar[:min(len(tohumlar), 10)])
    print(f"\nSONUÇ: motor {'GEÇTİ' if a else 'KALDI'}, "
          f"sosyalist ayrışma {'GEÇTİ' if b else 'KALDI'}")


# ==========================================================================
# ETG CAN SİMİDİ TESTİ — "kapitalizmi ilelebet kurtarabilir mi?"
# ==========================================================================
def can_simidi_testi(tohumlar, turlar=1200, sermaye_payi=0.5, dilim=150):
    """Devlet, huzursuzluğu devrim eşiğinin altında tutmak için gereken ETG'yi
    verir. Ölçülen: gereken ETG zamanla yükseliyor mu, mali fren ne zaman
    devreye giriyor, ve fren devreye girince ne oluyor.

    Marksist beklenti: ETG çelişkiyi çözmez, erteler — artı-değerden ödenir ve
    LTRPF o kaynağı küçültürken otomasyon ihtiyacı büyütür. Model bunu
    varsaymaz; üretmesi beklenir.
    """
    print(f"\n{'='*78}")
    print(f"ETG CAN SİMİDİ TESTİ — {len(tohumlar)} tohum × {turlar} tur "
          f"(sermaye finansman payı {sermaye_payi:.0%})")
    print("=" * 78)

    kesit = {lo: {"etg": [], "borc": [], "kisit": [], "Om": [], "r": [], "iss": []}
             for lo in range(0, turlar, dilim)}
    devrim, temerrut = [], []
    for s in tohumlar:
        e = GhostEconomyEngine(s)
        e.P.cs_acik = True
        e.set_etg_finansman(sermaye_payi)
        ozet = e.run_simulation(turlar)
        devrim.append(ozet["sosyalist_devrimler"])
        temerrut.append(sum(len(c.temerrutler) for c in e.D))
        for lo in kesit:
            sg = [x for c in e.D for x in c.tarih[lo:lo+dilim]
                  if c.rejim == "kapitalist"]
            if not sg:
                continue
            kesit[lo]["etg"].append(st.mean([x["etg"] for x in sg]))
            kesit[lo]["borc"].append(st.mean([x["kamu_borc"] for x in sg]))
            kesit[lo]["kisit"].append(st.mean([x["cs_kisit"] for x in sg]))
            kesit[lo]["Om"].append(st.mean([x["Om"] for x in sg]))
            kesit[lo]["r"].append(st.mean([x["r"] for x in sg]))
            kesit[lo]["iss"].append(1 - st.mean([x["e"] for x in sg]))

    print(f"{'tur':>10}{'gereken ETG':>13}{'kamu borcu':>12}"
          f"{'fren devrede':>14}{'Omega':>9}{'r':>9}{'işsizlik':>10}")
    print("-" * 78)
    for lo in sorted(kesit):
        d = kesit[lo]
        if not d["etg"]:
            continue
        print(f"{lo:>4}-{lo+dilim:<5}{st.median(d['etg']):>13.4f}"
              f"{st.median(d['borc']):>12.3f}{st.median(d['kisit']):>13.0%}"
              f"{st.median(d['Om']):>9.3f}{st.median(d['r']):>9.4f}"
              f"{st.median(d['iss']):>10.3f}")
    print("-" * 78)
    ilk = [lo for lo in sorted(kesit) if kesit[lo]["etg"]][0]
    son = [lo for lo in sorted(kesit) if kesit[lo]["etg"]][-1]
    e0, e1 = st.median(kesit[ilk]["etg"]), st.median(kesit[son]["etg"])
    b0, b1 = st.median(kesit[ilk]["borc"]), st.median(kesit[son]["borc"])
    k1 = st.median(kesit[son]["kisit"])
    print(f"Gereken ETG {e0:.4f} → {e1:.4f}   "
          f"kamu borcu {b0:.2f} → {b1:.2f}   son dilimde fren {k1:.0%}")
    print(f"Devrim (medyan): {st.median(devrim):.1f}   "
          f"Kamu temerrüdü (medyan): {st.median(temerrut):.1f}")
    return {"etg_ilk": e0, "etg_son": e1, "borc_son": b1, "kisit_son": k1,
            "devrim": st.median(devrim), "temerrut": st.median(temerrut)}
