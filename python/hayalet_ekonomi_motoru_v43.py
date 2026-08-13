"""
HAYALET EKONOMİ MOTORU (onceki surum) - Karanlık Devlet Katmanı Sisteme Bağlanmış Sürüm
Cedeplar-UFMG Makrodinamikleri ve E. Ahmet Tonak Marksist Değer Sentezi

Bu modül, doğrusal olmayan diferansiyel denklemleri, sömürü oranlarını, Thirlwall
dış ticaret kısıtlarını, bölüşüm çatışmalarını, kurumsal rejimleri, karanlık devlet
mekanizmalarını ve endojen demografiyi içeren, oyun projelerine doğrudan entegre
edilebilir nesne yönelimli (OOP) simülasyon motorudur.

BİRİM SÖZLEŞMESİ: tüm oran/akım parametreleri TUR BAŞINA tanımlıdır.
1 tur = TUR_YIL yıl. Yıllık karşılık için yillik().

---------------------------------------------------------------------------
onceki surum -> onceki surum DEĞİŞİKLİK LİSTESİ
---------------------------------------------------------------------------

A. SENARYO YÜKLEYİCİ (ölçüm güvenilirliği)
 1. `load_scenario` içinde `random.seed(42)` ve `Random(42)` sabit yazılmıştı;
    GhostEconomyEngine(tohum=N) hiçbir etki yaratmıyor, bütün tohumlar birebir
    aynı sonucu veriyordu. Artık self.tohum kullanılıyor.
 2. Senaryonun oransal ayarları init_simulation()'dan ÖNCE yapılıyordu;
    `c.FX = fx_baslangic*c.Y` satırı bunları eziyordu. turkey_2001'in ana
    öncülü olan "rezerv tükenmiş" (FX = 0.02*Y) ayarı hiç yüklenmiyor,
    FX 0.35*Y olarak başlıyordu. Sıra artık: yapısal -> init -> oransal.
 3. Senaryolar `c.era` atıyor ama `c.q`'ya dokunmuyordu: Türkiye era=4
    (siber-fiziksel) ama q=0.53 (buhar çağı). Çağ atlama koşulu q > q_esik
    olduğu için ilerleme de donuyordu. Yeni `cag_ata()` yardımcısı, ülkenin
    göreli verimlilik konumunu koruyarak q'yu hedef çağla tutarlı kılar.
 4. Aynı tutarsızlık VARSAYILAN dünyada da vardı (Country.era=4, q~0.4-1.0).
    Bu, q'nun çağ 6 tavanına kadar ~200 kat büyümesine ve kapitalist kalan
    ülkelerde %60+ teknolojik işsizliğe yol açıyordu. __init__ artık
    cag_ata(P_BASLANGIC_CAGI) çağırır.

B. KARANLIK DEVLETİN ENDOJENLEŞTİRİLMESİ
 5. `mafya_tolerans` varsayılanı 0.0 olan, motorda hiçbir koşulda değişmeyen
    dışsal bir oyuncu kadranıydı. Oyuncu elle müdahale etmezse katmanın
    tamamı atıldı (1200 turluk varsayılan koşuda uyuşturucu ortalaması 0.0023,
    yani taban). Bu, el kitabının kendi teziyle çelişiyordu: karanlık devlet
    aşırı birikimin SONUCU olan yapısal bir subaptır. Artık kâr sıkışması,
    yatıştırılamayan Omega, baskı aygıtı, meşruiyet ve sendikal güç
    fonksiyonu olarak endojen. Oyuncu `mafya_kilit` ile devralabilir.
 6. Uyuşturucu denklemi: `d_uo = 0.008*uo_sok + ...` ve `uo_sok = 0.015*
    Omega*tolerans` -- katsayı iki kez uygulanıyordu (0.008 x 0.015 = 1.2e-4).
    El kitabının MERKEZİ mekanizması azami gücünde bile işsizlik kanalının
    beşte biri kalıyordu. Ayrıca bastırma terimi uo'ya orantılı değil SABİT
    olduğu için tolerans sürekli bir kadran değil aç/kapa düğmesi gibi
    davranıyordu. Denklem lojistik hale getirildi; yayılım ve bastırma
    ikisi de uo ile orantılı.
 7. Bastırma kapasitesi yalnızca PC'ye (meşruiyet) bağlıydı; PC çöktüğünde
    bastırma sıfırlanıp kaçak bir döngü oluşuyordu. Artık zor aygıtının
    meşruiyetten bağımsız bir tabanı var.

C. KARSERAL DEVLETİN SİSTEME BAĞLANMASI
 8. `cezaevi_orani` hesaplanıyor ve kaydediliyordu ama HİÇBİR ŞEYİ
    ETKİLEMİYORDU -- el kitabının 4. bölümünün tamamı bir çıktı değişkeniydi.
    Dört kanaldan bağlandı:
      (i)   L_etkin: hükümlü nüfus emek arzından düşülür (Itoh: artı-değer
            üretiminin öznesi değil, "atıl sermaye" yönetiminin nesnesi)
      (ii)  Kamu bütçesinde karseral harcama kalemi
      (iii) Eğitim bütçesinin güvenlik harcamasınca dışlanması
      (iv)  Protesto riskinin doğrudan disipliner bastırılması + PC aşınması
 9. Ölçek ampirik çapaya oturtuldu: tavan %2.5 (dünya rekoru ABD ~%0.65).

D. TONAK DEĞER GASBI VE THIRLWALL KANALLARI
10. El kitabı Bölüm 2-3'ün tamamı kodda yoktu. Eklendi:
      - lumpen_pay: illegal/asalak sektörün ekonomideki payı
      - gasp: illegalite primiyle üretken alandan çekilen değer
      - üretken artı-değer s = s_ham*(1-lumpen_pay); AR-GE, birikim ve r
        artık yalnızca bunu görür
      - gasbedilen değer üretken sermayeye değil spekülatif stoka akar
      - süper-sömürü ücret payının TABANINI düşürür
11. Thirlwall: lumpenleşme ihracat gelir esnekliğini düşürür (eps_lumpen),
    ithalat bağımlılığını artırır (pi_lumpen) -> BoP-kısıtlı büyüme daralır.
12. Lumpenleşmenin sınıf tepkisini ve sendikal dokuyu çözme etkisi artık
    POLİTİKA değişkenine değil fiili lumpenleşmeye bağlı. onceki surum'da her ikisi
    de `mafya_tolerans` ile çarpılıyordu; devletin savaştığı ama yine de
    yayılmış bir uyuşturucu ekonomisi hiçbir etki yaratmıyordu.
13. KODEY metrik seti (el kitabı Bölüm 6) hesaplanıp raporlanır:
    s/v, lumpen payı, gasp oranı, atıl öğeler endeksi, Thirlwall eps/pi.
    `kodey_trendi()` bunların zaman seyrini verir.

E. ORGANİK BİLEŞİMİN SÜREKLİLEŞTİRİLMESİ (LTRPF'nin yakıtı)
14. c/v çağ başına SABİT bir basamak fonksiyonuydu ve tavanı 15'ti. Bütün
    ülkeler çağ 6'ya vardıktan sonra organik bileşim doyuyor, kâr oranının
    düşme eğilimi yakıtsız kalıyordu; geri kalan düşüş yalnızca kapasite
    kullanımından geliyordu (1200 turluk koşuda c/v t~300'de 15.0'a dayanıp
    bir daha kımıldamıyordu). Artık c/v, q'nun sürekli bir fonksiyonudur
    (log-log parçalı doğrusal, ÇAĞ TABLOSUNUN KENDİ DEĞERLERİNE çapalı, çağ
    6'nın ötesinde son segmentin eğimiyle ekstrapole; tavan yok). Çağ
    eşiklerinde eski kalibrasyon birebir korunur -- değişen tek şey çağların
    içi ve çağ 6'nın ötesi. Bu, başlangıç çağı seçimini de LTRPF açısından
    önemsizleştirir.

---------------------------------------------------------------------------
DOĞRULAMA (120 turluk oyun ufku)
---------------------------------------------------------------------------
1) Endojen tolerans el kitabının öngördüğü gibi davranıyor: altın çağda kapalı
   (güçlü sendika, yüksek meşruiyet, kârlı birikim), neoliberal ve kriz
   senaryolarında açılıyor.  [tohum 42]

   senaryo             r      pay     iss    org    uyuşt.  cezaevi  tolerans
   golden_age_1950   0.0287  0.498   0.090  0.711  0.0010   0.0026    0.002
   neoliberal_1995   0.0291  0.337   0.255  0.309  0.0040   0.0053    0.086
   turkey_2001       0.0264  0.371   0.342  0.276  0.0055   0.0068    0.076
   socialist_siege   0.0188  0.393   0.422  0.287  0.0066   0.0086    0.115

2) KARŞI-OLGUSAL: katman artık sonucu gerçekten değiştiriyor. Tam tolerans
   altında kâr oranı düşer (değer üretken birikimden çekilir), sendikal doku
   çözülür, işsizlik artar, Thirlwall kısıtı daralır.
   [neoliberal_1995, 5 tohum ortalaması: 1/7/42/99/2024]

   konfigürasyon                 r     pay    iss    org   lumpen   gasp  eps/pi
   katman KAPALI (kilit 0)   0.0291  0.326  0.269  0.309  0.0233  0.0280  1.461
   ENDOJEN                   0.0291  0.326  0.270  0.308  0.0264  0.0316  1.456
   tam tolerans (kilit .85)  0.0276  0.324  0.284  0.280  0.0759  0.0920  1.376

3) LTRPF artık koşunun sonuna kadar yakıtlı (çağ 4'ten başlayan varsayılan
   dünya, 600 tur, 5 tohum):

   tohum   r_ilk    r_son   düşüş   c/v_son  K/Y_son
       1  0.0243   0.0155    -36%     36.99     44.4
       7  0.0236   0.0153    -35%     36.87     44.5
      42  0.0236   0.0156    -34%     37.06     44.2
      99  0.0238   0.0152    -36%     37.02     45.0
    2024  0.0237   0.0155    -35%     37.05     44.5

   1200 turda: r 0.0238 -> 0.0123 (-48%), c/v 10.3 -> 49.6, K/Y 26.8 -> 54.8.
   (onceki surum'da aynı koşuda c/v t~300'de 15.0'a dayanıyor, r yalnızca -17% düşüyordu.)
   120 turluk oyun ufkunda seküler eğilim henüz görünmez -- o pencerede
   konjonktür baskındır -- ama c/v artık orada da hareket eder (6.0 sabit
   yerine 8.08 -> 9.79).

4) Uyuşturucu yaygınlığı ampirik çapada: %0.10 (altın çağ) - %1.26 (tam
   tolerans). Karseral oran %0.26 - %0.86 (dünya rekoru ABD ~%0.65).

---------------------------------------------------------------------------
F. TEKNOLOJİK İŞSİZLİK (onceki surum'dan devralınan yapısal sorun -- ÇÖZÜLDÜ)
---------------------------------------------------------------------------
Belirti: uzun ufukta kapitalist ülkelerde işsizlik %70'e tırmanıp e'nin 0.30
sınırında saturasyona uğruyordu. (onceki surum'da bu gizliydi: 20 ülkenin 17'si
sosyalizme geçip planlı istihdamla maskeliyordu; kapitalist kalan 3 ülkede
işsizlik zaten %60.5'ti.) Beş ayrı eksiklik aynı sonuca çıkıyordu:

15. İÇSEL TEKNİK DEĞİŞME (`ito`). q büyümesi emek piyasasına hiç bakmıyordu.
    Marx'ta (Kapital I, böl. 15) makineleşmenin dürtüsü emek kıtlığı ve ücret
    baskısıdır; yedek ordu şişip ücretler tabana yapıştığında sermayenin emeği
    ikame etme güdüsü zayıflar. Kanal artık iki yönlü ve negatif geri
    beslemeli: düşük istihdam -> yavaş mekanizasyon -> istihdam toparlanır.

16. İŞ SÜRESİ TABANI ÇAĞA BAĞLI (`saat_min_era`). Taban teknolojik düzeyden
    bağımsız 0.32'de sabitti: tam otomasyon çağında bile buhar çağıyla aynı.
    İş-paylaşımı soğurucusu t~450'de tükeniyordu.

17. SABİT SERMAYENİN KRİZDE DEĞERSİZLEŞMESİ (`deger_carpani`). Model
    r = (1-pay)*u/kv özdeşliğine indirgendiği için sermaye yıkımı kâr oranını
    HİÇ yükseltmiyordu; kriz yalnızca yıkıyor, hiçbir şeyi onarmıyordu. Oysa
    Kapital III böl. 14'teki karşı-eğilimler listesinin ilk maddesi budur.

18. FAİZİN KÂR ORANI TAVANI. En belirleyici eksiklik: i_ef koşunun TAMAMINDA
    r'nin üzerinde kalıyordu (i_ef 0.026-0.033 vs r 0.017-0.024). Kâr-faiz
    makası sürekli negatif olunca net birikim g ~0.001'e sıkışıyor ve
    verimlilik artışını karşılayamıyordu. Marx (Kapital III, böl. 22): faiz
    artı-değerin bir bölüşüm biçimidir, üst sınırı kârın kendisidir.
    Tavan 0.80*r + 0.002 olarak konuldu -- geçirgen, dolayısıyla kâr sıkışması
    kanalı (r < i_ef) korunur ama artık ancak r < 0.01 iken, yani GERÇEK bir
    sıkışmada tetiklenir (turların %1'i; tavansız halde %63'ü).

19. Yardımcı düzeltmeler: Taylor kuralına istihdam ayağı (çifte yetki);
    ücret payı tabanı = emek gücünün değeri (0.15 -> 0.28); kredi iştahının
    borç stokuna duyarlı hale getirilmesi; hızlandırıcı 0.030 -> 0.090;
    işgücüne katılım oranı (gizli/durgun yedek ordu, ayrıca raporlanır).

SONUÇ (1200 tur, 5 tohum: 1/7/42/99/2024):

  tohum   r_ilk    r_son   düşüş   c/v_son   işsizlik   saat   katılım  delev%
      1  0.0232   0.0151    -35%    22.46      0.191   0.625    0.920     40%
      7  0.0221   0.0146    -34%    24.62      0.199   0.623    0.918     42%
     42  0.0219   0.0149    -32%    22.45      0.138   0.626    0.934     38%
     99  0.0226   0.0152    -33%    22.55      0.132   0.667    0.948     39%
   2024  0.0218   0.0146    -33%    24.82      0.204   0.622    0.913     44%

İşsizlik artık sürüklenmiyor, %13-20 bandında SALINIYOR; `saat` tabanına
dayanmıyor (0.62-0.67); deleveraging payı %58'den ~%40'a, çökme sayısı
721'den 439'a indi. LTRPF bozulmadı (-32%..-35%).

KALAN SINIRLILIK: 120 turluk ufukta senaryolar arası İSTİHDAM farkı zayıf
(altın çağ 0.020 vs neoliberal 0.017). Ayrışma artık bölüşüm değişkenlerinde
taşınıyor (ücret payı 0.472 vs 0.367; örgütlülük 0.716 vs 0.234). Neoliberal
odada daha yüksek işsizlik isteniyorsa kaldıraçlar: kurum bazlı `hizlandirici`
veya `kredi` katsayıları.
"""

import math
import random
import zlib
import statistics
from dataclasses import dataclass, field

TUR_YIL = 0.27  # 1 tur = ~0.27 yil (yaklasik 3.2 ay)

def yillik(x_tur):
    """Tur basi bir oranin yillik bilesik karsiligi."""
    return (1.0 + x_tur) ** (1.0 / TUR_YIL) - 1.0

# =====================================================================
# TEKNOLOJİK ÇAĞLAR (ERAS) VE BAŞLANGIÇ DEĞERLERİ
# =====================================================================
# Oyunun basladigi cag. Country.era ile birlikte degistirilirse cag_ata()
# q degerlerini otomatik olarak bu cagla tutarli hale getirir.
# Kampanya: Sanayi Devrimi'nden 2100'e. 340 yil / 0.27 ~= 1260 tur.
SURUM = "v4.4-Frozen"          # Tek surum kimligi: onceki v4.3-A/v4.3-R/v4.4 karisikligi
                        # temizlendi. Butun rapor ve deney kimlikleri bunu kullanir.
BASLANGIC_YILI = 1760
BITIS_YILI = 2100
KAMPANYA_TURU = int(round((BITIS_YILI - BASLANGIC_YILI) / TUR_YIL))
P_BASLANGIC_CAGI = 1
# yil_alt / yil_ust: TARIHSEL BANT (karar: "icsel ama tarihsel bant disina cikamaz").
# Cag atlama ICSELDIR (q > q_esik) ama banda cakilidir: yil_alt'tan once hicbir
# kosulda atlanamaz, yil_ust gecildiginde teknolojik gecikme ne olursa olsun
# atlanir. Boylece hizli gelisen bir oyuncu 1900'de tam otomasyona varamaz,
# geride kalan bir dunya da 2100'de buhar caginda kalmaz.
# Capalar: 2. Sanayi Devrimi (~1840-1905), savas sonrasi otomasyon (~1925-75),
# BIT devrimi (~1980-2015), yapay zeka (~2000-2030), tam otomasyon (~2072-2088).
#
# CAG 5 UZUN, CAG 6 KISA. Ilk kurulusta tersiydi (cag 5 ~35 yil, cag 6 ~55 yil)
# ve catisma cag 6'da kumeleniyordu. Oysa asil calkanti caginin YAPAY ZEKA VE
# ROBOTIK gecis donemi olmasi gerekir: otomasyon emegi yerinden etmeye baslamis
# ama deger uretimi hala canli emege bagli -- azami celiski bolgesi. Gunumuz
# bunun henuz basinda oldugu halde ticaret savaslari, cip ambargolari, tekellesme
# ile acik kaynak arasindaki catisma ve tirmanan jeopolitik kriz uretiyor.
# Cag 6 ise yalnizca SON KAPISMA olmalidir: tekno-baronlarin son barutlariyla
# saldirisi ve kazanmasi ya da yenilmesi. Bu yuzden cag 5 ~2010-2072 (60+ yil),
# cag 6 ~2072-2100 (28 yil).
ERAS = {
    1: {"name": "1.0 Buhar",      "cv": 1.0,  "qg": 0.0045, "pke": 0.20, "q_esik": 0.0,   "q_tavan": 4.0,   "kent": 0.15, "yil_alt": 1760, "yil_ust": 1760},
    2: {"name": "2.0 Elektrik",   "cv": 2.2,  "qg": 0.0075, "pke": 0.35, "q_esik": 2.6,   "q_tavan": 8.0,   "kent": 0.45, "yil_alt": 1840, "yil_ust": 1905},
    3: {"name": "3.0 Otomasyon",  "cv": 3.8,  "qg": 0.0095, "pke": 0.50, "q_esik": 5.2,   "q_tavan": 17.0,  "kent": 0.65, "yil_alt": 1925, "yil_ust": 1975},
    4: {"name": "4.0 Siber-fiz.", "cv": 6.0,  "qg": 0.0120, "pke": 0.75, "q_esik": 10.5,  "q_tavan": 36.0,  "kent": 0.78, "yil_alt": 1980, "yil_ust": 2015},
    5: {"name": "5.0 Insan-YZ",   "cv": 9.5,  "qg": 0.0145, "pke": 0.90, "q_esik": 21.0,  "q_tavan": 80.0,  "kent": 0.86, "yil_alt": 2000, "yil_ust": 2030},
    6: {"name": "6.0 Tam otom.",  "cv": 15.0, "qg": 0.0175, "pke": 0.98, "q_esik": 42.0,  "q_tavan": 200.0, "kent": 0.92, "yil_alt": 2072, "yil_ust": 2088},
}

# =====================================================================
# ORGANİK BİLEŞİM: c/v ARTIK ÇAĞ İÇİNDE SÜREKLİ  (onceki surum)
# =====================================================================
# onceki surum'a kadar c/v çağ başına SABİT bir basamak fonksiyonuydu ve tavanı 15'ti.
# Sonuç: bütün ülkeler çağ 6'ya vardıktan sonra organik bileşim doyuyor, kâr
# oranının düşme eğilimi yakıtsız kalıyordu -- geri kalan düşüş yalnızca
# kapasite kullanımından geliyordu (1200 turluk koşuda c/v t~300'de 15.0'a
# dayanıp bir daha hiç kımıldamıyordu).
#
# Artık c/v, q'nun sürekli bir fonksiyonudur: makineleşme ilerledikçe sabit
# sermayenin değişken sermayeye oranı pürüzsüz yükselir ve TAVANI YOKTUR.
#
# Çapalar ÇAĞ TABLOSUNUN KENDİ DEĞERLERİDİR: her çağın c/v'si o çağa giriş
# eşiğindeki q ile eşleştirilir. Bu yüzden çağ eşiklerinde eski kalibrasyon
# birebir korunur; değişen tek şey çağların İÇİ ve çağ 6'nın ÖTESİ.
CV_CAPALARI = [(max(ERAS[e]["q_esik"], 0.5), ERAS[e]["cv"]) for e in sorted(ERAS)]


def organik_bilesim(q):
    """c/v'yi q'nun sürekli fonksiyonu olarak verir (log-log parçalı doğrusal).

    Çağ 6'nın çapasının ötesinde son segmentin eğimiyle ekstrapole edilir;
    böylece eğilim koşunun sonuna kadar yakıtlı kalır.
    """
    q = max(q, 1e-6)
    def _egim(a, b):
        return math.log(b[1]/a[1])/math.log(b[0]/a[0])

    if q <= CV_CAPALARI[0][0]:
        e = _egim(CV_CAPALARI[0], CV_CAPALARI[1])
        return max(0.05, CV_CAPALARI[0][1]*(q/CV_CAPALARI[0][0])**e)
    for i in range(len(CV_CAPALARI)-1):
        a, b = CV_CAPALARI[i], CV_CAPALARI[i+1]
        if q <= b[0]:
            return a[1]*(q/a[0])**_egim(a, b)
    a, b = CV_CAPALARI[-2], CV_CAPALARI[-1]
    return b[1]*(q/b[0])**_egim(a, b)


# =====================================================================
# KURUMSAL REJİMLER (INSTITUTIONAL REGIMES)
# =====================================================================
KURUMLAR = {
    "liberal": {
        "devlet": 0.45,             # Devlet harcaması çarpanı
        "kredi": 0.55,              # Hanehalkı kredisine erişim kolaylığı
        "finans": 0.85,             # Finansallaşma eğilimi (r < i durumunda spekülasyona kayma)
        "org_eroz": 1.00,           # Sendikal aşınma çarpanı
        "emek_pay": 0.45,           # Verimlilik artışının örgütsüz emeğe yansıyan tabanı
        "sermaye_hareketi": 1.25,   # Cari açığın şiddeti (Altın standardı etkisi)
        "vt_baris": 0.60,           # Emperyalist rüşvet (Emek aristokrasisi koruma payı)
        "v_ucret": 0.05,            # Ücretlilerden alınan gelir vergisi oranı
        "v_kar": 0.08,              # Kârlardan alınan vergi oranı
        "kamu_hedef": 0.05,         # Kamu sermayesi hedef payı (Özelleştirme eğilimi)
        "egitim_pay": 0.04,         # Bütçenin eğitime ayrılan payı
        # onceki surum: Yatirimin kapasite acigina duyarliligi ARTIK KURUMSALDIR.
        # Yuksek deger = kisa yatirim ufku, finans gudumlu, cevrimsel yatirim.
        # Dusuk deger = koordine, sabirli sermaye, devletce duzlestirilmis birikim.
        # Yuksek hizlandirici K salinimlarini buyutur ve mekanizasyonu hizlandirir,
        # dolayisiyla YEDEK SANAYI ORDUSUNU buyutur -- neoliberal odanin daha
        # yuksek issizlik uretmesi bu kanaldan gelir ("zayif talep"ten degil).
        "hizlandirici": 0.100,
        # v4.4: krize KURUMSAL politika tepkisi. Oyuncu disi ulkelerin
        # birbirinden farkli davranmasini saglayan asgari mekanizma budur:
        # duzenli devlet karsi-dongusel harcar, neoliberal devlet kemer siker.
        "kars_dongusel": 0.60,
    },
    "duzenli": {
        "devlet": 1.15, "kredi": 0.45, "finans": 0.35, "org_eroz": 0.35,
        "emek_pay": 0.85, "sermaye_hareketi": 0.45, "vt_baris": 1.25,
        "v_ucret": 0.22, "v_kar": 0.42, "kamu_hedef": 0.28, "egitim_pay": 0.13,
        "hizlandirici": 0.045, "kars_dongusel": 1.70,
    },
    "neoliberal": {
        "devlet": 0.80, "kredi": 1.35, "finans": 1.30, "org_eroz": 1.85,
        "emek_pay": 0.40, "sermaye_hareketi": 1.35, "vt_baris": 0.85,
        "v_ucret": 0.20, "v_kar": 0.24, "kamu_hedef": 0.08, "egitim_pay": 0.10,
        "hizlandirici": 0.200, "kars_dongusel": 0.25,
    },
}

@dataclass
class Params:
    """Motorun global kalibrasyon sabitleri (v5.2 Kalibre Edilmiş Set)."""
    kv0: float = 11.0               # Taban kv (K / tur-hasilasi). Yillik K/Y ~ kv0*TUR_YIL
    kv_us: float = 0.42             # Organik bilesim -> kv esnekligi (EGILIM)
    ucuzlama_max: float = 0.40      # Ucuzlamanin DOYUMLU ust siniri (KARSI-EGILIM)
    ucuzlama_h: float = 3.5         # Ucuzlama doyum yarilanma sabiti
    q_doyum_taban: float = 0.05     # Cag icinde artik teknolojik buyume tabani
    phi: float = 0.16               # Goodwin istihdam-ücret duyarlılığı
    # Istihdam oraninin SAYISAL tabani. v4.4'da 0.30 idi ve otomasyon katmani
    # aciklandiginda surekli bagliyordu -- yani olculen %70 issizlik bir KIRPMA
    # ARTEFAKTIYDI, mekanizmanin gercek buyuklugu gorunmuyordu. Taban artik
    # yalnizca sifira bolmeyi engelleyecek kadar dusuktur.
    e_taban: float = 0.02
    e0: float = 0.90                # Baslangic olceklemesinde kullanilan normal istihdam
    e_norm_hiz: float = 0.004       # Istihdam normunun (hareketli capa) uyum hizi
    pay_degisim_tavani: float = 0.006 # Ucret payinin tur basi maksimum goreli degisimi
    u_normal: float = 0.82          # Normal kapasite kullanimi
    g_duy: float = 0.42             # Yatırımın kâr-faiz makasına duyarlılığı
    # Cag-1 kampanyasi (1760-2100) icin yeniden kalibre edildi. 0.0005 cag-4
    # baslangicli kosuya gore secilmisti; 340 yillik arkta birikim q ve nufus
    # artisini yakalayamiyor, sermaye kalici kisit haline geliyor (Y_K/Y_L
    # 0.85 -> 0.59) ve 19. yuzyil issizligi %28-40'a cikiyordu. 0.0080 ile
    # 19.yy ~%16, 20.yy ortasi ~%18, otomasyon sonrasi ~%62 olur: tarihsel
    # sirlama dogru, artik nufus otomasyonla birlikte olusur.
    g_taban: float = 0.0080         # Taban otonom özel yatırım oranı
    delta_K: float = 0.0205         # Sermaye amortisman oranı (tur basi; ~%7.6/yil)
    tuketim_normu: float = 0.72     # Toplumsal tuketim ozlemi rasyosu
    norm_uyum: float = 0.020        # Tüketim normunun uyum hızı
    norm_agirlik: float = 0.55      # Normun aspirasyona bagliligi
    norm_tavan: float = 0.92        # Tuketim normu ust siniri
    c_ucret: float = 0.95           # Ücretlerden tüketim eğilimi
    c_kar: float = 0.40             # Kârlardan tüketim eğilimi
    devlet_pay: tuple = (0.05, 0.10, 0.22, 0.32, 0.36, 0.38) # Çağlara göre taban kamu bütçe payı
    devlet_kriz: float = 0.08       # Kriz durumunda anti-konjonktürel ek kamu harcaması
    kredi_egilimi: float = 0.300    # Tüketim açığının borçla kapatılma katsayısı
    # onceki surum: 0.555'ten dusuruldu. Eski degerde ulkeler varliklarinin %38-44'unu
    # deleveraging icinde geciriyordu -- bu "birikimi noktalayan krizler" degil,
    # tersi. Cokmelerin TAMAMI hanehalki borcundan geliyor (varlik/Y ortalama
    # 0.16, azami 1.02, balon_limiti 2.2 -- spekulatif balon kanali hic
    # atesllenmiyor), dolayisiyla dogru kaldirac balon_limiti degil kredi tarafi.
    borc_limiti: float = 1.35       # Hanehalkı borç/hasıla üst limit eşiği
    # onceki surum: kredi iştahı borç STOKUNA duyarlı hale getirildi. onceki surum'da hanehalkı,
    # mevcut borcuna hiç bakmadan kalıcı bir tüketim açığını her tur borçla
    # kapatıyordu; borç oranı kaçınılmaz olarak limite çarpıyor, ülkeler turların
    # %80'ini deleveraging içinde geçiriyor ve net birikim negatife dönüyordu.
    # Gerçekte borç servisi kapasitesi doldukça kredi talebi de arzı da çekilir.
    kredi_us: float = 2.0           # Kredi istahinin borc oranina duyarlilik ussu
    i_notr: float = 0.0106          # Nötr politika faiz oranı (tur basi; ~%4.0/yil)
    i_min: float = 0.0032           # Faiz tabanı (~%1.2/yil)
    i_max: float = 0.0360           # Faiz tavanı (~%14/yil)
    tay_u: float = 0.060            # Taylor kuralı kapasite kullanım duyarlılığı
    # onceki surum: Taylor kuralına İSTİHDAM ayağı (çifte yetki). onceki surum'da politika faizi
    # yalnızca kapasite kullanımına ve enflasyona bakıyordu; u ~0.85 iken işsizlik
    # %70 olabiliyor ve merkez bankası hiçbir şey görmüyordu. Faiz kâr oranının
    # üzerinde kalınca net birikim negatife dönüyor, sermaye stoku eriyor ve
    # teknolojik işsizlik kalıcılaşıyordu.
    tay_e: float = 0.014            # Taylor kuralı istihdam duyarlılığı
    # =================================================================
    # FAİZİN KÂR ORANI TAVANI  (Marx, Kapital III, böl. 22)
    # -----------------------------------------------------------------
    # "Faiz oranının azami sınırı kârın kendisidir." Faiz, artı-değerin bir
    # bölüşüm biçimidir; kâr oranını KALICI olarak aşamaz, çünkü aşsaydı para
    # sermaye üretken yatırıma hiç girmez, tamamı faiz getiren sermayeye kayardı.
    #
    # onceki surum'e kadar i_ef Taylor kuralı + risk primlerinden bağımsız olarak
    # belirleniyordu ve 1200 turluk koşunun TAMAMINDA r'nin üzerinde kalıyordu
    # (i_ef 0.026-0.033 vs r 0.017-0.024). Sonuç: kâr-faiz makası sürekli
    # negatif, net birikim g ~0.001'e sıkışmış, verimlilik artışını karşılayamıyor
    # ve teknolojik işsizlik kalıcılaşıyor. Tavan konunca makas açılır ve
    # birikim yeniden mümkün olur.
    #
    # Tavan geçirgendir: r < faiz_kar_tavani*r + marj koşulu ancak r gerçekten
    # çok düşükken sağlanır, dolayısıyla kâr sıkışması / finansallaşma kanalı
    # (r < i_ef) korunur -- yalnızca sürekli değil, GERÇEK bir sıkışmada devreye
    # girer.
    # Marx III/22 tavani YALNIZCA uretken yatirimin esik getirisine (i_reel)
    # uygulanir. Spekulatif finans (i_spec) varlik fiyati beklentisinden
    # fiyatlanir, sanayinin kar oranindan degil -- ona tavan uygulanmaz.
    # onceki surum'de tek bir i_ef vardi ve tavan hepsine birden uygulaniyordu; bu,
    # teknolojik issizligi cozerken finansallasma kanalini (r < i) turlarin
    # %63'unden %1.3'une dusurup spekulatif balonu tamamen olduruyordu.
    # Ayrim bu odunlesmeyi ortadan kaldirir.
    faiz_kar_tavani: float = 0.80   # Faizin karliligin kacta kacini asamayacagi
    faiz_taban_marj: float = 0.0020 # Kar sifira yaklassa da kalan asgari faiz
    tay_pi: float = 1.20            # Taylor kuralı enflasyon duyarlılığı
    pi_hedef: float = 0.0054        # Hedef enflasyon oranı (tur basi; ~%2.0/yil)
    tay_balon: float = 0.0080       # Taylor kuralı varlık balonu reaksiyon katsayısı
    tay_kriz: float = 0.0048        # Kriz anında gevşeme payı
    tay_atalet: float = 0.88        # Faiz atalet katsayısı
    borc_faizi_marj: float = 0.0032 # Hanehalkı kredi risk primi marjı
    delev_hiz: float = 0.045        # Borç eritme (deleveraging) hızı
    delev_sure: int = 20            # Deleveraging sürecinin tur uzunluğu
    fin_pay: float = 0.55           # r < i durumunda spekülasyona kayan artık payı
    # Cag-1 kampanyasinda K'nin buyuklugu farkli oldugu icin yeniden kalibre
    # edildi (Minsky araligi 160 -> 69 yil).
    fin_stok: float = 0.0450        # Atil SERMAYE STOKUNDAN spekulasyona kayan pay
    balon_sonum: float = 0.02       # Spekülatif balon sönümlenme hızı
    balon_limiti: float = 2.2       # Varlık/hasıla mutlak patlama eşiği
    # Spekulatif akim ARTIK STOK GERI BESLEMELIDIR. Saf carpim formu (fin_pay x
    # kredi x finansallasma x beklenti x likidite) doygunluk icermez; boyle bir
    # terim ya tabana yapisir ya tavana kosar, arada anlamli denge kurmaz.
    spec_kredi: float = 0.030       # Kaldiracli spekulasyonun kendi kendini besleme hizi
    beklenti_hiz: float = 0.08      # Varlik getirisi beklentisinin uyarlanma hizi
    beklenti_tavan: float = 0.12    # Beklentinin ust siniri (asiri iyimserlik siniri)
    minsky_esik: float = 1.55       # Minsky kirilganlik bolgesinin baslangici (varlik/Y)
    minsky_sure: int = 14           # Kirilgan + tersine donmus durumda gecmesi gereken tur
    # NOT: tek turluk bir "beklenti < maliyet" kosulu yeterli DEGILDIR. balon_sonum
    # nedeniyle varlik dogal olarak eriyor, dolayisiyla beklenti cogu turda zaten
    # negatif; kosul tek basina "varlik/Y > esik"e indirgenir ve Minsky krizi
    # 14 yilda bire cikar. Sayac, gecici gurultuyu gercek bir donusten ayirir.
    delev_yatirim_soku: float = 0.25# Deleveraging sirasinda ozel yatirimin kesilme orani
    deflasyon: float = 0.35         # Borç-deflasyon sarmalının reel borç artış etkisi
    # onceki surum: hızlandırıcı 0.030 -> 0.090. Talep kısıtlı bir modelde kapasite
    # açığı-yatırım geri beslemesi ana istikrar mekanizmasıdır; 0.030'da bu
    # mekanizma fiilen yoktu ve net birikim uzun ufukta negatife sürükleniyordu.
    hizlandirici: float = 0.090     # Hizlandirici REFERANS degeri (kurumda yoksa kullanilir)
    ticaret_aciklik: float = 0.22   # GSYİH'nin ticarete konu olan payı
    eps0: float = 1.00              # Taban ihracat gelir esnekligi
    pi0: float = 1.00               # Taban ithalat gelir esnekligi
    eps_q: float = 0.85             # Göreli verimlilik -> ihracat artış katsayısı
    pi_q: float = 0.55              # Sanayileşme -> ithalat esneklik düşüş katsayısı
    eps_vt: float = 0.30            # Değer sızıntısı telafi gücü katsayısı
    cari_kats: float = 0.18488      # Cari dengenin büyüme farkına duyarlılığı
    fx_baslangic: float = 0.35      # Başlangıç rezerv/hasıla oranı
    kappa_B: float = 4.0            # Ödemeler dengesi risk primi hassasiyeti
    fx_kriz_uretim: float = 0.22    # Döviz krizinde üretim kayıp şoku
    fx_kriz_sure: int = 30          # Döviz krizinin soğuma turu süresi
    devaluasyon: float = 0.28       # Devalüasyon sonrası rekabetçilik primi
    deval_sonum: float = 0.010      # Devalüasyon etkisinin sönümlenme hızı
    ph_talep: float = 0.100         # Phillips eğrisi talep yönlü enflasyon katsayısı
    ph_maliyet: float = 0.45        # Phillips eğrisi maliyet yönlü enflasyon katsayısı
    ph_beklenti: float = 0.72       # Enflasyonist atalet (beklentiler) katsayısı
    ph_sok: float = 0.0080          # Savaş/Jeopolitik arz şoku şiddeti
    pi_min: float = -0.0068         # Deflasyon alt sınırı (~-%2.5/yil)
    ph_asimetri: float = 0.30       # Aşağı yönde fiyat katılık katsayısı
    pi_max: float = 0.085           # Hiperenflasyon tavan sınırı (~%39/yil)
    w_beklenti: float = 0.85        # Ücretlerin enflasyon telafi katsayısı
    w_org: float = 0.55             # Sendikalılığın telafi gücü çarpanı
    w_katilik: float = 0.3089       # Nominal ücret aşağı yönlü katılık katsayısı
    katilik_cozulme: float = 0.22   # Katılığın tamamen çözüleceği işsizlik eşiği
    # =================================================================
    # CALISMA SURESI: IKI KATMAN
    # -----------------------------------------------------------------
    # v4.4'da `saat` tek bir skalerdi ve `saat=1.0` sabit bir "tam hafta"
    # demekti. Bu iki ayri olguyu birbirine kariştiriyordu:
    #   (a) haftanin TARIHSEL kisalmasi (1760'ta ~70 saat, 2100'de ~30 saat) --
    #       makineleşme ve sinif mucadelesinin uzun donem kazanimi;
    #   (b) IS PAYLASIMI marji -- krizde herkesin daha az calismasi.
    # Tek skaler oldugu icin (b) sinirsiz genisleyip (a) gibi davraniyor, ve
    # otomasyon fazlasinin TAMAMINI soguruyordu: cag 6'da saat 0.176'ya (haftada
    # ~7 saat) yapisiyor ve issizlik hic olusmuyordu.
    #
    # Artik iki katman ayri:
    #   hafta_norm[era] : cagin normal tam haftasi (tarihsel kisalma)
    #   saat            : o normun icindeki paylasim payi [saat_min, 1.0]
    # Fazla emek saat_min'in altina inemedigi icin ISSIZLIGE donusur --
    # "sermaye isi paylastirmaz, isciyi atar".
    # Fiili haftalik sure = hafta_norm[era] * saat (raporlama icin).
    hafta_norm: tuple = (1.00, 0.86, 0.74, 0.64, 0.55, 0.47)  # cag 1..6
    saat_min: float = 0.85          # Paylasim marjinin alt siniri (normun %85'i)
    # onceki surum: saat tabanı ÇAĞA BAĞLI. onceki surum'da teknolojik düzeyden bağımsız olarak
    # 0.32'de sabitti: tam otomasyon çağında bile iş süresi tabanı buhar çağıyla
    # aynıydı. Sonuç: iş-paylaşımı soğurucusu t~150'de tükeniyor, u 1.0'a
    # dayanıyor ve verimlilik artışını emecek hiçbir mekanizma kalmıyordu.
    # Marx'ın makine bölümünün ve Grundrisse'deki "Makineler Üzerine Parça"nın
    # kendi mantığı budur: otomasyon çalışma gününü kısaltılabilir kılar.
    saat_min_era: float = 0.0       # Kullanilmiyor: tarihsel kisalma artik hafta_norm'da
    saat_org: float = 0.060         # Sendikalılık ve işsizliğin saat indirme gücü
    plan_istihdam: float = 0.97     # Planlı ekonomide hedef istihdam oranı
    saat_geri: float = 0.010        # Aşırı istihdam / dusuk issizlikte saat geri alma katsayısı
    w_verimlilik_taban: float = 0.55# Örgütsüz emeğin verimlilikten aldığı pay
    r_kriz_esigi: float = 0.016     # Karlilik krizi esigi (~%6.3/yil)
    r_kamu_kriz: float = 0.020      # Anti-konjonkturel kamu harcamasi esigi (~%8/yil)
    sv_r_ref: float = 0.048         # Savas kararinda karlilik sikismasi referansi
    stagf_pi_esigi: float = 0.016   # Stagflasyon enflasyon esigi (~%6.3/yil)
    delev_deflasyon: float = 0.008  # Deleveraging doneminin deflasyonist baskisi
    w_org_e: float = 0.006          # Sendikalarin istihdam kaynakli ek ucret basincii
    # v4.4: onceki surum'de frekans siralamasi TERSTI -- kucuk resesyon (50 yil)
    # finansal cokmeden (20 yil) daha seyrekti ve buyuk bunalim fiilen hic
    # olmuyordu (324 yilda 20 ulkede 2 kayit). Resesyon en sik olay olmalidir.
    # RESESYON ARTIK KANONIK TANIMLA OLCULUR (v4.4).
    # Eski olcut `derinlik = 1 - Y_ort/Y_trend` idi; ancak
    # `Y_trend = max(Y_trend*asinma, Y_ort)` oldugu icin hasila BUYURKEN derinlik
    # TAM OLARAK SIFIR olur (medyan 0.0000, p90 0.0000). Bu bir zirve-gorece
    # dususs (drawdown) olcusudur, konjonktur olcusu degil: esigi 0.0075'ten
    # 0.0025'e indirmek resesyon sikligini 30 yildan 29 yila ancak getiriyordu --
    # yani parametre degil TANIM sorunuydu.
    # Yeni olcut: art arda daralan hasila (klasik "iki ceyrek ust uste kucuulme").
    # Bunalim olcutu drawdown olarak KALIR -- ikisi farkli olgulardir.
    res_daralma: float = -0.0015    # Bu buyume hizinin altini daralma sayar
    res_sure: int = 2               # Art arda kac tur daralma resesyon sayilir
    res_bekleme: int = 12           # Ayni resesyonun tekrar tescil edilmemesi icin
    bun_esik: float = 0.105         # Büyük Bunalım (Depresyon) eşiği
    bun_sure: int = 10              # Depresyon tescil süresi
    trend_pencere: int = 30         # Trend hesaplama hareketli ortalama penceresi
    trend_asinma: float = 0.994     # Krizlerde trend aşınma katsayısı
    heg_muafiyet: float = 0.80      # Hegemonun BoPC dış ticaret kısıtından muafiyet oranı
    heg_esik: float = 1.25          # Hegemonya değişimi için güç üstünlüğü rasyosu
    heg_sure: int = 40              # Hegemonya devri için gereken tur süresi
    kg_org_esigi: float = 0.30      # Liberal -> Düzenli rejim geçişi için sendikal baraj
    kg_bunalim_penceresi: int = 60  # Donüşüm için bunalım hafıza süresi
    kg_kar_esigi: float = 0.35      # Düzenli -> Neoliberal geçişi için kârsızlık rasyosu
    kg_stagf_esigi: int = 20        # Ya da gereken stagflasyon birikim süresi
    # v4.4: neoliberal MUTLAK BIR YUTUCU DURUMDU. Cikisin tek kosulu
    # org >= 0.55 idi, uzun donemde org 0.24-0.35 bandinda kaliyor, dolayisiyla
    # 1200 turda 20 ulkede SIFIR kurumsal gecis olusuyordu. Iki degisiklik:
    # (a) baraj sendikal gucun ulasabildigi seviyeye cekildi,
    # (b) ikinci bir cikis yolu eklendi -- yeterince derin bir bunalim,
    #     sendikalar zayif olsa bile rejimi degistirmeye zorlar (1930'lar).
    kg_geri_donus_org: float = 0.38 # Neoliberal -> Düzenli geçiş sendikal barajı
    kg_omega_esigi: float = 0.45    # Ya da bu duzeyde siyasi ofke birikimi
    kg_derin_bunalim: float = 0.20  # Ya da bu derinlikte bir bunalim
    kg_min_sure: int = 80           # Bir kurumsal rejimde kalınması gereken asgari süre
    devrim_acik: bool = True        # Sosyalist devrim mekanizması aktiflik kontrolü
    kg_olasilik: float = 0.10       # Koşullar sağlandığında kurumsal geçiş olasılığı
    # =================================================================
    # LIBERAL REJIME DONUS: CLARKE + POLANYI
    # -----------------------------------------------------------------
    # Olcum: `liberal` 5 tohumun hicbirinde hayatta kalmiyor. Bu bir hata DEGIL,
    # iki kuramin da ongordugu sonuctur:
    #
    #   POLANYI (Buyuk Donusum): "Laissez-faire planlandi." Kendi kendini
    #   duzenleyen piyasa kendiliginden dogmaz; devletce KASITLI olarak insa
    #   edilir. Buna karsilik koruyucu karsi-hareket kendiliginden dogar.
    #   Dolayisiyla liberal rejime ENDOJEN surukleniş olamaz.
    #
    #   CLARKE (Keynesianism, Monetarism and the Crisis of the State):
    #   neoliberal devlet, devletin geri cekilmesi degil YENIDEN YAPILANDIRILMASIDIR;
    #   piyasa disiplinini aktif olarak dayatir. Mudahale aygiti bir kez kurulunca
    #   sokulmez. Yani "asgari devlete donus" diye bir endojen yol yoktur.
    #
    # Sonuc: liberal rejim yalnizca KASITLI BIR SIYASI PROJE olarak kurulabilir --
    # yuksek siyasi sermaye gerektirir ve onu tuketir. Endojen gecis tablosu
    # (liberal -> duzenli <-> neoliberal) degismez. Polanyi'nin cift hareketi
    # zaten duzenli <-> neoliberal salinimi olarak calisiyor (olcum: 333 ve 303
    # gecis, her iki yonde).
    ki_pc_esigi: float = 0.80       # Kasitli kurumsal insa icin gereken siyasi sermaye
    ki_pc_maliyet: float = 0.45     # Insaanin tukettigi siyasi sermaye
    ki_min_sure: int = 60           # Iki kasitli insa arasindaki asgari sure

    # =================================================================
    # SIYASI SERMAYE (PC) — YAPISAL DEGISIKLIGIN PARASI  (§26)
    # -----------------------------------------------------------------
    # PC yalnizca YAPISAL degisiklikleri kisitlar (kurum insasi, rejim duzeyi).
    # Gundelik bolusum kollari (ETG duzeyi, ETG finansmani, plan paylari)
    # siyaseten bedavadir ama IKTISADEN bedel oder: butce, kar orani, birikim.
    #
    # PC iki kaynaktan kazanilir: REFAH (buyume, istihdam, ucret payi) ve
    # ISTIKRAR (dusuk huzursuzluk). v4.4'da PC tur basi sabit +0.025 buyuyor
    # ve yalnizca baski/reform/hapsetmeyle azaliyordu -- performansla hic bagi
    # yoktu, yani "riza" bir sonuç degil bir saat gibi isliyordu.
    pc_hiz: float = 0.035           # PC'nin hedefine yakinsama hizi
    pc_taban: float = 0.10          # Her rejimde bulunan asgari riza
    pc_refah: float = 0.50          # Refah bileseninin agirligi
    pc_istikrar: float = 0.45       # Istikrar bileseninin agirligi
    pc_buyume_ref: float = 0.008    # Tam puan alinan tur basi buyume
    pc_pay_ref: float = 0.45        # Tam puan alinan ucret payi

    # =================================================================
    # POLITIKA GECIKMESI  (§25)
    # -----------------------------------------------------------------
    # Iki katmanli: (a) ILAN -> ETKI arasinda sabit gecikme; komut verildiginde
    # hemen yerlesmeye baslamaz, kurumsal/idari surec kadar bekler. (b) Sonra
    # yerlesme hizi REJIME gore degisir: neoliberal devlet hizli hareket eder
    # (merkezilesmis yurutme, zayif ara kurumlar), duzenli devlet yavas
    # (mutabakat, sendika/sermaye pazarligi, yerlesik kurumlar).
    pol_gecikme: int = 8            # Ilan ile etkinin baslamasi arasindaki tur
    pol_hiz_liberal: float = 1.00
    pol_hiz_duzenli: float = 0.55   # Mutabakat gerektirir -> yavas
    pol_hiz_neoliberal: float = 1.60# Merkezilesmis yurutme -> hizli
    pol_hiz_sosyalist: float = 0.80

    # =================================================================
    # RAKIP AI: EK POLITIKA KOLLARI  (§22, §50)
    # -----------------------------------------------------------------
    # Kurumsal rejime gore kredi, yatirim ve dis ticaret durusu.
    ai_kredi_adim: float = 0.03     # Kredi durusunun tur basi ayari
    ai_yatirim_adim: float = 0.010  # Kamu sermaye hedefinin ayari
    ai_ticaret_adim: float = 0.008  # Dis ticaret acikliginin ayari
    ai_kredi_bant: float = 0.45     # Kurumsal degerden azami sapma
    ai_ticaret_bant: float = 0.12
    # =================================================================
    # RAKIP ULKE POLITIKA AI'SI  (v4.4 alan A)
    # -----------------------------------------------------------------
    # v4.4'da rakip ulkeler yalnizca PARAMETRIK davraniyordu (kars_dongusel).
    # Artik her ulke, kurumsal rejimine gore, oyuncunun kullandigi AYNI genel
    # API uzerinden politika secer: set_temel_gelir, set_plan_profili,
    # set_kurumsal_insa. AI dogrudan durum degiskeni degistirmez (Invariant 7).
    #
    # Karar ilkesi: her rejim kendi CELISKISINI yonetmeye calisir.
    #   duzenli    -> issizlik ve huzursuzlugu bolusumle yatistirir
    #   neoliberal -> karliligi korur, bolusumu sikar, karanliga goz yumar
    #   liberal    -> mudahale etmez
    #   sosyalist  -> kusatma altinda sanayilesir, kitlik altinda tuketime doner
    ai_acik: bool = True            # Rakip ulke AI'si etkin mi
    ai_periyot: int = 12            # Kac turda bir politika gozden gecirilir
    ai_iss_esigi: float = 0.11      # Bolusumcu tepkiyi tetikleyen issizlik
    ai_omega_esigi: float = 0.45    # Yatistirma gerektiren huzursuzluk
    ai_etg_adim: float = 0.02       # ETG'nin tur basi ayarlanma adimi
    ai_etg_tavan_duzenli: float = 0.12
    ai_etg_tavan_neoliberal: float = 0.03
    ai_kitlik_esigi: float = 0.25   # Plancinin tuketime donme esigi
    # -----------------------------------------------------------------
    # CAN SIMIDI MODU: "ETG kapitalizmi ilelebet kurtarabilir mi?"
    # -----------------------------------------------------------------
    # Devlet, Omega'yi devrim esiginin altinda tutmak icin GEREKEN ETG'yi verir.
    # Marksist kriz teorisinde beklenen sonuc: ETG celiskiyi cozmez, ERTELER --
    # cunku arti-degerden odenir ve LTRPF o kaynagi kucultur, otomasyon ise
    # ihtiyaci buyutur. Bir makas. Model bunu VARSAYMAZ, uretmesi beklenir.
    cs_acik: bool = False           # Can simidi modu
    cs_omega_hedef: float = 0.55    # Altinda tutulmak istenen huzursuzluk
    cs_adim: float = 0.004          # ETG'nin tur basi ayarlanma adimi
    cs_tavan: float = 0.40          # Mali olarak denenebilecek azami ETG
    cs_borc_freni: float = 1.60     # Bu kamu borcunun uzerinde ETG artirilamaz
    issizlik_sigortasi: float = 0.55# İşsizlik transfer ödemesi katsayısı
    kamu_borc_limiti: float = 1.10  # Kamu borç/hasıla kemer sıkma barajı
    kemer_siddeti: float = 0.35     # Kemer sıkma bütçe daralma katsayısı
    kamu_temerrut: float = 1.90     # Kamu borç iflas barajı
    pay_tavani: float = 0.66321     # Ücret payı tavan sınırı
    # onceki surum: ücret payının tabanı EMEK GÜCÜNÜN DEĞERİ (geçim düzeyi) ile
    # eşitlendi. onceki surum'da mutlak taban 0.15'ti; örgütlülük zayıfladığında ücret
    # payı %16'ya kadar düşüyordu -- emek gücünün kendini yeniden üretemeyeceği,
    # ampirik olarak hiçbir yerde görülmemiş bir düzey. Marx'ta ücret, emek
    # gücünün değeri etrafında salınır ve bu değerin fiziksel bir alt sınırı
    # vardır. Sonuçları zincirleme idi: ezik ücret payı -> devasa tüketim açığı
    # -> kredi patlaması -> hanehalkı borcu turların %29'unda limitin üstünde
    # -> ülkeler zamanın %82'sini deleveraging içinde -> net birikim negatif
    # -> sermaye erimesi -> kalıcı kitlesel işsizlik.
    pay_taban0: float = 0.28        # Ücret payı mutlak tabanı = emek gücünün değeri
    pay_taban_org: float = 0.22     # Sendikalılığın ücret payı tabanına katkısı
    gecim_tabani: float = 0.28      # Kaçınılmaz asgari tüketim tabanı
    kamu_uyum: float = 0.006        # Kamu bütçesinin hedefe yakınlaşma hızı
    kamu_r_farki: float = 0.55      # Kamu sermayesi kârlılık verimlilik kaybı çarpanı
    kamu_istikrar: float = 0.60     # Kamu yatırımlarının anti-konjonktürel çarpanı
    kamu_verimlilik: float = 0.80   # Kamu yatırımlarının q üretkenlik katsayısı
    kont_esigi: float = 0.0280      # Enflasyon kontrol mekanizması barajı (~%11/yil)
    kont_sure: int = 25             # Fiyat kontrol maksimum tur ömrü
    kont_etki: float = 0.55         # Bastırılan enflasyon oranı
    kont_patlama: float = 0.70      # Kontrol bitince bastırılmış enflasyon patlama şoku
    mor_borc_esigi: float = 1.05    # Dış borç moratoryum barajı
    borc_orani_tavani: float = 3.50 # Borç iflas mutlak tavanı
    dis_borc_tavani: float = 1.60   # Dış borçlanma tıkacı eşiği
    mor_kesinti: float = 0.45       # Moratoryumda silinen borç oranı
    mor_ceza_sure: int = 60         # Finans piyasasından dışlanma tur süresi
    mor_ceza_prim: float = 0.55     # Uygulanan ek risk primi cezası
    nufus_artis: float = 0.0007     # Doğal işgücü artış hızı
    goc_duyarlilik: float = 0.0022  # Bölgeler arası ücret farkı göç katsayısı
    goc_tavan: float = 0.0015       # Bir turda gerçekleşebilecek maksimum göç oranı
    egitim_asinma: float = 0.004    # Nitelik sermaye stoku aşınma hızı
    egitim_q: float = 0.55          # Eğitimin labor productivity q büyümesine katkısı
    egitim_org: float = 0.0016      # Eğitimin işçi örgütlenme bilincine endojen katkısı
    kappa: float = 4.0              # Lojistik protesto fonksiyonu eğim dikliği
    b_pay: float = 3.2              # Sömürü oranının protestoya etkisi (Ahmet Tonak katkısı)
    b_iss: float = 4.5              # İşsizliğin protestoya etkisi (Yedek Sanayi Ordusu etkisi)
    theta: float = 2.05             # Protesto tolerans tabanı sabiti
    a1: float = 0.0060              # Sınıf bilinci birikim katsayısı
    a2: float = 0.0040              # Krizlerin siyasi öfke (Omega) birikimine etkisi
    a4: float = 0.0090              # Baskı/Polis rejiminin Omega geriletme katsayısı
    a5: float = 0.0050              # Reformların Omega yatıştırma katsayısı
    omega_kritik: float = 0.60      # Sosyalist devrim patlama eşiği (Omega >= 0.60)
    omega_sonum: float = 0.0020     # Siyasi öfke sönümlenme hızı
    som_refah: float = 0.035        # Sosyal refah yatıştırma payı
    som_vt: float = 0.55            # Emperyalist rüşvet payının Omega sönümleme gücü
    r_referans: float = 0.030       # Yatıştırma için asgari kârlılık referansı (~%11.5/yil)
    r_refah_olcek: float = 0.020    # Refah yatistirmasinin doyum araligi
    savas_baris_kesinti: float = 0.15 # Savaş durumunda sosyal yatıştırma bütçesi kesintisi
    tepki_esigi: float = 0.30       # Baskı/Polis rejimini tetikleyen gerilim barajı
    # v4.4: 0.85 esigi, PR'ye CARPIMSAL pasifizasyon sonumleyicileri
    # (lumpen_sonum x karseral_sonum, birlikte %30-40 kesinti) eklenmeden ONCE
    # kalibre edilmisti. Sonuc: PR azami 0.877'ye ulasiyor ama 10 tur ust uste
    # 0.85'te kalamiyor; pr_sayac hicbir zaman islemiyor ve 324 yilda 20 ulkede
    # SIFIR devrim oluyor. Esik, sonumlenmis PR olcegine tasindi.
    pr_esik: float = 0.74           # Protesto riski patlama eşiği (Omega=0 iken)
    # ESIK OFKEYE GORE ESNER. Olcum, cag 6'da protesto riskinin MEDYAN OLARAK
    # DAHA YUKSEK (0.494 vs 0.388) olmasina ragmen sabit 0.74 esigini HICBIR
    # turda asmadigini gosterdi (cag 5'te turlarin %3.5'i asiyor). Yani cag 6'da
    # devrim bir kosul degil ESIK problemiydi: kosullar devrim oncesi cag 5'ten
    # cok daha agir (Omega 1.000 vs 0.606, issizlik %57 vs %28, ucret payi 0.284
    # vs 0.532, mesruiyet 0.044 vs 0.205) ama karanlik devletin sonumlemesi
    # PR'nin kuyrugunu esige ulastirmiyordu.
    # Birikmis ofke, patlama icin gereken kivilcimi kucultur: Omega 1.0'a doymus
    # bir toplum, 0.3'teki bir toplumun patlamayacagi bir olayda patlar.
    pr_esik_omega: float = 0.06     # Omega'nin esigi dusurme gucu (izgara)
    pr_esik_min: float = 0.40       # Esigin inebilecegi taban
    pr_sure: int = 10               # Devrim için protestonun sürmesi gereken asgari tur
    org_kent: float = 0.0016        # Kentleşmenin sendikal örgütlenmeye taban katkısı
    org_kriz: float = 0.0022        # Ekonomik krizlerin sınıf örgütlenmesine etkisi
    org_baski: float = 0.0035       # Baskının sendikalar üzerindeki yıkım hızı
    org_erozyon: float = 0.0012     # Hizmetleşmenin sendikal örgütlülüğü aşındırma katsayısı
    org_era_era_erozyon: float = 0.55 # Çağlar ilerledikçe (3.0+) sendikasızlaşma hızı
    org_omega: float = 0.65         # Sendikalılığın devrimci Omega potansiyeline katkısı
    vt_siddet: float = 0.050        # Küresel değer transferinin ölçek çarpanı
    rd_pay: float = 0.14            # AR-GE payı katsayısı
    rd_olcek: float = 30.0          # AR-GE yogunlugunun q'ya aktarim olcegi
    yayilma: float = 0.0025         # Sosyalist devrimlerin yayılma katsayısı
    yayilim_merkez: float = 1.00    # Teknolojik yayilim hizi - Merkez
    yayilim_yari: float = 0.80      # Teknolojik yayilim hizi - Yarı-Çevre
    yayilim_cevre: float = 0.62      # Teknolojik yayilim hizi - Çevre (Orta gelir tuzagi)
    blok_pke_bonus: float = 0.04    # Sosyalist blok içi ticari PKE primi
    plan_g: float = 0.0100          # Sosyalist planlı NET birikim hedefi (tur basi)
    plan_kullanim: float = 0.80     # Planli ekonomide taban kapasite kullanimi
    plan_pke_kullanim: float = 0.16 # Planlama gucunun kapasite kullanimina katkisi
    plan_u_duy: float = 0.045       # Plancinin asiri kapasiteye tepki katsayisi
    g_tavani: float = 0.040         # Net birikim hizi ust siniri
    g_daralma_tavani: float = 0.030 # Net sermaye daralmasi alt siniri
    sos_pay_taban: float = 0.50     # Sosyalist ucret payi hedef tabani
    sos_pay_pke: float = 0.12       # Planlama gucunun ucret payi hedefine katkisi
    sos_pay_hiz: float = 0.010      # Ucret payinin hedefe yakinsama hizi
    sos_kitlik_agirlik: float = 0.55# Sosyalist planlama yetersizliği gerilim katsayısı
    # =================================================================
    # CAG 6 CATALI: ISSIZLIGIN ANLAMI REJIME VE BOLLUGA BAGLIDIR
    # -----------------------------------------------------------------
    # v4.4'da issizlik HER rejimde ayni gerilimi uretiyordu (`b_iss*iss`).
    # Oysa tam otomasyon altinda kimsenin calismadigi durum ayni FIZIKSEL
    # gercek olsa da, kapitalizmde yoksunluk, komunizmde emekten kurtulmadir.
    # Ayni `oto`, ayni `canli_pay`, zit anlam.
    #
    # Cag 6'yi distopya/utopya catalina ceviren mekanizma budur ve ayrica bir
    # "tekno-diktatorluk" ya da "komunizm" etiketi koymayi gerektirmez: ikisi
    # de ayni denklemin iki tarafidir.
    #
    # KOSUL BOLLUKTUR: sosyalist rejimde dusuk istihdam ancak KITLIK DUSUKSE
    # masumdur. Kitlik varken issizlik yine gerilim uretir -- yani planli
    # ekonomi otomasyonu bolluga cevirmeyi basaramazsa o da distopyaya doner.
    sos_iss_bolluk: float = 0.85    # Bollukta issizlik geriliminin sonumlenme orani
    sos_bolluk_esigi: float = 0.10  # Bu kitligin altinda "bolluk" sayilir

    # =================================================================
    # YALNIZ KALAN SOSYALIZMIN IKI YOLU + DUNYA DEVRIMI
    # -----------------------------------------------------------------
    # Tek basina kalmis (blok==1) ve abluka/ambargo altindaki bir sosyalist
    # ekonomi, kitlik biriktikce iki yoldan birine sapar:
    #   (a) RESTORASYON      : rejim kapitalizme doner, parti iktidari kaybeder
    #   (b) PIYASA SOSYALIZMI: parti IKTIDARDA KALIR ama kapitalist birikime
    #       kapilari acar (Cin yolu). Ucret payi duser, kar yukselir.
    # Hangisi olacagini partinin zor aygiti belirler: baski kapasitesi yeterliyse
    # iktidari koruyup ekonomiyi acar, degilse dusar.
    #
    # UYGULAMA NOTU: piyasa sosyalizmi ucuncu bir `rejim` DEGERI DEGILDIR.
    # Motorda 42 ayri rejim kontrolu var; ucuncu deger eklemek hepsini elden
    # gecirmeyi gerektirirdi. Bunun yerine `rejim = "kapitalist"` (butun iktisadi
    # mekanik aynen isler) + `parti_iktidari = True` (siyasi kabuk farkli).
    # Bu ayni zamanda teorik olarak dogru: piyasa sosyalizmi, kapitalist
    # birikimin farkli bir siyasi kabuk icindeki halidir.
    # Karsi devrim: yalnizlik olcutu MUTLAK sayi degil, blok esigidir. Ilk
    # kurulusta `blok <= 1` idi ve varsayilan kampanyada devrimler kumelendigi
    # icin HIC tetiklenmiyordu (8 devrim, 0 restorasyon) -- cag 5 dalgasi
    # kirilmiyor, potansiyel tukeniyor ve cag 6 bos kaliyordu. Karar: cag 5
    # devrimlerinin kabaca YARISI geri alinmali.
    izo_blok_esigi: int = 2         # Bu buyuklukteki bloklar hala kirilgan sayilir
    izo_abluka_kitlik: float = 0.130# Tam ablukanin dogurdugu kitlik (20 tohumda ~%53 geri alma)
    izo_ambargo_kitlik: float = 0.14# Ambargonun dogurdugu kitlik
    izo_kitlik_esigi: float = 0.28  # Yalnizligin sapmaya yol actigi kitlik
    izo_sure: int = 24              # Kosulun kac tur surmesi gerekir
    izo_baski_esigi: float = 0.55   # Bu baski kapasitesinin uzerinde parti kalir
    parti_pay_taban: float = 0.12   # Parti iktidarinda ucret payi tabani
    parti_baski_bonus: float = 0.25 # Parti iktidarinin ek baski kapasitesi
    # -----------------------------------------------------------------
    # DUNYA DEVRIMI: KOMINTERN'IN IKI KOSULU
    # -----------------------------------------------------------------
    # Ilk kurulusta esik "sosyalist ulkelerin dunya hasilasindaki payi > %50"
    # idi. Olcum bunun PRATIKTE ERISILEMEZ oldugunu gosterdi: kusatma altindaki
    # planli ekonomilerin hasilasi kucuk kaldigi icin 4-7 sosyalist ulkeyle bile
    # pay 0.00-0.04'te takiliyor, yani dunya devrimi oyunda hic gerceklesmiyordu.
    #
    # Hasila sarti terk edildi. Yerine iki klasik kosul:
    #   (1) ENTERNASYONAL DAYANISMA: sosyalist pakt var ve REKABET DEGIL
    #       ITTIFAK halinde. Motorda sosyalist ulkeler otomatik muttefik oldugu
    #       icin bu tek basina anlamsiz bir testti; olcut PIYASA SOSYALIZMINE
    #       SAPMA olarak tanimlandi. Parti iktidarini koruyup kapitalist
    #       birikime gecen devlet blokla dayanismaz, rekabet eder
    #       (Cin-Sovyet ayrismasi). Uyum = sosyalist / (sosyalist + piyasa sos.)
    #   (2) KAPITALIZMIN GENEL KRIZI: kapitalist ulkelerin yeterli bir payi
    #       surdurulemez krizde (yuksek huzursuzluk, bunalim, deleveraging +
    #       yuksek issizlik).
    # Iki kosul da dd_sure tur boyunca birlikte surmelidir.
    dd_pakt_esigi: int = 3          # Asgari sosyalist ulke sayisi
    dd_uyum_esigi: float = 0.70     # Paktin asgari uyumu (sapma orani dusuk olmali)
    dd_kriz_esigi: float = 0.45     # Kapitalist ulkelerin bu payi krizde olmali
    dd_omega_esigi: float = 0.60    # Surdurulemez huzursuzluk esigi
    dd_iss_esigi: float = 0.35      # Kriz sayilan issizlik esigi
    dd_sure: int = 20               # Iki kosulun birlikte surmesi gereken tur

    # -----------------------------------------------------------------
    # SOSYALISTLER ARASI REKABET: IDEOLOJIK MESAFE + OYUNCU KARARI
    # -----------------------------------------------------------------
    # Ilk kurulusta paktin tek catlagi piyasa sosyalizmine sapmaydi, bu yuzden
    # `pakt_uyumu` cogu kosuda 1.000 cikiyor ve "rekabet degil ittifak" kosulu
    # fiilen "yeterli sayida sosyalist ulke var mi" sorusuna indirgeniyordu.
    #
    # Rekabetin kosulu artik YALNIZCA IDEOLOJIK FARKLILIKTIR ve olcutu PLAN
    # PROFILI MESAFESIDIR: birikim hizi, tuketimle iliski ve savunma payi
    # uzerindeki hat ayriligi. Cin-Sovyet ayrismasinin tarihsel icerigi tam
    # olarak buydu; modelde serbest bir "ideoloji" degiskeni uydurmaya gerek
    # kalmiyor, mevcut plan vektoru zaten bu hatti tasiyor.
    #
    # REKABET OLUP OLMAYACAGINA OYUNCU KARAR VERIR: ideolojik mesafe yalnizca
    # ZEMINI kurar, durus bir politika secimidir (set_pakt_durusu). AI ulkeler
    # mesafe esigi uzerinde rekabete kayar; oyuncunun ulkesi yalnizca oyuncunun
    # karariyla degisir. Rekabet halindeki ulkeler birbirinin muttefiki olmaz ve
    # blok bonusundan yararlanmaz.
    pakt_mesafe_esigi: float = 0.10 # Bu plan mesafesinin uzerinde AI rekabete kayar
    pakt_durus_hiz: float = 0.05    # AI'nin durus degistirme olasiligi/turu

    # -----------------------------------------------------------------
    # ASIRI URETIM GERILIMI: CAG 5'IN KENDI SURUCUSU
    # -----------------------------------------------------------------
    # Olcum, Omega'nin MONOTON tirmandigini gosterdi: cag 5'te 0.57-0.69'a
    # cikiyor ama devrim esigini cogunlukla cag 6'da geciyordu (yogunluk cag 5'te
    # 0.043, cag 6'da 0.182 devrim/ulke-yuzyil). Yani cag 5 bir hazirlik donemi
    # kaliyor, dalga orada kirilmiyordu.
    #
    # Eksik surucu ASIRI URETIMDIR. Otomasyon fiziksel hasilayi buyutup yeni
    # degeri buzdugu icin gerceklesme makasi cag 5 BOYUNCA acilir (canli emek
    # payi 0.94 -> 0.32). Bu, Marx'in gerceklesme krizidir ve tam olarak
    # gunumuzun tablosudur: yapay zeka-robotik gecisi henuz basindayken bile
    # ticaret savaslari, cip ambargolari ve tirmanan jeopolitik kriz uretiyor.
    # Makas Omega'yi dogrudan beslemeliydi; beslemiyordu.
    #
    # Terim makasin ACILMA HIZINA degil DUZEYINE baglidir ve cag 6'da doyar --
    # cunku orada celiski artik gerceklesme degil, degerin kendisinin yok olusudur.
    asiri_uretim: float = 0.018     # Gerceklesme makasinin Omega'ya katkisi
    asiri_esik: float = 0.15        # Bu makasin altinda gerilim uretmez

    # =================================================================
    # MARKSIST POLITIK OZNE (parti)  — karanlik devletin karsi kuvveti
    # -----------------------------------------------------------------
    # Olcum, cag 6'da devrimin IMKANSIZ hale geldigini gosterdi: Omega 1.000'e
    # doyuyor, issizlik %54, ucret payi 0.29 -- nesnel kosullar azami. Ama
    # protesto riski dusuyor, cunku karanlik devlet (lumpen_sonum) ve karseral
    # aygit (karseral_sonum) protestoyu tam o noktada bastiriyor ve orgutluluk
    # 0.62'den 0.29'a eriyor. Model tekno-diktatorlugun devrimci ozneyi imha
    # ederek kazandigini soyluyordu; kapismanin tek sonucu vardi.
    #
    # Eksik olan KARSI KUVVETTI. `org` sendikalasmadir ve UCRETLI EMEGE baglidir;
    # otomasyon ucretli emegi yok ettikce org da erir. Marksist politik ozne ise
    # sendikanin ulasamadigi yeri orgutler: ISSIZLER KITLESINI -- ki otomasyon
    # altinda buyuyen tam da odur. Ayrica bolme ve yozlastirma politikalarina
    # (uyusturucu, karseral disiplin) dogrudan direnir: bilinclendirme, karanlik
    # devletin sonumleme gucunu kirar.
    #
    #   orgutlu = org + parti*(1-org)   -> parti, sendika disi kitleyi kapsar
    #   sonumleme carpanlari parti_direnc olcusunde zayiflar
    # Yavas kurulur: politik ozne bir kusak isidir. 0.010 ile cag 4te bile 0.16a
    # cikip devrim patlamasi yaratiyordu (24 devrim); asil zemini issizler kitlesi
    # oldugu icin agirligini cag 5-6da tasimasi gerekir.
    parti_hiz: float = 0.0008       # Politik oznenin yerlesme hizi (izgara)
    parti_iss: float = 0.55         # Issizler kitlesinin orgutlenme zemini
    parti_yoksullasma: float = 0.45 # Ucret payi dususunun bilinclendirici etkisi
    # Yoksullasma REFERANSI: ilk kurulusta pay_taban0 (0.28) kullanilmisti ama
    # ucret payi zaten ~0.29'da tabanlaniyor, dolayisiyla terim HIC atesllenmiyor
    # ve parti 0.14'te takiliyordu. Referans insanca bir bolusum duzeyidir.
    parti_pay_ref: float = 0.50
    parti_kriz: float = 0.30        # Kriz deneyiminin katkisi
    parti_baski: float = 0.42       # Baski aygitinin parti uzerindeki yikimi
    parti_lumpen: float = 0.60      # Lumpenlesmenin orgutlenmeyi cozme gucu
    parti_direnc: float = 0.85      # Partinin sonumleme carpanlarini kirma gucu
    parti_tavan: float = 0.90

    # -----------------------------------------------------------------
    # ASIRI URETIM KRIZI (tescil edilen tip)
    # -----------------------------------------------------------------
    # Yuklenen tarihsel kayitla (1825-2023, 27 kriz) karsilastirma, motorun
    # 19. yuzyilini BORC ve DOVIZ krizleriyle gecirdigini gosterdi; oysa donemin
    # baskin bicimi GENEL ASIRI URETIMDIR (1825, 1836-39, 1847, 1857, 1866,
    # 1873-79, 1882-85...). Motorda kayitli bir asiri uretim krizi tipi yoktu.
    #
    # Marx'ta asiri uretim kaybolmaz, YONETILIR: kredi, devlet talebi ve
    # finansallasma onu emer ve donusmus bicimde (borc, balon) geri getirir.
    # Bu yuzden tetikleyici HAM TALEP ACIGIDIR ve emme kapasitesi kurum ile
    # caga bagli oldugundan yer degistirme KENDILIGINDEN cikar: erken caglarda
    # kredi ince ve devlet kucuk oldugu icin acik krize doner; sonra kredi ve
    # finansallasma onu Minsky/borc krizine tercume eder.
    # Kayitli olcum: Minsky araligi 115 -> 88 -> 57 -> 37 yil (finansallasma
    # tarihsel olarak artiyor) -- bu zaten PDF'in 1980 sonrasi tablosuyla uyumlu.
    au_esik: float = 0.10           # Talep aciginin kriz sayildigi esik
    au_sure: int = 3                # Acigin kac tur surmesi gerekir
    au_bekleme: int = 26            # Ayni krizin tekrar tescil edilmemesi icin
    au_omega: float = 0.030         # Krizin sinif gerilimine dogrudan katkisi
    # =================================================================
    # PLAN PROFILI — sosyalist ekonominin ayrisma kaynagi (v4.4 alan B)
    # -----------------------------------------------------------------
    # v4.4'da sosyalist kolun TEK ayrisma kaynagi PKE idi, o da caga bagli
    # oldugu icin butun planli ekonomiler birbirinin ayni davraniyordu.
    #
    # Plan profili, artik urunun RAKIP kullanimlari arasinda bir paylastirmadir;
    # paylar normalize edilir, yani biri artarsa digeri MUTLAKA azalir. Serbest
    # parametre degil, gercek bir plan kisitidir.
    #
    # Planli ekonominin kriz bicimi KITLIK'tir (gerceklesme krizi degil):
    #   kitlik = 1 - (tuketim arzi / tuketim normu)
    # Sanayilesmeci plan yuksek birikim ve hizli teknoloji uretir ama kitlik
    # yaratir; tuketimci plan kitligi giderir ama teknolojik olarak geri kalir
    # ve dis kisit altinda zayiflar. Iki plan da "dogru" degildir.
    plan_pay_yatirim: float = 0.30  # Varsayilan profil: birikim
    plan_pay_tuketim: float = 0.55  # Varsayilan profil: tuketim mallari
    plan_pay_arge: float = 0.10     # Varsayilan profil: AR-GE
    plan_pay_savunma: float = 0.05  # Varsayilan profil: savunma
    plan_yatirim_olcek: float = 3.4 # Yatirim payinin birikim hizina donusumu
    plan_arge_olcek: float = 2.0    # AR-GE payinin verimlilik artisina donusumu
    plan_tuketim_ref: float = 0.55  # Kitligin sifir oldugu tuketim payi
    plan_kitlik_pay: float = 0.55   # Kitligin ucret payi hedefine etkisi
    plan_kitlik_q: float = 0.30     # Kitligin verimlilige (moral/devamsizlik) etkisi
    plan_savunma_ref: float = 0.05  # Notr savunma payi
    plan_hiz: float = 0.03          # Plan profilinin yeni hedefe yakinsama hizi
    sv_carpan: float = 0.35         # Savaş ihtimali global ölçek katsayısı
    sv_taban: float = 0.0006        # Taban otonom savaş çıkma olasılığı
    sv_kar_baskisi: float = 0.055   # Kârlılık krizlerinin savaş kararına etkisi
    sv_kaynak: float = 0.030        # Hammadde/Enerji ihtiyacı savaş ihtimali
    sv_doktrin: float = 0.040       # Saldirganlık doktrini katsayısı
    sv_mudahale: float = 0.35       # Emperyalist müdahale isteği katsayısı
    sv_min_sure: int = 20           # Savaş asgari tur süresi
    sv_max_sure: int = 70           # Savaş azami tur süresi
    sv_seferberlik: float = 0.10    # Savaş seferberlik kapasite kullanım artışı
    sv_tuketim: float = 0.012       # Savaşın sivil ücret payı üzerindeki kesinti etkisi
    sv_yikim: float = 0.006         # Savaşta sermaye ve altyapı yıkım katsayısı
    sv_yorgunluk: float = 0.012     # Savaş yorgunluğunun halk öfkesine etkisi
    sv_yenilgi_omega: float = 0.15  # Savaş yenilgisinin Omega patlatma gücü
    # =================================================================
    # ASKERI MUDAHALE KANALI — cag 5 dalgasini kiran kuvvet
    # -----------------------------------------------------------------
    # Olcum: cag 6'da HIC kapitalist ulke kalmiyor (10 tohumun hepsinde 0/20).
    # Cag 5 dalgasi butun dunyayi suupuruyordu ve uc mekanizma birbirini
    # besleyerek tek yonlu bir cig olusturuyordu:
    #   parti guclenir -> devrim artar -> blok buyur -> izolasyon olmaz
    #   -> karsi devrim duser -> cag 6'da devrilecek kimse kalmaz
    # Abluka->kitlik kanali YALNIZ kalmayi gerektirdigi icin buyuk bloklara
    # islemiyordu. Oysa buyuk bir sosyalist blok, tam da buyuk oldugu icin
    # topyekun savasi davet eder.
    #
    # Iki tikaniklik vardi:
    #  (1) Yenilgi->restorasyon `PKE < kd_pke_esigi` sartina bagliydi; PKE
    #      0.98-0.99 seyrettigi icin ASLA saglanmiyordu. Askeri olarak ezilen
    #      bir devlet, planlama kapasitesi ne olursa olsun restore edilebilir --
    #      belirleyici olan yenilginin AGIRLIGIDIR, plan gucu degil.
    #  (2) Mudahale yalnizca devrimden tam 3 tur sonra, tek seferlik tetikleniyor
    #      ve blok buyuklugune bakmiyordu. Artik sosyalist blok buyudukce
    #      kapitalist merkezin mudahale istegi de buyur.
    kd_pke_esigi: float = 0.62      # (artik yalnizca IC cokus yolu icin)
    kd_yenilgi_orani: float = 0.58  # Bu guc oraninin altinda ezilme sayilir (izgara)
    kd_askeri_olasilik: float = 0.60# Ezilen sosyalist devletin restore edilme ihtimali
    sv_blok_tehdidi: float = 4.50   # Sosyalist blok payinin mudahale istegini artirmasi (izgara)
    sv_mudahale_pencere: int = 40   # Devrim sonrasi mudahaleye acik tur araligi
    kd_olasilik: float = 0.55       # Müdahale sonrası karşı-devrim ihtimali
    ab_vt: float = 0.75             # Ablukanın değer transferi kesintisi etkisi
    ab_uretim: float = 0.12         # Ablukanın üretim üzerindeki şok etkisi
    amb_q: float = 0.45             # Ambargonun teknolojik q ilerlemesini kesme oranı
    amb_sos_esigi: int = 1          # Ambargo için gereken minimum sosyalist ülke sayısı
    it_esik: float = 0.45           # İttifak kurulması için gereken sosyalist tehdit barajı
    it_kopma: float = 0.02          # İttifakların kopma olasılığı katsayısı
    gecis_yikim: float = 0.10       # Çağ geçişlerinde gerçekleşen yaratıcı yıkım şoku
    gecis_sok_sure: int = 30        # Yaratıcı yıkım soğuma süresi
    gecis_omega: float = 0.080      # Yaratıcı yıkımın halk öfkesine etkisi
    # =================================================================
    # KARANLIK DEVLET: ENDOJEN MAFYA TOLERANSI  (onceki surum)
    # -----------------------------------------------------------------
    # El kitabi Bolum 1: karanlik devlet, birikim rejiminin tikanikligini
    # asmak icin kullanilan YAPISAL bir subaptir -- yani asiri birikimin
    # SONUCUDUR. onceki surum'da `mafya_tolerans` varsayilani 0.0 olan, motorda hicbir
    # kosulda degismeyen dissal bir oyuncu kadraniydi; oyuncu elle mudahale
    # etmezse butun karanlik politika katmani atil kaliyordu.
    kd_hiz: float = 0.020           # Tolerans stokunun hedefe yakinsama hizi
    kd_taban: float = 0.02          # Her devlette bulunan asgari gecirgenlik
    kd_tikanma: float = 0.55        # Kar sikismasinin (i_ef - r) tolerans hedefine etkisi
    kd_tikanma_olcek: float = 0.020 # Sikismanin normalize edildigi aralik
    kd_omega: float = 0.60          # Baska araci kalmamis sinif ofkesinin etkisi
    kd_baski: float = 0.35          # Baski aygitina sahip devletin bu araca yatkinligi
    kd_mesruiyet: float = 0.30      # Demokratik mesruiyetin (PC) frenleyici etkisi
    kd_org: float = 0.45            # Guclu sendikal orgutlenmenin frenleyici etkisi
    kd_tavan: float = 0.95

    # =================================================================
    # UYUSTURUCU YAYILIMI (lojistik)  (onceki surum)
    # -----------------------------------------------------------------
    # onceki surum denklemi: d_uo = 0.008*uo_sok + ... , uo_sok = 0.015*Omega*tolerans
    # Katsayi iki kez uygulaniyor (0.008 x 0.015 = 1.2e-4); el kitabinin MERKEZI
    # mekanizmasi azami gucunde bile issizlik kanalinin beste biri kaliyordu.
    # Ayrica bastirma terimi uo'ya oranti degil SABIT oldugu icin tolerans bir
    # kadran degil ac/kapa dugmesi gibi davraniyordu.
    # Kalibrasyon capasi: gercek dunyada bagimlilik orani ~%0.2 (siki denetim)
    # ile ~%3-4 (asiri narko-devlet) arasindadir. uo_tavan bu ust siniri kurar.
    uo_omega: float = 0.0060        # Devletin goz yummasi x sinif ofkesi (MERKEZI KANAL)
    uo_iss: float = 0.0045          # Yedek sanayi ordusu kanali
    uo_iss_esik: float = 0.06       # Bu issizligin uzeri yayilimi besler
    uo_gecim: float = 0.0055        # Ucretin gecim tabaninin altina dusmesi
    uo_bastirma: float = 0.35       # Devletin fiili bastirma kapasitesi
    uo_bastirma_taban: float = 0.35 # Mesruiyet cokse de kalan zor aygiti kapasitesi
    uo_cozulme: float = 0.045       # Dogal cozulme / tedavi / yaslanma
    uo_tavan: float = 0.060         # Doygunluk siniri (%6 = asiri narko-devlet)

    # =================================================================
    # KARSERAL DEVLET  (Itoh: "atil ogelerin" yonetimi)  (onceki surum)
    # -----------------------------------------------------------------
    # onceki surum'da cezaevi_orani hesaplaniyor ve gecmise kaydediliyordu ama HICBIR
    # SEYI ETKILEMIYORDU -- el kitabinin 4. bolumunun tamami bir cikti
    # degiskeniydi. onceki surum'de dort kanaldan sisteme baglanir.
    cezaevi_ref: float = 0.010      # Metriklerin normalize edildigi referans oran
    cezaevi_tavan: float = 0.025    # Karseral oranin ust siniri
    karseral_taban: float = 0.0008  # Her toplumda bulunan asgari hukumlu orani
    karseral_uo: float = 0.100      # Uyusturucunun hapsetmeye donusme katsayisi
    karseral_iss: float = 0.015     # Issizligin hapsetmeye donusme katsayisi
    karseral_baski: float = 0.020   # Polis baskisi x sinif ofkesinin katkisi
    karseral_maliyet: float = 1.30  # Hukumlu basina kamu harcamasi katsayisi
    karseral_egitim_disla: float = 0.45  # Guvenlik harcamasinin egitimi disllama orani
    karseral_disiplin: float = 0.20 # Protesto riskini sonumleme gucu
    karseral_mesruiyet: float = 0.006    # Kitlesel hapsetmenin PC asindirma hizi

    # =================================================================
    # TONAK DEGER GASBI: illegal / lumpen sektor  (onceki surum)
    # -----------------------------------------------------------------
    # El kitabi Bolum 2-3: illegal sektorde AR-GE sifir, kar orani olaganustu
    # (illegalite primi), toplumsal verimlilik negatif. Arti-deger sanayiden
    # "deger yakalayan" asalak alanlara kayar. onceki surum'da bu kanal hic yoktu;
    # uyusturucu yalnizca `nitelik`i dusuruyordu.
    lumpen_carpani: float = 6.0     # Kullanim orani -> sektor payi donusum katsayisi
    lumpen_tavan: float = 0.20      # Illegal sektorun ekonomideki azami payi
    illegalite_primi: float = 1.80  # Illegal sektorun olaganustu kar orani carpani
    gasp_varlik: float = 0.12       # Gasbedilen degerin spekulatif stoka akan payi
    gasp_taban: float = 0.25        # Super-somurunun ucret payi TABANINI dusurme gucu
    lumpen_sonum_gucu: float = 1.80 # Lumpenlesmenin sinif tepkisini sonumleme gucu
    lumpen_org: float = 0.060       # Lumpenlesmenin sendikal dokuyu cozme gucu
    eps_lumpen: float = 0.60        # Ihracat gelir esnekligini dusurme (Thirlwall)
    pi_lumpen: float = 0.45         # Ithalat gelir esnekligini artirma (Thirlwall)

    # =================================================================
    # İÇSEL TEKNİK DEĞİŞME YÖNÜ (Marx / Habakkuk)  -- teknolojik işsizlik çözümü
    # -----------------------------------------------------------------
    # onceki surum'e kadar q büyümesi yalnızca AR-GE yoğunluğuna, çağa ve eğitime
    # bağlıydı; EMEK PİYASASINA hiç bakmıyordu. Oysa Marx'ta (Kapital I, 15.
    # bölüm) makineleşmenin dürtüsü emek kıtlığı ve ücret baskısıdır: yedek
    # sanayi ordusu şişip ücretler tabana yapıştığında sermayenin emeği ikame
    # etme güdüsü zayıflar, emek-yoğun teknikler kârlı hale gelir.
    #
    # Bu eksiklik modelde tek yönlü bir çöküş üretiyordu: q durmadan büyüyor,
    # `saat` tabanına yapışıp soğurmayı bırakıyor, u 1.0'a dayanıyor ve
    # istihdamı dengeleyecek HİÇBİR mekanizma kalmıyordu (t=600'de %69 işsizlik).
    # Artık kanal iki yönlü ve NEGATİF geri beslemeli: düşük istihdam ->
    # yavaş mekanizasyon -> istihdam toparlanır -> mekanizasyon hızlanır.
    # =================================================================
    # ICSEL TEKNIK DEGISME (ito) — DORT SURUCU
    # -----------------------------------------------------------------
    # v4.4'da `ito` YALNIZCA yurtici ucret-maliyet hesabiydi:
    #     ito = (pay/ito_pay_ref) * (e/ito_e_ref)
    # Bu, Marx'in Kapital I/15'teki gozlemine (makine, ikame ettigi ucretten
    # ucuzsa devreye girer) sadikti ama mekanizasyonun diger UC surucusunu
    # disariida birakiyordu. Sonucu agirdi: emek ucuzlayinca mekanizasyon
    # duruyor, teknolojik issizlik kendiliginden cozuluyor ve tam otomasyon
    # cagi hicbir kalici artik nufus uretmiyordu.
    #
    # Eksik olanlar:
    #  (2) REKABETIN ZORLAYICI YASASI (Kapital I/12 ve III). Bireysel kapitalist
    #      ustun yontemi getirince ek arti-kar kapar; digerleri ya izler ya
    #      batar. Bu bir maliyet tercihi degil, "dis zorlayici yasa"dir. Ayni sey
    #      ulkeler arasi rekabette Thirlwall kisiti uzerinden isler: frontier'in
    #      gerisine dusen ulke ihracat esnekligini kaybeder.
    #  (3) MAKINENIN UCUZLAMASI. Sabit sermaye ucuzladikca ikame esigi duser;
    #      seri robot uretimi ve ucuzlayan enerji tam olarak budur. Ucret
    #      dusse bile makine daha hizli ucuzluyorsa ikame surer.
    #  (4) DEMOGRAFIK KITLIK. Yaslanan nufusta isgucu daralir; emek arzinin
    #      kendisi kit oldugunda ucret sinyalinden bagimsiz olarak ikame baskisi
    #      dogar.
    #
    # Dortu de TOPLANIR. Bu yuzden ucret payi coktugunde (1) sonse bile (2),(3),
    # (4) mekanizasyonu surdurur -- "durmak isteseler de duramazlar".
    ito_taban: float = 0.10         # Emek bol ve ucuzken bile suren otonom mekanizasyon
    ito_pay_ref: float = 0.45       # Mekanizasyon durtusunun notr oldugu ucret payi
    ito_e_ref: float = 0.90         # Mekanizasyon durtusunun notr oldugu istihdam
    ito_tavan: float = 1.60         # Azami hizlanma
    ito_rekabet: float = 1.30       # (2) Frontier'in gerisinde kalmanin zorlayiciligi
    ito_makine: float = 1.10        # (3) Sabit sermayenin ucuzlamasinin ikame etkisi
    ito_demografi: float = 0.90     # (4) Isgucu daralmasinin ikame baskisi
    ito_nufus_ref: float = 0.004    # Notr dogal nufus artisi (tur basi)

    # =================================================================
    # OTOMASYON STOKU — ROBOT KULLANIM DEGERI URETIR, DEGER URETMEZ
    # -----------------------------------------------------------------
    # TEMEL KURAL (Marx): arti-degerin tek kaynagi canli emektir. Makine
    # SABIT SERMAYEDIR; kendi degerini urune aktarir, YENI DEGER YARATMAZ.
    # Bu yuzden robotlar emek arzina EKLENMEZ -- eklenselerdi deger kaynagi
    # olurlardi ve LTRPF'nin butun temeli cokerdi.
    #
    # Dogru kurulus iki katmani AYIRIR:
    #   FIZIKSEL katman : robotlar uretim kapasitesini buyutur (kullanim degeri)
    #   DEGER katmani   : yeni deger yalnizca canli emekten gelir
    #
    # Sonuc, Marx'in Grundrisse'deki "hareketli celiskisi"dir: sermaye emek
    # zamanini asgariye indirirken onu zenginligin tek olcusu olarak korur.
    # Model bunu uretmelidir: devasa fiziksel hasila, buzulen yeni deger,
    # sifira giden kar orani, kalici artik nufus ve kronik asiri uretim.
    #
    #   canli_pay = canli emek / (canli emek + robot esdegeri)
    #   V (yeni deger) = Y * canli_pay      <- yalnizca canli emek
    #   v = pay*V   (ucretler)      s = (1-pay)*V   (arti-deger)
    #   r = s/K
    # canli_pay -> 0 iken V -> 0, s -> 0, r -> 0. Fiziksel hasila devasa olsa da.
    oto_esik_era: int = 5           # Otomasyon stokunun basladigi cag
    # Cag 6 kisaltilinca (2072-2100, ~28 yil) otomasyonun yerlesmeye vakti
    # kalmadi ve oto 0.57 -> 0.45 dustu. Karar "otomasyon bir kusak boyunca
    # yerlessin" idi; kusak ~28 yil oldugu icin hiz buna gore artirildi.
    oto_hiz: float = 0.030          # Otomasyon payinin yerlesme hizi
    oto_tavan: float = 0.80         # Sermayenin azami emek-ikame eden payi
    # BOYUTSAL NOT: robot_esdeger = oto_verim*oto*K/q ve K/q ~ kv*emek_esdeger
    # oldugundan robot/emek orani ~ oto_verim*oto*kv'dir. kv~22 ile oto_verim=0.55
    # secmek bu orani 9.3'e cikariyordu -- canli_pay %4'e cokuyor, issizlik %93'e
    # firliyor ve hem `e` hem `saat` tabanina yapisiyordu. 0.040, tam otomasyonda
    # canli emegin fiziksel hasilaya katkisini ~%25'e indirir: robotlar isin
    # buyuk cogunlugunu yapar ama hicbir degisken tabanina kirpilmaz.
    # Cag-1 kampanyasi (1760-2100) icin yeniden kalibre edildi. 0.040 cag-4
    # baslangicli 1200 turluk kosuya gore secilmisti; 340 yillik arkta otomasyonun
    # yerlesme suresi kisaldigi icin ayni deger issizligi ancak %56'ya cikariyor.
    # 0.110, tam otomasyonda issizligi ~%78'e tasir -- tasarim karari olan
    # "neredeyse tam issizlik" budur.
    oto_verim: float = 0.110        # Robot sermayesinin fiziksel emek esdegeri
    oto_canli_taban: float = 0.02   # Tam otomasyonda bile kalan canli emek payi

    # =================================================================
    # İŞGÜCÜNE KATILIM ORANI  -- Marx'in "gizli" ve "durgun" yedek ordusu
    # -----------------------------------------------------------------
    # onceki surum'e kadar L_max saf demografikti: uzun süreli işsizlik işgücünden
    # çıkışa yol açmıyordu. Gerçekte cesareti kırılmış işçi, uzayan eğitim,
    # erken emeklilik ve maluliyet aktif işgücünü daraltır. Bu, işsizliği
    # "çözmez" -- görünür işsizliği düşürüp gizli yedek orduya kaydırır --
    # bu yüzden katılım oranı ayrıca raporlanır.
    # =================================================================
    # EVRENSEL TEMEL GELIR (ETG)
    # -----------------------------------------------------------------
    # Artik nufusu yonetmenin UCUNCU teknigi. Modelde zaten iki tanesi var:
    # is paylasimi (saat) ve karseral/narkotik pasifizasyon (karanlik devlet).
    # Olcum, cag ilerledikce Omega'nin monoton biriktigini ve HIC cozulmedigini
    # gosteriyor (0.029 -> 0.592); yani yonetilmeyen gercek bir gerilim var.
    #
    # ETG tek yonlu bir "iyi sey" DEGILDIR. Es zamanli UC CELISKILI etkisi
    # vardir ve hangisinin baskin olacagi PARAMETRE DEGIL, orgutlulugun (org)
    # endojen fonksiyonudur:
    #
    #  1) UCRET SUBVANSIYONU (Marx, Kapital I/25, Speenhamland-Yoksullar Yasasi):
    #     gecimin bir kismi toplumsallasinca emek gucunun DEGERI duser; ucret
    #     tabani asagi iner, s/v yukselir. Sermaye el koyar. org DUSUKKEN baskin.
    #  2) METASIZLASMA (Gorz): rezervasyon ucreti yukselir, iscinin reddetme
    #     kapasitesi artar; asagi yonlu ucret katiligi guclenir. org YUKSEKKEN baskin.
    #  3) PASIFIZASYON: Omega'yi birikim tikanikligini COZMEDEN bastirir --
    #     karseral/narkotik kanala yeniden bolusumcu alternatif. kd_hedef
    #     icindeki refah_yoklugu terimine dogrudan baglanir.
    #
    # CAG KAPISI YOKTUR. ETG her cagda mumkundur ama yalnizca verimlilik
    # yeterince yuksekken MALI OLARAK tasinabilir; erken cagda deneyen oyuncu
    # butcesini batirir. Bu, sert bir anahtardan daha ogreticidir.
    etg_yerlesme: float = 0.020     # Fiili ETG'nin hedefe yakinsama hizi (yavas)
    etg_org_ref: float = 0.45       # Sübvansiyon/metasizlasma dengesinin dondugu org
    etg_taban_dus: float = 0.55     # (1) Ucret tabanini dusurme gucu
    etg_katilik: float = 0.60       # (2) Asagi yonlu ucret katiligini artirma gucu
    etg_omega: float = 0.060        # (3) Omega yatistirma gucu
    etg_kd: float = 0.20            # Karanlik devlet hedefini bastirma gucu
    etg_katilim: float = 0.30       # Gonullu isgucu cekilmesi
    etg_dogum: float = 0.35         # Dogurganliga refah etkisi
    etg_maliyet: float = 1.00       # Butcedeki agirligi (hasila orani olarak)
    # -----------------------------------------------------------------
    # ETG FINANSMANI: sermayeden mi ucretten mi?
    # -----------------------------------------------------------------
    # Olcum, ETG'nin issizligi artirma etkisinin BASKIN OLARAK butce
    # dislamasindan geldigini gosterdi (bütçe kanali %120, ucret katiligi %34).
    # Bu, finansman tasariminin belirleyici oldugu anlamina gelir -- yani
    # "sermayeden vergilendirerek kurtarilabilir mi?" sorusu modelde
    # gercekten sorulabilir bir sorudur.
    #
    # Ama Marx'in cerceveinde bu sorunun bir tuzagi vardir: sermaye vergisinin
    # TABANI arti-degerdir ve LTRPF onu seküler olarak kucultur. ETG'yi
    # sermayeden finanse etmek, kucullen bir tabandan buyuyen bir harcamayi
    # karsilamaya calismaktir. Ustelik sermaye vergisi net karliligi dusurdugu
    # icin birikimi yavaslatir ve LTRPF'yi HIZLANDIRIR -- yani kendi vergi
    # tabanini asindirir. Ucretten finanse etmek ise tuketimi kisar ve
    # gerceklesme krizini derinlestirir. Iki yol da bir celiskiye baglanir.
    etg_sermaye_payi: float = 0.50  # ETG'nin sermaye vergisinden karsilanan payi
    etg_vergi_sermaye: float = 1.15 # Sermaye vergisinin karliliga geri tepme katsayisi
    etg_vergi_ucret: float = 0.90   # Ucret vergisinin tuketime geri tepme katsayisi

    kat_taban: float = 0.52         # Katilim oraninin alt siniri
    kat_e_ref: float = 0.92         # Tam katilimin surdugu istihdam esigi
    kat_hiz: float = 0.010          # Katilimin uyum hizi (yavas, kusaklar arasi)

    # =================================================================
    # KRİZDE SABİT SERMAYENİN DEĞERSİZLEŞMESİ  (Marx'ın 1. karşı-eğilimi)
    # -----------------------------------------------------------------
    # onceki surum'e kadar bu model r = s/K = (1-pay)*u/kv özdeşliğine indirgeniyordu:
    # K düşünce Y de orantılı düştüğü için SERMAYE YIKIMI KÂR ORANINI HİÇ
    # YÜKSELTMİYORDU. Kriz yalnızca yıkıyor, hiçbir şeyi onarmıyordu.
    #
    # Marx'ta krizin işlevi tam da budur: sabit sermaye değersizleşir (iflaslar,
    # ahlaki aşınma, defterden silme), aynı fiziksel sermaye daha az değer
    # taşır, s/C yükselir ve yeni bir birikim çevrimi başlar. Bu, Kapital III
    # 14. bölümdeki karşı-eğilimler listesinin ilk maddesidir.
    #
    # Bu mekanizma olmadan LTRPF tek yönlü bir çöküşe dönüşüyor: r faize
    # yaklaşıyor, net birikim negatife dönüyor, sermaye eriyor ama kârlılık
    # onarılmıyor ve teknolojik işsizlik kalıcılaşıyor.
    dev_cokme: float = 0.055        # Finansal cokmede deger silinme orani
    dev_bunalim: float = 0.140      # Buyuk bunalimda deger silinme orani
    dev_savas: float = 0.030        # Savas turu basina deger silinme orani
    dev_taban: float = 0.30         # Deger carpaninin alt siniri
    dev_geri: float = 0.0016        # Degerin yeniden sisme (recovery) hizi

    baumol_us: float = 0.63067      # Baumol maliyet hastalığı üssü

# =====================================================================
# AJAN: ÜLKE (COUNTRY) SINIFI
# =====================================================================
class Country:
    """Oyun dünyasındaki her bir egemen bölgeyi temsil eden dinamik sınıf."""
    def __init__(self, ad, tip, K, L_max, q, pay, IR, baski_egilimi, saldirganlik):
        self.ad = ad
        self.tip = tip                    # "merkez", "yari", "cevre"
        self.K = K                        # Fiziksel sermaye stoku (üretken)
        self.L_max = L_max                # Toplam aktif işgücü nüfusu (arz)
        self.q = q                        # Labor productivity (canlı emeğin üretkenliği)
        self.pay = pay                    # Ücret payı (wage share, \omega)
        self.IR = IR                      # Kurumsal Katılık (0-1)
        self.baski_egilimi = baski_egilimi# Polis zoruyla bastırma eğilimi
        self.saldirganlik = saldirganlik  # Saldırganlık doktrini
        
        self.rejim = "kapitalist"         # "kapitalist" veya "sosyalist"
        self.era = 1                      # Başlangıç: buhar çağı (1760)
        self.Omega = 0.05                 # Siyasi öfke gerilim birikimi
        self.u = 0.82                     # Kapasite kullanımı
        self.e = 0.90                     # İstihdam oranı
        self.r = 0.04                     # Üretken kâr oranı (Marxian rate)
        self.g = 0.02                     # Birikim hızı
        self.PKE = 0.0                    # Planlama Gücü
        # Plan profili (yalnizca sosyalist rejimde anlamli). Paylar normalize edilir.
        self.plan = {"yatirim": 0.30, "tuketim": 0.55, "arge": 0.10, "savunma": 0.05}
        self.plan_hedef = None            # Politika: yakinsanacak yeni profil
        self.kitlik = 0.0                 # Planli ekonominin kriz olcusu
        self.parti_iktidari = False       # Piyasa sosyalizmi: parti iktidarda, ekonomi kapitalist
        self.pakt_durusu = "ittifak"      # "ittifak" | "rekabet" -- politika secimi
        self.ideolojik_mesafe = 0.0       # Blok ortalamasindan plan hatti sapmasi
        self.izo_sayac = 0                # Yalnizlik + kitlik baskisinin suresi
        self.restorasyon_t = None         # Restorasyon/piyasa sosyalizmi turu
        self.VT_net = 0.0                 # Net değer transfer sızıntısı
        self.kriz = 0                     # Kriz birikim sayacı
        self.pr_sayac = 0                 # Protesto sürme sayacı
        self.devrim_t = None              # SIMULASYON ICINDE gerceklesen devrim turu
        self.baslangic_rejimi_t = None    # Senaryonun BASLANGICTA sosyalist kurdugu tur
        self.devrim_era = None
        self.PC = 1.0                     # Rejim rızası
        self.savas = {}                   # {rakip_ad: kalan_savas_turu}
        self.abluka = 0                   # Ticari abluka
        self.ambargo = False              # Ambargo altında olma
        self.muttefik = set()             # Müttefikler
        self.savas_toplam = 0             # Savaşta geçen toplam tur
        self.savas_sayisi = 0             # Katılınan toplam savaş sayısı
        self.gecis_sok = 0
        
        # Finansal Durum
        self.borc = 0.0                   # Hanehalkı borç stoku
        self.varlik = 0.0                 # Spekülatif varlık balonu stoku
        self.Y = 1.0                      # GSYİH
        self.Y_zirve = 1.0                # Maksimum GSYİH
        self.delev = 0                    # Deleveraging kalan tur
        self.norm = 0.72                  # Toplumsal tüketim normu
        self.org = 0.08                   # İşçi sendikalaşma düzeyi
        
        # Merkez Bankası
        self.i_pol = 0.0106               # Politika faizi (çeyreklik)
        self.i_ef = 0.0106                # Risk primli efektif faiz (= i_reel)
        self.i_ham = 0.0106               # Tavan uygulanmadan once ham finansman maliyeti
        self.i_reel = 0.0106              # Uretken yatirimin esik getirisi (tavanli)
        self.i_spec = 0.0106              # Spekulatif finansman maliyeti (tavansiz)
        self.varlik_beklenti = 0.0        # Varlik getirisi beklentisi (Minsky)
        self.minsky_sayac = 0             # Kirilganlik + tersine donus sayaci
        self.FX = 0.35 * self.Y           # Döviz rezervleri
        self.eps = 1.0                    # İhracat esnekliği
        self.pi_m = 1.0                   # İthalat esnekliği
        self.cari = 0.0                   # Cari denge
        self.BoP_R = 0.0                  # BoP risk primi
        self.fx_kriz = 0                  # Döviz krizi kalan tur
        self.fx_baski = 0                 # Rezerv baskı süresi
        self.deval = 0.0                  # Devalüasyon primi stoku
        self.y_buyume = 0.02              # Büyüme hızı
        self.fx_krizleri = []
        
        # Nominal Katman
        self.pi_inf = 0.0054              # Enflasyon (tur başı; ~%2/yıl)
        self.pi_bek = 0.0054              # Enflasyon beklentisi
        self.p_duzey = 1.0                # Fiyat düzeyi
        self.w_nom = 1.0                  # Nominal ücret
        self.w_nom_buyume = 0.0054        # Nominal ücret artış hızı
        self.q_buyume = 0.0               # Gerçekleşen verimlilik artış hızı
        self.e_norm = 0.88                # Goodwin hareketli istihdam normu
        self.katilim = 1.0                # Isgucune katilim orani (gizli yedek ordu)
        self.etg_hedef = 0.0              # Politika: hedeflenen ETG (hasila orani)
        self.etg = 0.0                    # Fiili ETG (yavas yerlesir)
        self.etg_metasiz = 0.0            # Metasizlasma agirligi (teshis icin)
        self.etg_sermaye_payi = 0.50      # Politika: ETG'nin sermayeden finansman payi
        self.etg_vergi_sermaye_o = 0.0    # O turki sermaye vergisi yuku
        self.etg_vergi_ucret_o = 0.0      # O turki ucret vergisi yuku
        self.cs_kisit = 0                 # 1 ise: ETG gerekli ama finanse edilemiyor
        self.katilim_etg = 0.0            # ETG kaynakli gonullu cekilme
        self.deger_carpani = 1.0          # Sabit sermayenin deger asinmasi (kriz devaluasyonu)
        self.ito = 1.0                    # Mekanizasyon durtusu carpani (teshis icin)
        self.ito_bilesen = (0.0, 0.0, 0.0, 0.0)   # (ucret, rekabet, makine, demografi)
        self.oto = 0.0                    # Sermayenin emek-ikame eden payi
        self.canli_pay = 1.0              # Fiziksel hasilanin canli emekten gelen payi
        self.V_yeni = 0.0                 # O turda yaratilan YENI DEGER (v+s)
        self.saat = 1.0                   # Çalışma süresi rasyosu
        self.stagflasyon = 0              # Stagflasyon sayacı
        self.hegemon = False              # Rezerv para konumu
        self.heg_sayac = 0
        self.kurum = "neoliberal"         # Varsayılan rejim
        self.kurum_t = 0
        self.kurum_gecmis = []
        self.kurum_insa_t = -9999         # Son kasitli kurumsal insa turu
        self.kurum_insa_hedef = None      # Oyuncu/AI politikasi: insa edilecek rejim
        self.ai_muaf = False              # True ise politika AI'si bu ulkeye dokunmaz
        # Politika kuyrugu: {ad: (hedef_deger, etkinlesme_turu)}
        self.pol_kuyruk = {}
        # AI/oyuncu politika durusları (kurumsal degerin uzerine carpan/ek)
        self.kredi_durusu = 1.0           # Kredi genislemesi carpani
        self.yatirim_durusu = 0.0         # Kamu sermaye hedefine ek
        self.ticaret_durusu = 0.0         # Dis ticaret acikligina ek
        
        # Kamu ve Bütçe
        self.kamu_borc = 0.0
        self.vergi_geliri = 0.0
        self.vergi_carpani = 1.0
        self.kemer = 0
        self.kamu_pay = 0.08
        self.kontrol = 0
        self.bastirilmis_pi = 0.0
        self.dis_borc = 0.0
        self.mor_ceza = 0
        self.moratoryumlar = []
        self.goc_net = 0.0
        self.egitim = 0.08
        self.temerrutler = []
        self.bunalimlar = []
        self.resesyonlar = []
        
        self.Y_ort = 1.0
        self.Y_trend = 1.0
        self.res_ici = 0
        self.res_bekle = 0                # Resesyon tescili sonrasi bekleme sayaci
        self.talep_acigi = 0.0            # (Y_pot - D_talep)/Y_pot
        self.parti = 0.0                  # Marksist politik oznenin gucu
        self.orgutlu = 0.0                # org + parti*(1-org): toplam orgutlu guc
        self.au_ici = 0                   # Asiri uretim krizinin sure sayaci
        self.au_bekle = 0
        self.asiri_uretim_krizleri = []    # (tur, acik) kayitlari
        # Kriz siniflandirmasi: cokli bayrak + TEK birincil neden.
        # Bir ulke ayni turda resesyon + Minsky + FX krizi yasayabilir; frekanslar
        # cakismasin diye `birincil_kriz` karsilikli dislayicidir.
        self.olay_bayraklari = {}
        self.birincil_kriz = None
        self.kriz_gunlugu = []            # (tur, birincil, [ikincil...])
        self.bun_ici = 0
        self.tarih = []
        
        # --- YENİ DEMOGRAFİK VE MAFYA/UYUŞTURUCU DİNAMİKLERİ ---
        self.uyusturucu_orani = 0.01       # Uyuşturucu kullanan nüfus oranı
        self.cezaevi_orani = 0.003         # Cezaevi hükümlü nüfus oranı
        self.mafya_tolerans = 0.0          # Karanlik devlet gecirgenligi (0-1), ENDOJEN
        self.mafya_kilit = None            # Oyuncu bunu bir sayiya cekerse endojen guncelleme durur
        self.kd_hedef = 0.0                # Toleransin o turki hedef degeri (teshis icin)
        self.lumpen_pay = 0.0              # Illegal/asalak sektorun ekonomideki payi
        self.gasp = 0.0                    # Uretken alandan cekilen deger (Tonak)
        self.s_v = 1.0                     # Somuru orani s/v (Tonak metrigi)
        
        # Başlangıç kaba doğum/ölüm oranları (tip ve gelişmişliğe bağlı)
        if self.tip == "merkez":
            self.dogum_orani = 0.012
            self.olum_orani = 0.008
        elif self.tip == "yari":
            self.dogum_orani = 0.018
            self.olum_orani = 0.006
        else: # cevre
            self.dogum_orani = 0.026
            self.olum_orani = 0.006

    def saat_tabani(self, P):
        """Is paylasimi marjinin alt siniri. Tarihsel kisalma hafta_norm'dadir."""
        return P.saat_min

    def hafta_saati(self, P):
        """Fiili haftalik calisma suresi (cag normu x paylasim payi).

        Raporlama icindir: 1.00 = 1760'in tam haftasi (~70 saat).
        """
        return P.hafta_norm[min(self.era, 6)-1]*self.saat

    @property
    def L_etkin(self):
        """Karseral nufus dusulmus ETKIN isgucu arzi.

        Itoh: hapsedilen kitle artik arti-deger uretiminin oznesi degil,
        "atil sermaye" yonetiminin nesnesidir. Bu yuzden emek arzindan dusulur.
        """
        return self.L_max*self.katilim*(1.0 - min(0.90, self.cezaevi_orani))

    @property
    def iss_duzeltilmis(self):
        """ETG'nin gonullu cekilmesi geri eklenmis issizlik orani.

        ETG katilimi dusurur; bu L_etkin'i kucultup OLCULEN istihdam oranini
        mekanik olarak yukseltir. Gercek bir etkidir ama ETG'nin is yaratmasiyla
        karistirilmamalidir. Bu gosterge, cekilenler hala isgucunde sayilsaydi
        issizligin ne olacagini verir -- ikisi birlikte raporlanir.
        """
        if self.katilim_etg <= 0:
            return 1.0 - self.e
        pay_ = self.katilim
        return 1.0 - self.e*pay_/max(pay_ + self.katilim_etg, 1e-9)

    @property
    def atil_endeks(self):
        """KODEY: Karseral nufus / uretken emek gucu."""
        return self.cezaevi_orani/max(1.0-self.cezaevi_orani, 1e-6)

    @property
    def savasta(self): return len(self.savas) > 0
    @property
    def guc(self): return self.K * self.q

# =====================================================================
# SİMÜLASYON MOTORU
# =====================================================================
class GhostEconomyEngine:
    def sg(self, x):
        return 1.0/(1.0+math.exp(-max(-60, min(60, x))))
    def __init__(self, tohum=42):
        self.P = Params()
        self.tohum = tohum            # onceki surum: senaryo yukleyici de bunu kullanir
        self.baslangic_yili = BASLANGIC_YILI   # Senaryo bunu degistirebilir
        self.dunya_devrimi = False    # Bir kez tetiklenir, kurallari kalici degistirir
        self.dd_sayac = 0             # Iki kosulun birlikte surdugu tur sayisi
        self.pakt_uyumu = 0.0         # sosyalist / (sosyalist + piyasa sosyalizmi)
        self.kap_kriz_payi = 0.0      # Surdurulemez krizde olan kapitalist ulke payi
        # onceki surum: Senaryonun tarihsel baslangic istihdami. init_simulation K'yi bu
        # hedefe gore olcekler. Issizlik bu modelde YAVAS BIRIKEN bir stoktur:
        # 120 turluk (~32 yil) oyun ufkunda kurumsal farklardan TURETILEMEZ.
        # Senaryo odalarinin isi zaten budur -- baslangic durumu turetilmez, kurulur.
        # Oyuncunun politikasi bu seviyeyi DEGISTIRIR (uzun vadede hizlandirici
        # kanali issizligi 0.12'den 0.34'e kadar hareket ettirebiliyor).
        self.hedef_istihdam = self.P.e0
        # Senaryonun sermaye/emek bollugu carpani. Issizlik bu modelde Y/(q*saat*L)
        # ile belirlenir ve Y orta vadede K ile orantilidir; dolayisiyla baslangic
        # issizlik seviyesini kuran dogru degisken bu carpandir. Ampirik olarak
        # kalibre edilir (bkz. senaryo odalari).
        self.K_carpani = 1.0
        self.D = self.dunya_kur()
        self.log = []
        self.t = 0
        self.rng = random.Random(tohum)
        # onceki surum: VARSAYILAN dunyada da cag ile q tutarli kilinir.
        # onceki surum'da Country.era=4 ("siber-fiziksel cag") atanmis ama dunya_kur'un
        # verdigi q degerleri 0.40-1.00 (buhar cagi) araligindaydi. Sonuc: q,
        # cag 6'nin tavanina kadar ~200 KAT buyuyor, emek arzi ise neredeyse
        # sabit kaliyordu -> kapitalist ulkelerde %60-70 teknolojik issizlik.
        # (onceki surum'da bu gizliydi cunku 20 ulkenin 17'si sosyalizme gecip planli
        # istihdamla maskeliyordu; kapitalist kalan 3 ulkede issizlik %60.5 idi.)
        self.cag_ata(P_BASLANGIC_CAGI)
        self.init_simulation()

    def dunya_kur(self):
        """G20 ülkelerini ve Türkiye'yi ampirik değer katsayılarıyla başlatır."""
        # ad, tip, K, L_max, q, pay, IR, baski_egilimi, saldirganlik
        # Türkiye: Sömürü oranı = 144% => Ücret payı = 33.9% (~0.339), K/Y ve sızıntı transferleri entegre edilmiştir.
        # ABD: Yüksek organik bileşim, finans kapital odağı. Çin: Yoğun imalat ve yüksek s/v.
        T = [
            ("ABD", "merkez", 320, 110, 1.00, 0.52, 0.35, 0.40, 0.85),
            ("Almanya", "merkez", 210, 75, 0.98, 0.55, 0.42, 0.30, 0.55),
            ("Ingiltere", "merkez", 185, 62, 0.95, 0.54, 0.38, 0.45, 0.65),
            ("Fransa", "merkez", 175, 62, 0.94, 0.56, 0.48, 0.25, 0.50),
            ("Japonya", "merkez", 170, 72, 0.91, 0.50, 0.50, 0.45, 0.60),
            ("Italya", "yari", 130, 58, 0.83, 0.51, 0.52, 0.35, 0.45),
            ("Kanada", "merkez", 110, 38, 0.93, 0.55, 0.35, 0.30, 0.20),
            ("Avustralya", "merkez", 95, 33, 0.91, 0.55, 0.35, 0.30, 0.20),
            ("G.Kore", "yari", 100, 52, 0.81, 0.44, 0.42, 0.55, 0.35),
            ("Rusya", "yari", 130, 82, 0.70, 0.40, 0.60, 0.70, 0.80),
            ("Cin", "cevre", 140, 220, 0.58, 0.31, 0.55, 0.70, 0.60),
            ("Hindistan", "cevre", 85, 200, 0.42, 0.26, 0.58, 0.50, 0.45),
            ("Brezilya", "cevre", 85, 92, 0.55, 0.34, 0.52, 0.45, 0.25),
            ("Meksika", "cevre", 70, 78, 0.52, 0.32, 0.52, 0.45, 0.20),
            ("Endonezya", "cevre", 55, 98, 0.40, 0.25, 0.52, 0.50, 0.25),
            ("Turkiye", "cevre", 65, 62, 0.53, 0.339, 0.58, 0.60, 0.50), # Sömürü %144, ücret payı %33.9
            ("S.Arabistan", "cevre", 80, 28, 0.62, 0.35, 0.65, 0.75, 0.50),
            ("G.Afrika", "cevre", 50, 56, 0.45, 0.28, 0.52, 0.45, 0.25),
            ("Arjantin", "cevre", 55, 48, 0.52, 0.33, 0.58, 0.40, 0.25),
            ("AB-blok", "merkez", 145, 58, 0.94, 0.55, 0.48, 0.25, 0.40)
        ]
        return [Country(*x) for x in T]

    def init_simulation(self):
        """Kuresel olcegi istihdam ve kapasite hedefine baglar (v4.4 standardı)."""
        P = self.P
        hedef = sum(self.kappa_v(organik_bilesim(c.q), c.q)*c.q*c.L_max
                    * self.hedef_istihdam/P.u_normal for c in self.D)
        mevcut = sum(c.K for c in self.D) or 1.0
        self.K_olcek = hedef / mevcut
        kc = getattr(self, '_K_carpani_override', None)
        if kc is not None:
            self.K_carpani = kc
        for c in self.D:
            c.K *= self.K_olcek*self.K_carpani
            kv = self.kappa_v(organik_bilesim(c.q), c.q)
            c.Y = min(c.K/kv, c.q*c.L_max)*P.u_normal
            c.Y_zirve = c.Y
            c.norm = self.P.tuketim_normu
            c.FX = self.P.fx_baslangic*c.Y
            c.Y_ort = c.Y
            c.Y_trend = c.Y

    @property
    def yil(self):
        """Simulasyonun o andaki takvim yili."""
        return self.baslangic_yili + self.t*TUR_YIL

    def cag_ata(self, era, ulkeler=None):
        """Ulkeleri bir caga tasir ve q'yu O CAGLA TUTARLI hale getirir.

        onceki surum hatasi: senaryolar `c.era` atiyor ama `c.q`'ya dokunmuyordu. Sonuc:
        Turkiye era=4 (siber-fiziksel) ama q=0.53 (buhar cagi seviyesi). Cag
        atlama kosulu q > q_esik(era+1) oldugu icin teknolojik ilerleme de
        doniyordu; ayrica kappa_v cv=6.0 ile q=0.53'u birlestirip t=0'da
        anormal yuksek bir sermaye/hasila katsayisi uretiyordu.

        Burada ulkenin dunya icindeki GORELI verimlilik konumu korunur, mutlak
        seviye ise hedef cagin [q_esik, bir sonraki cagin q_esik'i] araligina
        tasinir -- boylece hicbir ulke atandigi turda hemen bir sonraki caga
        siçramaz ve merkez-cevre farki kaybolmaz.
        """
        ulkeler = ulkeler if ulkeler is not None else self.D
        qs = [c.q for c in self.D]
        qmin, qmax = min(qs), max(qs)
        alt = max(ERAS[era]["q_esik"], 0.5)
        ust = ERAS[era+1]["q_esik"] if era < 6 else ERAS[6]["q_tavan"]
        for c in ulkeler:
            konum = (c.q-qmin)/max(qmax-qmin, 1e-9)
            c.era = era
            c.q = alt + (ust-alt)*(0.10 + 0.55*konum)

    def kappa_v(self, cv, q):
        """Marxian KODEY: sabit sermayenin ucuzlaması doyumludur."""
        P = self.P
        L = max(0.0, math.log(max(q, 0.05) / 0.5))
        ucuz = P.ucuzlama_max * L / (L + P.ucuzlama_h)
        return P.kv0 * cv**P.kv_us / (1.0 + ucuz)

    def ucuzlama_orani(self, q):
        """Sabit sermayenin ucuzlama duzeyi [0, ucuzlama_max). ito icin ayrica
        gereklidir: makine ucuzladikca emegi ikame esigi duser."""
        P = self.P
        L = max(0.0, math.log(max(q, 0.05) / 0.5))
        return P.ucuzlama_max * L / (L + P.ucuzlama_h)

    # =====================================================================
    # SENARYO ODALARI LAUNCHER (YENİ KATMAN)
    # =====================================================================
    def load_scenario(self, isim, K_carpani=None):
        """Tarihsel/kurgusal ampirik senaryo odasini motora yukler.

        onceki surum sirasi (onceki surum'da bu sira yanlisti):
          1) YAPISAL ayarlar  -> cag, kurum, rejim, hegemonya, ittifak
          2) init_simulation() -> K olcegi, Y, FX, norm YENIDEN kurulur
          3) ORANSAL ayarlar  -> FX/Y, borc/Y, Omega, org, pay, kemer ...

        onceki surum'da oransal ayarlar 2. adimdan ONCE yapiliyordu; init_simulation
        `c.FX = fx_baslangic*c.Y` satiriyla senaryonun kurdugu degeri sessizce
        eziyordu. Ornegin turkey_2001'in ana oncülü olan "rezerv tukenmis"
        (FX = 0.02*Y) ayari hic yuklenmiyor, FX 0.35*Y olarak basliyordu.
        """
        self.log.append((self.t, "SENARYO", f"SENARYO ODASI YÜKLENDİ: {isim.upper()}"))
        # onceki surum: tohum artik dikkate aliniyor. onceki surum'da burada random.seed(42) ve
        # Random(42) sabit yazilmisti; GhostEconomyEngine(tohum=N) hicbir etki
        # yaratmiyor, butun tohumlar birebir ayni sonucu veriyordu.
        random.seed(self.tohum)
        self.rng = random.Random(self.tohum)
        self._K_carpani_override = K_carpani

        if isim == "turkey_2001":
            # Türkiye 2001 Krizi ve Neoliberal Geçiş
            self.hedef_istihdam = 0.885     # kriz oncesi yuksek issizlik
            self.K_carpani = 0.50   # 2001 krizi: yuksek issizlik
            self.cag_ata(4)
            for c in self.D:
                c.kurum = "neoliberal"
                if c.ad == "ABD":
                    c.hegemon = True
            self.init_simulation()
            for c in self.D:
                if c.ad == "Turkiye":
                    c.dis_borc = 1.35          # Limit sınırında
                    c.kamu_borc = 1.15         # Kemer sıkma sınırında
                    c.FX = 0.02*c.Y            # Rezerv tükenmiş
                    c.kemer = 40               # Ağır IMF bütçe kısıtı aktif
                    c.Omega = 0.45             # Yüksek halk öfkesi
                    c.org = 0.12               # Örgütlülük zayıf
                    c.pay = 0.339              # Ücret payı ezik
                    c.baski_egilimi = 0.70     # Polis gücü baskısı yüksek
                elif c.ad == "ABD":
                    c.FX = 0.80*c.Y

        elif isim == "golden_age_1950":
            # Altın Çağ Refah Devleti (1945-1975)
            self.hedef_istihdam = 0.975     # tam istihdam taahhudu
            self.K_carpani = 1.70   # tam istihdam taahhudu
            self.cag_ata(2)
            for c in self.D:
                c.kurum = "duzenli"
            self.init_simulation()
            for c in self.D:
                c.org = 0.72                   # Güçlü işçi sendikaları
                c.pay = 0.58                   # Emeğin yüksek payı
                c.e = 0.97                     # Tam istihdam
                c.e_norm = 0.96
                c.borc = 0.05*c.Y              # Düşük hanehalkı borcu
                c.varlik = 0.02*c.Y            # Sıfıra yakın spekülatif finans
                c.kamu_borc = 0.25
                c.PC = 1.0                     # Yüksek demokratik meşruiyet

        elif isim == "neoliberal_1995":
            # Neoliberal Küreselleşme ve Finansallaşma (1995-2020)
            self.hedef_istihdam = 0.905     # yedek sanayi ordusu disiplin araci
            self.K_carpani = 0.45   # yedek sanayi ordusu disiplin araci
            self.cag_ata(4)
            for c in self.D:
                c.kurum = "neoliberal"
            self.init_simulation()
            for c in self.D:
                c.org = 0.15                   # Sendikalar ezilmiş
                c.pay = 0.38                   # Düşük ücret payı
                c.borc = 0.60*c.Y              # Borçla güdümlenen tüketim
                c.varlik = 0.80*c.Y            # Spekülatif balonlar birikiyor
                c.PC = 0.85

        elif isim == "socialist_siege":
            # Kuşatılmış Planlı Ekonomi (Alternatif Gelecek)
            self.hedef_istihdam = 0.935
            self.K_carpani = 1.30
            self.cag_ata(5)
            for c in self.D:
                c.kurum = "duzenli"
                if c.ad in ["Rusya", "Cin", "Turkiye"]:
                    c.rejim = "sosyalist"
                    # Senaryo baslangici bir DEVRIM DEGILDIR. Onceden `devrim_t = 0`
                    # atanıyordu; bu hem get_summary'de devrim sayısını sisiriyor
                    # (t=5'te 0 gercek devrim varken 3 bildiriliyordu) hem de askeri
                    # mudahale penceresine (0 < t-devrim_t <= 40) sokuyordu.
                    c.baslangic_rejimi_t = 0
                elif c.ad in ["ABD", "Ingiltere", "Almanya"]:
                    c.saldirganlik = 0.95      # Emperyalist müdahale zirvede
                    c.muttefik.add("ABD")
                    c.muttefik.add("Ingiltere")
            self.init_simulation()
            for c in self.D:
                if c.rejim == "sosyalist":
                    c.pay = 0.65
                    c.borc = 0.0
                    c.varlik = 0.0
                    c.PKE = 0.75
        else:
            raise ValueError(f"Bilinmeyen senaryo: {isim}")

    def step(self):
        """Simülasyonda 1 tur (çeyrek dönem) ilerlemesini yöneten ana metot."""
        D = self.D
        P = self.P
        t = self.t
        rng = self.rng
        
        # 1. Uluslararası İttifakların ve Ambargoların İşlenmesi
        self.ittifak_isle()
        self.abluka_ambargo_isle()
        # Dunya devrimi bir kez tetiklendiginde abluka/ambargo/deger transferini
        # kalici olarak kapatir; bu yuzden abluka isleminden HEMEN SONRA calisir.
        self.dunya_devrimi_isle(D)
        self.savas_karari()
        
        # 2. Kurumsal Rejimlerin Kontrolü
        for c in D:
            self.politika_kuyrugu_isle(c)
            self.izolasyon_sapmasi_isle(c)
            self.kurumsal_gecis_isle(c)
            self.can_simidi_isle(c)
            self.politika_ai_isle(c)
            self.kurumsal_insa_isle(c)
            
        sos = [c for c in D if c.rejim == "sosyalist"]
        blok = len(sos)
        
        # 3. Hegemonya ve Rezerv Para Birimi Kontrolü
        kap_ler = [c for c in D if c.rejim == "kapitalist"]
        if kap_ler:
            mevcut = next((c for c in D if c.hegemon), None)
            aday = max(kap_ler, key=lambda c: c.guc)
            if mevcut is None or mevcut.rejim != "kapitalist":
                for c in D: c.hegemon = False
                aday.hegemon = True
                aday.heg_sayac = 0
                self.log.append((t, "HEGEMONYA", f"{aday.ad} rezerv para statusunu kazandi."))
            elif aday is not mevcut and aday.guc > mevcut.guc*P.heg_esik:
                aday.heg_sayac += 1
                if aday.heg_sayac >= P.heg_sure:
                    mevcut.hegemon = False
                    aday.hegemon = True
                    aday.heg_sayac = 0
                    self.log.append((t, "HEGEMONYA", f"{aday.ad} küresel para unvanini {mevcut.ad}'dan devraldi."))
            else:
                aday.heg_sayac = max(0, aday.heg_sayac-1)

        Yv = {c.ad: min(c.K/self.kappa_v(organik_bilesim(c.q)*c.deger_carpani, c.q),
                        c.q*c.L_etkin) for c in D}
        top = sum(Yv.values()) or 1e-6
        ort_cv = sum(organik_bilesim(c.q)*c.deger_carpani*Yv[c.ad] for c in D)/top
        ort_sv = sum((1/max(c.pay, .05)-1)*Yv[c.ad] for c in D)/top
        ort_q = sum(c.q*Yv[c.ad] for c in D)/top
        y_dunya = sum(c.y_buyume for c in D)/len(D) if t > 0 else 0.02
        
        # 4. Ajan Bazlı Makro Akışların Hesaplama Döngüsü
        for c in D:
            E = ERAS[c.era]
            # Deger bilesimi = teknik bilesim x kriz devaluasyonu.
            # Deger carpani her tur yavasca 1.0'a doner (yeni yatirimlar eski
            # deger duzeyini yeniden kurar), krizlerde asagi sicrar.
            c.deger_carpani = min(1.0, c.deger_carpani + P.dev_geri*(1.0-c.deger_carpani))
            if c.savasta:
                c.deger_carpani = max(P.dev_taban, c.deger_carpani*(1-P.dev_savas))
            cv = organik_bilesim(c.q)*c.deger_carpani
            kv = self.kappa_v(cv, c.q)
            Y_onceki = c.Y
            
            # A. Merkez Bankası & Politika Faizi (Taylor Rule + Balon/Kriz Duyarlılığı)
            varlik_o = c.varlik/max(c.Y, 1e-6)
            kriz_sinyal = 1.0 if (c.delev > 0 or c.r < P.r_kriz_esigi or c.fx_kriz > 0) else 0.0
            i_hedef = (P.i_notr + P.tay_pi*(c.pi_inf-P.pi_hedef)
                       + P.tay_u*(c.u-P.u_normal) + P.tay_e*(c.e-P.e0)
                       + P.tay_balon*max(0.0, varlik_o-1.0)
                       - P.tay_kriz*kriz_sinyal)
            c.i_pol = max(P.i_min, min(P.i_max, P.tay_atalet*c.i_pol + (1-P.tay_atalet)*i_hedef))
            
            # B. Dış Ticaret & Thirlwall BoPC Kısıtları (asimetrik esneklikler)
            q_rel = c.q/max(ort_q, 1e-6)
            # onceki surum: Cedeplar-UFMG (Missio & Jayme Jr.) -- lumpenlesme endojen
            # esneklikleri negatif yonde donusturur: nitelik birikimi kaybi
            # ihracat gelir esnekligini dusurur, ithalat bagimliligini artirir.
            # Bu, BoP-kisitli buyumeyi (Thirlwall) dogrudan daraltir.
            c.eps = P.eps0*(0.45 + P.eps_q*min(q_rel, 2.2)) \
                    * (1 + P.eps_vt*max(0.0, c.VT_net/max(c.Y, 1e-6))) * (1 + c.deval) \
                    * (1 - P.eps_lumpen*c.lumpen_pay)
            c.pi_m = max(0.35, P.pi0*(1.45 - P.pi_q*min(q_rel, 2.0))*(1 + P.pi_lumpen*c.lumpen_pay))
            if c.rejim == "sosyalist":
                c.pi_m *= 0.85 # Sosyalist ithal ikamesi
                
            y_max = c.eps*max(y_dunya, 0.0)/max(c.pi_m, 0.2)
            asim = c.y_buyume - y_max
            muaf = P.heg_muafiyet if c.hegemon else 0.0
            c.BoP_R = self.sg(P.kappa_B*asim*8)*(1-muaf)
            c.i_ham = c.i_pol*(1 + c.BoP_R + (P.mor_ceza_prim if c.mor_ceza > 0 else 0.0))
            # Uretken yatirimin esik getirisi -- Marx III/22 tavani buraya.
            c.i_reel = min(c.i_ham, P.faiz_kar_tavani*max(c.r, 0.0) + P.faiz_taban_marj)
            # Spekulatif finansman maliyeti -- tavansiz.
            c.i_spec = c.i_ham
            c.i_ef = c.i_reel   # geriye donuk ad: mevcut kullanimlarin tamami reeldir
            
            # C. Cari Açık Sızıntısı & Uluslararası Değer Transferi
            ihr_carpani = (1 - P.ab_vt*min(c.abluka, 3)/3) if c.abluka else 1.0
            aciklik_ef = max(0.05, P.ticaret_aciklik + c.ticaret_durusu)
            c.cari = (-P.cari_kats*KURUMLAR[c.kurum]['sermaye_hareketi']*aciklik_ef*c.Y*asim*4*(1-muaf)
                      + 0.30*c.VT_net) * ihr_carpani
            c.FX += c.cari
            
            # D. Ani Duruş (Sudden Stop) & Dış Borçlanma Tıkacı
            if c.dis_borc > P.dis_borc_tavani or c.mor_ceza > 0:
                c.cari = max(c.cari, 0.006*c.Y)
                if c.fx_kriz == 0 and c.dis_borc > P.dis_borc_tavani:
                    c.fx_kriz = max(c.fx_kriz, 12)
                    
            db_carpan = max(0.97, min(1.020, 1 + c.i_ef - max(c.y_buyume, -0.02)))
            c.dis_borc = max(0.0, min(P.borc_orani_tavani, c.dis_borc*db_carpan - c.cari/max(c.Y, 1e-6)))
            
            # E. Borç Yapılandırma & Moratoryum (Meksika '82, Arjantin '01)
            db_orani = c.dis_borc
            if (db_orani > P.mor_borc_esigi and c.fx_kriz > 0 and c.mor_ceza == 0
                and c.rejim == "kapitalist" and rng.random() < 0.20):
                c.dis_borc *= (1-P.mor_kesinti)
                c.mor_ceza = P.mor_ceza_sure
                c.moratoryumlar.append(t)
                self.log.append((t, "MORATORYUM", f"{c.ad} dis borclarini yapilandirdi. Oran: {db_orani:.2f}"))
            
            if c.mor_ceza > 0:
                c.mor_ceza -= 1
                c.BoP_R = min(1.0, c.BoP_R + P.mor_ceza_prim)
                
            c.deval = max(0.0, c.deval - P.deval_sonum)
            
            # F. Rezerv Erimesi ve Döviz Krizi (Tip C Kriz)
            c.fx_baski = c.fx_baski+1 if c.FX < -0.04*c.Y else 0
            if c.fx_baski >= 8 and c.fx_kriz == 0 and c.rejim == "kapitalist":
                c.fx_kriz = P.fx_kriz_sure
                c.FX = 0.06*c.Y
                c.deval = P.devaluasyon
                c.borc *= 1.12
                c.fx_krizleri.append(t)
                c.fx_baski = 0
                self.log.append((t, "DOVIZ KRIZI", f"{c.ad} odemeler dengesi krizine girdi! Para birimi coktu."))
                
            if c.fx_kriz > 0:
                c.fx_kriz -= 1
                
            # G. Arz Kapasitesi
            Y_K = c.K/kv
            # --- OTOMASYON: fiziksel kapasite vs deger yaratimi ---
            # Otomasyon stoku cag 5'ten itibaren, mekanizasyon durtusu olcusunde
            # birikir. Bu bir POLITIKA degil, rekabetin zorlayici yasasinin
            # sonucudur: duran geride kalir.
            if c.era >= P.oto_esik_era:
                hedef_oto = P.oto_tavan*min(1.0, c.ito/P.ito_tavan)*min(
                    1.0, (c.era - P.oto_esik_era + 1)/2.0)
                c.oto += P.oto_hiz*(hedef_oto - c.oto)
            c.oto = max(0.0, min(P.oto_tavan, c.oto))

            # Fiili emek girdisi: cag normu x paylasim payi. hafta_norm cag
            # ilerledikce dustugu icin ayni istihdam daha az emek-saati verir.
            canli_emek = c.L_etkin*c.hafta_saati(P)
            # Robotlar FIZIKSEL uretime katilir; emek esdegeri olarak olculur.
            robot_esdeger = P.oto_verim*c.oto*c.K/max(c.q, 1e-6)
            emek_esdeger = canli_emek + robot_esdeger
            # Canli emegin fiziksel hasiladaki payi -- YENI DEGERIN olcusu budur.
            c.canli_pay = max(P.oto_canli_taban,
                              canli_emek/max(emek_esdeger, 1e-9))
            Y_L = c.q*emek_esdeger
            Y_pot = min(Y_K, Y_L)*(1-min(P.ab_uretim*c.abluka, 0.45)) \
                    * (1-(P.fx_kriz_uretim if c.fx_kriz > 0 else 0.0))
                    
            # H. Efektif Talep & Borçlanma Sınırı (Clarke & Fisher Sentezi)
            etg_ucret_kesinti = P.etg_vergi_ucret*getattr(c, "etg_vergi_ucret_o", 0.0)
            # Satinalma gucu YENI DEGERDEN gelir (ucretler + kar), fiziksel
            # hasiladan degil. Otomasyon ilerledikce Y buyur ama V kucuulur:
            # kronik asiri uretim / gerceklesme krizi bu makastan dogar.
            V_onceki = max(getattr(c, "V_yeni", 0.0), c.Y*getattr(c, "canli_pay", 1.0))
            C_temel = (P.c_ucret*c.pay*V_onceki*max(0.15, 1-KURUMLAR[c.kurum]['v_ucret']-etg_ucret_kesinti)
                       + P.c_kar*(1-c.pay)*V_onceki*(1-KURUMLAR[c.kurum]['v_kar']))
            gerceklesen_oran = C_temel/max(c.Y, 1e-6)
            hedef_norm = P.norm_agirlik*P.tuketim_normu + (1-P.norm_agirlik)*gerceklesen_oran
            c.norm += P.norm_uyum*(hedef_norm - c.norm)
            c.norm = max(P.gecim_tabani, min(P.norm_tavan, c.norm))
            hedef_tuketim = c.norm*c.Y
            acik = max(0.0, hedef_tuketim - C_temel)
            
            if c.rejim == "kapitalist" and c.delev == 0:
                # Kredi istahi borc oranina gore soner: borc limite yaklastikca
                # yeni kredi kurur, borc oranI limitin ALTINDA asimptot yapar.
                kredi_istahi = max(0.0, 1.0 - (c.borc/max(c.Y, 1e-6)/P.borc_limiti)**P.kredi_us)
                yeni_kredi = (P.kredi_egilimi*KURUMLAR[c.kurum]['kredi']
                              * max(0.0, c.kredi_durusu)*acik*kredi_istahi)
                c.borc += yeni_kredi
            else:
                yeni_kredi = 0.0
                
            if c.delev > 0:
                c.borc = max(0.0, c.borc*(1-P.delev_hiz))
                c.delev -= 1
                
            borc_servisi = (c.i_ef + P.borc_faizi_marj)*TUR_YIL*c.borc
            C = C_temel + yeni_kredi - borc_servisi
            I = max(0.0, (c.g+P.delta_K)*c.K)*(1-(P.delev_yatirim_soku if c.delev > 0 else 0))
            
            # I. Kamu Maliyesi, Vergi & Kemer Sıkma
            # ETG finansmani icin ek vergi. Kaynagi (sermaye/ucret) oyuncu
            # politikasidir ve iki farkli celiskiye baglanir (bkz. Params).
            c.etg_vergi_sermaye_o = P.etg_maliyet*c.etg*c.etg_sermaye_payi
            c.etg_vergi_ucret_o = P.etg_maliyet*c.etg*(1.0-c.etg_sermaye_payi)
            v_ucret_ef = KURUMLAR[c.kurum]['v_ucret'] + c.etg_vergi_ucret_o/max(c.pay, 0.05)
            v_kar_ef = KURUMLAR[c.kurum]['v_kar'] + c.etg_vergi_sermaye_o/max(1-c.pay, 0.05)
            c.vergi_geliri = (min(0.85, v_ucret_ef)*c.pay + min(0.90, v_kar_ef)*(1-c.pay))*c.Y
            taban_hasila = max(c.Y_trend, Y_pot)
            # onceki surum: karseral harcama butcenin kalemi haline getirildi (el kitabi
            # Bolum 5: "sosyal yatirimlarin yerini guvenlik harcamalarina birakmasi")
            G_arzu = taban_hasila*(P.devlet_pay[c.era-1]*KURUMLAR[c.kurum]['devlet']
                                  + P.issizlik_sigortasi*max(0.0, (1-c.e)-0.05)
                                  + P.karseral_maliyet*c.cezaevi_orani
                                  + P.etg_maliyet*c.etg
                                  + (P.devlet_kriz*KURUMLAR[c.kurum].get('kars_dongusel', 1.0)
                                     if (c.delev > 0 or c.r < P.r_kamu_kriz) else 0))
            
            c.vergi_carpani += 0.030*(c.kamu_borc - 0.55)
            c.vergi_carpani = max(0.70, min(2.20, c.vergi_carpani))
            c.vergi_geliri *= c.vergi_carpani
            
            if c.kamu_borc > P.kamu_borc_limiti:
                c.kemer = 40
            if c.kemer > 0:
                G_arzu *= (1 - P.kemer_siddeti)
                c.kemer -= 1
            G = G_arzu
            
            birincil = (G - c.vergi_geliri)/max(c.Y, 1e-6)
            kb_carpan = max(0.97, min(1.020, 1 + c.i_ef - max(c.y_buyume, -0.02)))
            c.kamu_borc = max(0.0, min(P.borc_orani_tavani, c.kamu_borc*kb_carpan + birincil))
            
            # Kamu İflası / Temerrüt
            if c.kamu_borc > P.kamu_temerrut and rng.random() < 0.02:
                c.kamu_borc *= (1-P.mor_kesinti)
                c.mor_ceza = P.mor_ceza_sure
                c.vergi_carpani = min(2.20, c.vergi_carpani+0.15)
                c.temerrutler.append(t)
                self.log.append((t, "TEMERRUT", f"{c.ad} kamu borclarini odeyemedi! İflas ilan edildi."))
                
            D_talep = C + I + G + max(c.VT_net, 0)
            if c.savasta:
                D_talep = max(D_talep, Y_pot*0.95)

            # ASIRI URETIM: Y_pot ile efektif talep arasindaki ham acik.
            c.talep_acigi = max(0.0, (Y_pot - D_talep)/max(Y_pot, 1e-9))
                
            if c.rejim == "sosyalist":
                # Sosyalist planlı hasıla kapasitesi
                Y = Y_pot*min(0.99, P.plan_kullanim + P.plan_pke_kullanim*c.PKE)
            else:
                Y = min(Y_pot, max(D_talep, Y_pot*P.gecim_tabani))
                
            c.Y = Y
            c.Y_zirve = max(c.Y_zirve, Y)
            c.y_buyume = 0.85*c.y_buyume + 0.15*((Y-Y_onceki)/max(Y_onceki, 1e-6))
            c.u = max(0.20, min(1.0, Y/max(Y_K, 1e-9)))
            
            if c.savasta:
                c.u = min(1.0, c.u+P.sv_seferberlik)
                
            if c.rejim == "sosyalist":
                gereken_saat = (Y/c.q)/max(
                    c.L_etkin*P.plan_istihdam*P.hafta_norm[min(c.era, 6)-1], 1e-9)
                c.saat = max(c.saat_tabani(P), min(1.0, gereken_saat))
                c.e = max(P.e_taban, min(1.0, Y/max(Y_L, 1e-9)))
            else:
                # Istihdam artik FIZIKSEL kapasitenin kullanimidir; robotlar
                # kapasiteyi buyuttukce ayni hasila daha az canli emek ister.
                c.e = max(P.e_taban, min(1.0, Y/max(Y_L, 1e-9)))
                
            iss = 1.0 - c.e
            
            # Isgucune katilim: uzun sureli issizlik cikisa yol acar. Bir turluk
            # gecikmelidir (L_etkin bu turun basinda kullanildi) ve kasitli olarak
            # cok yavastir -- kusaklar arasi bir surectir, konjonkturel degil.
            # =========================================================
            # EVRENSEL TEMEL GELIR -- fiili duzey ve baskin okuma
            # =========================================================
            # Politika hedefi yavas yerlesir: bir gelir garantisi ancak
            # kurumsallastiginda davranis degistirir.
            # ETG YALNIZCA KAPITALIST REJIMDE tanimlidir. Planli ekonomide ucret
            # zaten planla belirlenir; "emek gucunun degeri", "rezervasyon ucreti"
            # ve "metasizlasma" kavramlarinin ucu de piyasa uzerinden calisir ve
            # orada karsiligi yoktur. Sosyalist kolda garantili gelir bir bolusum
            # normu sorunudur (pay/PKE), ETG mekanigi degil.
            if c.rejim != "kapitalist":
                c.etg_hedef = 0.0
                c.etg = 0.0
                c.etg_metasiz = 0.0
            else:
                c.etg += P.etg_yerlesme*self.politika_hizi(c)*(max(0.0, c.etg_hedef) - c.etg)
                c.etg = max(0.0, min(0.40, c.etg))
            # Hangi okumanin baskin oldugu ORGUTLULUGE baglidir:
            # org yuksek -> metasizlasma (isci el koyar), dusuk -> subvansiyon
            # (isveren el koyar). Bu, gercek bir teorik tartismanin mekanizma
            # hali; bir parametre secimi degil.
                c.etg_metasiz = min(1.0, c.org/P.etg_org_ref)

            hedef_katilim = P.kat_taban + (1.0-P.kat_taban)*min(1.0, c.e/P.kat_e_ref)
            # Gonullu cekilme: ETG katilimi dusurur. DIKKAT -- bu L_etkin'i
            # kucultup olculen istihdam oranini MEKANIK olarak yukseltir. Gercek
            # bir etki ve gercek bir elestiri; gizlenmiyor, gorunur birakiliyor.
            c.katilim_etg = P.etg_katilim*c.etg
            hedef_katilim -= c.katilim_etg
            c.katilim += P.kat_hiz*(hedef_katilim - c.katilim)
            c.katilim = max(P.kat_taban, min(1.0, c.katilim))
            
            # =========================================================
            # KARANLIK DEVLET KATMANI  (onceki surum'de yeniden kuruldu)
            # =========================================================
            # 1) ENDOJEN MAFYA TOLERANSI
            # Devlet uyusturucu ekonomisine, birikim tikandiginda ve sinif
            # ofkesini bastirmanin baska araci kalmadiginda goz yumar.
            # NOT: c.r ve c.i_ef burada bir onceki turun degerleridir (bu turun
            # r'si asagida hesaplanir). Bir turluk gecikme kasitlidir: devlet
            # politikasi gozlemlenmis karliliga tepki verir.
            if c.mafya_kilit is not None:
                c.mafya_tolerans = max(0.0, min(1.0, c.mafya_kilit))
                c.kd_hedef = c.mafya_tolerans
            elif c.rejim == "kapitalist":
                tikanma = min(1.0, max(0.0, (c.i_ef-c.r)/P.kd_tikanma_olcek))
                # Refah yatistirmasi mumkunse karanlik araca gerek kalmaz.
                refah_yoklugu = 1.0 - min(1.0, max(0.0, c.r-P.r_referans)/P.r_refah_olcek)
                c.kd_hedef = max(0.0, min(P.kd_tavan,
                                          P.kd_taban
                                          + P.kd_tikanma*tikanma
                                          + P.kd_omega*c.Omega*refah_yoklugu*max(0.0, 1.0-P.etg_kd*c.etg)
                                          + P.kd_baski*c.baski_egilimi
                                          - P.kd_mesruiyet*min(c.PC, 1.0)
                                          - P.kd_org*c.org))
                c.mafya_tolerans += P.kd_hiz*(c.kd_hedef - c.mafya_tolerans)
            else:
                c.kd_hedef = 0.0
                c.mafya_tolerans += P.kd_hiz*(0.0 - c.mafya_tolerans)
            c.mafya_tolerans = max(0.0, min(1.0, c.mafya_tolerans))

            # 2) UYUSTURUCU YAYILIMI -- lojistik, ic dengeli
            # Yayilim ve bastirma ARTIK IKISI DE uo ile orantili; boylece
            # tolerans surekli bir kadran gibi davranir (onceki surum'da ac/kapa idi).
            yayilim = (P.uo_omega*c.Omega*c.mafya_tolerans          # MERKEZI KANAL
                       + P.uo_iss*max(0.0, iss-P.uo_iss_esik)       # yedek sanayi ordusu
                       + P.uo_gecim*max(0.0, P.gecim_tabani-c.pay)) # gecim krizi
            # Bastirma kapasitesi mesruiyete TAM bagli degildir: rizasi cokmus bir
            # devletin de zor aygiti vardir. onceki surum-ilk denemede bastirma = f(PC) idi
            # ve PC cokunce bastirma sifirlanip kacak bir dongu olusuyordu.
            bastirma = P.uo_bastirma*(1.0-c.mafya_tolerans)*(
                P.uo_bastirma_taban + (1.0-P.uo_bastirma_taban)*min(c.PC, 1.0))
            d_uo = (yayilim*(1.0 - c.uyusturucu_orani/P.uo_tavan)
                    - (bastirma + P.uo_cozulme)*c.uyusturucu_orani)
            c.uyusturucu_orani = max(0.0005, min(P.uo_tavan, c.uyusturucu_orani + d_uo))
            
            # 3) KARSERAL NUFUS (Uyusturucu + issizlik + polis baskisi)
            # Karseral oran: ampirik capa olarak dunya rekoru ~%0.65 (ABD),
            # tipik OECD ~%0.1-0.2. Tavan %2.5 asiri karseral devlet senaryosudur.
            c.cezaevi_orani = max(0.0008, min(P.cezaevi_tavan,
                                              P.karseral_taban
                                              + P.karseral_uo*c.uyusturucu_orani
                                              + P.karseral_iss*iss
                                              + P.karseral_baski*c.baski_egilimi*c.Omega))
            
            # Endojen Doğum Oranı (Demografik Kriz)
            era_katsayi = 1.0 - 0.12 * (c.era - 1)
            refah_etki = max(0.0, c.pay - 0.30) + P.etg_dogum*c.etg
            huzursuzluk_soku = 0.35 * c.Omega + 0.20 * iss + 0.15 * max(0.0, c.pi_inf) + 0.40 * c.uyusturucu_orani
            
            base_br = 0.012 if c.tip == "merkez" else (0.018 if c.tip == "yari" else 0.026)
            c.dogum_orani = max(0.004, min(0.045, base_br * era_katsayi * (1.0 - min(0.85, huzursuzluk_soku)) + 0.01 * refah_etki))
            
            # Savaş, uyuşturucu salgını ve yaşlılık ölüm oranını artırır
            c.olum_orani = max(0.003, min(0.030, (0.008 if c.tip == "merkez" else 0.006) + (0.008 if c.savasta else 0.0) + 0.05 * c.uyusturucu_orani))
            
            c.e_norm = (1-P.e_norm_hiz)*c.e_norm + P.e_norm_hiz*c.e
            # =========================================================
            # TONAK DEGER GASBI  (onceki surum)
            # =========================================================
            # YENI DEGER yalnizca canli emekten gelir. Fiziksel hasila Y devasa
            # olabilir; deger buyuklugu V bundan bagimsiz olarak buzulur.
            c.V_yeni = Y*c.canli_pay
            s_ham = c.V_yeni*(1-c.pay)*(1 - c.kamu_pay*(1-P.kamu_r_farki))
            c.s_v = (1-c.pay)/max(c.pay, 1e-6)          # KODEY: somuru orani s/v
            c.lumpen_pay = min(P.lumpen_tavan, P.lumpen_carpani*c.uyusturucu_orani)
            # Illegal sektor, payinin OTESINDE deger ceker (illegalite primi);
            # payi kadari uretken birikimden dusulur, asan kismi ucretlerden gelir.
            c.gasp = s_ham*c.lumpen_pay*P.illegalite_primi
            # ETG'nin sermayeden finansmani NET karliligi dusurur: bu, birikimi
            # yavaslatarak LTRPF'yi hizlandirir ve kendi vergi tabanini asindirir.
            s_ham *= max(0.15, 1.0 - P.etg_vergi_sermaye*c.etg_vergi_sermaye_o)
            s = s_ham*(1.0 - c.lumpen_pay)              # uretken birikime kalan
            # Gasbedilen deger uretken sermayeye degil, asalak/spekulatif stoka akar.
            c.varlik += P.gasp_varlik*c.gasp
            c.r = s/max(c.K, 1e-6)
            
            # J. Spekülatif Varlık Balonu (Finansallaşma + Minsky)
            varlik_onc = c.varlik
            v_oran_onc = c.varlik/max(Y, 1e-6)
            if c.rejim == "kapitalist" and c.delev == 0:
                # (i) Kar sikismasi kanali: uretken alan spekulatif getiriyi
                #     yenemedigi olcude artik deger finansa kayar.
                makas = max(0.0, (c.i_spec-c.r)/max(c.i_spec, 1e-6))
                # (i) Arti-deger AKIMINDAN kayis + SERMAYE STOKUNDAN kayis.
                # v4.4'da yalnizca akim (s) vardi. Otomasyon katmani aciklinca
                # s cokuyor ve spekulasyon kanali onunla birlikte oluyordu
                # (Minsky araligi 40 -> 540 yil). Oysa uretken karlilik dustukce
                # finansallasmanin ARTMASI beklenir: finansal getiri arayan sey
                # arti-deger akimi degil, atil duran SERMAYE STOKUDUR. Ikisi de
                # gereklidir; biri akimi, digeri stogu temsil eder.
                kayan = P.fin_pay*KURUMLAR[c.kurum]['finans']*max(s, 0.0)*makas
                # NOT: burada AYRICA bir "atil kapasite" kosulu KULLANILMAZ.
                # Ilk denemede `max(0, 1 - u/u_normal)` carpani konmustu; u zaten
                # normalin uzerinde seyrettigi icin terim hep sifirlaniyordu.
                # Dogru kapi zaten `makas`tir: uretken alan finansal getiriyi
                # yenemiyorsa sermaye oraya kayar, kapasite dolu olsa bile.
                kayan += P.fin_stok*KURUMLAR[c.kurum]['finans']*c.K*makas
                # (ii) Kaldiracli spekulasyon: balon kendi beklentisini besler.
                kayan += (P.spec_kredi*KURUMLAR[c.kurum]['kredi']
                          * c.varlik*max(0.0, c.varlik_beklenti))
                # (iii) Doygunluk: mutlak sinira yaklastikca akim soner.
                kayan *= max(0.0, 1.0 - v_oran_onc/P.balon_limiti)
                c.varlik += kayan
            c.varlik *= (1-P.balon_sonum)
            
            # Varlik FIYATI (varlik/Y) uzerinden getiri beklentisi -- uyarlanan/
            # ekstrapolatif (Minsky). Ham stok yerine orani kullanmak gerekir:
            # hasila buyurken sabit bir stok reel olarak deger kaybediyor demektir.
            v_oran_yeni = c.varlik/max(Y, 1e-6)
            getiri = (v_oran_yeni/v_oran_onc - 1.0) if v_oran_onc > 1e-9 else 0.0
            c.varlik_beklenti = min(P.beklenti_tavan,
                                    (1-P.beklenti_hiz)*c.varlik_beklenti + P.beklenti_hiz*getiri)
            # Kirilganlik + tersine donus sayaci
            if v_oran_yeni > P.minsky_esik and c.varlik_beklenti < c.i_spec:
                c.minsky_sayac += 1
            else:
                c.minsky_sayac = max(0, c.minsky_sayac-1)
            
            varlik_orani = c.varlik/max(Y, 1e-6)
            borc_orani = c.borc/max(Y, 1e-6)
            
            # K. Fisher & Clarke Borç Balon Patlaması (Tip B Kriz)
            cokme = None
            if c.rejim == "kapitalist" and c.delev == 0:
                if borc_orani > P.borc_limiti:
                    cokme = "BORC"        # Tip B2: hanehalki borc krizi
                elif varlik_orani > P.balon_limiti:
                    cokme = "BALON"       # Tip B: mutlak balon siniri
                elif c.minsky_sayac >= P.minsky_sure:
                    # Tip B (Minsky): varlik getirisi finansman maliyetinin altina
                    # dustu. Kirilganlik bolgesinde bu, teminat degerini cokerten
                    # geri donusu tetikler. Sabit bir varlik/Y esiginden cok daha
                    # dogru bir tetikleyicidir.
                    cokme = "MINSKY"
                    
                if cokme:
                    c.minsky_sayac = 0
                    c.delev = P.delev_sure
                    c.varlik *= 0.35
                    c.borc *= (1 + P.deflasyon + max(0.0, -c.pi_inf)*3)
                    c.K *= 0.97
                    # Finansal cokme sabit sermayeyi degersizlestirir
                    c.deger_carpani = max(P.dev_taban, c.deger_carpani*(1-P.dev_cokme))
                    self.log.append((t, "COKME", f"{c.ad} spekulatif varlik balonu {cokme} patladi! Sistem de-leveraginge giriyor."))
            
            # L. Bölgeler Arası Değer Transferi (Sızıntı)
            if c.rejim == "sosyalist":
                disa = (1.0/(1.0+0.6*blok))*(1-P.ab_vt*min(c.abluka, 3)/3)
            else:
                disa = 1.0-P.ab_vt*min(c.abluka, 3)/3 if c.abluka else 1.0
                
            d1 = (cv-ort_cv)/max(ort_cv, .05)
            d2 = ((1/max(c.pay, .05)-1)-ort_sv)/max(ort_sv, .05)
            wd1, wd2 = (0.9, 0.1) if c.tip == "cevre" else (0.2, 0.8)
            
            c.VT_net = P.vt_siddet*Y*(wd1*d1+wd2*d2)*max(disa, 0.0)
            r_ef = (s+c.VT_net)/max(c.K, 1e-6)
            
            # M. Kamu Sermayesi & Kamulaştırma Payı
            kamu_hedef_ef = max(0.0, min(0.95, KURUMLAR[c.kurum]['kamu_hedef']
                                         + c.yatirim_durusu))
            c.kamu_pay += P.kamu_uyum*(kamu_hedef_ef-c.kamu_pay)
            c.kamu_pay = max(0.0, min(0.85, c.kamu_pay))
            
            if c.rejim == "kapitalist":
                hz = KURUMLAR[c.kurum].get('hizlandirici', P.hizlandirici)
                g_ozel = P.g_taban + P.g_duy*(r_ef - c.i_ef) + hz*(c.u-P.u_normal)
                if c.delev > 0: g_ozel -= 0.0025
                g_kamu = 0.004 - P.kamu_istikrar*min(0.0, r_ef-c.i_ef)
                c.g = (1-c.kamu_pay)*g_ozel + c.kamu_pay*g_kamu
            else:
                # Blok bonusu yalnizca ITTIFAK halindeki ulkelere; rekabet
                # halindeki bir ulke fiilen yalnizdir.
                _ittifakta = c.pakt_durusu != "rekabet" and blok > 1
                c.PKE = min(0.99, E["pke"]+(P.blok_pke_bonus if _ittifakta else 0))
                # Plan profili hedefe yavas yakinsar (plan degisikligi bir tur
                # meselesi degildir) ve her zaman normalize edilir.
                if c.plan_hedef:
                    ph = P.plan_hiz*self.politika_hizi(c)
                    for k in c.plan:
                        c.plan[k] += ph*(c.plan_hedef.get(k, c.plan[k]) - c.plan[k])
                tp = sum(max(0.0, v) for v in c.plan.values()) or 1.0
                for k in c.plan:
                    c.plan[k] = max(0.0, c.plan[k])/tp
                # KITLIK: tuketim mallarina ayrilan payin normun altinda kalmasi.
                # Planli ekonominin kendine ozgu kriz bicimi budur.
                # Kitligin IKI kaynagi var:
                #  (a) planin tuketime ayirdigi payin norm altinda kalmasi
                #  (b) ABLUKA/AMBARGO: tuketim mali ithal edilemez, plan ne olursa
                #      olsun kitlik dogar. v4.4'da yalnizca (a) vardi; bu yuzden
                #      sosyalist AI kitlik gorunce tuketimci plana gecip kitligi
                #      SIFIRLIYOR ve restorasyon kosulunu kendisi engelliyordu
                #      (8 devrim, 0 restorasyon). Kusatma altinda plan degistirmek
                #      kitligi gidermeye yetmez -- Kuba ve SSCB deneyimi budur.
                _plan_kitlik = 1.0 - c.plan["tuketim"]/max(P.plan_tuketim_ref, 1e-6)
                _kusatma = P.izo_abluka_kitlik*(min(c.abluka, 3)/3.0) \
                           + (P.izo_ambargo_kitlik if c.ambargo else 0.0)
                c.kitlik = max(0.0, min(1.0, _plan_kitlik + _kusatma))
                # Birikim hizi artik plan payina baglidir.
                c.g = (P.plan_g*c.PKE*P.plan_yatirim_olcek*c.plan["yatirim"]
                       + P.plan_u_duy*(c.u-P.u_normal))
                c.g = max(-P.g_daralma_tavani, min(P.g_tavani, c.g))
                
            c.K = max(1.0, c.K*(1+c.g))
            
            if c.savasta:
                rg = sum(next((x.guc for x in D if x.ad == k), 0) for k in c.savas)
                oran = rg/max(c.guc+rg, 1e-6)
                c.K *= (1-P.sv_yikim*(0.5+oran))
                c.pay = max(0.12, c.pay*(1-P.sv_tuketim))
                c.Omega = min(1.0, c.Omega+P.sv_yorgunluk*0.8)
                
            # N. Haftalık Çalışma Süresi Ayarlaması
            if c.rejim != "sosyalist":
                if iss > 0.06:
                    c.saat -= P.saat_org*c.org*min(iss, 0.30)
                elif iss < 0.05:
                    c.saat += P.saat_geri*(0.05-iss)*10
                c.saat = max(c.saat_tabani(P), min(1.0, c.saat))
                
            # O. Eğitim, AR-GE & Nitelik Birikimi
            # onceki surum: guvenlik harcamasi egitim butcesini disllar
            egitim_pay_ef = KURUMLAR[c.kurum]['egitim_pay']*(
                1 - P.karseral_egitim_disla*min(1.0, c.cezaevi_orani/P.cezaevi_ref))
            egitim_harcama = G*egitim_pay_ef/max(c.Y, 1e-6)
            c.egitim += egitim_harcama*0.25 - P.egitim_asinma*3*c.egitim
            c.egitim = max(0.0, min(1.0, c.egitim))
            
            if c.rejim == "kapitalist":
                rd = P.rd_pay*max(s, 0.0)/max(c.K, 1)
            else:
                # Planli ekonomide AR-GE artik degerin bir payi degil, PLANIN
                # bir kalemidir; kar orani araciligina ihtiyac duymaz.
                rd = P.plan_arge_olcek*c.plan["arge"]*c.PKE*P.rd_pay
            hiz = 1.0
            if c.ambargo:
                hiz *= (1-P.amb_q)
            if c.rejim == "sosyalist" and blok > 1:
                hiz *= (1+0.10*min(blok, 6))
                
            # Asimetrik teknolojik yayılım hızı (Orta gelir tuzağı kilidi)
            hiz *= {"merkez": P.yayilim_merkez, "yari": P.yayilim_yari}.get(c.tip, P.yayilim_cevre)
            # Uyuşturucu kullanımı nitelikli emek birikimini ve verimliliği doğrudan aşındırır
            nitelik = max(0.1, (1 + P.egitim_q*c.egitim) * (1.0 - 0.70 * c.uyusturucu_orani))
            kamu_din = 1 - c.kamu_pay*(1-P.kamu_verimlilik)
            
            doyum = max(P.q_doyum_taban, 1.0 - c.q/E["q_tavan"])
            if c.rejim == "sosyalist":
                # Kitlik verimliligi asindirir (moral, devamsizlik, ikinci ekonomi).
                doyum *= max(0.15, 1.0 - P.plan_kitlik_q*c.kitlik)
            # Mekanizasyonun DURTUSU: emek kitligi x ucret baskisi.
            # Emek bol ve ucuzsa sermaye emegi ikame etmez.
            # (1) Ucret-maliyet durtusu (Marx, Kapital I/15)
            ito_ucret = (c.pay/P.ito_pay_ref)*(c.e/P.ito_e_ref)
            # (2) Rekabetin zorlayici yasasi: frontier'in gerisine dusen
            #     mekanize etmek ZORUNDADIR, ucreti ucuz olsa bile.
            ito_rek = P.ito_rekabet*max(0.0, 1.0 - c.q/max(ort_q, 1e-6))
            # (3) Makinenin ucuzlamasi: seri uretim + ucuz enerji
            ito_mak = P.ito_makine*self.ucuzlama_orani(c.q)
            # (4) Demografik kitlik: yaslanan nufusta isgucu daralir
            nufus_hizi = c.dogum_orani - c.olum_orani
            ito_dem = P.ito_demografi*max(0.0, 1.0 - nufus_hizi/P.ito_nufus_ref)
            c.ito = P.ito_taban + (1.0-P.ito_taban)*min(
                P.ito_tavan, ito_ucret + ito_rek + ito_mak + ito_dem)
            c.ito_bilesen = (ito_ucret, ito_rek, ito_mak, ito_dem)
            q_buyume = E["qg"]*(0.5+1.6*min(rd*P.rd_olcek, 1.2))*hiz*nitelik*kamu_din*doyum*c.ito
            if rng.random() < 0.012:
                q_buyume += 0.03*doyum
            c.q *= (1+q_buyume)
            c.q_buyume = q_buyume
            
            # Çağ Atlama / Faz Geçişi -- icsel ama tarihsel banda cakili
            _atla = False
            if c.era < 6:
                _E2 = ERAS[c.era+1]
                _yil = self.yil
                _atla = _yil >= _E2["yil_alt"] and (
                    c.q > _E2["q_esik"] or _yil >= _E2["yil_ust"])
            if _atla:
                c.era += 1
                c.IR = min(1.0, c.IR+0.08)
                c.K *= (1-P.gecis_yikim)
                c.gecis_sok = P.gecis_sok_sure
                if c.rejim == "kapitalist":
                    c.Omega = min(1.0, c.Omega+P.gecis_omega)
                self.log.append((t, "CAG", f"{c.ad} sanayisi cag atladi: {ERAS[c.era]['name']} evresine girdi!"))
                
            # P. Phillips Eğrisi & Enflasyon
            birim_emek = max(-0.15, min(0.25, c.w_nom_buyume - q_buyume))
            sok = P.ph_sok if (c.savasta or c.fx_kriz > 0) else 0.0
            bosluk = c.u - P.u_normal
            talep_etkisi = P.ph_talep*bosluk if bosluk > 0 else P.ph_talep*P.ph_asimetri*max(bosluk, -0.30)
            pi_ham = (P.ph_beklenti*c.pi_bek + talep_etkisi
                      + P.ph_maliyet*max(birim_emek, -0.04) + sok)
            if c.delev > 0:
                pi_ham -= P.delev_deflasyon
                
            # Fiyat Kontrolleri
            if c.kontrol == 0 and pi_ham > P.kont_esigi and c.rejim == "kapitalist":
                c.kontrol = P.kont_sure
                self.log.append((t, "KONTROL", f"{c.ad} hiperenflasyon baskisi altinda fiyat kontrolleri baslatti."))
                
            if c.kontrol > 0:
                bastirilan = pi_ham*P.kont_etki
                c.bastirilmis_pi += bastirilan
                pi_ham -= bastirilan
                c.kontrol -= 1
                if c.kontrol == 0:
                    pi_ham += c.bastirilmis_pi*P.kont_patlama
                    c.bastirilmis_pi = 0.0
                    self.log.append((t, "KONTROL BITTI", f"{c.ad} fiyat kontrol donemi bitti, bastirilmis enflasyon puskurdu!"))
                    
            c.pi_inf = max(P.pi_min, min(P.pi_max, pi_ham))
            c.pi_bek = 0.80*c.pi_bek + 0.14*c.pi_inf + 0.06*P.pi_hedef
            c.p_duzey *= (1+c.pi_inf)
            
            if c.pi_inf > P.stagf_pi_esigi and iss > 0.10:
                c.stagflasyon += 1
            else:
                c.stagflasyon = max(0, c.stagflasyon-1)
                
            # Q. Goodwin Sınıfsal Nominal Ücret Pazarlığı
            if c.rejim == "kapitalist":
                telafi = P.w_beklenti*(1 + P.w_org*c.org)
                bos_e = c.e - c.e_norm
                # (2) METASIZLASMA: garantili gelir rezervasyon ucretini
                # yukseltir; isci ucret indirimini reddedebilir hale gelir, yani
                # asagi yonlu nominal katilik ARTAR (kat -> 1'e yaklasir).
                kat = P.w_katilik + (1-P.w_katilik)*min(1.0, iss/P.katilik_cozulme)
                kat = min(1.0, kat + P.etg_katilik*c.etg*c.etg_metasiz)
                goodwin = P.phi*bos_e if bos_e > 0 else P.phi*kat*bos_e
                taban = KURUMLAR[c.kurum]['emek_pay']
                aktarim = taban + (1-taban)*c.org
                c.w_nom_buyume = (telafi*c.pi_bek + goodwin + P.w_org_e*c.org*(c.e-P.e0) + aktarim*q_buyume)
                
                if c.kontrol > 0:
                    c.w_nom_buyume *= (1-P.kont_etki)
                d_pay = max(-P.pay_degisim_tavani, min(P.pay_degisim_tavani, c.w_nom_buyume - c.pi_inf - q_buyume))
                c.pay *= (1 + d_pay)
            else:
                # Ucret payi hedefi kitliktan dusulur: nominal pay yuksek olsa da
                # tuketim mali yoksa gercek bolusum duser.
                hedef_pay = (P.sos_pay_taban + P.sos_pay_pke*c.PKE
                             - P.plan_kitlik_pay*c.kitlik)
                c.pay += P.sos_pay_hiz*(hedef_pay - c.pay)
                
            # onceki surum: illegal sektorun super-somurusu ucret payinin TABANINI dusurur.
            # (Ilk denemede bu bir buyume orani drenaji olarak kurulmustu; 1200 turda
            # bilesiklenip ucret payini 0.58'den 0.17'ye suruyordu -- seviye etkisi
            # olmasi gerekirken sinirsiz bir kaymaya donusuyordu.)
            # (1) UCRET SUBVANSIYONU: gecimin toplumsallasan kismi kadar emek
            # gucunun degeri duser. Yalnizca subvansiyon agirligi (1-metasiz)
            # olcusunde etkilidir -- orgutlu isci bunu ucret indirimine
            # cevirtmez.
            etg_taban_etkisi = P.etg_taban_dus*c.etg*(1.0 - c.etg_metasiz)
            pay_taban = max(0.10, P.pay_taban0 + P.pay_taban_org*c.org
                            - P.gasp_taban*c.lumpen_pay
                            - etg_taban_etkisi)
            if c.parti_iktidari:
                # Parti iktidari + kapitalist birikim: emegin pazarlik zemini
                # siyaseten bastirilmis oldugu icin ucret payi tabani duser.
                pay_taban = min(pay_taban, P.parti_pay_taban)
            c.pay = max(pay_taban, min(P.pay_tavani, c.pay))
            
            # R. İki Kademeli Kriz Tescil Sınıflandırması (Resesyon vs Depresyon)
            c.Y_ort = 0.90*c.Y_ort + 0.10*Y if t > 0 else Y
            c.Y_trend = max(c.Y_trend*P.trend_asinma, c.Y_ort)
            derinlik = 1 - c.Y_ort/max(c.Y_trend, 1e-9)
            
            # Asiri uretim krizi: emilemeyen talep acigi (planli ekonomide yok --
            # gerceklesme krizi kapitalizme ozgudur).
            c.au_bekle = max(0, c.au_bekle-1)
            if c.rejim == "kapitalist" and c.talep_acigi > P.au_esik:
                c.au_ici += 1
                if c.au_ici >= P.au_sure and c.au_bekle == 0:
                    c.asiri_uretim_krizleri.append((t, round(c.talep_acigi, 4)))
                    c.au_bekle = P.au_bekleme
                    c.Omega = min(1.0, c.Omega + P.au_omega)
                    self.log.append((t, "ASIRI URETIM",
                                     f"{c.ad}: satilamayan urun kitlesi birikti "
                                     f"(talep acigi %{c.talep_acigi*100:.0f}). Asiri uretim krizi."))
            else:
                c.au_ici = 0

            # Resesyon: art arda daralan hasila (konjonkturel olgu)
            c.res_bekle = max(0, c.res_bekle-1)
            if c.y_buyume < P.res_daralma:
                c.res_ici += 1
                if c.res_ici >= P.res_sure and c.res_bekle == 0:
                    c.resesyonlar.append((t, round(c.y_buyume, 4)))
                    c.res_bekle = P.res_bekleme
            else:
                c.res_ici = 0
                
            if derinlik > P.bun_esik:
                c.bun_ici += 1
                if c.bun_ici == P.bun_sure:
                    pen = c.tarih[max(0, len(c.tarih)-45):max(1, len(c.tarih)-15)]
                    rli_t = sum(1 for h in pen if h["r"] < h.get("i_spec", h["i_ef"]))/max(len(pen), 1) if pen else 0.0
                    stagf = c.stagflasyon > 15
                    if stagf or rli_t > 0.30:
                        tip = "STAGFLASYON" if stagf else "KAR SIKISMASI"
                    elif c.fx_kriz > 0 or (c.fx_krizleri and t - c.fx_krizleri[-1] < 40):
                        tip = "DOVIZ"
                    elif c.delev > 0:
                        tip = "FINANSAL"
                    elif c.pay < 0.45 and c.u < 0.75:
                        tip = "GERCEKLESME"
                    else:
                        tip = "KARMA"
                    # Buyuk bunalim: kitlesel iflas ve defterden silme
                    c.deger_carpani = max(P.dev_taban, c.deger_carpani*(1-P.dev_bunalim))
                    c.bunalimlar.append((t, tip, round(derinlik, 3)))
                    self.log.append((t, "BUYUK BUNALIM", f"{c.ad} bolgesinde {tip} bunalimi koptu! Derinlik: {derinlik:.2f}"))
            else:
                c.bun_ici = 0
                
            # S. Sınıf Örgütlenme Stoku & Kentleşme (Lojistik stok modeli)
            if c.gecis_sok > 0: c.gecis_sok -= 1
            krizde = (c.r < P.r_kriz_esigi) or (iss > 0.13) or c.savasta or c.gecis_sok > 0 or c.delev > 0
            c.kriz = c.kriz+1 if krizde else max(0, c.kriz-2)
            kriz_n = min(c.kriz/25, 1.2)
            
            if c.rejim == "kapitalist":
                aktif_pr = self.sg(P.kappa*(P.b_pay*(1-c.pay)+P.b_iss*iss-P.theta))
                baski0 = c.baski_egilimi*min(c.PC, 1.0)*(1.0 if (aktif_pr > P.tepki_esigi or kriz_n > P.tepki_esigi) else 0.0)
                eroz = P.org_erozyon*KURUMLAR[c.kurum]['org_eroz']*(P.org_era_era_erozyon*(c.era-2) if c.era >= 3 else 0.0)
                buyume = (P.org_kent*E["kent"] + P.org_kriz*kriz_n + P.egitim_org*c.egitim)
                azalma = (P.org_baski*baski0 + eroz)
                dorg = buyume*(1.0-c.org) - azalma*c.org
                # Uyuşturucu mafyası ve yaygın kullanım, işçiler arasındaki dayanışmayı kırar ve sendikalaşmayı baltalar
                # onceki surum: cozulme, POLITIKA degiskenine degil fiili lumpenlesmeye bagli.
                # onceki surum'da terim mafya_tolerans ile carpiliyordu; devletin savastigi
                # ama yine de yayilmis bir uyusturucu ekonomisi sendikal dokuyu
                # hic etkilemiyordu.
                dorg -= P.lumpen_org * c.lumpen_pay * c.org
                c.org = max(0.0, min(0.98, c.org+dorg))
            else:
                c.org = min(0.98, c.org+0.001*(0.98-c.org))
                
            # T. Lojistik Protesto Riski & Sosyalist Devrim (v4.4)
            if c.rejim == "kapitalist":
                arg = P.b_pay*(1-c.pay)+P.b_iss*iss-P.theta
            else:
                # v4.4: gerilim artik (1-PKE) vekilinden degil FIILI KITLIKTAN
                # gelir. Planlama gucu yuksek ama tuketimi kisan bir plan da
                # huzursuzluk uretir -- ki tarihsel olarak olan tam budur.
                # Bolluk carpani: kitlik sos_bolluk_esigi'nin altindaysa
                # issizlik gerilimi sos_iss_bolluk oraninda sonumlenir; kitlik
                # arttikca issizlik yine tam agirliginla geri gelir.
                bolluk = max(0.0, 1.0 - c.kitlik/max(P.sos_bolluk_esigi, 1e-6))
                iss_agirlik = 1.0 - P.sos_iss_bolluk*min(1.0, bolluk)
                arg = (P.b_pay*P.sos_kitlik_agirlik*(0.5*(1-c.PKE) + c.kitlik)
                       + P.b_iss*iss*iss_agirlik - P.theta)
            # Mafya toleransı ve uyuşturucu kullanımı sınıf tepkisini sönümler (Lumpenleşme Etkisi)
            # --- MARKSIST POLITIK OZNE ---
            # Zemin: issizler kitlesi + yoksullasma + kriz deneyimi.
            # Yikici: baski aygiti ve lumpenlesme.
            _iss_simdi = 1.0 - c.e
            _zemin = (P.parti_iss*_iss_simdi
                      + P.parti_yoksullasma*max(0.0, 1.0 - c.pay/P.parti_pay_ref)
                      + P.parti_kriz*kriz_n)
            _yikim = P.parti_baski*c.baski_egilimi + P.parti_lumpen*c.lumpen_pay
            _hedef = max(0.0, min(P.parti_tavan, _zemin - _yikim))
            c.parti += P.parti_hiz*(_hedef - c.parti)
            c.parti = max(0.0, min(P.parti_tavan, c.parti))
            # Parti, sendikanin ulasamadigi kitleyi kapsar.
            c.orgutlu = c.org + c.parti*(1.0 - c.org)

            # Bolme/yozlastirma politikalarina direnc: bilinclendirme sonumlemeyi kirar
            _direnc = 1.0 - P.parti_direnc*c.parti
            lumpen_sonum = 1.0 - min(0.85, P.lumpen_sonum_gucu*c.lumpen_pay*_direnc)
            # onceki surum: Karseral disiplin -- hapsetme, disipline edilemeyen nufusu
            # fiziksel olarak izole ederek protesto riskini dogrudan bastirir.
            karseral_sonum = 1.0 - min(0.40, P.karseral_disiplin*min(
                2.0, c.cezaevi_orani/P.cezaevi_ref)*_direnc)
            PR = self.sg(P.kappa*arg) * lumpen_sonum * karseral_sonum
            _esik_ef = max(P.pr_esik_min, P.pr_esik - P.pr_esik_omega*c.Omega)
            c.pr_sayac = c.pr_sayac+1 if PR >= _esik_ef else 0
            
            if c.rejim == "kapitalist":
                aktif = 1.0 if (PR > P.tepki_esigi or kriz_n > P.tepki_esigi) else 0.0
                baski = c.baski_egilimi*min(c.PC, 1.0)*aktif
                reform = (1-c.baski_egilimi)*min(c.PC, 1.0)*aktif
                # (3) PASIFIZASYON: ETG, karliliga bagli refah yatistirmasindan
                # BAGIMSIZ bir yatistirma kanalidir -- kar sikismasi altinda bile
                # calisir. Bedeli butcededir, birikimde degil.
                refah = P.som_refah*min(1.0, max(0.0, c.r-P.r_referans)/P.r_refah_olcek)
                refah += P.etg_omega*c.etg
                vt_baris = P.som_vt*KURUMLAR[c.kurum]['vt_baris']*max(0.0, c.VT_net/max(Y, 1e-6))
                if c.savasta:
                    refah *= P.savas_baris_kesinti
                    vt_baris *= P.savas_baris_kesinti
                    
                # ASIRI URETIM: fiziksel hasila ile satinalma gucu arasindaki
                # makas. canli_pay dustukce Y buyur ama V kucuulur; arada kalan
                # satilamayan urun kitlesi sinif gerilimi uretir.
                makas = max(0.0, (1.0 - c.canli_pay) - P.asiri_esik)
                asiri = P.asiri_uretim*makas*(0.4+1.6*c.orgutlu)

                dO = (P.org_omega*(P.a1*PR + P.a2*kriz_n)*(0.4+1.6*c.orgutlu)
                      + asiri
                      - P.a4*baski - P.a5*reform - P.omega_sonum - refah - vt_baris)
                c.Omega = max(0.0, min(1.0, c.Omega+dO))
                
                if blok:
                    c.Omega = min(1.0, c.Omega+P.yayilma*blok/len(D))
                c.IR = min(1.0, c.IR+0.003*baski)
                # onceki surum: kitlesel hapsetme rizayi asindirir (karseral devletin bedeli)
                # v4.4: riza artik PERFORMANSIN sonucudur.
                refah = (0.40*min(1.0, max(0.0, c.y_buyume/P.pc_buyume_ref))
                         + 0.35*min(1.0, max(0.0, c.e/P.e0))
                         + 0.25*min(1.0, max(0.0, c.pay/P.pc_pay_ref)))
                istikrar = 1.0 - min(1.0, c.Omega)
                hedef_pc = max(0.0, min(1.0, P.pc_taban
                                        + P.pc_refah*refah + P.pc_istikrar*istikrar))
                c.PC += P.pc_hiz*(hedef_pc - c.PC)
                c.PC = max(0.0, min(1.0, c.PC - 0.06*(baski+reform)
                                    - P.karseral_mesruiyet*min(2.0, c.cezaevi_orani/P.cezaevi_ref)))
                
                # Devrim Kontrolü
                if P.devrim_acik and c.pr_sayac >= P.pr_sure and c.Omega >= P.omega_kritik:
                    c.rejim = "sosyalist"
                    c.devrim_t = t
                    c.devrim_era = c.era
                    c.IR = 0.25
                    c.pay = min(0.80, c.pay+0.12)
                    c.borc = 0.0
                    c.varlik = 0.0
                    c.delev = 0
                    c.FX = max(c.FX, 0.15*Y)
                    c.fx_kriz = 0
                    c.savas.clear()
                    self.log.append((t, "DEVRIM", f"{c.ad} bolgesinde SOSYALİST DEVRİM patlak verdi! Yeni rejim kuruldu."))
            else:
                c.Omega = max(0, c.Omega-0.002)
                
            # Veri Kaydı
            c.tarih.append(dict(
                t=t, r=c.r, g=c.g, e=c.e, u=c.u, pay=c.pay, q=c.q, cv=cv,
                Om=c.Omega, PR=PR, era=c.era, rej=c.rejim, VT=c.VT_net,
                PKE=c.PKE, K=c.K, Y=Y, borc=borc_orani, varlik=varlik_orani,
                kitlik=c.kitlik, plan_yatirim=c.plan["yatirim"],
                plan_tuketim=c.plan["tuketim"], plan_arge=c.plan["arge"],
                org=c.org, delev=c.delev, savas=c.savasta,
                derinlik=derinlik, i_pol=c.i_pol, i_ef=c.i_ef,
                FX=c.FX/max(Y, 1e-6), eps=c.eps, pi_m=c.pi_m,
                BoP=c.BoP_R, y=c.y_buyume, pi=c.pi_inf,
                heg=c.hegemon, stagf=c.stagflasyon, saat=c.saat, kurum=c.kurum,
                kamu_borc=c.kamu_borc, kamu_pay=c.kamu_pay,
                dis_borc=c.dis_borc, egitim=c.egitim,
                kontrol=c.kontrol, L=c.L_max, vergi=c.vergi_geliri/max(Y, 1e-6),
                uyusturucu=c.uyusturucu_orani, cezaevi=c.cezaevi_orani, mafya_tolerans=c.mafya_tolerans,
                kd_hedef=c.kd_hedef, dogum=c.dogum_orani, olum=c.olum_orani,
                i_spec=c.i_spec, i_reel=c.i_reel, varlik_beklenti=c.varlik_beklenti,
                katilim=c.katilim, ito=c.ito, deger=c.deger_carpani,
                oto=c.oto, canli_pay=c.canli_pay, V_yeni=c.V_yeni,
                parti=c.parti, orgutlu=c.orgutlu,
                hafta=c.hafta_saati(P), PC=c.PC,
                kredi_durusu=c.kredi_durusu, yatirim_durusu=c.yatirim_durusu,
                ticaret_durusu=c.ticaret_durusu,
                etg=c.etg, etg_metasiz=c.etg_metasiz, cs_kisit=c.cs_kisit,
                etg_v_sermaye=c.etg_vergi_sermaye_o, etg_v_ucret=c.etg_vergi_ucret_o,
                iss_duz=c.iss_duzeltilmis, katilim_etg=c.katilim_etg,
                # KODEY metrik seti (el kitabi Bolum 6)
                s_v=c.s_v, lumpen_pay=c.lumpen_pay,
                gasp_orani=c.gasp/max(Y, 1e-6), atil_endeks=c.atil_endeks,
                L_etkin=c.L_etkin
            ))
            
        # 5. Sıfır Toplamlı Uluslararası Göç Akışları
        goc_ulke = list(D)
        cek = {c.ad: c.pay*c.q*c.e for c in goc_ulke}
        ort_cek = sum(cek.values())/len(cek) if cek else 1.0
        akislar = {}
        for c in goc_ulke:
            fark = (cek[c.ad]-ort_cek)/max(ort_cek, 1e-6)
            akislar[c.ad] = max(-P.goc_tavan, min(P.goc_tavan, P.goc_duyarlilik*fark))
            
        net = sum(akislar[c.ad]*c.L_max for c in goc_ulke)
        tot_L = sum(c.L_max for c in goc_ulke) or 1
        for c in goc_ulke:
            # Endojen nüfus artışı (Doğum - Ölüm, yıllık orandan çeyreklik tura ölçeklenir)
            nufus_artis_endojen = (c.dogum_orani - c.olum_orani) * TUR_YIL
            c.L_max *= (1 + nufus_artis_endojen)
            c.goc_net = akislar[c.ad] - net/tot_L
            c.L_max *= (1 + c.goc_net)
            
        # Savaş Hasarlarının Dağıtımı
        self.savas_yikim_isle()
        # Kriz siniflandirmasi turun SONUNDA calisir: tur ici tescillerin
        # (resesyon, Minsky, FX, temerrut, devrim) tamami olustuktan sonra.
        self.kriz_siniflandir()
        self.t += 1

    def kurumsal_gecis_isle(self, c):
        """Kriz birikimi ve sendikal örgütlülüğe göre kurumsal rejim geçişlerini yönetir."""
        P = self.P
        t = self.t
        if c.rejim != "kapitalist" or t - c.kurum_t < P.kg_min_sure:
            return
        son_bunalim = c.bunalimlar[-1][0] if c.bunalimlar else -9999
        taze_bunalim = 0 <= t - son_bunalim <= P.kg_bunalim_penceresi
        pen = c.tarih[max(0, len(c.tarih)-60):]
        # Duzenli -> neoliberal donusumun kosulu "uretken sermaye finansal getiriyi
        # yenemiyor"dur; dolayisiyla olcut i_reel degil i_spec'tir.
        rli = sum(1 for h in pen if h["r"] < h.get("i_spec", h["i_ef"]))/max(len(pen), 1) if pen else 0.0
        
        derin = c.bunalimlar[-1][2] if c.bunalimlar else 0.0
        zorlayici = taze_bunalim and (c.Omega >= P.kg_omega_esigi
                                      or derin >= P.kg_derin_bunalim)
        
        yeni = None
        if c.kurum == "liberal":
            if taze_bunalim and (c.org >= P.kg_org_esigi or zorlayici):
                yeni = "duzenli"
        elif c.kurum == "duzenli":
            if rli >= P.kg_kar_esigi or c.stagflasyon >= P.kg_stagf_esigi:
                yeni = "neoliberal"
        elif c.kurum == "neoliberal":
            if taze_bunalim and (c.org >= P.kg_geri_donus_org or zorlayici):
                yeni = "duzenli"
                
        if yeni and self.rng.random() < P.kg_olasilik:
            c.kurum_gecmis.append((t, c.kurum, yeni))
            self.log.append((t, "KURUM", f"{c.ad}: Kurumsal rejim {c.kurum} -> {yeni} olarak değişti."))
            c.kurum = yeni
            c.kurum_t = t

    def politika_hizi(self, c):
        """Yerlesme hizi carpani: rejim/kurum ne kadar hizli hareket edebilir."""
        P = self.P
        if c.rejim == "sosyalist":
            return P.pol_hiz_sosyalist
        return {"liberal": P.pol_hiz_liberal,
                "duzenli": P.pol_hiz_duzenli,
                "neoliberal": P.pol_hiz_neoliberal}.get(c.kurum, 1.0)

    def politika_kuyrugu_isle(self, c):
        """Ilan edilmis politikalari gecikme dolunca yururluge koyar (§25)."""
        if not c.pol_kuyruk:
            return
        for ad in list(c.pol_kuyruk):
            deger, etkin_t = c.pol_kuyruk[ad]
            if self.t >= etkin_t:
                if ad == "etg":
                    c.etg_hedef = deger
                elif ad == "etg_finansman":
                    c.etg_sermaye_payi = deger
                elif ad == "plan":
                    c.plan_hedef = deger
                elif ad == "kurum_insa":
                    c.kurum_insa_hedef = deger
                elif ad == "kredi":
                    c.kredi_durusu = deger
                elif ad == "yatirim":
                    c.yatirim_durusu = deger
                elif ad == "ticaret":
                    c.ticaret_durusu = deger
                del c.pol_kuyruk[ad]

    def politika_ilan(self, c, ad, deger, gecikme=None):
        """Bir politikayi ILAN eder; etkisi `pol_gecikme` tur sonra baslar."""
        g = self.P.pol_gecikme if gecikme is None else gecikme
        c.pol_kuyruk[ad] = (deger, self.t + max(0, g))

    def can_simidi_isle(self, c):
        """Devlet, huzursuzlugu esik altinda tutmak icin gereken ETG'yi arar.

        Mali fren gercektir: kamu borcu `cs_borc_freni`'ni asarsa ETG
        artirilamaz -- yani "gereken" ile "finanse edilebilir" ayrisir. Bu
        ayrisma, testin olcmek istedigi seydir.
        """
        P = self.P
        if not P.cs_acik or c.rejim != "kapitalist":
            return
        finanse_edilebilir = c.kamu_borc < P.cs_borc_freni
        if c.Omega > P.cs_omega_hedef and finanse_edilebilir:
            c.etg_hedef = min(P.cs_tavan, c.etg_hedef + P.cs_adim)
            c.cs_kisit = 0
        elif c.Omega > P.cs_omega_hedef:
            c.cs_kisit = 1            # gerekiyor ama finanse edilemiyor
        else:
            c.etg_hedef = max(0.0, c.etg_hedef - P.cs_adim*0.5)
            c.cs_kisit = 0

    def politika_ai_isle(self, c):
        """Rakip ulkenin kurumsal rejimine gore politika secimi.

        Oyuncunun kullandigi genel API'nin aynisini kullanir; dogrudan sonuc
        degistirmez. Oyuncunun kontrol ettigi ulke `ai_muaf` ile disarida
        birakilir.
        """
        P = self.P
        if not P.ai_acik or getattr(c, "ai_muaf", False):
            return
        if P.cs_acik and c.rejim == "kapitalist":
            return   # can simidi modu ETG'yi devralir
        # DETERMINIZM: burada `hash(c.ad)` kullaniliyordu. Python'da str hash'i
        # PYTHONHASHSEED ile SURECE OZGU rastgelelestirilir, dolayisiyla ayni
        # tohum ayri sureclerde AYRI sonuc uretiyordu (olculdu: tohum 42 icin
        # gecis 32/37/38, cokme 76/83/86, savas 1/3/2). Bu, o tarihe kadar
        # raporlanan butun Monte Carlo sonuclarini yeniden uretilemez kiliyordu.
        # crc32 surecler arasi kararlidir.
        if (self.t + zlib.crc32(c.ad.encode("utf-8")) % P.ai_periyot) % P.ai_periyot:
            return

        iss = 1.0 - c.e
        sikinti = (iss > P.ai_iss_esigi) or (c.Omega > P.ai_omega_esigi)

        if c.rejim == "sosyalist":
            # Kusatma/savas ve teknolojik gerilik -> sanayilesme.
            # Kitlik ve huzursuzluk -> tuketime donus.
            if c.kitlik > P.ai_kitlik_esigi or c.Omega > P.ai_omega_esigi:
                self.set_plan_profili("tuketimci", c.ad)
            elif c.savasta or c.ambargo:
                self.set_plan_profili("sanayilesmeci", c.ad)
            else:
                self.set_plan_profili("dengeli", c.ad)
            return

        # --- Ek politika kollari: kredi, yatirim, dis ticaret (§22) ---
        kredi_hedef, yat_hedef, tic_hedef = 1.0, 0.0, 0.0
        if c.kurum == "neoliberal":
            # Krizde kredi genislemesiyle talebi ayakta tutar, kamu sermayesini
            # ozelleştirir, disa aciklik artirir.
            kredi_hedef = 1.0 + (P.ai_kredi_bant if sikinti else 0.15)
            yat_hedef = -P.ai_yatirim_adim*4
            tic_hedef = +P.ai_ticaret_bant
        elif c.kurum == "duzenli":
            # Krediyi frenler, kamu yatirimini artirir, disa acikligi sinirlar.
            kredi_hedef = 1.0 - (P.ai_kredi_bant*0.6 if not sikinti else 0.20)
            yat_hedef = +P.ai_yatirim_adim*4
            tic_hedef = -P.ai_ticaret_bant*0.5
        elif c.kurum == "liberal":
            kredi_hedef, yat_hedef, tic_hedef = 1.0, 0.0, +P.ai_ticaret_bant*0.5
        if c.rejim == "sosyalist":
            kredi_hedef, yat_hedef, tic_hedef = 0.0, +P.ai_yatirim_adim*6, -P.ai_ticaret_bant
        for ad, hedef, adim in (("kredi", kredi_hedef, P.ai_kredi_adim),
                                ("yatirim", yat_hedef, P.ai_yatirim_adim),
                                ("ticaret", tic_hedef, P.ai_ticaret_adim)):
            mevcut = {"kredi": c.kredi_durusu, "yatirim": c.yatirim_durusu,
                      "ticaret": c.ticaret_durusu}[ad]
            yeni = mevcut + max(-adim, min(adim, hedef - mevcut))
            self.politika_ilan(c, ad, yeni)

        if c.kurum == "duzenli":
            # Bolusumcu yatistirma: sikinti varsa temel geliri yukseltir.
            hedef = c.etg_hedef + (P.ai_etg_adim if sikinti else -P.ai_etg_adim)
            # Mali kisit: kamu borcu yuksekse geri ceker.
            if c.kamu_borc > P.kamu_borc_limiti:
                hedef -= P.ai_etg_adim
            c.etg_hedef = max(0.0, min(P.ai_etg_tavan_duzenli, hedef))
        elif c.kurum == "neoliberal":
            # Karliligi korur: bolusumu sikar, ETG'yi asgaride tutar.
            hedef = c.etg_hedef - P.ai_etg_adim
            if c.Omega > P.ai_omega_esigi + 0.2:
                hedef = c.etg_hedef + P.ai_etg_adim   # yalnizca patlama esiginde
            c.etg_hedef = max(0.0, min(P.ai_etg_tavan_neoliberal, hedef))
            # NOT: AI liberal rejim INSA ETMEZ. Ilk denemede neoliberal AI'ye
            # "kar sikismasinda liberal projeyi dene" kurali verilmisti; LTRPF
            # r'yi surekli asagi cektigi icin bu kural gec donemde hep tetikleniyor
            # ve liberal, soyu tukenmis bir rejimden %28'lik bir paya sicriyordu.
            # Bu Clarke'a aykiridir: neoliberal devlet, mudahale aygitini
            # SOKMEZ; onu piyasa disiplinini dayatmak icin yeniden yapilandirir.
            # Liberal insa yalnizca OYUNCUYA acik bir siyasi projedir (Polanyi).
        else:  # liberal
            c.etg_hedef = 0.0

    def izolasyon_sapmasi_isle(self, c):
        """Yalniz kalmis sosyalist ekonominin iki yolu (restorasyon / Cin yolu).

        `blok` burada kendi hesaplanir; boylece step() icindeki cagri sirasina
        bagimlilik kalmaz.
        """
        P = self.P
        if c.rejim != "sosyalist":
            c.izo_sayac = 0
            return
        blok = sum(1 for x in self.D if x.rejim == "sosyalist")
        yalniz = blok <= P.izo_blok_esigi
        baski_altinda = bool(c.abluka) or c.ambargo or c.savasta
        if yalniz and baski_altinda and c.kitlik > P.izo_kitlik_esigi:
            c.izo_sayac += 1
        else:
            c.izo_sayac = max(0, c.izo_sayac - 1)
        if c.izo_sayac < P.izo_sure:
            return

        c.izo_sayac = 0
        c.restorasyon_t = self.t
        c.rejim = "kapitalist"
        c.kitlik = 0.0
        c.plan_hedef = None
        if c.baski_egilimi >= P.izo_baski_esigi:
            # (b) Cin yolu: parti iktidarda kalir, ekonomi kapitalistlesir
            c.parti_iktidari = True
            c.kurum = "neoliberal"
            self.log.append((self.t, "PIYASA SOS.",
                             f"{c.ad}: parti iktidari korudu ama kapitalist birikime "
                             f"kapilari acti (piyasa sosyalizmi)."))
        else:
            # (a) Restorasyon: kitlik rejimi dusurdu
            c.parti_iktidari = False
            c.kurum = "liberal"
            c.Omega = min(1.0, c.Omega + 0.20)
            self.log.append((self.t, "RESTORASYON",
                             f"{c.ad}: kusatma ve kitlik altinda sosyalist rejim "
                             f"cokti, kapitalizm restore edildi."))

    def dunya_devrimi_isle(self, D):
        """Dunya devrimi: enternasyonal dayanisma + kapitalizmin genel krizi.

        Hasila sarti YOKTUR (bkz. Params). Iki kosul dd_sure tur boyunca
        birlikte surmelidir; tetiklendiginde abluka, ambargo ve deger transferi
        kalici olarak sona erer.
        """
        P = self.P
        sos = [c for c in D if c.rejim == "sosyalist"]
        piyasa = [c for c in D if c.parti_iktidari]
        kap = [c for c in D if c.rejim == "kapitalist" and not c.parti_iktidari]

        # (1) Enternasyonal dayanisma
        pakt_var = len(sos) >= P.dd_pakt_esigi
        # Uyum: ittifak halindeki sosyalistler / (tum sosyalistler + sapanlar).
        # Hem ideolojik rekabet hem piyasa sosyalizmine sapma uyumu dusurur.
        ittifakta = sum(1 for c in sos if c.pakt_durusu != "rekabet")
        self.pakt_uyumu = ittifakta/max(len(sos) + len(piyasa), 1)
        dayanisma = pakt_var and self.pakt_uyumu >= P.dd_uyum_esigi

        # (2) Kapitalizmin genel krizi
        def _krizde(c):
            return (c.Omega > P.dd_omega_esigi
                    or c.bun_ici > 0
                    or (c.delev > 0 and (1.0-c.e) > P.dd_iss_esigi))
        self.kap_kriz_payi = (sum(1 for c in kap if _krizde(c))/len(kap)) if kap else 0.0
        genel_kriz = self.kap_kriz_payi >= P.dd_kriz_esigi

        if dayanisma and genel_kriz:
            self.dd_sayac += 1
        else:
            self.dd_sayac = max(0, self.dd_sayac - 1)

        if self.dd_sayac >= P.dd_sure and not self.dunya_devrimi:
            self.dunya_devrimi = True
            self.log.append((self.t, "DUNYA DEVRIMI",
                             f"Sosyalist pakt ({len(sos)} ulke, uyum "
                             f"%{self.pakt_uyumu*100:.0f}) ile kapitalizmin genel krizi "
                             f"(%{self.kap_kriz_payi*100:.0f}) ortusdu. Abluka ve deger "
                             f"transferi sona erdi."))
        if self.dunya_devrimi:
            for c in D:
                c.abluka = 0
                c.ambargo = False
                c.VT_net = 0.0

    def kurumsal_insa_isle(self, c):
        """Kasitli kurumsal insa (Polanyi: 'laissez-faire planlandi').

        Endojen gecisten farkli olarak bu bir SIYASI PROJEDIR: yuksek siyasi
        sermaye gerektirir, onu tuketir ve basarisiz olabilir. Liberal rejime
        ulasmanin TEK yolu budur.
        """
        P = self.P
        hedef = c.kurum_insa_hedef
        if hedef is None or hedef == c.kurum or c.rejim != "kapitalist":
            return
        if self.t - c.kurum_insa_t < P.ki_min_sure:
            return
        if c.PC < P.ki_pc_esigi:
            return
        c.PC = max(0.0, c.PC - P.ki_pc_maliyet)
        c.kurum_gecmis.append((self.t, c.kurum, hedef))
        self.log.append((self.t, "KURUM", f"{c.ad}: {c.kurum} -> {hedef} rejimi siyasi proje olarak İNŞA EDİLDİ."))
        c.kurum = hedef
        c.kurum_t = self.t
        c.kurum_insa_t = self.t
        c.kurum_insa_hedef = None

    PLAN_PROFILLERI = {
        "sanayilesmeci": {"yatirim": 0.46, "tuketim": 0.32, "arge": 0.14, "savunma": 0.08},
        "tuketimci":     {"yatirim": 0.18, "tuketim": 0.72, "arge": 0.06, "savunma": 0.04},
        "dengeli":       {"yatirim": 0.30, "tuketim": 0.55, "arge": 0.10, "savunma": 0.05},
    }

    def set_plan_profili(self, profil, ulke=None):
        """Sosyalist plan profilini belirler (isim ya da paylar sozlugu).

        Paylar RAKIP kullanimlardir: biri artarsa digeri azalir. Bir POLITIKA
        HEDEFIDIR; profil `plan_hiz` ile yavas yakinsar ve butun sonuclar
        (birikim, verimlilik, kitlik, ucret payi, huzursuzluk) endojen uretilir.
        """
        if isinstance(profil, str):
            if profil not in self.PLAN_PROFILLERI:
                raise ValueError(f"Bilinmeyen plan profili: {profil}")
            profil = self.PLAN_PROFILLERI[profil]
        top = sum(max(0.0, v) for v in profil.values()) or 1.0
        norm = {k: max(0.0, v)/top for k, v in profil.items()}
        for c in (self.D if ulke is None else [x for x in self.D if x.ad == ulke]):
            self.politika_ilan(c, "plan", dict(norm))

    def set_pakt_durusu(self, durus, ulke=None):
        """Sosyalist pakt icindeki durus: "ittifak" ya da "rekabet".

        Ideolojik mesafe yalnizca zemini kurar; rekabet olup olmayacagi bir
        POLITIKA SECIMIDIR. Rekabet halindeki ulke muttefik kazanmaz ve blok
        planlama bonusundan yararlanmaz -- bedeli budur.
        """
        if durus not in ("ittifak", "rekabet"):
            raise ValueError("durus 'ittifak' ya da 'rekabet' olmali")
        for c in (self.D if ulke is None else [x for x in self.D if x.ad == ulke]):
            c.pakt_durusu = durus

    def set_etg_finansman(self, sermaye_payi, ulke=None):
        """ETG'nin ne kadarinin sermaye vergisinden karsilanacagini belirler.

        0.0 = tamamen ucretten (tuketimi kisar, gerceklesme krizini derinlestirir)
        1.0 = tamamen sermayeden (net karliligi dusurur, LTRPF'yi hizlandirir)
        """
        for c in (self.D if ulke is None else [x for x in self.D if x.ad == ulke]):
            self.politika_ilan(c, "etg_finansman", max(0.0, min(1.0, sermaye_payi)))

    def set_kurumsal_insa(self, kurum, ulke=None):
        """Kasitli kurumsal insa politikasi. Liberal rejime tek erisim yolu."""
        if kurum not in KURUMLAR:
            raise ValueError(f"Bilinmeyen kurum: {kurum}")
        for c in (self.D if ulke is None else [x for x in self.D if x.ad == ulke]):
            self.politika_ilan(c, "kurum_insa", kurum)

    def ilan(self, a, b, sebep):
        """İki ülke arasında savaş başlatır."""
        sure = self.rng.randint(self.P.sv_min_sure, self.P.sv_max_sure)
        a.savas[b.ad] = sure
        b.savas[a.ad] = sure
        a.savas_sayisi += 1
        b.savas_sayisi += 1
        self.log.append((self.t, "SAVAS", f"{a.ad} ile {b.ad} arasinda savas patlak verdi! Sebep: {sebep}"))
        
        for m_ad in list(a.muttefik):
            m = next((x for x in self.D if x.ad == m_ad), None)
            if m and not m.savasta and self.rng.random() < 0.5:
                m.savas[b.ad] = sure
                b.savas[m.ad] = sure
                m.savas_sayisi += 1
                b.savas_sayisi += 1

    def savas_karari(self):
        """Kârlılık sıkışması ve saldırganlık parametrelerine göre otonom savaş kararlarını hesaplar."""
        kap = [c for c in self.D if c.rejim == "kapitalist"]
        sos = [c for c in self.D if c.rejim == "sosyalist"]
        
        # Sosyalist blok buyudukce kapitalist merkezin mudahale istegi buyur:
        # tehdit algisi topyekun savasi davet eder.
        blok_pay = len(sos)/max(len(self.D), 1)
        tehdit_carpani = 1.0 + self.P.sv_blok_tehdidi*blok_pay
        for s in sos:
            if s.devrim_t is None or s.savasta:
                continue
            if not (0 < self.t - s.devrim_t <= self.P.sv_mudahale_pencere):
                continue
            for m in kap:
                if m.tip != "merkez" or m.savasta: continue
                istek = (self.P.sv_mudahale*m.saldirganlik*tehdit_carpani
                         * (1 if m.guc > s.guc*0.8 else 0.3))
                if self.rng.random() < istek*self.P.sv_carpan*0.10:
                    self.ilan(m, s, "emperyalist mudahale")
                    break
                        
        for c in kap:
            if c.savasta: continue
            sikisma = max(0.0, (self.P.sv_r_ref - c.r)/self.P.sv_r_ref)
            kaynak = self.P.sv_kaynak if c.era >= 3 else 0.0
            p = (self.P.sv_taban + self.P.sv_kar_baskisi*sikisma + kaynak + self.P.sv_doktrin*c.saldirganlik)*c.saldirganlik
            if self.rng.random() < p*0.06*self.P.sv_carpan:
                ad = [x for x in self.D if x is not c and x.ad not in c.muttefik and not x.savasta and x.guc < c.guc*1.15]
                if ad:
                    h = max(ad, key=lambda x: (x.L_max*x.q)/max(x.guc, 1)+self.rng.random()*0.4)
                    self.ilan(c, h, "pazar ve hammadde arayisi")

    def savas_yikim_isle(self):
        """Aktif savaşların fiziksel altyapı hasarlarını ve rejim meşruiyet etkilerini işler."""
        ad2c = {c.ad: c for c in self.D}
        for c in self.D:
            if not c.savasta: continue
            c.savas_toplam += 1
            for rk in list(c.savas):
                c.savas[rk] -= 1
                if c.savas[rk] <= 0:
                    rakip = ad2c.get(rk)
                    if rakip:
                        oran = c.guc/max(c.guc+rakip.guc, 1e-6)
                        if oran < 0.42:
                            c.Omega = min(1.0, c.Omega+self.P.sv_yenilgi_omega)
                            c.K *= 0.94
                            self.log.append((self.t, "YENILGI", f"{c.ad} savasi kaybetti. Toplumsal gerilim patladi."))
                        _ezildi = oran < self.P.kd_yenilgi_orani
                        _ic_cokus = c.PKE < self.P.kd_pke_esigi
                        if (c.rejim == "sosyalist" and rakip.rejim == "kapitalist"
                            and ((_ezildi and self.rng.random() < self.P.kd_askeri_olasilik)
                                 or (_ic_cokus and self.rng.random() < self.P.kd_olasilik))):
                            c.rejim = "kapitalist"
                            c.Omega = 0.10
                            c.org *= 0.5
                            c.devrim_t = None
                            c.devrim_era = None
                            c.pay = max(0.15, c.pay*0.75)
                            c.IR = 0.75
                            c.muttefik.clear()
                            self.log.append((self.t, "KARSI-DEVRIM", f"{c.ad} rejiminde kapitalizm zorla restore edildi!"))
                    del c.savas[rk]

    def ittifak_isle(self):
        """Sosyalist ve kapitalist blokların diplomatik ittifaklarını günceller."""
        sos = [c for c in self.D if c.rejim == "sosyalist"]
        # Ideolojik mesafe: ulkenin plan hattinin blok ortalamasindan sapmasi.
        if sos:
            anahtar = ("yatirim", "tuketim", "arge", "savunma")
            ort = {k: sum(c.plan[k] for c in sos)/len(sos) for k in anahtar}
            for c in sos:
                c.ideolojik_mesafe = sum(abs(c.plan[k]-ort[k]) for k in anahtar)/2.0
                # AI ulkeler mesafeye gore durus alir; oyuncunun ulkesi muaf.
                if not getattr(c, "ai_muaf", False) and self.rng.random() < self.P.pakt_durus_hiz:
                    c.pakt_durusu = ("rekabet"
                                     if c.ideolojik_mesafe > self.P.pakt_mesafe_esigi
                                     else "ittifak")
        # Rekabet halindeki sosyalist ulkeler birbirinin muttefiki OLMAZ.
        for a in sos:
            if a.pakt_durusu == "rekabet":
                a.muttefik = set()
            else:
                a.muttefik = {b.ad for b in sos
                              if b is not a and b.pakt_durusu != "rekabet"}
        kap = [c for c in self.D if c.rejim == "kapitalist"]
        tehdit = len(sos)/max(len(self.D), 1)
        for a in kap:
            if tehdit > self.P.it_esik:
                for b in kap:
                    if b is a: continue
                    if (a.tip == "merkez" and b.tip == "merkez" and a.era == b.era 
                        and a.saldirganlik > 0.6 and b.saldirganlik > 0.6): continue
                    if self.rng.random() < tehdit*0.02:
                        a.muttefik.add(b.ad)
                        b.muttefik.add(a.ad)
            if self.rng.random() < self.P.it_kopma and a.muttefik:
                a.muttefik.discard(self.rng.choice(list(a.muttefik)))

    def abluka_ambargo_isle(self):
        """Sınıfsal bloklara göre dış ticaret ablukası ve ambargoları günceller."""
        sos = [c for c in self.D if c.rejim == "sosyalist"]
        kap = [c for c in self.D if c.rejim == "kapitalist"]
        for c in self.D:
            c.abluka = 0
            c.ambargo = False
            
        if len(sos) >= self.P.amb_sos_esigi and kap:
            mrk = [m for m in kap if m.tip == "merkez" and m.saldirganlik > 0.4]
            for s in sos:
                s.ambargo = True
                s.abluka = len(mrk)
                
        for c in self.D:
            if c.savasta:
                c.abluka += len(c.savas)

    def run_simulation(self, turlar=1200):
        """Belirtilen tur kadar simülasyonu koşturur."""
        for _ in range(turlar):
            self.step()
        return self.get_summary()

    def get_summary(self):
        """Genel istatistikleri ve KODEY metrik setini derler."""
        revolutions = sum(1 for c in self.D if c.devrim_t is not None)
        baslangic_sos = sum(1 for c in self.D if c.baslangic_rejimi_t is not None)
        crashes = sum(1 for _, k, _ in self.log if k == "COKME")
        wars = sum(c.savas_sayisi for c in self.D) // 2
        kap = [c for c in self.D if c.rejim == "kapitalist"] or self.D
        return {
            "toplam_tur": self.t,
            "sosyalist_devrimler": revolutions,
            "baslangicta_sosyalist": baslangic_sos,
            "ekonomik_cokmeler": crashes,
            "toplam_savaslar": wars,
            "kucuk_resesyonlar": sum(len(c.resesyonlar) for c in self.D),
            "buyuk_bunalimlar": sum(len(c.bunalimlar) for c in self.D),
            "cokme_BORC": sum(1 for _, k, m in self.log if k == "COKME" and "BORC" in m),
            "cokme_BALON": sum(1 for _, k, m in self.log if k == "COKME" and "BALON" in m),
            "cokme_MINSKY": sum(1 for _, k, m in self.log if k == "COKME" and "MINSKY" in m),
            "kurumsal_gecisler": sum(len(c.kurum_gecmis) for c in self.D),
            "temerrutler": sum(len(c.temerrutler) for c in self.D),
            # --- KODEY metrik seti ---
            "ort_somuru_orani_sv": round(statistics.mean([c.s_v for c in kap]), 3),
            "ort_lumpen_payi": round(statistics.mean([c.lumpen_pay for c in self.D]), 4),
            "ort_mafya_toleransi": round(statistics.mean([c.mafya_tolerans for c in kap]), 3),
            "ort_cezaevi_orani": round(statistics.mean([c.cezaevi_orani for c in self.D]), 4),
            "ort_atil_endeks": round(statistics.mean([c.atil_endeks for c in self.D]), 4),
            "ort_thirlwall_eps_pi": round(statistics.mean(
                [c.eps/max(c.pi_m, 1e-6) for c in self.D]), 3),
            "toplam_nufus": round(sum(c.L_max for c in self.D), 1),
            "ort_katilim_orani": round(statistics.mean([c.katilim for c in self.D]), 3),
            "piyasa_sosyalizmi": sum(1 for c in self.D if c.parti_iktidari),
            "restorasyon": sum(1 for c in self.D if c.restorasyon_t is not None
                               and not c.parti_iktidari),
            "dunya_devrimi": self.dunya_devrimi,
            "pakt_uyumu": round(self.pakt_uyumu, 3),
            "pakt_rekabet": sum(1 for c in self.D
                                if c.rejim == "sosyalist" and c.pakt_durusu == "rekabet"),
            "ort_ideolojik_mesafe": round(statistics.mean(
                [c.ideolojik_mesafe for c in self.D if c.rejim == "sosyalist"]), 4)
            if any(c.rejim == "sosyalist" for c in self.D) else 0.0,
            "kap_kriz_payi": round(self.kap_kriz_payi, 3),
            "ort_etg": round(statistics.mean([c.etg for c in self.D]), 4),
            "kurum_gecis_duzenli_neoliberal": sum(
                1 for c in self.D for (_, e_, y_) in c.kurum_gecmis
                if e_ == "duzenli" and y_ == "neoliberal"),
            "kurum_gecis_neoliberal_duzenli": sum(
                1 for c in self.D for (_, e_, y_) in c.kurum_gecmis
                if e_ == "neoliberal" and y_ == "duzenli"),
            "ort_mekanizasyon_durtusu": round(statistics.mean([c.ito for c in self.D]), 3),
            "ort_deger_carpani": round(statistics.mean([c.deger_carpani for c in self.D]), 3),
        }

    def oyuncu_ulkesi(self, ad):
        """Bir ulkeyi oyuncuya devreder: politika AI'si ona dokunmaz."""
        for c in self.D:
            c.ai_muaf = (c.ad == ad)

    def set_temel_gelir(self, oran, ulke=None):
        # NOT: sosyalist rejimde yok sayilir (bkz. step icindeki ETG blogu).
        """ETG politikasini belirler (hasila orani olarak hedef).

        Bir POLITIKA HEDEFIDIR, dogrudan durum degisikligi degil: fiili ETG
        `etg_yerlesme` hiziyla yerlesir ve sonuclari (ucret tabani, katilik,
        Omega, butce, katilim, dogurganlik) motor tarafindan endojen uretilir.
        v4.4 Invariant 6/7 ile uyumludur.
        """
        for c in (self.D if ulke is None else [x for x in self.D if x.ad == ulke]):
            self.politika_ilan(c, "etg", max(0.0, min(0.40, oran)))

    def tarihsel_rapor(self, ulke=None, dilim=150):
        """Bir kosunun TARIHSEL SONUC RAPORU (§42/43 yerine).

        Bu oyunda zafer/yenilgi yoktur. Devrim bir kayip degil, oyuncunun elindeki
        politika setinin degismesidir: bolusum ve kurum kollarinin yerini plan
        paylari alir. Rapor, kazanip kazanmadigini soylemez -- NE OLDUGUNU anlatir.
        Bu, sartnamenin §43'undeki "zafer tek politikaya indirgenemez" kuralini
        yapisal olarak karsilar: karsilastirilacak bir hedef yoksa tek optimal
        politika kavrami tanimsizdir.
        """
        c = (self.D[0] if ulke is None else
             next(x for x in self.D if x.ad == ulke))
        h = c.tarih
        if not h:
            return {}
        ilk, son = h[:dilim], h[-dilim:]

        def ort(seg, k):
            v = [x[k] for x in seg if k in x]
            return statistics.mean(v) if v else float("nan")

        donemler = []
        for lo in range(0, len(h), dilim):
            seg = h[lo:lo+dilim]
            if not seg:
                continue
            donemler.append({
                "t0": lo, "t1": lo+len(seg)-1,
                "kurum": max(set(x["kurum"] for x in seg),
                             key=[x["kurum"] for x in seg].count),
                "rejim": max(set(x["rej"] for x in seg),
                             key=[x["rej"] for x in seg].count),
                "issizlik": round(1-ort(seg, "e"), 3),
                "ucret_payi": round(ort(seg, "pay"), 3),
                "kar_orani": round(ort(seg, "r"), 5),
                "orgutluluk": round(ort(seg, "org"), 3),
                "huzursuzluk": round(ort(seg, "Om"), 3),
                "otomasyon": round(ort(seg, "oto"), 3),
                "canli_emek_payi": round(ort(seg, "canli_pay"), 3),
                "etg": round(ort(seg, "etg"), 4),
                "kitlik": round(ort(seg, "kitlik"), 3),
            })

        olaylar = []
        for t_, tip, mesaj in self.log:
            if c.ad in mesaj or tip in ("SENARYO",):
                olaylar.append({"tur": t_, "yil_kabaca": round(t_*TUR_YIL, 1),
                                "tip": tip, "mesaj": mesaj})

        return {
            "ulke": c.ad,
            "tip": c.tip,
            "son_rejim": c.rejim,
            "son_kurum": c.kurum,
            "devrim_turu": c.devrim_t,
            "kurum_gecisleri": list(c.kurum_gecmis),
            "baslangic": {"issizlik": round(1-ort(ilk, "e"), 3),
                          "ucret_payi": round(ort(ilk, "pay"), 3),
                          "kar_orani": round(ort(ilk, "r"), 5),
                          "cag": round(ort(ilk, "era"), 1)},
            "bitis": {"issizlik": round(1-ort(son, "e"), 3),
                      "ucret_payi": round(ort(son, "pay"), 3),
                      "kar_orani": round(ort(son, "r"), 5),
                      "cag": round(ort(son, "era"), 1)},
            "kriz_sayilari": {"resesyon": len(c.resesyonlar),
                              "buyuk_bunalim": len(c.bunalimlar),
                              "doviz_krizi": len(c.fx_krizleri),
                              "temerrut": len(c.temerrutler),
                              "moratoryum": len(c.moratoryumlar),
                              "savas": c.savas_sayisi},
            "donemler": donemler,
            "olaylar": olaylar,
        }

    # Birincil neden siralamasi: yapisal olan konjonkturel olani ezer.
    KRIZ_ONCELIK = ("DEVRIM", "RESTORASYON", "BUYUK_BUNALIM", "DEVLET_COKUSU",
                    "MORATORYUM", "FX_KRIZI", "MINSKY", "BORC_KRIZI",
                    "PLAN_KITLIGI", "ASIRI_URETIM", "RESESYON")

    def kriz_siniflandir(self):
        """Her ulke icin coklu olay bayragi + TEK birincil kriz nedeni uretir."""
        for c in self.D:
            b = {
                "RESESYON": bool(c.resesyonlar and c.resesyonlar[-1][0] == self.t),
                "ASIRI_URETIM": bool(c.asiri_uretim_krizleri
                                     and c.asiri_uretim_krizleri[-1][0] == self.t),
                "BUYUK_BUNALIM": bool(c.bunalimlar and c.bunalimlar[-1][0] == self.t),
                "FX_KRIZI": bool(c.fx_krizleri and c.fx_krizleri[-1] == self.t),
                "MORATORYUM": bool(c.moratoryumlar and c.moratoryumlar[-1] == self.t),
                "DEVLET_COKUSU": bool(c.temerrutler and c.temerrutler[-1] == self.t),
                "DEVRIM": c.devrim_t == self.t,
                "RESTORASYON": c.restorasyon_t == self.t,
                "PLAN_KITLIGI": c.rejim == "sosyalist" and c.kitlik > self.P.izo_kitlik_esigi,
                "MINSKY": False,
                "BORC_KRIZI": False,
            }
            for _t, k, g in self.log[-12:]:
                if _t == self.t and k == "COKME" and c.ad in g:
                    if "MINSKY" in g.upper():
                        b["MINSKY"] = True
                    elif "BORC" in g.upper():
                        b["BORC_KRIZI"] = True
            c.olay_bayraklari = b
            c.birincil_kriz = next((k for k in self.KRIZ_ONCELIK if b.get(k)), None)
            if c.birincil_kriz:
                c.kriz_gunlugu.append((self.t, c.birincil_kriz,
                                       [k for k in b if b[k] and k != c.birincil_kriz]))

    def degismez_denetle(self):
        """Her tur sonunda iktisadi muhasebe degismezlerini denetler.

        NaN/Inf ya da imkansiz deger sessizce devam ETMEZ: olay olarak kaydedilir.
        Boylece "bu ulke neden coktu" sorusu sonradan cevaplanabilir.
        """
        hata = []
        for c in self.D:
            for ad, v, alt, ust in (
                ("pay", c.pay, 0.0, 1.0), ("e", c.e, 0.0, 1.0),
                ("u", c.u, 0.0, 5.0), ("org", c.org, 0.0, 1.0),
                ("Omega", c.Omega, 0.0, 1.0), ("canli_pay", c.canli_pay, 0.0, 1.0),
                ("oto", c.oto, 0.0, 1.0), ("etg", c.etg, 0.0, 1.0),
            ):
                if v != v or v in (float("inf"), float("-inf")) or not (alt-1e-9 <= v <= ust+1e-9):
                    hata.append(f"{c.ad}.{ad}={v}")
            for ad, v in (("q", c.q), ("K", c.K), ("Y", c.Y)):
                if v != v or v <= 0:
                    hata.append(f"{c.ad}.{ad}={v}")
        if hata:
            self.log.append((self.t, "DEGISMEZ IHLALI", "; ".join(hata[:6])))
        return hata

    def deney_kimligi(self, senaryo=None):
        """Kosunun yeniden uretilebilir kimligi: hangi kodla, hangi parametreyle.

        Parametre karmasi crc32'dir; surecler arasi kararlidir (hash() DEGIL).
        """
        import dataclasses
        pars = sorted((k, getattr(self.P, k)) for k in
                      (f.name for f in dataclasses.fields(self.P)))
        imza = ";".join(f"{k}={v}" for k, v in pars)
        return {
            "model": SURUM,
            "parametre_karmasi": f"{zlib.crc32(imza.encode('utf-8')):08x}",
            "tohum": self.tohum,
            "senaryo": senaryo or "varsayilan",
            "tur": self.t,
            "ulke_sayisi": len(self.D),
            "baslangic_yili": self.baslangic_yili,
        }

    def kriz_oranlari(self):
        """Kriz siklıklarini ULKE-YIL basina verir; farkli tur uzunluklari
        karsilastirilabilir olsun diye. Birincil neden uzerinden sayilir, yani
        ayni turda coklu kriz frekanslari sismez."""
        ulke_yil = len(self.D)*self.t*TUR_YIL
        say = {}
        for c in self.D:
            for (_t, bir, _ik) in c.kriz_gunlugu:
                say[bir] = say.get(bir, 0) + 1
        return {k: {"toplam": v, "ulke_yil_basina": round(v/max(ulke_yil, 1e-9), 6),
                    "aralik_yil": round(ulke_yil/v, 1) if v else None}
                for k, v in sorted(say.items(), key=lambda x: -x[1])}

    def kodey_trendi(self, dilim=150):
        """KODEY metrik setinin zaman icindeki seyri."""
        out = []
        for lo in range(0, self.t, dilim):
            hi = lo + dilim
            seg = [x for c in self.D for x in c.tarih[lo:hi]]
            if not seg:
                continue
            out.append({
                "t0": lo, "t1": hi-1,
                "tolerans": round(statistics.mean([x["mafya_tolerans"] for x in seg]), 4),
                "uyusturucu": round(statistics.mean([x["uyusturucu"] for x in seg]), 4),
                "cezaevi": round(statistics.mean([x["cezaevi"] for x in seg]), 4),
                "lumpen_pay": round(statistics.mean([x["lumpen_pay"] for x in seg]), 4),
                "gasp_orani": round(statistics.mean([x["gasp_orani"] for x in seg]), 4),
                "s_v": round(statistics.mean([x["s_v"] for x in seg]), 3),
                "eps/pi": round(statistics.mean([x["eps"]/max(x["pi_m"], 1e-6) for x in seg]), 3),
                "dogum": round(statistics.mean([x["dogum"] for x in seg]), 5),
            })
        return out

    def kar_orani_trendi(self, dilim=150):
        """LTRPF tarihsel dogrulamasi verilerini hazirlar."""
        out = []
        for lo in range(0, self.t, dilim):
            hi = lo + dilim
            rs, cvs, kys, us = [], [], [], []
            for c in self.D:
                pen = c.tarih[lo:hi]
                if pen:
                    rs.append(statistics.mean([x["r"] for x in pen]))
                    cvs.append(statistics.mean([x["cv"] for x in pen]))
                    kys.append(statistics.mean([x["K"]/max(x["Y"], 1e-6) for x in pen]))
                    us.append(statistics.mean([x["u"] for x in pen]))
            if rs:
                out.append({
                    "t0": lo, "t1": hi-1,
                    "r": statistics.mean(rs),
                    "r_yillik": yillik(statistics.mean(rs)),
                    "cv": statistics.mean(cvs),
                    "K/Y": statistics.mean(kys),
                    "u": statistics.mean(us)
                })
        return out

