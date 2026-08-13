"""Frozen markdown -> calisabilir .py kaynaklari.

`docs/hayalet_ekonomisi_v44_frozen.md` bu projenin TEK DOGRULUK KAYNAGIDIR.
Motorun ve konsol oyununun tam kaynagi o belgenin icinde ```python fence'leri
arasinda gomulu durur; diskte ayrica bir kopyasi YOKTU ve dort test betigi de
onu import ettigi icin hicbiri calismiyordu.

Bu betik fence'leri bulur ve iki dosyayi yeniden uretir:

    docs/...frozen.md  --[blok 0]-->  python/hayalet_ekonomi_motoru_v43.py
                       --[blok 1]-->  python/hayalet_ekonomisi_oyunu_v32.py

TASARIM KARARI: cikarilan dosyalara BASLIK YORUMU EKLENMEZ. Boylece
    <cikti dosyasi satiri N>  ==  <markdown satiri N + ofset>
bagintisi bozulmaz ve port sirasinda "md:4602" gibi bir referans dogrudan
motor dosyasindaki satira cevrilebilir. Ofset her kosuda ekrana basilir.

Fence konumu ARANIR, sabit satir numarasi kullanilmaz: belge duzenlenirse
betik yine dogru calisir. Beklenen blok sayisi 2'den farkli cikarsa hata verir.

Kullanim:
    python tools/extract_sources.py            # cikar ve yaz
    python tools/extract_sources.py --check    # yazma, mevcut dosyalarla karsilastir
"""

import hashlib
import os
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BELGE = os.path.join(KOK, "docs", "hayalet_ekonomisi_v44_frozen.md")

# blok sirasi -> hedef dosya. Belgedeki bolum 12 (motor) ve bolum 13 (oyun).
HEDEFLER = [
    ("hayalet_ekonomi_motoru_v43.py", "motor  (belge bolum 12)"),
    ("hayalet_ekonomisi_oyunu_v32.py", "oyun   (belge bolum 13)"),
]


def bloklari_bul(satirlar):
    """```python ile acilan fence bloklarini (govde, ilk_satir_no) olarak dondurur.

    ilk_satir_no 1 tabanlidir ve fence'in KENDISINI degil govdenin ilk satirini
    gosterir; ofset hesabi bunun uzerinden yapilir.
    """
    bloklar = []
    i = 0
    while i < len(satirlar):
        if satirlar[i].rstrip("\r\n") == "```python":
            bas = i + 1
            j = bas
            while j < len(satirlar) and satirlar[j].rstrip("\r\n") != "```":
                j += 1
            if j >= len(satirlar):
                raise SystemExit(f"HATA: satir {i+1}'de acilan fence kapanmamis.")
            bloklar.append((satirlar[bas:j], bas + 1))
            i = j + 1
        else:
            i += 1
    return bloklar


def main():
    kontrol = "--check" in sys.argv

    if not os.path.exists(BELGE):
        raise SystemExit(f"HATA: kaynak belge bulunamadi: {BELGE}")

    with open(BELGE, "r", encoding="utf-8", newline="") as f:
        satirlar = f.readlines()

    bloklar = bloklari_bul(satirlar)
    if len(bloklar) != len(HEDEFLER):
        raise SystemExit(
            f"HATA: {len(HEDEFLER)} python blogu bekleniyordu, {len(bloklar)} bulundu. "
            "Belge degismis olabilir; HEDEFLER listesini gozden gecirin."
        )

    print(f"kaynak : {BELGE}")
    print(f"blok   : {len(bloklar)}\n")

    farkli = False
    for (govde, ilk_satir), (dosya_adi, etiket) in zip(bloklar, HEDEFLER):
        metin = "".join(govde)
        # Satir sonlari LF'e sabitlenir: belge CRLF ile kaydedilmis olsa bile
        # uretilen .py dosyalari platformdan bagimsiz ayni hash'i vermeli.
        metin = metin.replace("\r\n", "\n").replace("\r", "\n")
        yol = os.path.join(KOK, "python", dosya_adi)
        ozet = hashlib.sha256(metin.encode("utf-8")).hexdigest()[:12]
        ofset = ilk_satir - 1

        if kontrol:
            if not os.path.exists(yol):
                print(f"  EKSIK    {dosya_adi}")
                farkli = True
                continue
            with open(yol, "r", encoding="utf-8", newline="") as f:
                mevcut = f.read()
            durum = "AYNI" if mevcut == metin else "FARKLI"
            if durum == "FARKLI":
                farkli = True
            print(f"  {durum:8s} {dosya_adi}")
        else:
            with open(yol, "w", encoding="utf-8", newline="\n") as f:
                f.write(metin)
            print(f"  yazildi  {dosya_adi:34s} {etiket}")
            print(f"           {len(govde):5d} satir   sha256:{ozet}")
            print(f"           satir haritasi:  {dosya_adi}:N  ==  frozen.md:N+{ofset}\n")

    if kontrol:
        print("\nSONUC:", "FARK VAR" if farkli else "tum dosyalar belgeyle ayni")
        sys.exit(1 if farkli else 0)


if __name__ == "__main__":
    main()
