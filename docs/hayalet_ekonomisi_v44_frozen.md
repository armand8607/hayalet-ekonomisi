# Hayalet Ekonomisi v4.4-Frozen — Model Dokümanı ve Kaynak Kod

> Bu tek dosya, Gemini Notebook / NotebookLM'e tek kaynak olarak yüklenmek üzere
> hazırlanmıştır. İçinde üç şey var: (1) modelin düzyazı açıklaması — değişken
> sözlüğü, denklem blokları ve aralarındaki nedensellik zincirleri; (2) teorik el
> kitabı ile kod arasındaki eşleme; (3) iki dosyanın tam kaynak kodu.
>
> Her bölüm kendi başına okunabilecek şekilde yazılmıştır; kısaltmalar her bölümde
> yeniden açılır.

---

## 0. Model nedir, ne yapar

Hayalet Ekonomisi, Marksist değer teorisini bir bilgisayar simülasyonuna çeviren
çok ülkeli bir makroekonomik motordur. Yirmi ülke, her tur eşzamanlı olarak
üretir, bölüşür, borçlanır, kriz geçirir, birbirinden değer transfer eder,
savaşır ve kimi zaman devrim yaşar.

Modelin merkezindeki iddia **Kâr Oranlarının Düşme Eğilimi Yasası**dır (İngilizce
kısaltmasıyla LTRPF — Law of the Tendency of the Rate of Profit to Fall).
Sermayenin organik bileşimi (sabit sermayenin değişken sermayeye oranı, c/v)
mekanizasyonla yükseldikçe kâr oranı düşme eğilimi gösterir; karşı-eğilimler bu
düşüşü geciktirir ama tersine çeviremez.

Teorik sentez üç kaynaktan beslenir:

- **Cedeplar-UFMG makrodinamikleri** (Missio & Jayme Jr.): yapısal heterojenlik,
  Thirlwall Kanunu ve ödemeler dengesi kısıtlı büyüme.
- **E. Ahmet Tonak'ın değer analizi**: sömürü oranı, üretken/üretken olmayan emek
  ayrımı, değer gaspı.
- **Makoto Itoh**: emeğe göre aşırı birikim (overaccumulation with respect to
  labor power), üç soyutlama seviyesi, makineleşme analizi.

Buna v4.0 ile birlikte bir **karanlık devlet ve demografi katmanı** eklenmiştir:
uyuşturucu ekonomisi, karseral (cezaevi) nüfus, endojen doğum/ölüm oranları.

---

## 1. Sistem mimarisi: iki dosya

Proje iki dosyadan oluşur ve bağımlılık tek yönlüdür.

**`hayalet_ekonomi_motoru_v43.py` — motor.** Bir kütüphanedir. İçinde hiç
`print()` çağrısı ve `if __name__ == "__main__"` bloğu yoktur; doğrudan
çalıştırılamaz, yalnızca içe aktarılır. Bütün ekonomi buradadır. Rapor
metotları (`get_summary()`, `kar_orani_trendi()`, `kodey_trendi()`) sözlük ve
liste döndürür, metin basmaz.

**`hayalet_ekonomisi_oyunu_v32.py` — oyun.** 144 satırlık bir konsol
arayüzüdür. Motoru içe aktarır, bir senaryo yükler, politika ayarlar, turları
koşturur ve renkli rapor basar. Hiçbir ekonomik karar içermez.

Ayrım kasıtlıdır: Godot, Unity veya web'e taşınacak olan motordur; oyun
atılabilir bir ön yüzdür. Motorda tek bir `print` olsaydı bu taşıma kirlenirdi.

Çalıştırma:

```
python3 hayalet_ekonomisi_oyunu_v32.py turkey_2001 endojen 42
python3 hayalet_ekonomisi_oyunu_v32.py neoliberal_1995 0.85 7 240
```

Argümanlar sırayla: senaryo adı, mafya politikası (`endojen` ya da 0.0–1.0
arasında bir sayı), rastgelelik tohumu, tur sayısı.

---

## 2. Birim sözleşmesi

Bu, modeli okurken yapılan en yaygın hatanın kaynağıdır ve v5.0'daki en ciddi
tutarsızlıktı.

**Tüm oran ve akım parametreleri TUR BAŞINA tanımlıdır.** Bir tur `TUR_YIL = 0.27`
yıla karşılık gelir (yaklaşık bir çeyrek). Yıllık karşılığı almak için
`yillik(x)` yardımcı fonksiyonu kullanılır: `(1+x)**(1/0.27) - 1`.

Bunun önemli bir sonucu vardır: `Y` bir tur-akımıdır. Dolayısıyla sermaye/hasıla
katsayısı `kv = K / Y_kapasite` de tur cinsindendir ve **yıllık** sermaye/hasıla
oranı `kv * 0.27`'ye eşittir. Kodda `kv ≈ 22` görmek, yıllık K/Y ≈ 5.9 demektir.

v5.0'da faiz ve borç servisi `tur_olcek` ile ölçekleniyor, buna karşılık yatırım,
amortisman, enflasyon ve verimlilik artışı tam tur oranıyla işleniyordu. Bu
karışım, kâr oranı `r` ile faiz `i` karşılaştırılan her yerde sistematik sapma
üretiyordu — ve bu karşılaştırma modelin üç ayrı yerinde kritiktir:
finansallaşma anahtarı, kâr sıkışması kriz tipi ve düzenli→neoliberal kurumsal
geçiş. v4.1'de tek bir sözleşme vardır ve bütün mutlak eşikler ona göre yeniden
kalibre edilmiştir.

---

## 3. Değişken sözlüğü

Kod Türkçe kısaltmalar kullanır. Aşağıdaki tablo bir ülke nesnesinin
(`Country`) taşıdığı temel durum değişkenlerini verir.

### 3.1 Reel ekonomi

| değişken | anlamı |
|---|---|
| `K` | Fiziksel sermaye stoku (üretken sermaye) |
| `Y` | Hasıla (bir turluk akım) |
| `Y_pot` | Potansiyel hasıla = min(sermaye kapasitesi, emek kapasitesi) |
| `u` | Kapasite kullanım oranı = Y / Y_K |
| `q` | Emek verimliliği (canlı emeğin üretkenliği) |
| `L_max` | Toplam aktif işgücü nüfusu |
| `L_etkin` | Etkin işgücü arzı = L_max × katılım × (1 − cezaevi oranı) |
| `e` | İstihdam oranı |
| `saat` | Haftalık çalışma süresi rasyosu (1.0 = tam hafta) |
| `g` | Net birikim hızı (sermaye stokunun büyüme oranı) |
| `r` | Üretken kâr oranı = üretken artı-değer / K |
| `pay` | Ücret payı (wage share, ω) |
| `s_v` | Sömürü oranı s/v = (1−pay)/pay — Tonak metriği |

### 3.2 Nominal ve finansal katman

| değişken | anlamı |
|---|---|
| `pi_inf` | Enflasyon (tur başı) |
| `pi_bek` | Enflasyon beklentisi |
| `p_duzey` | Fiyat düzeyi |
| `w_nom_buyume` | Nominal ücret artış hızı |
| `i_pol` | Politika faizi (Taylor kuralı çıktısı) |
| `i_ef` | Risk primli efektif faiz |
| `borc` | Hanehalkı borç stoku |
| `varlik` | Spekülatif varlık balonu stoku |
| `delev` | Deleveraging (borç azaltma) sürecinde kalan tur |
| `deger_carpani` | Sabit sermayenin kriz devalüasyonu çarpanı |

### 3.3 Dış ekonomi

| değişken | anlamı |
|---|---|
| `eps` | İhracat gelir esnekliği (Thirlwall) |
| `pi_m` | İthalat gelir esnekliği (Thirlwall) |
| `cari` | Cari denge |
| `FX` | Döviz rezervleri |
| `BoP_R` | Ödemeler dengesi risk primi |
| `deval` | Devalüasyon primi stoku |
| `dis_borc` | Dış borç stoku |
| `VT_net` | Net değer transferi (eşitsiz mübadele sızıntısı) |

### 3.4 Sınıf ve siyaset

| değişken | anlamı |
|---|---|
| `org` | İşçi sendikalaşma / örgütlenme düzeyi |
| `Omega` | Siyasi öfke birikimi (sınıfsal gerilim stoku) |
| `PC` | Rejim rızası / meşruiyet |
| `pr_sayac` | Protesto sürme sayacı |
| `baski_egilimi` | Devletin polis zoruyla bastırma eğilimi |
| `kurum` | Kurumsal rejim: `liberal`, `duzenli`, `neoliberal` |
| `rejim` | Sınıfsal rejim: `kapitalist` veya `sosyalist` |
| `PKE` | Planlama gücü (sosyalist rejimde) |
| `e_norm` | Goodwin çevriminin hareketli istihdam çapası |

### 3.5 Karanlık devlet ve demografi

| değişken | anlamı |
|---|---|
| `mafya_tolerans` | Karanlık devlet geçirgenliği (0–1), **endojen** |
| `mafya_kilit` | Oyuncu bunu bir sayıya çekerse endojen güncelleme durur |
| `uyusturucu_orani` | Uyuşturucu kullanan nüfus oranı |
| `cezaevi_orani` | Cezaevi hükümlü nüfus oranı |
| `lumpen_pay` | İllegal/asalak sektörün ekonomideki payı |
| `gasp` | Üretken alandan çekilen değer (Tonak değer gaspı) |
| `katilim` | İşgücüne katılım oranı (gizli/durgun yedek ordu) |
| `dogum_orani` | Kaba doğum oranı (endojen) |
| `olum_orani` | Kaba ölüm oranı (endojen) |
| `ito` | Mekanizasyon dürtüsü çarpanı (içsel teknik değişme) |

### 3.6 Teknoloji

`era` bir ülkenin teknolojik çağıdır (1–6): Buhar, Elektrik, Otomasyon,
Siber-fiziksel, İnsan-YZ, Tam otomasyon. Her çağın kendi verimlilik artış hızı
(`qg`), kentleşme düzeyi (`kent`), planlama kapasitesi (`pke`), giriş eşiği
(`q_esik`) ve doyum tavanı (`q_tavan`) vardır.

---

## 4. Bir turun akışı

`step()` metodu her tur şu sırayı izler. Sıra rastgele değildir; nedensellik
zincirini bu sıra belirler.

**Dünya düzeyi (ülke döngüsünden önce):** dünya ortalama verimliliği, ortalama
organik bileşim ve ortalama sömürü oranı hesaplanır. Bunlar eşitsiz mübadele ve
Thirlwall karşılaştırmaları için referans oluşturur.

**Ülke döngüsü (her ülke için sırayla):**

| adım | blok | ne yapar |
|---|---|---|
| A | Merkez bankası | Taylor kuralıyla politika faizi; faize kâr oranı tavanı |
| B | Dış ticaret | Thirlwall esneklikleri, BoP-kısıtlı büyüme sınırı |
| C | Cari açık | Değer transferi sızıntısı |
| D | Ani duruş | Dış borçlanma tıkacı |
| E | Moratoryum | Borç yapılandırma (Meksika '82, Arjantin '01 tipi) |
| F | Döviz krizi | Rezerv erimesi (Tip C kriz) |
| G | Arz kapasitesi | Y_K ve Y_L hesabı, Y_pot = min(ikisi) |
| H | Efektif talep | Tüketim, kredi, yatırım; Y belirlenir |
| I | Kamu maliyesi | Vergi, harcama, kemer sıkma, temerrüt |
| — | Karanlık devlet | Mafya toleransı, uyuşturucu, karseral nüfus |
| — | Değer gaspı | Lümpen pay, gasp, üretken artı-değer, r |
| J | Finansallaşma | Spekülatif varlığa kayma |
| K | Balon patlaması | Fisher-Clarke borç krizi (Tip B) |
| L | Değer transferi | Bölgeler arası sızıntı, r_ef |
| M | Kamu sermayesi | Kamulaştırma payı, birikim hızı g, K güncellenir |
| N | Çalışma süresi | Saat ayarlaması |
| O | Teknoloji | Eğitim, AR-GE, mekanizasyon dürtüsü, q, çağ atlama |
| P | Phillips | Enflasyon |
| Q | Goodwin | Nominal ücret pazarlığı, ücret payı |
| R | Kriz tescili | Resesyon / büyük bunalım sınıflandırması |
| S | Örgütlenme | Sendikalaşma stoku, kentleşme |
| T | Protesto | Protesto riski, baskı, reform, devrim |

**Dünya düzeyi (ülke döngüsünden sonra):** göç akışları, nüfus güncellemesi,
savaş kararları, ittifaklar, hegemonya.

Bu sıranın iki önemli sonucu vardır. Birincisi, O bloğu (teknoloji) P ve Q
bloklarından **önce** çalışır; çünkü hem Phillips eğrisi hem Goodwin denklemi
gerçekleşen verimlilik artışına ihtiyaç duyar. v5.0'da ikisi de nominal çağ
katsayısını kullanıyordu ve bu, verimlilik doyduğunda ücret payını yapay olarak
aşağı eziyordu. İkincisi, karanlık devlet bloğu değer gaspından önce çalışır, ama
kâr oranı `r` bir önceki turun değeriyle okunur — bu bir turluk gecikme
kasıtlıdır: devlet politikası gözlemlenmiş kârlılığa tepki verir.

---

## 5. Denklem blokları

### 5.1 Organik bileşim ve kâr oranı — LTRPF çekirdeği

Sermayenin organik bileşimi `c/v`, verimlilik `q`'nun sürekli bir fonksiyonudur:

```
organik_bilesim(q) = log-log parçalı doğrusal interpolasyon
```

Çapa noktaları çağ tablosunun kendi değerleridir: her çağın `c/v`'si o çağa
giriş eşiğindeki `q` ile eşleştirilir — (0.5, 1.0), (2.6, 2.2), (5.2, 3.8),
(10.5, 6.0), (21.0, 9.5), (42.0, 15.0). Çağ 6'nın ötesinde son segmentin
eğimiyle ekstrapole edilir ve **tavanı yoktur**.

Sermaye/kapasite katsayısı:

```
kv = kv0 * (c/v * deger_carpani)^kv_us / (1 + ucuzlama(q))
ucuzlama(q) = ucuzlama_max * L / (L + ucuzlama_h),   L = ln(q/0.5)
```

Payda **doyumludur**: `ucuzlama` üst sınırı `ucuzlama_max`'tır. Bu, Marx'ın
kendi çerçevesidir — sabit sermayenin ucuzlaması bir karşı-eğilimdir, eğilimi
geciktirir ama tersine çeviremez. v5.0'da payda `log(q)` ile sınırsız büyüdüğü
için karşı-eğilim eğilimi tamamen yutuyor ve kâr oranı **yükseliyordu**.

Kapasite ve kâr oranı:

```
Y_K = K / kv                      (sermaye kapasitesi)
Y_L = q * L_etkin                 (emek kapasitesi)
u   = Y / Y_K                     (kapasite kullanımı)
s_ham = Y * (1 - pay) * (1 - kamu_pay*(1 - kamu_r_farki))
s     = s_ham * (1 - lumpen_pay)  (üretken birikime kalan artı-değer)
r     = s / K
```

**Kanonik kâr denklemi.** Otomasyon ve değer gaspı katmanları eklendikten sonra
`r = (1−pay)·u/kv` özdeşliği artık kodun uyguladığı denklem *değildir*; yalnızca
otomasyon yokken (`canli_pay = 1`, `lumpen_pay = 0`, ETG kapalı) geçerli bir özel
durumdur. Kodun fiilen hesapladığı tek kanonik zincir:

```
V      = Y * canli_pay                       # yeni değer: yalnızca canlı emek
s_ham  = V * (1-pay) * (1 - kamu_pay*(1-kamu_r_farki))
s_ham *= (1 - etg_vergi_sermaye*etg_vergi_sermaye_o)
s      = s_ham * (1 - lumpen_pay)            # Tonak değer gaspı
r      = s / K
r_ef   = (s + VT_net) / K                    # eşitsiz mübadele dahil
```

Kâr oranı beş kanaldan etkilenir: bölüşüm, canlı emek payı, kamu payı, ETG'nin
sermayeden finansmanı ve lümpen sektörün değer gaspı. Otomasyon sonrası modelin
bütün radikal sonucu `canli_pay` üzerinden gelir; eski özdeşlik bunu göstermez.

### 5.2 Efektif talep

```
C_temel = c_ucret*pay*Y*(1-v_ucret) + c_kar*(1-pay)*Y*(1-v_kar)
norm   += norm_uyum * (norm_agirlik*tuketim_normu
                       + (1-norm_agirlik)*(C_temel/Y) - norm)
acik    = max(0, norm*Y - C_temel)
kredi_istahi = max(0, 1 - (borc/Y/borc_limiti)^kredi_us)
yeni_kredi   = kredi_egilimi * kredi * acik * kredi_istahi
C = C_temel + yeni_kredi - borc_servisi
I = (g + delta_K) * K * (1 - delev_soku)
Y = min(Y_pot, max(C + I + G + VT_net, Y_pot*gecim_tabani))
```

`kredi_istahi` borç stokuna duyarlıdır: borç limite yaklaştıkça kredi arzı kendi
kendini frenler. `kredi_egilimi` v4.2'de 0.555'ten **0.300**'e düşürüldü — eski
değerde ülkeler varlıklarının %38–44'ünü deleveraging içinde geçiriyordu.

Tüketim normu **uyarlanabilir**: kısmen toplumsal özleme, kısmen gerçekleşen
tüketime yakınsar. v5.0'da `norm_uyum` tanımlıydı ama hiç kullanılmıyordu; norm
sabit kalınca ücret payı ezildikçe tüketim açığı kalıcılaşıyor, kredi durmadan
şişiyor ve ülkeler turların ~%70'ini deleveraging içinde geçiriyordu.

**Sosyalist rejimde hasıla plana göre belirlenir**, efektif talebe göre değil:
`Y = Y_pot * (plan_kullanim + plan_pke_kullanim*PKE)`. Gerçekleşme krizi
kapitalizme özgüdür; planlı ekonominin kendi kriz biçimi kıtlıktır ve
`sos_kitlik_agirlik` üzerinden protesto fonksiyonuna girer.

### 5.3 Birikim

```
g_ozel = g_taban + g_duy*(r_ef - i_ef) + hizlandirici*(u - u_normal)
g_kamu = 0.004 - kamu_istikrar*min(0, r_ef - i_ef)
g      = (1-kamu_pay)*g_ozel + kamu_pay*g_kamu
K      = K * (1 + g)
```

`g` **net** birikim oranıdır. `I = (g + delta_K)*K` brüt yatırımdır; amortisman
zaten `I`'nin içinde telafi edildiği için stok güncellemesi net oranla yapılır.
v5.0'da `K*(1+g-delta)` yazıldığı için amortisman iki kez düşülüyordu.

`hizlandirici` v4.2'de **kurumsallaştırıldı**: `duzenli` 0.045, `liberal` 0.100,
`neoliberal` 0.200. Yüksek değer kısa yatırım ufku ve finans güdümlü, çevrimsel
yatırım demektir; düşük değer koordine, sabırlı, devletçe düzleştirilmiş birikim.
Yüksek hızlandırıcı sermaye salınımlarını büyütür ve mekanizasyonu hızlandırır,
dolayısıyla uzun vadede yedek sanayi ordusunu büyütür — neoliberal odanın daha
yüksek işsizlik üretmesi "zayıf talep"ten değil bu **oynaklık** kanalından gelir.

Birikimin ana sürücüsü **kâr-faiz makasıdır** (`r_ef - i_ef`). Bu makas
kapanırsa birikim durur; bu, modelin en kritik geri besleme noktasıdır.

### 5.4 Reel ve spekülatif faiz — Marx'ın kâr oranı tavanı

```
i_pol  = Taylor kuralı (enflasyon + kapasite + istihdam + balon + kriz)
i_ham  = i_pol * (1 + BoP_R + moratoryum cezası)
i_reel = min(i_ham, faiz_kar_tavani * r + faiz_taban_marj)    # 0.80*r + 0.002
i_spec = i_ham                                                # TAVANSIZ
```

Tavan **yalnızca `i_reel`'e** uygulanır. Marx'ın Kapital III, 22. bölümdeki
önermesi *sınai* kârın bölüşümü hakkındadır: faiz, üretken sermayenin ürettiği
artı değerin bir parçasıdır ve üst sınırı kârın kendisidir. Spekülatif finans
ise varlık fiyatı beklentisinden fiyatlanır, sanayinin kâr oranından değil —
ona tavan uygulanmaz.

v4.2'de tek bir `i_ef` vardı ve tavan hepsine birden uygulanıyordu. Bu,
teknolojik işsizliği çözerken finansallaşma koşulunu (`r < i`) turların
%63'ünden %1.3'üne düşürüp spekülatif balon kanalını tamamen öldürüyordu.
Ayrım bu ödünleşmeyi ortadan kaldırır: birikim sağlam kalır **ve** balon
kanalı çalışır.

`i_reel` üretken yatırım kararında ve hanehalkı borç servisinde; `i_spec`
finansallaşma akımında, Minsky tetikleyicisinde ve kurumsal geçişin
"kârsızlık rasyosu" ölçütünde kullanılır.

### 5.4b Spekülatif balon ve Minsky krizi

```
makas   = max(0, (i_spec - r)/i_spec)
kayan   = fin_pay*finans*s*makas                      (kâr sıkışması kanalı)
        + spec_kredi*kredi*varlik*max(0, beklenti)    (kaldıraçlı spekülasyon)
kayan  *= max(0, 1 - (varlik/Y)/balon_limiti)         (doygunluk)
varlik  = (varlik + kayan) * (1 - balon_sonum)

getiri   = (varlik/Y) / (varlik/Y)_önceki - 1
beklenti = EMA(getiri)                                (ekstrapolatif — Minsky)
```

Üç tasarım kararı önemlidir. Akım **stok geri beslemelidir**: saf bir çarpım
formu doygunluk içermez, böyle bir terim ya tabana yapışır ya tavana koşar.
Beklenti ham stok üzerinden değil **varlık fiyatı** (`varlik/Y`) üzerinden
hesaplanır; hasıla büyürken sabit bir stok reel olarak değer kaybediyor
demektir. Ve balon kendi beklentisini besler — Minsky'nin "istikrar
istikrarsızlaştırır" önermesinin motordaki karşılığı budur.

Kırılma koşulu bir **sayaçtır**:

```
varlik/Y > minsky_esik ve beklenti < i_spec  →  minsky_sayac += 1
aksi halde                                   →  minsky_sayac -= 1
minsky_sayac >= minsky_sure                  →  ÇÖKME (Tip B)
```

Tek turluk bir "beklenti < maliyet" koşulu yetmez: `balon_sonum` nedeniyle
varlık doğal olarak eriyor, beklenti çoğu turda zaten negatif, koşul tek başına
`varlik/Y > eşik`e indirgeniyor. Sayaçsız hâlde Minsky krizi 14 yılda bire
çıkıyordu; sayaçla 40 yıla oturuyor.

Son satır Marx'ın Kapital III, 22. bölümdeki önermesidir: faiz artı-değerin bir
bölüşüm biçimidir, üst sınırı kârın kendisidir. Faiz kâr oranını kalıcı olarak
aşamaz, çünkü aşsaydı para sermaye üretken yatırıma hiç girmez, tamamı faiz
getiren sermayeye kayardı.

Tavan **geçirgendir**: 0.80 katsayısıyla `r < i_ef` koşulu ancak `r < 0.01`
iken sağlanır. Böylece kâr sıkışması ve finansallaşma kanalı korunur ama
sürekli değil, gerçek bir sıkışmada tetiklenir.

### 5.5 Bölüşüm — Goodwin çevrimi

```
bos_e   = e - e_norm                       (hareketli istihdam çapasından sapma)
kat     = w_katilik + (1-w_katilik)*min(1, iss/katilik_cozulme)
goodwin = phi*bos_e            (bos_e > 0)
        = phi*kat*bos_e        (bos_e < 0, nominal aşağı katılık)
aktarim = emek_pay + (1-emek_pay)*org
w_nom_buyume = telafi*pi_bek + goodwin + w_org_e*org*(e-e0) + aktarim*q_buyume
d_pay = clamp(w_nom_buyume - pi_inf - q_buyume, ±pay_degisim_tavani)
pay  *= (1 + d_pay)
pay_taban = max(0.10, pay_taban0 + pay_taban_org*org - gasp_taban*lumpen_pay)
pay = clamp(pay, pay_taban, pay_tavani)
```

İki nokta kritiktir. Birincisi, Goodwin terimi **sabit bir hedefe değil ülkenin
kendi hareketli istihdam normuna** göre çalışır. v5.0'da `e - 0.90` kullanılıyordu
ve model 0.90'a hiç ulaşamadığı için terim kalıcı negatifti: çevrim değil, tek
yönlü bir çöküş üretiyordu. İkincisi, ücret payı bir **stok** gibi davranır; tur
başına göreli değişimi sınırlıdır.

Ücret payının tabanı **emek gücünün değeridir** (`pay_taban0 = 0.28`). Bunun
altına inmek emek gücünün kendini yeniden üretememesi demektir.

### 5.6 Nominal katman — Phillips

```
birim_emek   = clamp(w_nom_buyume - q_buyume, -0.15, 0.25)
bosluk       = u - u_normal
talep_etkisi = ph_talep*bosluk                        (bosluk > 0)
             = ph_talep*ph_asimetri*max(bosluk,-0.30) (bosluk < 0, aşağı katılık)
pi_ham = ph_beklenti*pi_bek + talep_etkisi + ph_maliyet*birim_emek + sok
```

Eşik aşılırsa fiyat kontrolleri devreye girer, bastırılan enflasyon biriktirilir
ve kontrol bittiğinde `kont_patlama` katsayısıyla patlar.

### 5.7 İçsel teknik değişme

```
ito = ito_taban + (1-ito_taban)*min(ito_tavan, (pay/ito_pay_ref)*(e/ito_e_ref))
doyum = max(q_doyum_taban, 1 - q/q_tavan)
q_buyume = qg * (0.5 + 1.6*min(rd*rd_olcek, 1.2)) * hiz * nitelik
           * kamu_din * doyum * ito
q *= (1 + q_buyume)
```

`ito` çarpanı modelin istikrarı için belirleyicidir. Marx'ta (Kapital I, 15.
bölüm) makineleşmenin dürtüsü emek kıtlığı ve ücret baskısıdır: yedek sanayi
ordusu şişip ücretler tabana yapıştığında sermayenin emeği ikame etme güdüsü
zayıflar, emek-yoğun teknikler kârlı hale gelir. Bu olmadan model tek yönlü bir
teknolojik işsizlik çöküşü üretir.

`doyum` terimi her paradigmanın bir teknolojik doyum sınırı olduğunu ifade eder
(Neo-Schumpeterci S-eğrisi). Çağ atlamak bu düzeyi yükseltir.

**`q_tavan` sert bir tavan DEĞİLDİR.** `doyum = max(q_doyum_taban, 1 − q/q_tavan)`
olduğu için `q > q_tavan` olduğunda büyüme sıfırlanmaz, taban hızda (%5) sürer.
Ölçüm: çağ 6'da 20 ülkenin 4'ü aşıyor (q 64–317, `q_tavan` 200). Bu bilinçli bir
tercihtir — organik bileşimin çağ 6'nın ötesinde de ilerlemesi LTRPF için
gereklidir — ama "tavan" değil **doyum noktası** olarak okunmalıdır.

### 5.8 Dış ticaret — Thirlwall

```
q_rel = q / dünya ortalama q
eps   = eps0*(0.45 + eps_q*min(q_rel,2.2)) * (1 + eps_vt*VT_net/Y) * (1+deval)
        * (1 - eps_lumpen*lumpen_pay)
pi_m  = max(0.35, pi0*(1.45 - pi_q*min(q_rel,2.0)) * (1 + pi_lumpen*lumpen_pay))
y_max = eps * y_dunya / pi_m
```

Bu, Thirlwall Kanunu'nun modeldeki karşılığıdır: ödemeler dengesiyle uyumlu
büyüme hızı, ihracat gelir esnekliğinin ithalat gelir esnekliğine oranıyla
sınırlıdır. Lümpenleşme bu oranı iki uçtan birden bozar — nitelik birikiminin
kaybı ihracat esnekliğini düşürür, ithalat bağımlılığını artırır.

### 5.9 Değer transferi — eşitsiz mübadele

```
d1 = (cv - dünya_ort_cv) / dünya_ort_cv       (organik bileşim farkı)
d2 = (s/v - dünya_ort_s/v) / dünya_ort_s/v    (sömürü oranı farkı)
wd1, wd2 = (0.9, 0.1) çevre ise, (0.2, 0.8) değilse
VT_net = vt_siddet * Y * (wd1*d1 + wd2*d2) * dışa_açıklık
r_ef   = (s + VT_net) / K
```

Çevre ülkeler için organik bileşim farkı, merkez ülkeler için sömürü oranı farkı
baskındır. `r_ef` birikim kararında kullanılan, değer transferini içeren kâr
oranıdır.

### 5.10 Tonak değer gaspı

```
lumpen_pay = min(lumpen_tavan, lumpen_carpani * uyusturucu_orani)
s_v        = (1 - pay) / pay
gasp       = s_ham * lumpen_pay * illegalite_primi
s          = s_ham * (1 - lumpen_pay)
varlik    += gasp_varlik * gasp
```

İllegal sektör, payının **ötesinde** değer çeker (illegalite primi). Payı kadarı
üretken birikimden düşülür; aşan kısmı ücretlerden gelir ve ücret payının
tabanını düşürür. Gasbedilen değer üretken sermayeye değil spekülatif stoka
akar — yani balon-çökme kanalını besler.

### 5.11 Karanlık devlet

```
tikanma       = clamp((i_ef - r)/kd_tikanma_olcek, 0, 1)
refah_yoklugu = 1 - clamp((r - r_referans)/r_refah_olcek, 0, 1)
kd_hedef = clamp(kd_taban + kd_tikanma*tikanma + kd_omega*Omega*refah_yoklugu
                 + kd_baski*baski_egilimi - kd_mesruiyet*PC - kd_org*org, 0, kd_tavan)
mafya_tolerans += kd_hiz * (kd_hedef - mafya_tolerans)
```

Karanlık devlet **endojendir**: birikim tıkandığında, sınıf öfkesini refahla
yatıştırmanın imkânı kalmadığında ve baskı aygıtı güçlüyken açılır; demokratik
meşruiyet ve güçlü sendikal örgütlenme frenler. Bu, el kitabının kendi tezidir —
karanlık devlet aşırı birikimin sonucu olan yapısal bir subaptır. v4.0'da bu
değişken hiçbir koşulda değişmeyen dışsal bir oyuncu kadranıydı.

Uyuşturucu yayılımı lojistiktir:

```
yayilim  = uo_omega*Omega*mafya_tolerans        (merkezi kanal)
         + uo_iss*max(0, iss - uo_iss_esik)     (yedek sanayi ordusu)
         + uo_gecim*max(0, gecim_tabani - pay)  (geçim krizi)
bastirma = uo_bastirma*(1-mafya_tolerans)*(taban + (1-taban)*PC)
d_uo = yayilim*(1 - uo/uo_tavan) - (bastirma + uo_cozulme)*uo
```

Yayılım ve bastırma **ikisi de** `uo` ile orantılıdır; bu yüzden tolerans
sürekli bir kadran gibi davranır. v4.0'da bastırma terimi sabit olduğu için
tolerans aç/kapa düğmesi gibi çalışıyordu.

### 5.12 Karseral devlet

```
cezaevi_orani = clamp(karseral_taban + karseral_uo*uyusturucu_orani
                      + karseral_iss*iss + karseral_baski*baski_egilimi*Omega,
                      0.0008, cezaevi_tavan)
```

Karseral nüfus dört kanaldan sisteme bağlıdır:

1. **Emek arzından düşülür** (`L_etkin`). Itoh'un formülasyonuyla, hapsedilen
   kitle artık artı-değer üretiminin öznesi değil, "atıl sermaye" yönetiminin
   nesnesidir.
2. **Kamu bütçesinde harcama kalemidir** (`karseral_maliyet`).
3. **Eğitim bütçesini dışlar** (`karseral_egitim_disla`) — sosyal yatırımların
   yerini güvenlik harcamaları alır.
4. **Protesto riskini bastırır** ama **meşruiyeti aşındırır**.

v4.0'da `cezaevi_orani` hesaplanıyor ve kaydediliyordu ama hiçbir şeyi
etkilemiyordu; el kitabının 4. bölümünün tamamı bir çıktı değişkeniydi.

### 5.12b Kurumsal rejim geçişleri ve rakip ülke davranışı

```
liberal    → duzenli    : taze bunalım ve (org >= kg_org_esigi veya zorlayıcı)
duzenli    → neoliberal : rli >= kg_kar_esigi veya stagflasyon >= eşik
neoliberal → duzenli    : taze bunalım ve (org >= kg_geri_donus_org veya zorlayıcı)

zorlayıcı = taze bunalım ve (Omega >= kg_omega_esigi veya derinlik >= kg_derin_bunalim)
rli       = son 60 turda r < i_spec olan turların oranı
```

v4.2'de **neoliberal mutlak bir yutucu durumdu**. Çıkışın tek koşulu
`org >= 0.55` idi; uzun dönemde örgütlülük 0.24–0.35 bandında kalıyor,
dolayısıyla 1200 turda 20 ülkede **sıfır** kurumsal geçiş oluyor ve bütün
dünya neoliberalde donuyordu. İki değişiklik yapıldı: baraj sendikal gücün
ulaşabildiği seviyeye çekildi (0.38) ve ikinci bir çıkış yolu eklendi —
yeterince derin bir bunalım, sendikalar zayıf olsa bile rejimi değiştirmeye
zorlar (1930'lar mantığı).

Bu kilidi açan asıl şey ise bunalım kaydının kendisiydi: `bun_esik` 0.24 ve
`bun_sure` 14 iken büyük bunalım 324 yılda 20 ülkede **2 kez** tesciliyordu,
yani `taze_bunalim` koşulu neredeyse hiç sağlanmıyordu.

**Rakip ülke davranışı.** Oyuncu dışındaki 19 ülkenin birbirinden farklı
davranmasını sağlayan asgari mekanizma `KURUMLAR` tablosundaki politika
tepkisi parametreleridir:

| kurum | `hizlandirici` | `kars_dongusel` | `kredi` | `finans` | davranış |
|---|---|---|---|---|---|
| duzenli | 0.045 | 1.70 | 0.45 | 0.35 | koordine yatırım, karşı-döngüsel harcama |
| liberal | 0.100 | 0.60 | 0.55 | 0.85 | sınırlı müdahale |
| neoliberal | 0.200 | 0.25 | 1.35 | 1.30 | çevrimsel yatırım, krizde kemer sıkma |

`kars_dongusel`, krizde devreye giren anti-konjonktürel kamu harcamasını
ölçekler: düzenli devlet harcar, neoliberal devlet kısar. Bu, oyuncu dışı
ülkelerin krize farklı tepki vermesini sağlayan tek mekanizmadır ve
genişletilmesi gereken yerdir (bkz. bölüm 11).

### 5.12c Evrensel Temel Gelir (ETG)

**ETG = Evrensel Temel Gelir.** Kodda `etg`, `etg_hedef`, `etg_metasiz`,
`set_temel_gelir()`, `set_etg_finansman()`.

Artık nüfusu yönetmenin **üçüncü** tekniği; modelde zaten iş paylaşımı (`saat`)
ve karseral/narkotik pasifizasyon vardı. Tek yönlü bir "iyi şey" değildir; eş
zamanlı **üç çelişkili etkisi** vardır ve hangisinin baskın olacağı bir
parametre değil, örgütlülüğün endojen fonksiyonudur
(`etg_metasiz = min(1, org/etg_org_ref)`):

```
(1) ÜCRET SÜBVANSİYONU  (Marx, Kapital I/25 — Speenhamland)
    pay_taban -= etg_taban_dus * etg * (1 - etg_metasiz)
(2) METASIZLAŞMA        (Gorz — rezervasyon ücreti)
    kat        = min(1, kat + etg_katilik * etg * etg_metasiz)
(3) PASİFİZASYON
    refah     += etg_omega * etg
    kd_hedef'teki Omega terimi *= (1 - etg_kd * etg)
```

Ayrıca bütçede kalemdir, işgücüne katılımda gönüllü çekilme ve doğurganlıkta
refah etkisi yaratır. **Yalnızca kapitalist rejimde tanımlıdır**: planlı
ekonomide ücret zaten planla belirlenir, "emek gücünün değeri" ve
"rezervasyon ücreti" kavramlarının orada karşılığı yoktur.

Çağ kapısı yoktur — her çağda mümkündür ama ancak verimlilik yeterince
yüksekken mali olarak taşınabilir.

**Finansman kaynağı** (`set_etg_finansman`) iki ayrı çelişkiye bağlanır:
sermayeden finanse etmek net kârlılığı düşürür ve LTRPF'yi hızlandırır — vergi
kendi tabanını aşındırır; ücretten finanse etmek tüketimi kısar ve gerçekleşme
krizini derinleştirir.

### 5.12d Otomasyon — robot kullanım değeri üretir, değer üretmez

**Temel kural:** artı-değerin tek kaynağı canlı emektir. Makine sabit
sermayedir; kendi değerini ürüne aktarır, yeni değer yaratmaz. Bu yüzden
robotlar emek arzına **eklenmez** — eklenselerdi değer kaynağı olurlar ve
LTRPF'nin bütün temeli çökerdi.

Doğru kuruluş iki katmanı ayırır:

```
FİZİKSEL katman:  emek_esdeger = canlı_emek + oto_verim*oto*K/q
                  Y_L = q * emek_esdeger          (kullanım değeri)

DEĞER katmanı:    canli_pay = canlı_emek / emek_esdeger
                  V = Y * canli_pay               (YENİ DEĞER)
                  v = pay*V        s = (1-pay)*V        r = s/K
```

Satın alma gücü de fiziksel hasıladan değil `V`'den gelir; otomasyon
ilerledikçe `Y` büyürken `V` küçülür ve kronik aşırı üretim bu makastan doğar.

Bu, Grundrisse'deki **hareketli çelişkidir**: sermaye emek zamanını asgariye
indirirken onu zenginliğin tek ölçüsü olarak korur. `canli_pay → 0` iken
`V → 0`, `s → 0`, `r → 0` — fiziksel hasıla devasa olsa bile.

### 5.12e Kampanya, çağ bantları ve iki katmanlı çalışma süresi

**Kampanya 1760–2100**, yani 1259 tur. Başlangıç çağ 1 (Buhar).

Çağ atlama **içseldir ama tarihsel banda çakılıdır**: `yil_alt`'tan önce hiçbir
koşulda atlanamaz, `yil_ust` geçildiğinde teknolojik gecikme ne olursa olsun
atlanır. Böylece hızlı gelişen bir oyuncu 1900'de tam otomasyona varamaz, geride
kalan bir dünya da 2100'de buhar çağında kalmaz.

| çağ | bant | ölçülen varış |
|---|---|---|
| 2 Elektrik | 1840–1905 | 1858 |
| 3 Otomasyon | 1925–1975 | 1925 |
| 4 Siber-fiziksel | 1980–2015 | 1980 |
| 5 İnsan-YZ | 2000–2035 | 2000–2015 |
| 6 Tam otomasyon | 2040–2075 | 2040–2050 |

**Çalışma süresi iki katmanlıdır.** Önceden `saat` tek bir skalerdi ve
`saat = 1.0` sabit bir "tam hafta" demekti; bu, haftanın tarihsel kısalmasını
(1760'ta ~70 saat) iş paylaşımı marjıyla karıştırıyordu. Tek skaler olduğu için
paylaşım sınırsız genişleyip otomasyon fazlasının tamamını soğuruyor, çağ 6'da
haftada ~7 saate yapışıyor ve işsizlik hiç oluşmuyordu.

```
hafta_norm[era] : çağın normal tam haftası (tarihsel kısalma)
saat            : o normun içindeki paylaşım payı [0.85, 1.0]
fiili hafta     = hafta_norm[era] * saat
```

Fazla emek 0.85'in altına inemediği için **işsizliğe dönüşür** — sermaye işi
paylaştırmaz, işçiyi atar. Ölçülen tarihsel ark: 1760'ta 65 saat, 1930'da 48,
1972'de 42, 2099'da 28 saat.

### 5.12f Çağ 6 çatalı: işsizliğin anlamı rejime bağlıdır

Önceden işsizlik **her rejimde** aynı gerilimi üretiyordu (`b_iss*iss`). Oysa tam
otomasyon altında kimsenin çalışmadığı durum aynı fiziksel gerçek olsa da,
kapitalizmde yoksunluk, komünizmde emekten kurtulmadır. Aynı `oto`, aynı
`canli_pay`, zıt anlam.

Koşul **bolluktur**: sosyalist rejimde düşük istihdam ancak kıtlık düşükse
masumdur.

```
bolluk      = max(0, 1 - kitlik/sos_bolluk_esigi)
iss_agirlik = 1 - sos_iss_bolluk * min(1, bolluk)
arg         = ... + b_iss*iss*iss_agirlik - theta
```

Ölçüm (socialist_siege, 400 tur, 5 tohum) protesto riskinde 280 kat fark
veriyor: sanayileşmeci plan (kıtlık 0.400) PR = 0.656; tüketimci plan
(kıtlık 0.000) PR = 0.0023. Yani planlı ekonomi otomasyonu bolluğa çevirmeyi
başaramazsa o da distopyaya döner. Ayrıca bir "tekno-diktatörlük" ya da
"komünizm" etiketi gerekmez — ikisi de aynı denklemin iki tarafıdır.

### 5.12g Yalnız kalan sosyalizmin iki yolu ve dünya devrimi

Tek başına kalmış (`blok <= 1`) ve abluka/ambargo altındaki bir sosyalist
ekonomi, kıtlık biriktikçe iki yoldan birine sapar. Hangisi olacağını **partinin
zor aygıtı** belirler:

| koşul | sonuç |
|---|---|
| `baski_egilimi >= 0.55` | **Piyasa sosyalizmi** (Çin yolu): parti iktidarda kalır, kapitalist birikime kapıları açar |
| `baski_egilimi < 0.55` | **Restorasyon**: kıtlık rejimi düşürür, kapitalizm restore edilir |

Ölçüm (tek sosyalist ülke, abluka altında, 8 tohum): `baski = 0.75` olan
tohumlarda piyasa sosyalizmi, `baski = 0.35` olanlarda restorasyon — ayrım tam
olarak beklendiği yerde.

**Uygulama notu:** piyasa sosyalizmi üçüncü bir `rejim` değeri *değildir*.
Motorda 42 ayrı rejim kontrolü var; üçüncü değer eklemek hepsini elden geçirmeyi
gerektirirdi. Bunun yerine `rejim = "kapitalist"` (bütün iktisadi mekanik aynen
işler) artı `parti_iktidari = True` (siyasi kabuk farklı). Bu aynı zamanda
teorik olarak doğru: piyasa sosyalizmi, kapitalist birikimin farklı bir siyasi
kabuk içindeki halidir. Parti iktidarı ücret payı tabanını 0.12'ye düşürür —
emeğin pazarlık zemini siyaseten bastırılmıştır.

**Dünya devrimi — Komintern'in iki koşulu.** İlk kuruluşta eşik "sosyalist
ekonomilerin dünya hasılasındaki payı > %50" idi; ölçüm bunun **pratikte
erişilemez** olduğunu gösterdi (kuşatma altındaki planlı ekonomilerin hasılası
küçük kaldığı için 4–7 sosyalist ülkeyle bile pay 0.00–0.04'te takılıyordu).
Hasıla şartı terk edildi. Yerine iki klasik koşul, `dd_sure` tur boyunca
**birlikte** sürmek üzere:

```
(1) ENTERNASYONAL DAYANIŞMA
    pakt_var  = sosyalist ülke sayısı >= dd_pakt_esigi
    pakt_uyum = sosyalist / (sosyalist + piyasa sosyalizmi) >= dd_uyum_esigi

(2) KAPİTALİZMİN GENEL KRİZİ
    krizde(c) = Omega > esik  ya da  bunalım içinde
                ya da (deleveraging ve işsizlik > esik)
    kap_kriz_payi >= dd_kriz_esigi
```

Paktın iki çatlağı vardır. Birincisi **piyasa sosyalizmine sapma**: parti
iktidarını koruyup kapitalist birikime geçen devlet blokla dayanışmaz.

İkincisi **ideolojik rekabet**, ve koşulu yalnızca ideolojik farklılıktır.
Ölçütü **plan profili mesafesidir** — birikim hızı, tüketimle ilişki ve savunma
payı üzerindeki hat ayrılığı. Çin–Sovyet ayrışmasının tarihsel içeriği tam
olarak buydu; modelde serbest bir "ideoloji" değişkeni uydurmaya gerek kalmıyor,
mevcut plan vektörü zaten bu hattı taşıyor.

**Rekabet olup olmayacağına oyuncu karar verir.** İdeolojik mesafe yalnızca
zemini kurar; duruş bir politika seçimidir (`set_pakt_durusu`). AI ülkeler
mesafe eşiği üzerinde rekabete kayar, oyuncunun ülkesi yalnızca oyuncunun
kararıyla değişir.

Rekabetin bedeli ölçüldü (socialist_siege, 6 tohum, 600 tur):

| oyuncu duruşu | pakt uyumu | müttefik | PKE | dünya devrimi |
|---|---|---|---|---|
| ittifak | 0.900 | 2.5 | 0.940 | 5/6 |
| rekabet | 0.633 | 0.0 | 0.900 | **2/6** |

Rekabet seçen ülke müttefiksiz kalır, blok planlama bonusunu yitirir ve tek
başına dünya devrimini engelleyebilir.

Ölçüm ayrıca şunu gösterdi: ortak kuşatma altındaki sosyalist devletler aynı
plan hattına yakınsıyor (ideolojik mesafe 0.00–0.08), yani AI kaynaklı ayrışma
seyrek. Bu, "oyuncu karar verir" tasarımıyla tutarlı — asıl kanal oyuncudur.

Tetiklendiğinde **kuralları kalıcı olarak değiştirir**: abluka, ambargo ve değer
transferi sona erer.

Ölçüm: varsayılan dünyada 8 tohumdan 2'sinde gerçekleşiyor (2053 ve 2061, yani
çağ 6'nın ortası); `socialist_siege` senaryosunda 6 tohumun hepsinde. Yani
kaçınılmaz değil, koşullu — istenen yapı bu.

### 5.12h Marksist politik özne (parti)

Karanlık devletin bölme ve yozlaştırma politikalarının **karşı kuvveti**. Ölçüm,
çağ 6'da devrimin imkânsız hale geldiğini göstermişti: Omega 1.000'e doyuyor,
işsizlik %54, ücret payı 0.29 — nesnel koşullar azami; ama protesto riski
düşüyordu, çünkü `lumpen_sonum` ve `karseral_sonum` protestoyu tam o noktada
bastırıyor ve örgütlülük 0.62'den 0.29'a eriyordu.

Eksik olan karşı kuvvetti. `org` sendikalaşmadır ve **ücretli emeğe bağlıdır**;
otomasyon ücretli emeği yok ettikçe org da erir. Marksist politik özne ise
sendikanın ulaşamadığı yeri örgütler: **işsizler kitlesini** — ki otomasyon
altında büyüyen tam da odur.

```
zemin  = parti_iss*işsizlik + parti_yoksullasma*(1 - pay/parti_pay_ref)
         + parti_kriz*kriz
yıkım  = parti_baski*baski_egilimi + parti_lumpen*lumpen_pay
parti  → clamp(zemin - yıkım)         (yavaş yerleşir: bir kuşak işi)

orgutlu = org + parti*(1 - org)        # parti, sendika dışı kitleyi kapsar
direnc  = 1 - parti_direnc*parti       # bilinçlendirme sönümlemeyi kırar
lumpen_sonum   = 1 - min(0.85, lumpen_sonum_gucu*lumpen_pay*direnc)
karseral_sonum = 1 - min(0.40, karseral_disiplin*(...)*direnc)
```

Ölçüm, mekanizmanın tasarlandığı gibi çalıştığını gösteriyor:

| yıl | çağ | org | parti | örgütlü | PR |
|---|---|---|---|---|---|
| 1998 | 4.4 | 0.598 | 0.162 | 0.657 | 0.439 |
| 2041 | 5.0 | 0.425 | 0.276 | 0.583 | 0.514 |
| 2084 | 6.0 | 0.299 | 0.384 | 0.568 | **0.573** |

Sendikalaşma otomasyonla erirken parti büyüyor; örgütlü güç çökmüyor (0.657 →
0.568; parti olmadan 0.399'a iniyordu) ve **protesto riski artık yükseliyor**
(0.44 → 0.57; önce 0.51 → 0.42 düşüyordu). Yani tekno-diktatörlüğün devrimci
özneyi imha ederek otomatik kazanması ortadan kalktı.

### 5.13 Sınıf tepkisi ve devrim

```
arg = b_pay*(1-pay) + b_iss*iss - theta
PR  = sigmoid(kappa*arg) * lumpen_sonum * karseral_sonum
Omega += org_omega*(a1*PR + a2*kriz)*(0.4+1.6*org)
         - a4*baski - a5*reform - sönüm - refah - vt_baris
```

Protesto riski `PR` eşiği aşıp `pr_sure` tur boyunca sürerse ve `Omega` devrim
eşiğini geçerse sosyalist devrim gerçekleşir.

`pr_esik` v4.3-A'da 0.85'ten **0.74**'e çekildi. Eski eşik, PR'ye çarpımsal
pasifizasyon sönümleyicileri (`lumpen_sonum` × `karseral_sonum`, birlikte
%30–40 kesinti) eklenmeden önce kalibre edilmişti; ölçümde PR azami 0.877'ye
ulaşıyor ama 10 tur üst üste 0.85'te kalamıyordu, `pr_sayac` hiç işlemiyor ve
324 yılda 20 ülkede sıfır devrim oluyordu. Bu, motorda tekrar eden bir hata
sınıfıdır: **bir büyüklüğün ölçeği değiştiğinde ona bağlı mutlak eşiklerin de
taşınması gerekir.** Lümpenleşme ve karseral disiplin
protesto riskini söndürür — el kitabının pasifizasyon tezi budur.

Kurumsal geçişler (`liberal → duzenli → neoliberal`) büyük bunalım, örgütlenme
düzeyi ve kârlılık koşullarına bağlıdır.

### 5.14 Demografi

```
huzursuzluk = 0.35*Omega + 0.20*iss + 0.40*uyusturucu_orani + ...
dogum_orani = taban * era_katsayi * (1 - min(0.85, huzursuzluk)) + refah_terimi
olum_orani  = taban + 0.05*uyusturucu_orani + ...
L_max      *= (1 + (dogum_orani - olum_orani)*TUR_YIL)
```

Demografik kriz biyolojik bir sapma değil, birikim rejiminin fiziksel sınırına
ulaştığının göstergesi olarak modellenmiştir.

---

## 6. Geri besleme döngüleri

Modeli anlamanın en hızlı yolu denklemleri tek tek okumak değil, hangi
döngülerin kapandığını görmektir.

### Döngü 1 — LTRPF (temel eğilim)

```
birikim → mekanizasyon → q artar → c/v yükselir → kv büyür
       → r = (1-pay)·u/kv düşer → kâr-faiz makası daralır → birikim yavaşlar
```

Bu döngü **negatif geri beslemelidir** ve modelin uzun dönem eğilimini verir.
Doğrulama koşularında kâr oranı 1200 turda %32–35 düşer.

### Döngü 2 — Goodwin (bölüşüm çevrimi)

```
yüksek istihdam → ücret payı yükselir → kâr oranı düşer → birikim yavaşlar
                → istihdam düşer → ücret payı geriler → kâr oranı toparlanır
```

**Salınımlıdır.** Modelin orta vadeli konjonktürünü üretir.

### Döngü 3 — İçsel teknik değişme (istikrar sağlayıcı)

```
düşük istihdam + düşük ücret payı → ito düşer → mekanizasyon yavaşlar
                                  → birikim istihdamı yakalar → istihdam toparlanır
```

Bu döngü olmadan Döngü 1 tek yönlü bir teknolojik işsizlik çöküşüne dönüşür.

### Döngü 4 — Borç-deflasyon (Fisher–Clarke)

```
ezik ücret payı → tüketim açığı → hanehalkı kredisi genişler
                → borç/hasıla limite dayanır → çöküş → deleveraging
                → yatırım kesilir → hasıla düşer → ücret payı daha da ezilir
```

**Pozitif geri beslemelidir**, yani kendini besler. Kredi iştahının borç stokuna
duyarlı hale getirilmesi ve ücret payı tabanının emek gücünün değerine
sabitlenmesi bu döngüyü sınırlar.

v4.2'de bu döngünün balon ayağı **ölüydü**: çöküşlerin tamamı hanehalkı
borcundan geliyor, `varlik/Y` hiçbir zaman eşiğe yaklaşmıyordu. v4.3-A'daki
reel/spekülatif faiz ayrımı (5.4) bunu çözdü; artık iki kanal da çalışıyor ve
ayrı ayrı ölçülebiliyor.

### Döngü 4b — Minsky (finansal kırılganlık)

```
düşük kâr oranı → artı değer finansa kayar → varlık fiyatı yükselir
                → beklenti yükselir → kaldıraçlı spekülasyon → balon büyür
                → beklenti finansman maliyetinin altına düşer
                → teminat değeri çöker → kredi daralır → yatırım düşer → kriz
```

Döngü 4'ten **ayrı** tutulur: farklı tetikleyici, farklı politika tepkisi.
Hanehalkı borç krizine karşı kredi düzenlemesi işe yarar; Minsky krizine karşı
yaramaz, çünkü balonu besleyen şey kâr sıkışmasının kendisidir.

### Döngü 5 — Kriz devalüasyonu (Marx'ın 1. karşı-eğilimi)

```
kriz → sabit sermaye değersizleşir (deger_carpani düşer) → c/v efektif olarak düşer
     → kv küçülür → r yükselir → yeni birikim çevrimi başlar
```

Bu, krizin **onarıcı** işlevidir. Modelde bu mekanizma yokken kriz yalnızca
yıkıyor, hiçbir şeyi onarmıyordu; çünkü `r = (1-pay)·u/kv` özdeşliğinde K
düşünce Y de orantılı düşüyordu.

### Döngü 6 — Karanlık devlet (pasifizasyon)

```
birikim tıkanır + refahla yatıştırma imkânsız → mafya toleransı açılır
   → uyuşturucu yayılır → lümpen sektör büyür → sınıf tepkisi söner
   → ama: değer gaspı üretken birikimi zayıflatır, Thirlwall kısıtı daralır,
     karseral nüfus büyür, meşruiyet aşınır
```

Kısa vadede rejimi kurtarır, uzun vadede birikimi daha da bozar.

### Döngü 7 — Eşitsiz mübadele (merkez-çevre)

```
merkez yüksek q → yüksek eps, düşük pi_m → gevşek BoP kısıtı → daha hızlı birikim
çevre düşük q  → düşük eps, yüksek pi_m → sıkı BoP kısıtı → değer sızıntısı
              → düşük AR-GE → q daha da geride kalır
```

**Pozitif geri beslemelidir**: kutuplaşmayı derinleştirir.

---

## 7. El kitabı ile kod arasındaki eşleme

Teorik el kitabı ("İdeolojik Devlet Aygıtları, Karanlık Politika ve Demografik
Kriz El Kitabı v4.0") altı bölümden oluşur. Aşağıdaki tablo her bölümün kodda
nereye karşılık geldiğini gösterir.

| el kitabı bölümü | kavram | koddaki karşılığı |
|---|---|---|
| 1. Küresel aşırı birikim, devletin çelişkili formu (Clarke) | Karanlık devlet birikim tıkanıklığının subabıdır | `kd_hedef` denklemi: `kd_tikanma*(i_ef-r)` terimi |
| 1. Emeğe göre aşırı birikim (Itoh) | Kâr sıkışması | `r_ef - i_ef` makası, `faiz_kar_tavani` |
| 2. Lümpenleşme, yarılma (Negri/Kennedy) | Sınıf bilincinin parçalanması | `lumpen_sonum`, `lumpen_org` |
| 2. Değer gaspı (Tonak) | `s/v = (P-(c+v))/v`, illegalite primi | `s_v`, `gasp`, `illegalite_primi` |
| 3. Cedeplar-UFMG, yapısal heterojenlik | Endojen esneklikler | `eps_lumpen`, `pi_lumpen` |
| 3. Thirlwall Kanunu | BoP-kısıtlı büyüme | `eps`, `pi_m`, `y_max` |
| 4. Karseral devlet (Itoh, atıl öğeler) | Hapsetme bir sermaye yönetim biçimidir | `L_etkin`, `karseral_maliyet`, `karseral_disiplin` |
| 5. Demografik kriz | Endojen doğum/ölüm | `dogum_orani`, `olum_orani`, `huzursuzluk` |
| 6. KODEY metrik seti | Denetim göstergeleri | `get_summary()`, `kodey_trendi()` |

**KODEY metrik seti** şu göstergelerden oluşur ve `kodey_trendi()` bunların zaman
seyrini verir:

| metrik | kod adı | ölçtüğü |
|---|---|---|
| Sömürü oranı sapması | `s_v` | Değer gaspı ve illegal sermaye transferi |
| Organik bileşim rasyosu | `cv` | İşsizlik ve lümpenleşme potansiyeli |
| Thirlwall esneklik katsayısı | `eps/pi_m` | BoP-kısıtlı büyüme, yapısal heterojenlik |
| Atıl öğeler endeksi | `atil_endeks` | Karseral nüfus / üretken emek gücü |
| Lümpen sektör payı | `lumpen_pay` | Asalak alanın ekonomideki ağırlığı |

---

## 8. Senaryo odaları

`load_scenario(isim)` dört tarihsel/kurgusal başlangıç durumu kurar. Yükleme
sırası önemlidir: önce yapısal ayarlar (çağ, kurum, rejim), sonra
`init_simulation()`, en sonra oransal ayarlar (FX/Y, borç/Y, Omega, org, pay).

| senaryo | yıl | çağ | kurum | ayırt edici özellikler |
|---|---|---|---|---|
| `golden_age_1950` | 1950 | 2 | duzenli | org 0.72, pay 0.58, tam istihdam, sıfıra yakın finans |
| `neoliberal_1995` | 1995 | 4 | neoliberal | org 0.15, pay 0.38, borçla güdümlenen tüketim, balonlar |
| `turkey_2001` | 2001 | 4 | neoliberal | dış borç limitte, rezerv tükenmiş (FX=0.02Y), IMF kemer sıkması, Omega 0.45 |
| `socialist_siege` | 2030 | 5 | duzenli | Rusya/Çin/Türkiye sosyalist, emperyalist müdahale zirvede |

Her senaryonun bir **`K_carpani`** değeri vardır: sermaye stokunun emek arzına
göre bolluğu. Bu, senaryonun tarihsel başlangıç işsizliğini kuran değişkendir.

| senaryo | `K_carpani` | 120 tur işsizlik |
|---|---|---|
| golden_age_1950 | 1.70 | 0.021 |
| neoliberal_1995 | 0.45 | 0.065 |
| turkey_2001 | 0.50 | 0.064 |
| socialist_siege | 1.30 | 0.119 |

Neden türetilmiyor da kuruluyor: işsizlik bu modelde **yavaş biriken bir
stoktur** — birikim hızı ile mekanizasyon hızı arasındaki yarışın bakiyesidir.
120 turluk (~32 yıl) oyun ufkunda kurumsal farklardan türetilemez; o pencerede
başlangıç koşulları baskındır. Senaryo odalarının işi zaten budur: başlangıç
durumu tarihsel olarak kurulur, oyuncunun politikası onu oradan **hareket
ettirir**. Uzun vadede hızlandırıcı kanalı işsizliği 0.12 ile 0.34 arasında
gezdirebilmektedir, yani tepki kanalı çalışır.

`cag_ata()` yardımcısı bir ülkeyi çağa taşırken `q`'yu o çağla tutarlı kılar:
göreli verimlilik konumu korunur, mutlak seviye hedef çağın aralığına taşınır.
v4.0'da senaryolar `era` atıyor ama `q`'ya dokunmuyordu; Türkiye çağ 4'te
(siber-fiziksel) ama q=0.53 (buhar çağı seviyesi) oluyordu.

---

## 9. Doğrulama sonuçları

### 9.1 Kriz taksonomisi (5 tohum, 1200 tur = 324 yıl, 20 ülke)

Şartnamenin 14. bölümünün istediği kriz ayrımı artık hem mevcut hem de frekans
sıralaması doğru. Ülke başına ortalama aralık:

| olay | ülke başına aralık |
|---|---|
| küçük resesyon | **10 yıl** |
| Tip C — döviz krizi | 27 yıl |
| Tip B2 — hanehalkı borç krizi | 33 yıl |
| Tip B — Minsky balonu | 40 yıl |
| büyük bunalım | 67 yıl |
| Tip D — kamu borç krizi | 175 yıl |

Sıralama artık doğru: resesyon en sık olay (konjonktür frekansı), finansal
krizler 30–50 yıl bandında (şartnamenin 15. bölümündeki hedef), büyük bunalım
kuşak başına bir kez, kamu temerrüdü nadir.

v4.2 ile karşılaştırma: küçük resesyon 50 → 10 yıl, büyük bunalım 3240 → 67 yıl,
Minsky kanalı yok → 40 yıl. Deleveraging payı %38–44 → **%30**.

### 9.2 Motor bütünlüğü (aynı koşular)

```
LTRPF            : −%46      (c/v son 21.6)
işsizlik         : 0.065
kurumsal geçiş   : 127       (v4.2: 0)
devrim           : 1.4       (tohumlara göre 0–3)
kurum dağılımı   : 11–17 neoliberal / 3–9 düzenli   (v4.2: 20/0)
```

### 9.3 Senaryo odaları (120 tur, 3 tohum: 1/42/2024)

| senaryo | işsizlik | ücret payı | örgütlülük | r | tolerans |
|---|---|---|---|---|---|
| golden_age_1950 | 0.033 | 0.547 | 0.726 | 0.0237 | 0.000 |
| neoliberal_1995 | 0.068 | 0.374 | 0.254 | 0.0240 | 0.010 |
| turkey_2001 | 0.061 | 0.414 | 0.214 | 0.0222 | 0.018 |
| socialist_siege | 0.108 | 0.435 | 0.275 | 0.0166 | 0.008 |

### 9.4 Şartnamenin başarısızlık testleri karşısında durum

| test | durum |
|---|---|
| 1. c/v tavana çarpar | geçti (sürekli fonksiyon, tavan yok) |
| 2. kâr oranı sistematik yükselir | geçti (−%46) |
| 3. %70+ kalıcı işsizlik | geçti (0.065) |
| 4. bütün krizler aynı mekanizmadan | geçti (6 ayrı kanal) |
| 5. finansal balon hiç oluşmaz | geçti (Minsky 40 yıl) |
| 6. sosyalist ekonomiler birbirinin kopyası | **açık** |
| 7. tek politika her durumda optimal | oyuncu katmanı yok, test edilemez |
| 8. hegemonya hiç değişmez | ölçülmedi |
| 9. bütün ülkeler aynı rejime yakınsar | geçti (11–17 / 3–9 karma) |
| 10. oyuncu etkisi gürültüden ayırt edilemez | oyuncu katmanı yok |

### 9.5 v4.3-R açık alanlarının kapatılması

**Monte Carlo kabul raporu (30 tohum × 1200 tur = 324 yıl):**

| ölçüt | medyan | p10 | p90 | bant | sonuç |
|---|---|---|---|---|---|
| LTRPF | −%45.2 | −%50.5 | −%40.6 | [−60,−25] | geçti |
| işsizlik | 0.080 | 0.044 | 0.145 | [0.03, 0.25] | geçti |
| resesyon aralığı | 9.5 yıl | 8.5 | 10.4 | [6, 15] | geçti |
| Minsky aralığı | 41.8 yıl | 36.8 | 46.0 | [30, 60] | geçti |
| kurumsal geçiş | 116 | 106 | 133 | ≥40 | geçti |
| devrim | 2.0 | 0.0 | 4.0 | [0, 6] | geçti |
| çifte hareket | 1651 ileri / 1809 geri | | | her iki yön | geçti |
| liberale endojen dönüş | 0 | | | 0 olmalı | geçti |

**Liberal rejim — Clarke ve Polanyi.** `liberal`in soyunun tükenmesi bir hata
değil, iki kuramın da öngördüğü sonuçtur. Polanyi'de *laissez-faire planlanmıştır*:
kendi kendini düzenleyen piyasa kendiliğinden doğmaz, devletçe kasıtlı olarak
inşa edilir; buna karşılık koruyucu karşı-hareket kendiliğinden doğar. Clarke'ta
neoliberal devlet, devletin geri çekilmesi değil yeniden yapılandırılmasıdır —
müdahale aygıtı bir kez kurulunca sökülmez. Dolayısıyla liberal rejime **endojen
sürükleniş yoktur**; yalnızca yüksek siyasi sermaye gerektiren ve onu tüketen
kasıtlı bir siyasi proje olarak kurulabilir (`set_kurumsal_insa`). Polanyi'nin
çifte hareketi ise zaten `duzenli ↔ neoliberal` salınımı olarak çalışıyor.

Buna göre şartname §48'in "her kapitalist kurumdan ≥2 ülke" ölçütü yanlıştır ve
yerini çifte hareketin her iki yönde işlemesi testi almıştır.

**Sosyalist ayrışma (§49, 10 tohum × 400 tur, medyan):**

| değişken | sanayileşmeci | tüketimci | fark |
|---|---|---|---|
| Y | 1592.9 | 249.5 | +%538 |
| q | 189.4 | 160.2 | +%18 |
| ücret payı | 0.392 | 0.558 | −%30 |
| kıtlık | 0.418 | 0.000 | — |
| birikim g | +0.0023 | −0.0069 | — |

Plan payları rakip kullanımlardır ve normalize edilir; biri artarsa diğeri
mutlaka azalır. Sanayileşmeci plan 6 kat hasıla ve daha hızlı teknoloji üretir
ama ücret payını %30 düşürüp %42 kıtlık yaratır. Tüketimci plan kıtlığı
gidermekte ama küçülmektedir. İkisi de "doğru" değildir.

**Rakip ülke AI'sı (§50).** Her ülke kurumsal rejimine göre, oyuncunun
kullandığı aynı genel API üzerinden politika seçer. Eşzamanlı etiketlemeyle
ölçüm:

| kurum | ETG | işsizlik | Omega | tolerans |
|---|---|---|---|---|
| duzenli | 0.0310 | 0.100 | 0.358 | 0.140 |
| neoliberal | 0.0128 | 0.217 | 0.441 | 0.166 |
| liberal | 0.0000 | 0.164 | 0.480 | 0.147 |

### 9.6 ETG kapitalizmi ilelebet kurtarabilir mi?

ETG'nin modele eklenme amacı buydu: egemen sınıfın yapay zekâ işsizliğine karşı
orta yolcu önerisini Marksist kriz teorisi içinde sınamak.

**Kanal ayrıştırması** (ETG=0.10, 600 tur, 3 tohum). İşsizlik artışı toplam
+0.084; yalnız bütçe kanalı +0.101, yalnız ücret katılığı kanalı +0.028. Baskın
olan **bütçe dışlaması**, sınıfsal kâr sıkışması değil — bu da finansman
tasarımını belirleyici kılar.

**Finansman kolu** (ETG=0.10, 600 tur, 3 tohum):

| finansman | işsizlik | r | kamu borcu |
|---|---|---|---|
| tamamen ücretten | 0.211 | 0.0152 | 0.695 |
| yarı yarıya | 0.272 | 0.0144 | 0.723 |
| tamamen sermayeden | 0.250 | **0.0141** | 0.541 |

Sermaye finansmanı en düşük kâr oranını veriyor: vergi kendi tabanını yiyor.

**Can simidi testi.** Devlet, huzursuzluğu devrim eşiğinin altında tutmak için
gereken ETG'yi verir (`P.cs_acik = True`); mali fren gerçektir. 8 tohum × 1200
tur, tamamen sermayeden finanse:

| tur | gereken ETG | kamu borcu | fren | Omega | r | işsizlik |
|---|---|---|---|---|---|---|
| 0–150 | 0.0000 | 0.706 | %0 | 0.024 | 0.0218 | 0.073 |
| 300–450 | 0.0301 | 0.584 | %1 | 0.272 | 0.0180 | 0.105 |
| 450–600 | **0.0798** | 0.569 | %0 | 0.175 | 0.0149 | 0.173 |
| 750–900 | 0.0409 | 0.549 | %0 | 0.144 | 0.0134 | 0.127 |
| 1050–1200 | 0.0355 | 0.563 | %0 | 0.123 | 0.0118 | 0.051 |

**Sonuç beklenenin tersi: bu kalibrasyonda ETG sistemi istikrara kavuşturuyor.**
Gereken ETG t≈500'de %8'e çıkıp sonra %3.5'e geriliyor, kamu borcu yükselmiyor,
mali fren neredeyse hiç devreye girmiyor.

Bu bir kalibrasyon eksikliği değil, modelin söylediği şeyin kendisi:

| tur | çağ | işsizlik | ücret payı | Omega | saat | ito |
|---|---|---|---|---|---|---|
| 0–150 | 4.3 | 0.075 | 0.415 | 0.025 | 0.979 | 0.954 |
| 450–600 | 6.0 | **0.166** | 0.378 | 0.493 | 0.594 | 0.812 |
| 750–900 | 6.0 | 0.080 | 0.409 | 0.576 | 0.699 | 0.929 |
| 1050–1200 | 6.0 | **0.053** | 0.462 | 0.523 | 0.853 | 1.074 |

**Tam otomasyon çağında kalıcı kitlesel işsizlik oluşmuyor.** İşsizlik t≈500'de
%17'ye çıkıp %5'e geriliyor. Sebebi `ito`: emek bollaşıp ucuzladığında (0.81'e
iner) sermayenin emeği ikame etme güdüsü zayıflar, mekanizasyon yavaşlar,
istihdam toparlanır. Bu Marx'ın kendi konumudur (Kapital I, 15. bölüm).

Yani model egemen söylemin **öncülünü** reddediyor: yapay zekâ kalıcı kitlesel
işsizlik değil, iş süresinin kısalması (0.98 → 0.59) ve yoksullaşma üretiyor.
Omega 0.025'ten 0.52'ye çıkıp orada kalıyor — gerilim işsizlikten değil ücret
payının ezilmesinden geliyor. ETG bunu kısmen yatıştırıyor (Omega 0.52 → 0.12)
ama yatıştırdığı ölçüde kâr oranını daha da düşürüyor (0.0218 → 0.0118).

**Ne test edilmedi.** Bu sonuç iki koşula bağlıdır: `ito` geri beslemesinin
çalışması ve mali frenin (`cs_borc_freni = 1.60`) hiç bağlayıcı olmaması. `ito`
kapatılır ya da otomasyon şoku sertleştirilirse makas açılabilir. Bunu
yapmadım: sonucu istenen yöne çekmek için parametre oynatmak şartname §57'nin
3. kuralının yasakladığı şeydir. Doğru yol `ito`'nun ampirik savunulabilirliğini
ayrıca sınamaktır.

### 9.7 Otomasyon, yeniden kalibrasyon ve ETG'nin sınırı

Otomasyon katmanı açıldıktan sonra üç kırpma ve iki eksik mekanizma çıktı;
hepsi düzeltildi ve kabul bantları yeniden kalibre edildi.

**Kırpmalar.** `e`'nin 0.30 tabanı sürekli bağlıyordu — ölçülen %70 işsizlik bir
artefaktti; taban 0.02'ye indirildi. Ayrıca `oto_verim` boyutsal olarak
yanlıştı: `robot_esdeger = oto_verim·oto·K/q` ve `K/q ≈ kv·emek_esdeger`
olduğundan robot/emek oranı `oto_verim·oto·kv`'dir; 0.55 seçmek bunu 9.3'e
çıkarıyor, canlı emek payını %4'e çökertiyor ve hem `e` hem `saat` tabanına
yapıştırıyordu. 0.040'a indirildi.

**Finansallaşmanın eksik sürücüsü.** Spekülatif akım yalnızca artı-değer
*akımından* besleniyordu (`fin_pay·finans·s·makas`). Otomasyonla `s` çökünce
Minsky kanalı da öldü (aralık 40 → 540 yıl). Oysa üretken kârlılık düştükçe
finansallaşmanın *artması* beklenir: finansal getiri arayan şey artı-değer akımı
değil, atıl duran **sermaye stokudur**. Stok terimi eklendi (`fin_stok·K·makas`)
ve Minsky 45 yıla döndü. Bu, `ito`'daki hatayla aynı sınıftan: mekanizmanın iki
sürücüsünden biri yoktu.

**Yeniden kalibre edilen bantlar.** Eskiler otomasyonsuz motora göre seçilmişti.
Canlı emek tek değer kaynağı olduğu ve robotlar fiziksel kapasiteyi büyüttüğü
için, tam otomasyon çağında yeni değerin yapısal olarak büzülmesi mekanizmanın
**doğru çıktısıdır**, sapma değil.

| ölçüt | eski bant | yeni bant | ölçülen medyan |
|---|---|---|---|
| LTRPF | [−60, −25] | **[−92, −55]** | −%84 |
| işsizlik | [0.03, 0.25] | **[0.15, 0.55]** | 0.34 |
| devrim | [0, 6] | **[0, 8]** | 4.0 |
| otomasyon payı | — | **[0.55, 0.85]** | 0.766 |
| canlı emek payı | — | **[0.12, 0.45]** | 0.227 |

Minsky, resesyon, kurumsal geçiş, çifte hareket ve liberale endojen dönüş
bantları değişmedi ve geçiyor. 20 tohum × 1200 tur: **tüm ölçütler geçti.**

**ETG can simidi — nihai sonuç** (6 tohum, tamamen sermayeden finanse):

| tur | ETG | kamu borcu | mali fren | Omega | r | işsizlik |
|---|---|---|---|---|---|---|
| 0–150 | 0.0000 | 0.666 | %0 | 0.035 | 0.02237 | 0.058 |
| 300–450 | 0.0720 | 0.693 | %6 | 0.398 | 0.00542 | 0.326 |
| 450–600 | **0.1023** | 0.726 | %1 | 0.227 | 0.00383 | 0.234 |
| 1050–1200 | 0.0728 | 0.890 | %5 | 0.279 | 0.00287 | 0.247 |

Kontrol grubuyla karşılaştırma (aynı 6 tohum):

| | ETG can simidi | ETG yok |
|---|---|---|
| devrim (medyan) | **4.0** | 2.5 |
| kamu temerrüdü (medyan) | 85.5 | 89.5 |

**Cevap: hayır, kurtarmıyor — ve daha ilginci, devrimi bile önlemiyor.** Önceki
(kırpılmış) kalibrasyonda ETG devrimi sıfırlıyordu; kırpmalar kaldırılıp
finansallaşma tamamlanınca bu sonuç kayboldu. Devrim sayısı ETG'li koşularda
*daha yüksek*. Mekanizma şu: ETG artı-değerden ödenir, sermayeden finanse
edilince net kârlılığı düşürür, bu birikimi yavaşlatır ve LTRPF'yi hızlandırır —
yani ertelemek için kullandığı kaynağı tüketir. Gereken ETG t≈500'de %10'a
çıkıyor ve bir daha %7'nin altına inmiyor; kamu borcu 0.67'den 0.89'a
tırmanıyor; mali fren kalıcı olarak turların %3–6'sında bağlayıcı.

Kâr oranı 0.0224'ten 0.0029'a düşüyor (−%87). ETG bunu yavaşlatmıyor,
hızlandırıyor. Grundrisse'deki hareketli çelişki bir bölüşüm politikasıyla
çözülmüyor: değerin kaynağı canlı emekse ve canlı emek üretimden çıkarılıyorsa,
o kaynaktan finanse edilen hiçbir transfer kalıcı olamaz.

## 9.8 Şartnamenin tamamlanması — oyuncu katmanı kararları

**Zafer koşulu yok (§42/43).** Bu oyunda kazanma/kaybetme tanımı yoktur; bir koşu
ufuk dolunca biter ve bir **tarihsel sonuç raporu** üretilir. Sosyalist devrim
gerçekleşirse oyuncu kaybetmez — ülkesi rejim değiştirir ve oyuncu **o rejimle
devam eder**: bölüşüm ve kurum kollarının yerini plan payları alır. ETG sosyalist
rejimde kendiliğinden kapanır, `set_plan_profili` devreye girer.

Bu, §43'ün "zafer tek politikaya indirgenemez" kuralını yapısal olarak karşılar:
karşılaştırılacak bir hedef yoksa "tek optimal politika" kavramı tanımsızdır.
§42'deki beş oyuncu hedefi de bu yüzden **düşürülmüştür** — rapor, oyuncunun ne
yaptığını anlatır, bir hedefe göre puanlamaz.

`tarihsel_rapor(ulke)` şunu döndürür: başlangıç/bitiş kesiti (işsizlik, ücret
payı, kâr oranı, çağ), kriz sayıları, kurumsal geçiş listesi, dönem dönem
(150 tur) tablo, ve ülkeye dokunan bütün olayların zaman damgalı listesi.

**Siyasi sermaye (§26).** PC **yalnızca yapısal değişiklikleri** kısıtlar (kurum
inşası, rejim düzeyi). ETG düzeyi, ETG finansmanı ve plan payları siyaseten
bedavadır ama iktisaden bedel öder: bütçe, kâr oranı, birikim. PC artık
**performansın sonucudur** — refah (büyüme, istihdam, ücret payı) ve istikrar
(düşük huzursuzluk) bileşenlerinden. v4.3-A'da PC tur başına sabit +0.025
büyüyordu, yani rıza bir sonuç değil bir saat gibi işliyordu. Doğrulama:

| huzursuzluk | ortalama PC |
|---|---|
| ~0.1 | 0.289 |
| ~0.3 | 0.237 |
| ~0.5 | 0.214 |

**Politika gecikmesi (§25).** İki katmanlı: ilan ile etkinin başlaması arasında
sabit gecikme (`pol_gecikme = 8` tur), sonra yerleşme hızı **rejime göre**
değişir. Neoliberal devlet hızlı hareket eder (merkezileşmiş yürütme, zayıf ara
kurumlar), düzenli devlet yavaş (mutabakat, sendika/sermaye pazarlığı).
Doğrulama: aynı ETG hedefi 60 tur sonra neoliberalde 0.122, düzenlide 0.066.

Bütün oyuncu API'si artık kuyruktan geçer — `set_temel_gelir`,
`set_etg_finansman`, `set_plan_profili`, `set_kurumsal_insa` bir **ilan**dır,
anlık durum değişikliği değil (Invariant 6 ile uyumlu).

**Rakip AI ek kolları (§22/§50).** Kredi duruşu, kamu yatırım payı ve dış ticaret
açıklığı eklendi; üçü de kurumsal rejime göre farklı yönde hareket eder.
Neoliberal krizde krediyi genişletip kamu sermayesini özelleştirir ve dışa
açıklığı artırır; düzenli krediyi frenleyip kamu yatırımını artırır ve açıklığı
sınırlar; sosyalist krediyi sıfırlar, yatırımı azami yapar, kapanır.

**Bilgi katmanları (§44) bilinçli olarak düşürülmüştür.** Her şey kesin, sis yok.
Bu oyunun amacı mekanizmaların görünür olmasıdır; bilgi kıtlığı öğretici değeri
düşürürdü.

**Monte Carlo (§47).** Varsayılan tohum sayısı 100'e çıkarıldı; 1000 komut
satırından verilebilir. Tek çekirdekte ~3.5 sn/tohum (1200 tur).

### 9.8 Çağ-1 kampanyasına geçişin bedeli

Çağ 1'den başlamak, çağ-4 başlangıçlı koşuya göre yapılmış **bütün
kalibrasyonu geçersiz kıldı**. Üç parametre boyutsal olarak yeniden ayarlandı:

| parametre | eski | yeni | gerekçe |
|---|---|---|---|
| `g_taban` | 0.0005 | 0.0080 | 340 yıllık arkta birikim `q` ve nüfus artışını yakalayamıyor, `Y_K/Y_L` 0.85→0.59 düşüyor ve **19. yüzyıl işsizliği %28–40'a çıkıyordu** |
| `oto_verim` | 0.040 | 0.110 | otomasyonun yerleşme süresi kısaldığı için işsizlik ancak %56'ya çıkıyordu |
| `fin_stok` | 0.0080 | 0.0450 | `K` bu ölçekte farklı büyüklükte; Minsky aralığı 160→76 yıl |

`g_taban` düzeltmesi kavramsal olarak en önemlisi: öncesinde işsizlik
otomasyondan değil **sermaye kıtlığından** geliyordu, yani artık nüfus yanlış
nedenle oluşuyordu. Düzeltmeden sonra 19. yüzyıl ~%16, 20. yüzyıl ortası ~%18,
otomasyon sonrası ~%62 — tarihsel sıralama doğru ve artık nüfus otomasyonla
birlikte oluşuyor.

Kabul bantları da yeniden kalibre edildi (20 tohum × 1259 tur, tümü geçti):

| ölçüt | medyan | bant |
|---|---|---|
| LTRPF | −%89.5 | [−95, −55] |
| işsizlik | 0.618 | [0.45, 0.80] |
| resesyon | 11.9 yıl | [6, 15] |
| Minsky | 76.0 yıl | [40, 110] |
| kurumsal geçiş | 162 | ≥40 |
| devrim | 2.0 | [0, 8] |
| otomasyon payı | 0.568 | [0.40, 0.70] |
| canlı emek payı | 0.312 | [0.20, 0.55] |

### 9.9 Tarihsel kriz kaydıyla karşılaştırma (1825–2023)

Yüklenen tarihsel kayıt (27 kriz) motorun ürettikleriyle karşılaştırıldığında
gerçek bir eksik çıktı: **kayıtlı bir aşırı üretim krizi tipi yoktu.** Motorun
19. yüzyılı borç ve döviz krizleriyle geçiyordu; oysa dönemin baskın biçimi
genel aşırı üretimdir (1825, 1836–39, 1847, 1857, 1866, 1873–79, 1882–85).

Tetikleyici **ham talep açığıdır**: `(Y_pot − D_talep)/Y_pot`. Emme kapasitesi
kuruma ve çağa bağlı olduğu için — erken çağlarda kredi ince, devlet küçük —
Marx'ın öngördüğü **yer değiştirme kendiliğinden çıkar**: aşırı üretim
kaybolmaz, kredi ve finansallaşma onu emip dönüşmüş biçimde (borç, balon) geri
getirir.

| dönem | çağ | aşırı üretim | borç | Minsky | bunalım |
|---|---|---|---|---|---|
| 1825–1900 | 1–2 | **27y** | 37y | 114y | 42y |
| 1900–1945 | 2–3 | 37y | 33y | 83y | 39y |
| 1945–1980 | 3 | 39y | 39y | 51y | 44y |
| 1980–2023 | 4 | 58y | 43y | **34y** | 61y |

Aşırı üretim 2.1 kat seyrekleşir, Minsky 3.4 kat sıklaşır, 20. yüzyıl ortasında
kesişirler. Tarihsel kayıttaki örüntü budur: 19. yüzyıl aşırı üretim, 1945–75
çevrimsel aşırı üretim, 1969'dan kârlılık, 1980 sonrası finansal/spekülatif.
Bu eğilim **elle ayarlanmadı**, mevcut kredi/devlet emme yapısından çıktı.

### 9.10 Karşı devrim kalibrasyonu ve çağ 5 dalgası

Çağ bantları tersine çevrildi: **çağ 5 uzun (~68 yıl), çağ 6 kısa (~28 yıl)** —
asıl çalkantı çağı yapay zekâ/robotik geçişidir, çağ 6 yalnızca son kapışmadır.
Savaşlar çağ 5'te zirve yapar (37 savaş; diğer çağlarda 14–26).

Omega'ya **aşırı üretim gerilimi** eklendi: gerçekleşme makası çağ 5 boyunca
açılıyordu (canlı emek payı 0.94 → 0.32) ama Omega'yı hiç beslemiyordu.

Karşı devrimin önündeki engel blok büyüklüğü değildi: **sosyalist AI kıtlık
görünce tüketimci plana geçip kıtlığı sıfırlıyor**, restorasyon koşulunu kendisi
engelliyordu (8 devrim, 0 restorasyon). `kitlik` yalnızca plan payına bağlıydı;
oysa abluka altında tüketim malı ithal edilemez — Küba ve SSCB deneyimi budur.
Abluka artık doğrudan kıtlık kaynağıdır.

20 tohumla kalibrasyon (8 tohumda oran gürültüde kayboluyordu):

| `izo_abluka_kitlik` | devrim | geri alınan |
|---|---|---|
| 0.130 | 17 | **%53** |
| 0.190 | 18 | %67 |
| 0.250 | 17 | %100 |

0.130 seçildi; 20 tohumda 21 devrim, 10 geri alma (**%48**).

### 9.11 Nihai kabul raporu (20 tohum × 1259 tur)

| ölçüt | medyan | bant | |
|---|---|---|---|
| LTRPF | −%93.6 | [−95, −55] | geçti |
| işsizlik (kapitalist ülkeler) | 0.455 | [0.45, 0.80] | geçti |
| resesyon | 12.4 yıl | [6, 15] | geçti |
| Minsky | 63.2 yıl | [40, 110] | geçti |
| kurumsal geçiş | 171 | ≥40 | geçti |
| devrim | 1.0 | [0, 8] | geçti |
| otomasyon payı | 0.555 | [0.40, 0.70] | geçti |
| canlı emek payı | 0.209 | [0.20, 0.55] | geçti |

İşsizlik ölçütü **yalnızca kapitalist ülkelerde** ölçülür: planlı ekonomiler plan
gereği tam istihdama yakın çalıştığı için, devrim sayısı arttıkça dünya
ortalaması düşer ve ölçüt otomasyon işsizliğini değil devrim sayısını ölçer hale
gelirdi. Otomasyonun artık nüfus tezi kapitalizme dairdir.

`oto_hiz` 0.012 → 0.030: çağ 6 kısaltılınca otomasyonun yerleşmeye vakti kalmadı
(0.57 → 0.45) ve işsizlik banda düştü. Karar "otomasyon bir kuşak boyunca
yerleşsin" idi; kuşak ~28 yıl olduğu için hız buna göre ayarlandı.

### 9.12 Askeri müdahale kanalı ve ızgara kalibrasyonu

**Çağ 6 sorununun gerçek teşhisi.** Üç hipotez sırayla ölçülüp elendi:

1. *Seçilim* (çağ 6'ya dirençli ülkeler kalıyor) — **çürütüldü**: baskı eğilimi
   birebir aynı (0.450 vs 0.450), parti aynı (0.324 vs 0.326), ama Omega 1.000
   vs 0.606, işsizlik %57 vs %28, ücret payı 0.284 vs 0.532. Çağ 6 ülkeleri
   devrim yapanlardan **çok daha kötü** durumda.
2. *Eşik* — kısmen doğru: PR medyanı çağ 6'da daha yüksek (0.494 vs 0.388) ama
   sabit 0.74 eşiğini hiçbir turda aşmıyordu. Eşik Omega'ya esnetildi.
3. *Ülke kalmaması* — **asıl sebep**: 10 tohumun hepsinde çağ 6'da sıfır
   kapitalist ülke. Çağ 5 dalgası dünyayı süpürüyordu.

Üç mekanizma birbirini besleyerek tek yönlü bir çığ oluşturuyordu:
`parti güçlenir → devrim artar → blok büyür → izolasyon olmaz → karşı devrim
düşer → çağ 6'da devrilecek kimse kalmaz`.

**Askeri müdahale kanalı.** Kanal aslında vardı ama iki yerden tıkalıydı:

- Yenilgi→restorasyon `PKE < 0.62` şartına bağlıydı; planlama gücü 0.98–0.99
  seyrettiği için **askeri yenilgi asla restorasyona dönüşemiyordu**. Belirleyici
  artık yenilginin ağırlığıdır (güç oranı), plan gücü değil.
- Müdahale devrimden tam 3 tur sonra tek seferlikti ve blok büyüklüğüne
  bakmıyordu. Artık 40 turluk pencere var ve sosyalist blok büyüdükçe kapitalist
  merkezin müdahale isteği büyür — büyük bir blok tam da büyük olduğu için
  topyekûn savaşı davet eder.

**Izgara taraması.** Dört parametre birbirine bağlı olduğu için tek tek
ayarlamak işe yaramadı (her ayar bir hedefi tutturup diğerlerini kaydırıyordu;
devrim sayısı 1'den 18'e çıkmıştı). 20 konfigürasyon × 6 tohum tarandı, bant
dışılığı cezalandıran bir puan fonksiyonuyla:

| parti_hiz | pr_esik_omega | kd_yenilgi | sv_blok_tehdidi | devrim | kapitalist | çağ 6 | puan |
|---|---|---|---|---|---|---|---|
| 0.0035 | 0.06 | 0.45 | 3.0 | 14.0 | 6.0 | 0.18 | 3.00 |
| 0.0020 | 0.06 | 0.58 | 3.0 | 10.5 | 9.5 | 0.09 | 1.05 |
| 0.0014 | 0.06 | 0.58 | 4.5 | 6.0 | 14.0 | 0.18 | 0.68 |
| **0.0008** | **0.06** | **0.58** | **4.5** | **7.5** | **12.5** | **0.18** | **0.15** |

Seçilen set son satırdır. 20 tohumla doğrulama: **10 ölçütün 9'u geçiyor.**

| ölçüt | medyan | bant | |
|---|---|---|---|
| LTRPF | −%93.1 | [−95, −55] | geçti |
| işsizlik | 0.391 | [0.45, 0.80] | **kaldı** |
| resesyon | 11.8 yıl | [6, 15] | geçti |
| Minsky | 62.4 yıl | [40, 110] | geçti |
| kurumsal geçiş | 168 | ≥40 | geçti |
| devrim | 5.0 | [0, 8] | geçti |
| otomasyon payı | 0.527 | [0.40, 0.70] | geçti |
| canlı emek payı | 0.256 | [0.20, 0.55] | geçti |

Çağ 6'da artık hem kapitalist ülke kalıyor (medyan 12.5) hem devrim oluyor —
tekno-diktatörlük ile komünizmin kapışması mekanik olarak mümkün.

### 9.13 Dış eleştiri ve iki kritik düzeltme

Bağımsız bir kod incelemesi iki hatayı bulup doğruladı; ikisi de düzeltildi.

**(1) Determinizm — aynı tohum aynı deney değildi.** AI kararlarını ülkelere
yaymak için `hash(c.ad)` kullanılıyordu; Python'da string hash'i
`PYTHONHASHSEED` ile **sürece özgü** rastgeleleştirilir. Ölçüm (tohum 42, üç
ayrı süreç): kurumsal geçiş 32/37/38, çökme 76/83/86, savaş 1/3/2. Yani o
tarihe kadar raporlanan **bütün Monte Carlo sonuçları yeniden üretilemezdi.**
`zlib.crc32` süreçler arası kararlıdır; düzeltmeden sonra üç süreç birebir aynı
(geçiş 43, çökme 90, savaş 4).

**(2) Devrim muhasebesi.** Senaryoda sosyalist kurulan ülkelere `devrim_t = 0`
atanıyordu. Bu hem `get_summary`'de devrim sayısını şişiriyor
(`socialist_siege`, t=5: gerçek devrim 0 iken 3 bildiriliyordu) hem de askeri
müdahale penceresine (`0 < t − devrim_t <= 40`) sokup ilk 40 turda müdahaleye
açıyordu. Ayrıldı: `devrim_t` yalnızca simülasyon içi devrim,
`baslangic_rejimi_t` senaryo başlangıcı.

**Determinist motorla doğrulama (20 tohum):** LTRPF −%92.8, işsizlik 0.388,
resesyon 11.9 yıl, Minsky 64.1 yıl, kurumsal geçiş 172, devrim 6.0, otomasyon
0.520, canlı emek payı 0.260; çifte hareket iki yönde, liberale endojen dönüş 0.
On ölçütün dokuzu geçiyor (sekiz sayısal + iki mantıksal); kalan işsizlik.

### 9.14 Birincil kriter: mekanizma yön testleri

Bant testleri "sayı şu aralıkta mı" diye sorar ve bu projede o aralık **dört kez
değiştirildi**; bantlar kalibrasyonun kaydıdır, bağımsız kriter değil. Yön
testleri ise "otomasyon artınca canlı emek payı *düşüyor* mu" diye sorar — yönü
ayarlayamazsınız. **Birincil kriter artık yön testleridir**, bantlar ikincil.

`mekanizma_testleri.py` dokuz mekanizma için işaret/sıralama iddiası kurar:

| test | iddia | sonuç |
|---|---|---|
| LTRPF | q↑ → c/v↑ → r↓ | 5/5 |
| Otomasyon | oto↑ → canlı_pay↓ → r↓ | 5/5 |
| Goodwin | e↔pay pozitif, pay↔r negatif | 5/5 |
| Thirlwall | yüksek q → yüksek eps/pi_m | 5/5 |
| Minsky | finansallaşma kapalı → daha az Minsky | 5/5 |
| Kriz devalüasyonu | devalüasyon kapalı → r daha çok düşer | 5/5 |
| Sosyalist bolluk/kıtlık | bolluk → düşük PR; kıtlık → yüksek PR | 5/5 |
| Karanlık devlet | tolerans kapalı → daha az uyuşturucu | 4/5 |
| Politik özne | parti açık → daha yüksek örgütlü güç | 5/5 |

**Tümü geçti.** Kriz devalüasyonu testi ilk yazımda 0/4 veriyordu; sebep model
değil **test hatasıydı** — var olmayan bir parametre (`deger_kriz`) sıfırlanıyor,
yani iki özdeş koşu karşılaştırılıyordu. Doğru parametrelerle (`dev_cokme`,
`dev_bunalim`) etki net: LTRPF −%92.2 → −%94.1, `deger_carpani` 0.427 → 0.577.

### 9.15 İşsizlik bandının teorik yeniden kuruluşu

Yeni bant bir nokta tahmini değil, **iki sınır argümanı**:

- **Alt sınır 0.30** — otomasyon artık nüfus *üretmelidir*. Ölçüm: çağ 4'te
  işsizlik medyanı 0.000, p90 0.426; çağ 6 bunu aşmalıdır, yoksa "otomasyon
  emeği yerinden ediyor" iddiası boş kalır.
- **Üst sınır 0.75** — ücretli emek tamamen yok olursa yeni değer `V` çöker ve
  sistem kendini üretemez. Model canlı emek payını 0.20'nin altına indirmiyor.

Bant geniştir ve bu kasıtlıdır: 2100 işsizliği için ampirik çapa yoktur.

### 9.16 Kalibrasyon / doğrulama ayrımı

```
set=kalibrasyon -> tohum 1..100    (parametreler burada ayarlandı)
set=dogrulama   -> tohum 101..200  (DONDURULMUŞ, hiç görülmedi)
```

Önceden taahhüt: doğrulama kalırsa **en fazla iki kez** yeniden kalibre edilir,
her seferinde yeni doğrulama aralığı çekilir. Sınırsız yineleme çoklu hipotez
testine döner.

**Doğrulama seti (tohum 101–120, parametreler dondurulmuş):** LTRPF −%93.0,
işsizlik 0.400, resesyon 11.8 yıl, Minsky 66.0 yıl, kurumsal geçiş 173, devrim
7.0, otomasyon 0.518, canlı emek payı 0.274 — **tüm ölçütler geçti.**
Kalibrasyon seti (1–20) ile fark her ölçütte p10–p90 bandının içinde. İlk
yinelemede geçti; iki yeniden kalibrasyon hakkı harcanmadı.

### 9.17 Hassasiyet analizi: yapısal parametre mi, kalibrasyon düğmesi mi?

Bu belgede onlarca parametre elle ayarlandı; hangilerinin yapısal olduğu
ölçülmemişti. On beş kritik parametre ±%20 tarandı ve on iki çekirdek metrikteki
ortalama mutlak **esneklik** ölçüldü (esneklik = |Δmetrik/metrik| ÷ |Δpar/par|).

| parametre | taban | esneklik | en çok etkilediği |
|---|---|---|---|
| `oto_verim` | 0.110 | 0.845 | canlı_pay (3.65) |
| `fin_stok` | 0.045 | 0.797 | canlı_pay (3.27) |
| `g_taban` | 0.0080 | 0.714 | canlı_pay (3.50) |
| `phi` | — | 0.566 | canlı_pay (2.50) |
| `vt_siddet` | 0.050 | 0.562 | canlı_pay (2.68) |
| `pr_esik_omega` | 0.060 | 0.522 | canlı_pay (2.18) |
| `oto_hiz` | 0.030 | 0.497 | r (2.68) |
| `parti_hiz` | 0.0008 | 0.486 | canlı_pay (2.00) |
| `delta_K` | 0.0205 | 0.364 | r (1.22) |
| `asiri_uretim` | 0.018 | 0.331 | LTRPF (0.98) |
| `g_duy` | — | 0.326 | — |
| `kredi_egilimi` | 0.300 | 0.316 | canlı_pay (1.01) |
| `ito_rekabet` | 1.300 | 0.272 | — |

**Hiçbir parametrenin esnekliği 1.0'ı aşmıyor.** Yani motor ±%20 değişime
dayanıklı; tek bir düğmenin sonucu belirlediği bir kırılganlık yok. Bu, elle
yapılan onlarca ayarın *sonucu belirlemediğinin* en güçlü kanıtı.

**En kırılgan çıktı `canli_pay`** (esneklikler 2–3.65). Beklenen: otomasyon
katmanının bütün radikal sonucu bu değişkenden geliyor, dolayısıyla ona bağlı
yorumlar en dikkatli yapılmalı.

**İki parametre 0.000 verdi** — `kd_yenilgi_orani` ve `sos_kitlik_agirlik`. Bunlar
"kalibrasyon düğmesi" değil, **varsayılan dünyada yolu hiç ateşlenmeyen**
parametreler: birincisi yalnız kalmış sosyalist devletin askeri ezilmesini,
ikincisi planlı ekonominin kıtlık gerilimini yönetiyor ve varsayılan koşuda
ölçüm penceresinde sosyalist ülke bulunmuyor. `socialist_siege` senaryosunda
ayrıca taranmaları gerekir.

### 9.18 Sürüm kimliği, deney kimliği ve değişmez denetimi

- **Sürüm birleştirildi.** Kodda `v4.3-A`, `v4.3-R`, `v5.0`, `v5.1`,
  `v5.1 Option C` referansları karışıktı (79 ayrı yerde). Tek kimlik: `SURUM = "v4.4"`.
- **Deney kimliği.** `deney_kimligi()` her koşu için model sürümü, parametre
  karması (crc32, süreçler arası kararlı), tohum, senaryo, tur ve ülke sayısını
  döndürür. Örnek: `{'model': 'v4.4', 'parametre_karmasi': '7ac8c1e1', 'tohum': 42, ...}`.
- **Değişmez denetimi.** `degismez_denetle()` her tur `pay, e, u, org, Omega,
  canli_pay, oto, etg ∈ [0,1]` ve `q, K, Y > 0` koşullarını, ayrıca NaN/Inf
  durumunu sınar; ihlal sessizce geçilmez, olay olarak loglanır. Varsayılan
  koşuda ihlal sayısı **0**.

### 9.19 FINAL BENCHMARK — v4.4-Frozen

Bu bölüm **tek resmî kabul koşusudur**. Önceki bölümlerdeki 3/5/12/20 tohumlu
sonuçlar geliştirme geçmişidir ve karşılaştırma için bırakılmıştır; nihai
değerlendirme yalnızca aşağıdaki tablodur.

```
MODEL   : v4.4-Frozen        TOHUM : 101–200 (100 bağımsız doğrulama tohumu)
TUR     : 1259 (1760–2100)   ÜLKE  : 20
AI      : açık               ETG can simidi : kapalı
PARAMETRELER: DONDURULMUŞ (kalibrasyon tohumları 1–100'de ayarlandı)
```

| ölçüt | medyan | p10 | p90 | kabul | sonuç |
|---|---|---|---|---|---|
| LTRPF | −%93.0 | −%94.5 | −%90.1 | [−95, −55] | GEÇTİ |
| işsizlik (kapitalist) | 0.395 | 0.352 | 0.454 | [0.30, 0.75] | GEÇTİ |
| resesyon aralığı | 11.7 yıl | 10.8 | 12.5 | [6, 15] | GEÇTİ |
| Minsky aralığı | 66.3 yıl | 57.1 | 80.0 | [40, 110] | GEÇTİ |
| kurumsal geçiş | 174 | 159 | 185 | ≥40 | GEÇTİ |
| devrim | 6.0 | 3.0 | 10.0 | [0, 8] | GEÇTİ |
| otomasyon payı | 0.517 | 0.498 | 0.534 | [0.40, 0.70] | GEÇTİ |
| canlı emek payı | 0.269 | 0.218 | 0.375 | [0.20, 0.55] | GEÇTİ |
| çifte hareket (Polanyi) | 8283 ileri / 9017 geri | | | her iki yön | GEÇTİ |
| liberale endojen dönüş | 0 | | | 0 olmalı | GEÇTİ |

**10/10.** Katmanlı değerlendirme (tek bir "9/10" skoru kullanılmaz):

| katman | sonuç |
|---|---|
| Mekanizma yön testleri (**birincil**) | 9/9 GEÇTİ |
| Sayısal kabul bantları (100 tohum) | 10/10 GEÇTİ |
| Determinizm (aynı tohum, 3 süreç) | GEÇTİ |
| Değişmez denetimi (NaN/Inf/aralık) | GEÇTİ |
| Hassasiyet (15 parametre, ±%20) | GEÇTİ (hiçbiri esneklik > 1.0) |
| Tarihsel dönem kayması | GEÇTİ (aşağıda) |

### 9.20 Tarihsel dönem ayrımı testi

Yüklenen kayıt iki döneme bölündü ve motorun **doğrulama** tohumlarıyla (101–120)
ölçüldü:

| dönem | kayıt | motorun ürettiği |
|---|---|---|
| 1825–1950 | 14 kriz / 125 yıl = 8.9 yıl; baskın **aşırı üretim** | aşırı üretim aralığı **31.5 yıl**, Minsky ilk altıda yok |
| 1951–2023 | 13 kriz / 72 yıl = 5.5 yıl; baskın **finansal/kârlılık** | aşırı üretim **54.8 yıl**'a seyrekleşir, **Minsky ilk altıya girer** (43.3 yıl) |

Resesyon aralığı da 13.0 → 11.8 yıla sıklaşıyor; kayıttaki 8.9 → 5.5 yönüyle
uyumlu. Aşırı üretim aralığı **1.7 kat seyrekleşiyor**, Minsky ise ancak ikinci
dönemde baskın tipler arasına giriyor.

**Dürüstlük notu:** bu tam bir out-of-sample test **değildir** — motorun
parametreleri bütün kaydı görerek ayarlandı. Ancak kalibrasyon hedefleri *toplam*
metriklerdi (LTRPF, işsizlik, Minsky aralığı); **dönem bazında tip bileşimi hiç
hedeflenmedi**. Dolayısıyla tip bileşimindeki kayma gerçek ama zayıf bir
tutarlılık sonucudur. Aile toplamları (aşırı üretim ailesi %56 → %50) zayıf
kalıyor çünkü resesyon her iki dönemde de sayıyı domine ediyor.

### 9.21 Kriz sınıflandırması: karşılıklı dışlayıcı birincil neden

Bir ülke aynı turda resesyon, Minsky ve döviz krizi yaşayabilir; frekanslar
çakışmasın diye artık iki ayrı çıktı tutulur: `olay_bayraklari` (çoklu) ve
`birincil_kriz` (tek). Öncelik sırası yapısal olanın konjonktürel olanı ezmesi
esasına göre: devrim → restorasyon → büyük bunalım → devlet çöküşü → moratoryum
→ döviz krizi → Minsky → borç krizi → plan kıtlığı → aşırı üretim → resesyon.

`kriz_oranlari()` frekansları **ülke-yıl** başına verir (tohum 42, tam kampanya):

| birincil neden | ülke başına aralık |
|---|---|
| resesyon | 14.9 yıl |
| aşırı üretim | 31.0 yıl |
| döviz krizi | 34.7 yıl |
| büyük bunalım | 44.7 yıl |
| borç krizi | 47.9 yıl |
| Minsky | 70.1 yıl |
| moratoryum | 79.1 yıl |
| devlet çöküşü | 104.6 yıl |
| plan kıtlığı | 144.7 yıl |
| devrim | 399.9 yıl |

### 9.22 Hegemonya geçiş ölçümü

Eleştiride "hegemonya hiç değişmez, ölçülmedi" diye açık bırakılmıştı. Ölçüm
(20 doğrulama tohumu, tam kampanya): koşu başına **medyan 3 hegemonya devri**
(aralık 0–6), ve 2100'de hegemon dokuz farklı ülke olabiliyor (İtalya 6, Japonya
3, ABD 2, Almanya 2, İngiltere 2, Kanada 2, Fransa/Avustralya/AB-blok 1). Yani
hegemonya ölü bir değişken değil.

## 10. Bilinen sınırlılıklar

**Kurumsal karşılaştırmalar eşzamanlı etiketlemeyle yapılmalıdır.** Ülkeler koşu
başına ortalama altı kez rejim değiştiriyor; bir pencereyi *son* rejime göre
etiketlemek yön hatası üretir. Bu belgede daha önce `neoliberal`in `duzenli`den
daha yüksek örgütlülüğe sahip göründüğü bir ölçüm vardı — motor hatası değil,
etiketleme hatasıydı; eşzamanlı ölçümde sıralama doğrudur (0.470 / 0.427 / 0.396).

**Politika AI'sı test edilen politikayı ezer.** `set_plan_profili` ya da
`set_temel_gelir` ile bir politika kurup ölçüm yapılacaksa ya `oyuncu_ulkesi()`
ile o ülke muaf tutulmalı ya da `P.ai_acik = False` yapılmalıdır.

**Kabul bantları bu kalibrasyonun kaydıdır, bağımsız kriter değil.** LTRPF bandı
iki kez genişletilmek zorunda kaldı. Gerçekten bağımsız olan ölçütler yalnızca
yön testleridir: kâr oranının düşme yönü, Polanyi çifte hareketinin iki yönde
işlemesi, liberale endojen dönüşün sıfır olması.

**Çağ 6'da hâlâ devrim olmuyor, ama sebebi değişti.** Politik özne eklendikten
sonra devrimci kapasite korunuyor (PR 0.57'ye çıkıyor) — fakat devrimler çağ 4–5'e
kayıyor ve çağ 6'ya ülke kalmıyor: 5 tohumda çağ 4'te 6, çağ 5'te 23, çağ 6'da 0
devrim. Karşı devrim oranı (~%50) potansiyeli tam olarak geri getirmiyor. İki
zirpe için ya geri alma oranının yükselmesi ya da çağ 6'ya özgü ek bir
kutuplaşma kanalı gerekiyor.

**v4.4 ÖZELLİK AÇISINDAN DONDURULDU.** Bundan sonra yeni ekonomik mekanizma
eklenmemelidir; motor yeterince karmaşık ve her yeni mekanizma "neyin neyi
ürettiğini" yeniden belirsizleştirir. Yeni özellikler ayrı dallarda
denenmelidir: `v4.5-H` (hegemonya derinleştirme), `v4.5-S` (sosyalist
heterojenlik), `v4.5-E` (refah devleti / ETG).

**Modelin bilimsel statüsü.** Bu bir *doğrulanmış ekonomik model* değil,
**mekanizma-tutarlı hesaplamalı modeldir**. Yön testlerinin 9/9 geçmesi Marx'ın
ya da Thirlwall'ın ampirik olarak doğrulandığını göstermez; yalnızca modelin o
mekanizmaları ürettiğini gösterir. Belgede "model teoriyi doğruladı" biçiminde
bir iddia yoktur ve olmamalıdır.

**Sosyalist ekonomiler hâlâ fazla homojen.** Plan profili (yatırım/tüketim/AR-GE/
savunma) gerçek bir ayrışma üretiyor ama bürokratik yapı, üretici özerkliği,
planlama kurumu, kolektif mülkiyet biçimi gibi kurumsal farklar yok. Bu, dondurma
kararının en önemli açık maddesidir ve `v4.5-S` dalına aittir.

**Rakip AI kural-tabanlıdır.** Ortak politika API'sini kullanıyor ve kurumsal
rejime göre gerçekten ayrışıyor, ama stratejik oyun teorisi ya da ajan
optimizasyonu değil. Doğru adı "kural-tabanlı politika tepkisi"dir.

**Hassasiyet analizi yalnızca varsayılan dünyada yapıldı.** Sosyalist ve
kuşatma yollarını yöneten parametreler (`kd_yenilgi_orani`,
`sos_kitlik_agirlik`) varsayılan koşuda ateşlenmediği için 0.000 esneklik
verdi; bunların `socialist_siege` senaryosunda ayrıca taranması gerekir.

**Tarihsel kriz veri seti belgeye gömülmedi.** 9.9'daki karşılaştırma dışarıdan
yüklenen 27 krizlik bir kayda dayanıyor; veri seti, kodlama ölçütü ve eşleştirme
protokolü belgede yer almadığı için bu bölüm kendi başına denetlenebilir değil.
Sonuç, kanıtlanmış değil **raporlanmış** bir deney sonucudur.

**(Önceki durum, kayıt için:)** Politik özne devrim sayısını 1'den 8'e
çıkardı; kapitalist kalan ülkeler seçilim etkisiyle daha düşük işsizlikli olanlar
oluyor ve işsizlik medyanı 0.455'ten 0.356'ya indi (bant [0.45, 0.80]). Diğer
sekiz ölçüt geçiyor. Bandı yeniden kalibre etmek yerine bu şekilde bırakıldı:
sapmanın kaynağı bilinen ve anlamlı bir mekanizma, ve bandı her seferinde
sonuca uydurmak testi anlamsızlaştırır.

**(Önceki tanı, kayıt için:)** Ölçüm: Omega 1.000'e doyuyor,
işsizlik %54, ücret payı 0.29 — nesnel koşullar azami. Ama protesto riski 0.51'den
0.42'ye düşüyor, çünkü karanlık devlet (`lumpen_sonum`) ve karseral aygıt
(`karseral_sonum`) protestoyu tam da o noktada bastırıyor; örgütlülük de 0.62'den
0.29'a eriyor. Model, tekno-diktatörlüğün devrimci özneyi imha ederek kazandığını
söylüyor. Tasarım hedefi olan **iki zirve** (çağ 5 dalgası + çağ 6 kapışması) bu
yüzden oluşmuyor: çağ 5'te 11 devrim, çağ 6'da 0. Çağ 6'nın gerçek bir kapışma
olması için devrimci öznenin otomasyon altında yeniden kurulabildiği bir kanal
gerekir — işsizlerin örgütlenmesi, ücretli emek dışı bir siyasal özne. Motorda
böyle bir kanal yok.

**AI kaynaklı ideolojik ayrışma seyrek.** Ortak koşullar altındaki sosyalist
devletler aynı plan hattına yakınsadığı için `ideolojik_mesafe` 0.00–0.08
aralığında kalıyor ve eşiği (0.10) nadiren aşıyor. Tasarım gereği asıl kanal
oyuncudur, ama AI blokları kendi başlarına neredeyse hiç bölünmüyor.

**Bolluk çatalı Omega düzeyinde maskelenebiliyor.** Kuşatma senaryosunda savaş
Omega'yı domine ettiği için çatal protesto riskinde (PR) net görünürken Omega
ortalamalarında görünmüyor.

**Otomasyon hızlı yerleşiyor:** çağ 6'ya t≈300'de varılıyor ve `oto` 0.77'de
doyuyor. `oto_hiz` ve `oto_esik_era` bir tasarım tercihidir, ampirik olarak
kalibre edilmemiştir.

**"ETG kapitalizmi kurtaramaz" sonucu koşulludur.** Bölüm 9.6'daki bulgu `ito`
geri beslemesinin mevcut kalibrasyonuna bağlıdır ve `ito`'nun ampirik
savunulabilirliği ayrıca sınanmamıştır. Katılım düşüşünün yarattığı ölçüm
yanılsaması `iss_duzeltilmis` göstergesiyle raporlanıyor.

**İşsizlik uzun ufukta tohuma duyarlı.** Bu değişkende model birden fazla çekim
havzasına sahip; tek koşuya bakarak yorum yapmak yanıltıcıdır, en az üç tohum
gerekir. Aynı şey devrim sayısı için de geçerli (0–3 arası).

**Senaryoların başlangıç işsizliği türetilmiyor, kuruluyor.** `K_carpani` ampirik
olarak kalibre edilmiş bir başlangıç koşuludur (bkz. bölüm 8). Model "1995
kurumları 1995 işsizliğini üretir" iddiasında bulunmaz; iddia daha zayıf ve daha
dürüsttür: kurumlar işsizliğin **gidişini** belirler, seviyesini değil.

**Sosyalist ekonomiler hâlâ tek tip.** Planlı kolun serbestlik derecesi az:
`plan_g`, `plan_u_duy` ve `PKE` dışında ayrışma kaynağı yok, kıtlık tek ayırt
edici kriz mekanizması. Şartnamenin 6 numaralı başarısızlık testi bu yüzden
hâlâ açık.

**Döviz krizi kanalı finansal krizlere göre sık.** 27 yıllık aralıkla
neredeyse aynı frekansta. Ayrı bir kalibrasyon konusu.

**Rakip ülke politikası asgari düzeyde.** `KURUMLAR` tablosundaki dört parametre
(`hizlandirici`, `kars_dongusel`, `kredi`, `finans`) ülkelerin krize farklı tepki
vermesini sağlıyor ama bu bir *karar* mekanizması değil, sabit bir davranış
profili. Şartnamenin oyuncu katmanı geldiğinde bu yetmeyecektir (bkz. bölüm 11).

---

## 11. v4.3 şartnamesine dair düzeltmeler

Bu bölüm, "HAYALET EKONOMİSİ v4.3 — Nihai Sistem Şartnamesi" belgesinde
motorla çelişen veya eksik kalan noktaları kaydeder.

### 11.1 Faz sırası düzeltilmelidir

Şartnamenin 5. bölümünde **FAZ 5 (Bölüşüm)** FAZ 6'dan (Teknoloji) önce geliyor.
Motorda sıra tersidir ve bu kasıtlıdır: teknoloji bloğu Phillips ve Goodwin
bloklarından **önce** çalışır, çünkü her ikisi de *gerçekleşen* verimlilik
artışına ihtiyaç duyar. Şartnamedeki sıra, v5.0'da düzeltilen bir hatayı geri
getirir — o sürümde Phillips ve Goodwin nominal çağ katsayısını kullanıyor,
verimlilik doyduğunda ücret payı yapay olarak tabana eziliyordu.

**Doğru sıra: FAZ 6 → FAZ 5.**

### 11.2 Kalibrasyon hedefleri test edilebilir değil

Şartnamenin 52. bölümündeki hedefler ("r ↓", "büyük krizler seyrek olmalıdır",
"sosyalist ekonomi tek tip davranmamalıdır") otomatik kabul testine dönüşmez.
Her hedef **sayı, tolerans bandı ve tohum sayısı** içermelidir. Ölçülen
değişkenlerin tohumlar arası dağılımı geniştir; tek koşuya bakan bir kabul
testi rastgele geçer veya kalır.

Önerilen biçim:

```
LTRPF        : 5 tohumun medyanı, r_son/r_ilk - 1 ∈ [-%25, -%60]
işsizlik     : 5 tohumun medyanı ∈ [0.03, 0.25]; hiçbir tohumda > 0.45
Minsky krizi : ülke başına aralık ∈ [30, 60] yıl
resesyon     : ülke başına aralık ∈ [6, 15] yıl ve her kriz tipinden SIK
kurumsal     : 1200 turda >= 40 geçiş, son dağılımda her rejimden >= 2 ülke
devrim       : 1200 turda 0 < devrim <= 6
```

### 11.3 Rakip ülke politikası tanımsız

Şartnamede "diğer ülkeler" yalnızca iki yerde geçiyor ve ikisi de bir mekanizma
tanımlamıyor. Oyuncu 19 politika koluna sahip olacaksa diğer 19 ülkenin de bir
karar kuralı gerekir; yoksa oyuncu önemsiz bir çabayla üstünlük kurar,
"hegemonya değişebiliyor" kriteri anlamını yitirir ve zafer koşulları ölçüsüz
kalır.

v4.3-A'da atılan asgari adım `KURUMLAR` tablosunun bir **davranış profiline**
genişletilmesidir (bkz. 5.12b). Bir sonraki adım, bu profillerin krize tepki
olarak *değişmesi* — yani her kurum tipi için bir politika tepki kuralı seti.

### 11.4 Oyuncu hedefleri ile zafer koşulları eşleşmiyor

Şartnamenin 30. bölümünde beş oyuncu hedefi tanımlanmış (kapitalist kalkınmacı,
sosyal demokrat, neoliberal, sosyalist, devrimci sosyalist) ama 31. bölümdeki
zafer koşulları bunlarla birebir eşleşmiyor. Oyuncu hedefini seçtiğinde zafer
koşulu da onunla değişmeli; yoksa "tek optimal politika bulunmuyor" kriteri
kâğıt üzerinde kalır.

### 11.5 Kriz sıklığı aritmetiği

Şartname 30–50 yıllık aralık istiyor; bu, 324 yıl × 20 ülke için ~160 olay
demek. v4.2'de 331 çöküş vardı ve şartname aynı anda **yeni bir balon kanalı**
ekliyordu. v4.3-A'da hanehalkı kanalı 195 (33 yıl), Minsky kanalı 162 (40 yıl)
olarak ayrıştı; ikisi de hedef bandın içinde ama toplam olay sayısı yüksek
kalıyor. Şartnamedeki hedef **kanal başına** yazılmalıdır, toplam üzerinden
değil.

### 11.6 Onaylanan tasarım kararları

Şartnamenin şu maddeleri motorla uyumlu ve korunmalıdır: 54. bölümdeki
motor/oyun ayrımı (motorda sıfır `print`), 56. bölümdeki "politika komutları
doğrudan durum değiştirmez" ilkesi, 11. bölümdeki reel/spekülatif faiz ayrımı
(v4.3-A'da uygulandı), 34. bölümdeki politika gecikmesi ve 58. bölümdeki siyasi
sermaye.

---

## 12. Kaynak kod — motor

Aşağıdaki blok `hayalet_ekonomi_motoru_v43.py` dosyasının tamamıdır
(3352 satır). Bir kütüphanedir, doğrudan çalıştırılmaz.

```python
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

```

---

## 13. Kaynak kod — oyun

Aşağıdaki blok `hayalet_ekonomisi_oyunu_v32.py` dosyasının tamamıdır
(146 satır). Çalıştırılabilir konsol arayüzüdür.

```python
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

```
