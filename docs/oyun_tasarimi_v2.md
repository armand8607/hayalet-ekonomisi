# Hayalet Ekonomisi v2 — Victoria biçiminde büyük strateji

**Durum: TASLAK — karar kaydı, kod değil.**

Hedef: **Victoria 3'e benzeyen ama ekonomi motoru bambaşka olan** bir büyük
strateji oyunu. Victoria 3'ün kendisine dokunulmuyor, kodu değiştirilmiyor;
biçimi örnek alınıyor. Altına konan şey arz/talep dengesi değil,
**Marksist kriz teorisi**.

| belge | neyi anlatır |
|---|---|
| [hayalet_ekonomisi_v44_frozen.md](hayalet_ekonomisi_v44_frozen.md) | v4.4 motoru — **artık otorite değil**, denklem kaynağı |
| **bu belge** | v2 oyunu — mimari, kuplaj, ekranlar, aşamalar |

---

## 0. Çekirdek döngü: krizler yazılmaz, dayatılır

Bu belgenin geri kalanı bu tek cümlenin sonuçlarıdır:

> **Oyuncu, dünya ve ülke ekonomisinin altında yatan kriz teorisinin dayattığı
> krizlere göre yol alır.**

Yani krizler **elle yazılmış olay zincirleri değildir.** Hiçbir yerde "1873'te
bir bunalım tetikle" satırı olmayacak. Bunalım, aşırı üretim, balon patlaması,
döviz krizi, devrim — hepsi **denklemlerin sonucu** olarak ortaya çıkar:
üretkenlik yükselir, organik bileşim yükselir, kâr oranı düşer, birikim
yavaşlar, gerçekleşme makası açılır, borç şişer, balon patlar.

Sonuçları tasarımı boydan boya bağlar:

- **Olay sistemi yoktur, kriz tescili vardır.** Günceye düşen her satır bir
  ölçümün eşiği geçmesidir (`R` bloğu: resesyon / bunalım tescili), bir olay
  tablosundan çekiliş değil.
- **Zorluk ayarı yoktur.** Oyunun zorluğu seçtiğin ülkenin dünya sistemindeki
  konumudur — çevre ülke olmak zaten zordur, çünkü değer transferi (`C`, `L`)
  onu sürekli boşaltır.
- **Rastgelelik ikincildir.** Tohum krizlerin *zamanlamasını* ve
  *ayrıntısını* değiştirir, *kaçınılmazlığını* değil. Kâr oranı her koşuda
  düşer; ne zaman ve neye mal olarak düşeceği oyuncunun kararlarına bağlıdır.
- **Oyuncunun işi krizi önlemek değil, karşılamaktır.** Kolları (§2.3 geri
  besleme sütunu) krizin *biçimini* ve *bedelinin kime yükleneceğini*
  değiştirir. Kimin ödeyeceği — ücret mi kâr mı — oyunun asıl kararıdır.

**Tek oyunculu.** Victoria 3'ün çok oyunculu kipi örnek alınmaz. Sebep
mekaniktir, teknik değil: bu oyunun konusu bir ülkenin dünya sistemindeki
konumuyla ve kendi birikim çelişkisiyle hesaplaşmasıdır; ikinci bir insan
oyuncu o hesaplaşmayı bir müzakereye çevirir.

---

## 1. v4.4 ile ilişki: yalnızca denklemler

v4.4-Frozen bundan sonra **bir kütüphanedir, bir çerçeve değil.** Ondan
alınacak tek şey **kriz teorisi denklemleridir.** Başka hiçbir kısıtı
bağlayıcı değildir.

### 1.1 Taşınan — kriz çekirdeği

`step()` içindeki A–T blokları ve dört adlandırılmış mekanizma. Bunlar oyunun
iktisadi tezidir:

| blok | mekanizma |
|---|---|
| **c/v** | Organik bileşim, `q`'nun sürekli fonksiyonu — **tavanı yok**, LTRPF'nin yakıtı |
| **G** | Arz kapasitesi + **otomasyon**; canlı emeğin fiziksel hasıladaki payı |
| **H** | Efektif talep & borçlanma sınırı (Clarke & Fisher) — **aşırı üretim / gerçekleşme krizi** |
| **J** | Spekülatif varlık balonu — finansallaşma + **Minsky** |
| **K** | Fisher & Clarke borç/balon patlaması (Tip B) |
| **P** | Phillips eğrisi & enflasyon |
| **Q** | **Goodwin** sınıfsal nominal ücret pazarlığı |
| **R** | İki kademeli kriz tescili (resesyon / bunalım) |
| **A** | Merkez bankası: Taylor kuralı + balon/kriz duyarlılığı |
| **B** | Dış ticaret & **Thirlwall** ödemeler dengesi kısıtı |
| **C** | Cari açık sızıntısı & uluslararası **değer transferi** |
| **D** | Ani duruş & dış borçlanma tıkacı |
| **E** | Borç yapılandırma & moratoryum |
| **F** | Rezerv erimesi & döviz krizi (Tip C) |
| **L** | Bölgeler arası değer transferi — **eşitsiz mübadele** |
| **I / M** | Kamu maliyesi, vergi, kemer sıkma; kamu sermayesi & birikim |
| **N** | Haftalık çalışma süresi |
| **S** | Sınıf örgütlenme stoku & kentleşme (lojistik stok) |
| **T** | Lojistik protesto riski & **sosyalist devrim** |
| — | **Tonak değer gaspı** — gasbedilen değer üretken sermayeye değil spekülatif stoka akar |
| — | Evrensel temel gelir ve finansmanı |
| — | Karanlık devlet (illegalite primi, cezaevi oranı) |
| — | Marksist politik özne (parti, örgütlü güç) |

Ayrıca saf yardımcılar: `organik_bilesim(q)`, `sg(x)`, `kappa_v(cv,q)`,
`ucuzlama_orani(q)`.

### 1.2 Taşınmayan — hepsi serbest

| v4.4'te | v2'de |
|---|---|
| 20 ülke | **serbest** — hedef tam dünya (§3.6) |
| 1259 tur, 1 tur = 0.27 yıl | **serbest** — haftalık tik (§3.2) |
| 1760–2100 | **serbest** — 1836–1936 (§3.3) |
| 355 sabitlik kalibrasyon | **geçersiz** — yeni mimaride yeniden ayarlanacak |
| 10 kabul bandı | **geçersiz** — eski kalibrasyonun kaydıydı |
| Senaryo odaları | yeniden tanımlanacak |
| Sıfır asset kuralı | **gevşetiliyor** (§3.1) |
| CPython parite zorunluluğu (`py_sum`, `py_round`) | **düşüyor** — kâhin yok, bit-parite hedefi yok |

> **`py_sum` / `py_round` neden düşüyor:** ikisi de yalnızca CPython kâhiniyle
> bit-birebir tutmak için vardı. Kâhin ortadan kalkınca amaçları da kalkar.
> Kaldırmak serbesttir; ama **kaldırılırsa CLAUDE.md'deki iki tuzak notu da
> güncellenmeli**, yoksa gelecekteki bir oturum var olmayan bir kuralı arar.

---

## 2. Mimari: iki katman, tanımlı kuplaj

Asıl tasarım sorusu şu: kriz denklemleri **toplam büyüklükler** üzerine
yazılmıştır (`r`, `q`, `c/v`, `pay`, `u`, `V`), Victoria ise **mekânsal ve
mikro**dur (eyalet, pop, bina, mal). İkisi nasıl bağlanır?

Cevap: **birbirinin yerine geçmezler, üst üste binerler.**

```
  MIKRO KATMAN  (Victoria bicimi)
  eyalet -> bina -> pop -> mal piyasasi
        |                        ^
        | toplamlar              | geri besleme
        v                        |
  DEGER KATMANI  (kriz cekirdegi)
  V, c/v, r, kriz durumlari
```

### 2.1 Mikro katman — ne üretir

Her haftalık tikte, ülke başına **gözlenen toplamlar**:

| toplam | mikro kaynağı |
|---|---|
| `K` sermaye stoku | binaların birikmiş inşaat maliyeti |
| `L`, `e` | pop'ların istihdam durumu |
| `pay` ücret payı | ücret ödemeleri ÷ toplam hasıla |
| `Y` fiziksel hasıla | binaların mal çıktısı toplamı |
| `u` kapasite kullanımı | doluluk / azami kapasite |
| `q` üretkenlik | aktif üretim yöntemlerinin ağırlıklı seviyesi |
| `oto` otomasyon payı | makine-ağırlıklı üretim yöntemlerinin payı |

### 2.2 Değer katmanı — ne hesaplar

Bu toplamları alır, **değer büyüklüklerini** üretir:

- `c/v = organik_bilesim(q)` — üretkenlik yükseldikçe yükselir, **tavansız**
- `V` yeni değer — **yalnızca canlı emekten**; `oto` yükseldikçe `Y` büyür ama
  `V` küçülür
- `r` kâr oranı — birikimin hızını yöneten büyüklük
- Kriz durumları: aşırı üretim açığı, Minsky sayacı, borç patlaması, döviz
  krizi, resesyon/bunalım tescili

### 2.3 Kuplaj — bu belgenin kalbi

Her kriz mekanizmasının hangi Victoria altsistemini **okuduğu** ve hangisini
**geri beslediği**:

| kriz mekanizması | okur | geri besler |
|---|---|---|
| **LTRPF** (`c/v`, `r`) | üretim yöntemi seviyesi → `q` | birikim hızı: `r` düşünce inşaat yavaşlar |
| **Otomasyon → değer** | makine-ağırlıklı üretim yöntemleri | `V` küçülür → satınalma gücü düşer |
| **Aşırı üretim (H)** | mal arzı vs pop satınalma gücü | satılamayan mal → bina kapanır, işten çıkarma |
| **Minsky (J, K)** | yatırım havuzu, finans binaları | balon patlar → kredi kurur, delev başlar |
| **Goodwin (Q)** | istihdam oranı, sendika gücü | ücret pazarlığı → `pay` ↔ `r` salınımı |
| **Thirlwall (B)** | ticaret rotaları, pazar erişimi | ithalat tıkanır → büyüme tavanı |
| **Değer transferi (C, L)** | ticaret ortakları, üretkenlik farkı | çevreden merkeze **eşitsiz mübadele** |
| **Döviz krizi (F)** | rezerv, cari açık | devalüasyon → ithalat çöker |
| **Örgütlenme (S)** | kentleşme, fabrika pop yoğunluğu | sendika gücü, siyasi kanun baskısı |
| **Devrim (T)** | öfke, örgütlenme, protesto riski | **rejim değişir**, oyuncunun kolları değişir |
| **Kurumsal geçiş** | yürürlükteki kanunlar | Polanyi çifte hareketi: liberal ↔ düzenli ↔ neoliberal |

### 2.4 Tersine çevrilen mantık

Victoria 3'te kârlılık **bina başına piyasa sonucudur**: bina ucuz girdi alır,
pahalı çıktı satar, kâr eder. v2'de bu katman **durur**, ama üstüne şu gelir:

> **Toplam kâr oranı `r` piyasadan okunmaz; değer katmanında hesaplanır ve
> bütün birikim sürecini kısıtlar.**

Yani tek tek binalar kârlı görünürken toplam kâr oranı düşebilir — ve düşer.
Oyunun anlattığı şey tam olarak budur ve Victoria 3'ün kendi mantığının
Marksist tersine çevrilmesidir.

**Üretim yöntemi yükseltmesi buradaki en güzel bağlantıdır:** Victoria'nın
kendi teknoloji döngüsü (daha iyi üretim yöntemi = daha yüksek `q`) doğrudan
`c/v`'yi yükseltir, o da `r`'yi düşürür. Oyuncu her "iyileştirme"yle kendi kâr
oranını aşındırır. Mekanizma zaten oradaydı; v2 sadece sonucunu görünür kılar.

---

## 3. Uygulanan kararlar

Önceki taslakta açık bırakılan sorular, **Victoria 3'e en yakın** seçenekle
kapatıldı.

### 3.1 Harita: gerçek coğrafi, eyalet bazlı

Victoria 3 gerçek dünya haritasını eyaletlere böler. **Aynısı yapılacak.**

Sonucu: **sıfır asset kuralı gevşetiliyor.** Ama tamamen değil —
uzlaşma şu:

- **`.png` yok** — hâlâ hiçbir bitmap yok, her şey `_draw()` ile çizilir
- **Vektör geometri verisi var** — eyalet sınırları sıkıştırılmış poligon
  tablosu olarak depoda durur (üretilmiş veri dosyası, `tables.gd` gibi)

Böylece "her görsel koddur" ilkesi korunur, coğrafya kazanılır.

### 3.2 Zaman: haftalık tik

Victoria 3 günlük tikler, ekonomiyi haftalık günceller. v2:
**haftalık ekonomik tik**, duraklat + hız kademeleri.

> **DİKKAT — oran parametreleri yeniden ölçeklenmeli.** v4.4'ün bütün oran ve
> akım parametreleri **tur başına** tanımlıydı ve 1 tur = 0.27 yıldı. Hafta =
> 0.0192 yıl, yani **14 kat kısa**. Denklemler kopyalanırken her oran
> parametresi yeniden ölçeklenmezse motor 14 kat hızlı koşar. Bu, taşımanın
> en olası sessiz hatasıdır.

### 3.3 Zaman aralığı: 1836–1936

Victoria 3'ün aralığı, birebir. ~5200 haftalık tik.

v4.4'ün 1760–2100'ü düşüyor. Bunun bir bedeli var: **çağ 5–6 (İnsan-YZ, tam
otomasyon) 1936'da yaşanmaz.** Otomasyon mekanizması korunur ama tarihsel
olarak erken sanayi otomasyonuna denk gelir. Geç kapitalizm senaryosu istenirse
ayrı bir kampanya olarak açılır (§5).

### 3.4 Ülke değiştirme: yok

Victoria 3'te başta bir ülke seçilir ve sonuna kadar o oynanır. **Aynısı.**
Devrim ülkeyi değiştirmez; **elindeki kolları** değiştirir — bu zaten v4.4'ün
ve mevcut oyunun çerçevesiydi, korunur.

### 3.5 Ana ekran: harita

Victoria 3'te harita ana ekrandır, paneller üstüne açılır. **Aynısı.**
12 çekirdek metrik grafiği harita üstünde açılan bir panele taşınır — silinmez,
oyunun öğretici omurgası odur.

### 3.6 Ülke sayısı: tam dünya

v4.4'ün 20 ülkesi bir kısıt değildi, kalibrasyon kolaylığıydı. Hedef Victoria
ölçeğidir: **tam dünya, ~100+ ülke**, dinamik kurulma/ilhak.

Aşamalı gerçekleşir (§4): önce eyalet-ülke veri modeli, sonra harita, sonra
ülke sayısı ölçeklenir. Kriz denklemleri ülke sayısından bağımsızdır —
`L` (bölgeler arası değer transferi) ve `C` (uluslararası transfer) dışında
hepsi ülke-içidir; o ikisi de ülke sayısına göre genelleşir.

### 3.7 Tek oyunculu

Victoria 3'ün çok oyunculu kipi **örnek alınmaz** (§0). Bu, V3'e benzerlik
hedefinden bilinçli bir sapmadır ve gerekçesi mekaniktir: oyunun konusu bir
ülkenin dünya sistemindeki konumuyla hesaplaşmasıdır, ikinci bir insan oyuncu
onu müzakereye çevirir.

Pratik sonucu: **ağ katmanı, belirlenimci lockstep, oturum yönetimi yok.**
Mimaride bunlara yer ayrılmaz — sonradan eklenmesi gerekirse yeniden
tasarlanır.

---

## 4. Aşamalar

Bu bir yeniden inşadır; v4.4'ün oyun katmanı üstüne eklenmez, yanına kurulur.

| aşama | iş |
|---|---|
| **B0** | **Kriz çekirdeğinin ayıklanması.** A–T blokları v4.4'ten çıkarılır, ülke-içi saf bir modül haline getirilir, oran parametreleri haftalığa ölçeklenir |
| **B1** | **Mikro katman iskeleti.** Eyalet, pop, bina, üretim yöntemi, mal piyasası — tek ülkede, haritasız |
| **B2** | **Kuplaj.** §2.3 tablosunun bağlanması; mikro toplamlar → değer katmanı → geri besleme |
| **B3** | **Yön testleri yeşile.** §5'teki dokuz iddia yeni motorda geçmeli |
| **B4** | **Harita.** Eyalet geometrisi, harita modları, ülke seçimi |
| **B5** | **Ölçek.** Ülke sayısı tam dünyaya çıkarılır, başarım ölçülür |
| **B6** | **Arayüz.** Victoria düzeni: harita ana ekran, paneller üstünde, günce, diplomasi |

**B0 ve B3 en kritik ikilidir.** B0 yanlış yapılırsa (özellikle §3.2'deki
ölçekleme) motor sessizce yanlış koşar; B3 onu yakalayan tek şeydir.

---

## 5. Doğrulama: ne taşınır, ne taşınmaz

v4.4'ün doğrulama merdiveni yeni mimaride büyük ölçüde geçersizdir — ama
**tamamı değil**, ve hangi parçanın kaldığı bu projenin en değerli kavrayışıdır.

| katman | v2'de |
|---|---|
| RNG akış paritesi | **düşer** — kâhin yok |
| crc32, parametre dökümü | **düşer** |
| Tur-tur iz karşılaştırması | **düşer** |
| 10 kabul bandı | **düşer** — eski kalibrasyonun kaydıydı, bağımsız ölçüt değildi |
| **9 mekanizma yön testi** | **TAŞINIR — tek ve birincil ölçüt** |

Sebep belgenin kendi epistemolojisinde yazılı (§9.14):

> "kabul bantları kalibrasyonun kaydıdır, bağımsız kriter değil; bağımsız olan
> yön testleridir"

Yön testleri **büyüklük değil yön** iddia eder — `q↑` ise `c/v↑` ve `r↓`;
otomasyon artarsa canlı emek payı düşer; finansallaşma kapalıysa daha az
Minsky. Bu iddialar **kalibrasyondan bağımsızdır**, dolayısıyla **yeni bir
motorda da sınanabilirler.**

Dokuz iddia, v2'nin kabul ölçütü olarak aynen geçerli:

| test | iddia |
|---|---|
| LTRPF | `q↑` → `c/v↑` → `r↓` |
| Otomasyon | `oto↑` → `canli_pay↓` → `r↓` |
| Goodwin | `e ↔ pay` pozitif, `pay ↔ r` negatif |
| Thirlwall | yüksek `q` → yüksek `eps/pi_m` |
| Minsky | finansallaşma kapalı → daha az Minsky |
| Kriz devalüasyonu | devalüasyon kapalı → `r` daha çok düşer |
| Sosyalist bolluk/kıtlık | bolluk → düşük protesto riski |
| Karanlık devlet | tolerans kapalı → daha az uyuşturucu |
| Politik özne | parti açık → daha yüksek örgütlü güç |

> **Kural:** B3 bitmeden B4'e geçilmez. Dokuz testi geçmeyen bir motor
> Victoria biçiminde bir kabuğa sarıldığında **güzel görünen ama iktisadi
> olarak anlamsız** bir oyun olur — ve bu, oynayarak fark edilmez.

---

## 6. Riskler

**6.1 Ölçekleme sessizliği.** §3.2. Tur→hafta dönüşümü her oran parametresini
etkiler; tek tek gözden geçirilmeli, toplu çarpanla geçiştirilmemeli (bazıları
stok, bazıları akım).

**6.2 Mikro-makro tutarsızlığı.** Mikro katman `pay` ve `e` üretirken değer
katmanı bunları kullanıyor; ama Goodwin bloğu `pay`'i **geri** yazıyor. Kimin
otorite olduğu her alan için tek tek kararlaştırılmalı, yoksa iki katman
birbirini ezer.

**6.3 Başarım.** 5200 tik × ~100 ülke = 520 000 ülke-tik; v4.4'ün 1259 tur ×
20 ülkesi 25 180'di, yani **~21 kat** ağır — üstelik bu yalnızca değer katmanı,
mikro katman (pop, bina, mal piyasası) bunun üstüne biniyor. B5'te ölçülmeli;
gerekirse mikro katman aylık, değer katmanı haftalık koşar.

**6.4 Kapsam.** Victoria 3 yüzlerce insan-yılıdır. B0–B3 iktisadi çekirdeği
kurar ve tek başına anlamlı bir oyundur; B4–B6 kabuktur ve kademeli
büyütülebilir.
