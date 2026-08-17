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

Krizler **elle yazılmış olay zincirleri değildir.** Hiçbir yerde "1873'te bir
bunalım tetikle" satırı olmayacak. Bunalım, aşırı üretim, balon patlaması,
döviz krizi, savaş, devrim — hepsi **denklemlerin sonucu** olarak ortaya çıkar.

- **Olay sistemi yoktur, kriz tescili vardır.** Günceye düşen her satır bir
  ölçümün eşiği geçmesidir (`R` bloğu), bir olay tablosundan çekiliş değil.
- **Zorluk ayarı yoktur.** Zorluk, seçtiğin ülkenin dünya sistemindeki
  konumudur — çevre olmak zaten zordur, çünkü değer transferi (`C`, `L`) onu
  sürekli boşaltır.
- **Rastgelelik ikincildir.** Tohum krizlerin *zamanlamasını* değiştirir,
  *kaçınılmazlığını* değil.
- **Oyuncunun işi krizi önlemek değil, karşılamaktır.** Kolları krizin
  *biçimini* ve *bedelinin kime yükleneceğini* değiştirir. **Kimin ödeyeceği
  oyunun asıl kararıdır.**

**Tek oyunculu.** Victoria 3'ün çok oyunculu kipi örnek alınmaz. Sebep
mekaniktir: oyunun konusu bir ülkenin dünya sistemindeki konumuyla ve kendi
birikim çelişkisiyle hesaplaşmasıdır; ikinci bir insan oyuncu onu bir
müzakereye çevirir.

---

## 1. v4.4 ile ilişki: yalnızca denklemler

v4.4-Frozen bundan sonra **bir kütüphanedir, bir çerçeve değil.**

### 1.1 Taşınan — kriz çekirdeği

| blok | mekanizma |
|---|---|
| **c/v** | Organik bileşim, `q`'nun sürekli fonksiyonu — **tavanı yok**, LTRPF'nin yakıtı |
| **G** | Arz kapasitesi + **otomasyon**; canlı emeğin fiziksel hasıladaki payı |
| **H** | Efektif talep & borçlanma sınırı — **aşırı üretim / gerçekleşme krizi** |
| **J** | Spekülatif varlık balonu — finansallaşma + **Minsky** |
| **K** | Fisher & Clarke borç/balon patlaması |
| **P** | Phillips eğrisi & enflasyon |
| **Q** | **Goodwin** sınıfsal nominal ücret pazarlığı |
| **R** | İki kademeli kriz tescili (resesyon / bunalım) |
| **A** | Merkez bankası: Taylor kuralı + balon/kriz duyarlılığı |
| **B** | Dış ticaret & **Thirlwall** ödemeler dengesi kısıtı |
| **C** | Cari açık sızıntısı & uluslararası **değer transferi** |
| **D** | Ani duruş & dış borçlanma tıkacı |
| **E** | Borç yapılandırma & moratoryum |
| **F** | Rezerv erimesi & döviz krizi |
| **L** | Bölgeler arası değer transferi — **eşitsiz mübadele** |
| **I / M** | Kamu maliyesi, vergi, kemer sıkma; kamu sermayesi & birikim |
| **N** | Haftalık çalışma süresi |
| **S** | Sınıf örgütlenme stoku & kentleşme |
| **T** | Lojistik protesto riski & **sosyalist devrim** |
| — | **Tonak değer gaspı**, evrensel temel gelir, karanlık devlet, Marksist politik özne |

Saf yardımcılar: `organik_bilesim(q)`, `sg(x)`, `kappa_v(cv,q)`,
`ucuzlama_orani(q)`.

### 1.2 Taşınmayan — hepsi serbest

| v4.4'te | v2'de |
|---|---|
| 20 ülke | **serbest** — hedef tam dünya |
| 1259 tur, 1 tur = 0.27 yıl | **serbest** — haftalık tik |
| 1760–2100 | **serbest** — 1836–1936 |
| 355 sabitlik kalibrasyon | **geçersiz** |
| 10 kabul bandı | **geçersiz** — eski kalibrasyonun kaydıydı |
| Sıfır asset kuralı | **gevşetiliyor** (§5.1) |
| CPython parite zorunluluğu | **düşüyor** — kâhin yok |

> **`py_sum` / `py_round` neden düşüyor:** ikisi de yalnızca CPython kâhiniyle
> bit-birebir tutmak için vardı. Kaldırılırsa **CLAUDE.md'deki iki tuzak notu
> da güncellenmeli.**

---

## 2. Mimari: iki katman, tanımlı kuplaj

```
  MIKRO KATMAN  (Victoria bicimi)
  eyalet -> bina -> pop -> mal piyasasi
        |                        ^
        | toplamlar              | geri besleme
        v                        |
  DEGER KATMANI  (kriz cekirdegi)
  V, c/v, r, kriz durumlari
```

### 2.1 Mikro katman ne üretir

| toplam | mikro kaynağı |
|---|---|
| `K` | binaların birikmiş inşaat maliyeti |
| `L`, `e` | pop'ların istihdam durumu |
| `pay` | ücret ödemeleri ÷ toplam hasıla |
| `Y` | binaların mal çıktısı toplamı |
| `u` | doluluk / azami kapasite |
| `q` | aktif üretim yöntemlerinin ağırlıklı seviyesi |
| `oto` | makine-ağırlıklı üretim yöntemlerinin payı |

### 2.2 Değer katmanı ne hesaplar

`c/v = organik_bilesim(q)` (tavansız) · `V` yeni değer (yalnızca canlı
emekten) · `r` kâr oranı · kriz durumları.

### 2.3 Kuplaj

| kriz mekanizması | okur | geri besler |
|---|---|---|
| **LTRPF** | üretim yöntemi seviyesi → `q` | birikim hızı: `r` düşünce inşaat yavaşlar |
| Otomasyon → değer | makine-ağırlıklı üretim yöntemleri | `V` küçülür → satınalma gücü düşer |
| Aşırı üretim (H) | mal arzı vs pop satınalma gücü | bina kapanır, işten çıkarma |
| Minsky (J, K) | yatırım havuzu, finans binaları | balon patlar → kredi kurur |
| Goodwin (Q) | istihdam oranı, **sendika gücü** | ücret pazarlığı → `pay` ↔ `r` salınımı |
| Thirlwall (B) | ticaret rotaları, pazar erişimi | ithalat tıkanır → büyüme tavanı |
| Değer transferi (C, L) | ticaret ortakları, üretkenlik farkı | **eşitsiz mübadele** |
| Döviz krizi (F) | rezerv, cari açık | devalüasyon → ithalat çöker |
| Örgütlenme (S) | kentleşme, fabrika pop yoğunluğu | sendika gücü, kanun baskısı |
| Devrim (T) | öfke, örgütlenme, protesto riski | **rejim değişir**, kollar değişir |
| Kurumsal geçiş | yürürlükteki kanunlar | Polanyi: liberal ↔ düzenli ↔ neoliberal |

### 2.4 Tersine çevrilen mantık

Victoria 3'te kârlılık bina başına piyasa sonucudur. v2'de o katman durur, ama:

> **Toplam kâr oranı `r` piyasadan okunmaz; değer katmanında hesaplanır ve
> bütün birikim sürecini kısıtlar.**

Tek tek binalar kârlı görünürken toplam kâr oranı düşer. **Üretim yöntemi
yükseltmesi en güzel bağlantıdır:** Victoria'nın kendi teknoloji döngüsü `q`'yu
yükseltir, o `c/v`'yi yükseltir, o `r`'yi düşürür. Oyuncu her "iyileştirme"yle
kendi kâr oranını aşındırır.

---

## 3. Krizden çıkış: savaş, ittifak, diplomasi

**Evet — ve bunlar eklenti değil, teorinin gereğidir.** Kâr oranı sıkıştıkça
sermaye ulusal sınırların dışına taşar; pazar arayışı, sermaye ihracı ve çevre
üzerindeki rekabet aynı sıkışmanın yüzleridir. Emperyalizm ve savaş bu oyunda
ayrı bir strateji katmanı değil, **iktisadi krizin dış politikadaki
görünümüdür.**

### 3.1 Hangi kriz hangi dış çıkışa iter

| kriz | dış çıkış | motor karşılığı |
|---|---|---|
| Aşırı üretim | Yeni pazar açmak — gerekirse zorla | pazar erişimi, `B` bloğu |
| Düşen kâr oranı | Sermaye ihracı: `c/v`'nin düşük, `r`'nin yüksek olduğu çevreye | `C`, `L` değer transferi |
| Değer transferi sürsün | Eşitsiz mübadeleyi dayatmak | tarife, abluka, himaye |
| Borç ödenemiyor | Moratoryum — ama alacaklı devlet müdahale edebilir | `E` bloğu + `ilan()` |
| Rakip aynı çevreyi istiyor | **Emperyalistler arası savaş** | `savas_karari()`, `guc()` |
| İçeride öfke patlama noktasında | **Dış savaşla basınç boşaltma** | §4 ile bağlantılı |
| Bir yerde devrim oldu | Kuşatma, abluka, müdahale | `abluka`, `ambargo`, `dunya_devrimi_isle()` |

### 3.2 Savaş bir kriz çıkışıdır — en şiddetlisi

Motorda `savas_yikim_isle()` sermayeyi yok eder. Marksist okumada bunun
sonucu tektir ve acımasızdır:

> **Savaş sermayeyi imha eder, sermayenin imhası kâr oranını yükseltir.**

Yani savaş, "bırak yansın" çıkışının ulusal ölçekli ve silahlı biçimidir.
Oyun bunu bir zafer olarak değil, **bir muhasebe olarak** gösterir: kâr oranı
grafiği savaştan sonra yukarı döner, nüfus grafiği aşağı.

### 3.3 İttifak ve bloklar

Motorda hazır: `muttefik`, `ideolojik_mesafe`, `saldirganlik`, `hegemon`,
`abluka`, `ambargo`, `pakt_durusu`.

- **Merkez içi rekabet** — aynı çevre için yarışan merkez ülkeler
- **Sosyalist pakt** — `pakt_durusu` ile ittifak mı rekabet mi
- **Kuşatma** — devrim olan ülkeye abluka ve ambargo
- **Himaye** — çevre ülkeyi bir merkeze bağlamak: koruma karşılığı değer transferi

### 3.4 Kapsam dürüstlüğü

**Taktik savaş yoktur.** Cephe yönetimi, birlik hareketi, muharebe çözümü
olmayacak. Savaş bir **iktisadi olaydır**: sonucu `guc()` (= `K·q`), yıpranma,
abluka ve iç cephe (öfke, örgütlenme) belirler. Paradox'un askeri derinliği
hedeflenmiyor; hedeflenen, savaşın ekonomiden **çıkması** ve ekonomiye
**dönmesi**.

---

## 4. Karanlık devlet: rıza ve zor

v4.4'te bu mekanizma dar bir haldeydi (uyuşturucuya tolerans, cezaevi oranı,
illegalite primi). v2'de **tam haliyle** açılıyor.

### 4.1 Ne yapar — asıl mekanik kavrayış

Motorda **öfke (`Omega`) ile örgütlenme (`org`) ayrı değişkenlerdir** ve
devrim ikisini birden gerektirir (`T` bloğu). Karanlık devletin işlevi buradan
çıkar:

> **Amaç öfkeyi azaltmak değil; öfkenin SINIFSAL ÖRGÜTLENMEYE dönüşmesini
> kırmaktır.** Öfke yerinde kalır, hedefi değiştirilir — sınıftan komşuya.

Bunun için yeni bir durum değişkeni gelir: **`bolunme`** — emekçi sınıfın
kendi içine bölünmüşlüğü. Etkileri:

| `bolunme` şunu yapar | hangi bloğa |
|---|---|
| `Omega` → `org` dönüşümünü kırar | `S` — örgütlenme stoku |
| Sendika pazarlık gücünü düşürür → `pay` kazanımı zayıflar | `Q` — Goodwin |
| Protestoyu sınıfsal olmaktan çıkarır, topluluklar arası şiddete çevirir | `T` — protesto riski |

Sermaye için sonuç nettir: **ücret payı baskılanır, kâr oranı korunur, devrim
riski düşer.** Bedeli başka yerden çıkar (§4.3).

### 4.2 İki aygıt

Gramsci'nin ayrımı doğrudan iki kola dönüşür.

**RIZA — ucuz, yavaş, sinsi.** Sınıf bilincinin yerine başka bir bilinç koyar:

- dini cemaat/tarikat ağlarının önünü açmak
- mistisizm, astroloji, evrim karşıtlığı, düz dünyacılık gibi akımları desteklemek
- milliyetçiliği körüklemek; ülke içindeki küçük etnik gruplara karşı düşmanlık
- mülteci düşmanlığı, ırkçılık
- LGBT düşmanlığı, kadınlara karşı baskıcı politikalar
- uyuşturucuya göz yummak

**ZOR — hızlı, pahalı, iz bırakır.** Rıza yetmediğinde devreye girer:

- sendikal harekete baskı, grev kırma
- muhalif siyasi karakterlerin tutuklanması
- paramiliter faşist grupların önünü açmak; siyasi cinayet

### 4.3 Bedeller — bunlar bedava kollar değildir

Mekanizmanın tasarım değeri burada. Her aygıt **kendi geleceğini yiyerek**
çalışır.

**Rıza aygıtlarının bedeli — üretkenlik.**

> Bilim karşıtlığı, eğitim tabanını çürütür: `egitim_pay` düşer, `q` büyümesi
> (`qg`) yavaşlar.

Ve `q` büyümesi, LTRPF'ye karşı elindeki **tek karşı eğilimdir.** Yani:

> **Karanlık devlet toplumsal barışı, kendi gelecekteki birikimini yiyerek
> satın alır.** Bugün devrimi öteler, yarın kâr oranını daha da düşürür.

Uyuşturucuya göz yumma ayrıca motorun **Tonak değer gaspı** kanalına bağlanır:
illegal sektör değer çeker, ama gasbedilen değer üretken sermayeye değil
**spekülatif stoka** akar — yani doğrudan Minsky balonunu besler.

**Zor aygıtlarının bedeli — emek gücü ve meşruiyet.**

- Tutuklama → `cezaevi_orani` ↑ → `l_etkin()` ↓ → **daha az canlı emek → daha
  az yeni değer** (`V`). Baskı, artı değerin kaynağını daraltır.
- Siyasi cinayet → kısa vadede örgütlenme kırılır, ama `Omega` **yükselir**:
  şehitler radikalleştirir.
- Baskıdan sağ çıkan örgütlenme **daha radikal** döner: `org` yeniden büyüdüğünde
  ılımlı kanal kapalıdır.
- Uluslararası meşruiyet düşer: ittifak bulmak zorlaşır (§3.3).

### 4.4 Karşı hareket — sendikalar ve sosyalist yapılar

Karanlık devlet tek taraflı bir kol değil, **bir mücadelenin bir tarafı.**
Karşısında `bolunme`yi aşağı iten kuvvetler vardır:

| kuvvet | ne yapar |
|---|---|
| **Sendikalar** | `org` yüksekken `bolunme` birikimi yavaşlar; sendika ayrıca aktif olarak `bolunme`yi düşürür — sınıfı ortak çıkar etrafında yeniden birleştirir |
| **Sosyalist parti** (Marksist politik özne) | Dağınık öfkeyi sınıfsal güce çevirir — tam da karanlık devletin kırmaya çalıştığı kanal. `parti_iktidari` açıkken bölünme en hızlı geriler |
| **Kentleşme** (`S`) | Fabrika yoğunluğu örgütlenmeyi besler; bölünme kentte kırda olduğundan zor tutunur |
| **Dayanışma kazanımları** | Ücret, sosyal harcama ve iş güvencesi kazanımları bölünme anlatısını zayıflatır |

Sonuç bir **yarıştır**: karanlık devlet `bolunme`yi iter, sendika ve parti
çeker. Kim kazanırsa krizin siyasi sonucunu o belirler — patlama mı, çürüme mi.

### 4.5 Oyuncu hangi tarafta

**Her ikisi de oynanabilir.** Kapitalist rejimde bu kollar senin elindedir;
kullanmamak da bir karardır ve bedeli daha erken devrimdir. Sosyalist parti
iktidara gelirse kollar tersine döner: bölünmeyi çözmek, örgütlenmeyi
derinleştirmek senin işin olur.

Yapay zekâ yönetimindeki ülkeler bu kolları kendi krizlerine göre kullanır —
yani dünyada başka ülkelerin faşizme kayışını **dışarıdan izlersin**, ve o
kayış senin ihracat pazarını, ittifaklarını ve savaş riskini etkiler.

### 4.6 Temsil ilkesi

Bunlar oyunda **ne iseler o olarak** görünür: mağdurları adlandırılmış,
bedelleri sayılmış politikalar. "Etkinlik" kolu gibi sunulmaz.

- Ekranda **kimin** hedef alındığı yazılır — hangi etnik grup, hangi topluluk.
- Cezaevi oranı, siyasi cinayet sayısı ve eğitim tabanındaki çöküş **görünür
  metriklerdir**, gizli çarpanlar değil.
- Karşı hareket dekor değil, ölçülebilir bir kuvvettir (§4.4).

Oyun bu politikaları bir yönetim tekniği olarak değil, **sınıf egemenliğinin
bir aracı olarak** modeller — ve maliyetini kimin ödediğini sayar.

---

## 5. Uygulanan kararlar

Victoria 3'e en yakın seçenekle kapatıldı.

### 5.1 Harita: gerçek coğrafi, eyalet bazlı

Sıfır asset kuralı **gevşetiliyor** ama tamamen değil: `.png` yok (her şey
`_draw()`), **vektör geometri verisi var** (eyalet sınırları sıkıştırılmış
poligon tablosu, üretilmiş veri dosyası).

### 5.2 Zaman: haftalık tik

> **UYARI — en olası sessiz hata.** v4.4'ün bütün oran parametreleri **tur
> başına** tanımlıydı, 1 tur = 0.27 yıl. Hafta = 0.0192 yıl, yani **14 kat
> kısa**. Yeniden ölçeklenmezse motor 14 kat hızlı koşar ve bu oynayarak fark
> edilmez.

### 5.3 Zaman aralığı: **1836–2100** (karar verildi)

Victoria 3'ün 1836–1936'sı **uzatıldı**. Sebep: çağ tablosu otomasyonu
2000'e koyuyor, dolayısıyla 1936'da biten bir kampanya bütün geç dönem
mekanizmalarını (otomasyon, canlı emek payının çöküşü, tam otomasyon doruğu)
oyun dışında bırakıyordu.

~13 700 haftalık tik. Victoria'nın dönem hissi bir ölçüde dağılır; buna
karşılık **bütün mekanizmalar doğal yerinde** kalır ve takvim kurgusallaşmaz.

> **DÜZELTME — LTRPF otomasyonu beklemez.** Önceki taslakta kâr oranının
> düşüşü otomasyona bağlanmıştı; bu yanlıştı. Düşüşü **organik bileşimin
> tavansız yükselişi** sürükler ve **ilk günden itibaren kademe kademe**
> işler. Ölçüldü: 1836–1936 arasında, otomasyon **sıfırken**,
> `q` 1.32→17.25, `c/v` 1.59→8.34, `r` **0.150→0.065 (−%57)**.
> Teknolojik ilerleme geçici iyileşme sağlar ama eğilimi tersine çevirmez.
> **Tam otomasyon bu eğilimin doruk noktasıdır, koşulu değil.**

### 5.4 Ülke değiştirme: yok

Devrim ülkeyi değiştirmez; **elindeki kolları** değiştirir.

### 5.5 Ana ekran: harita

Paneller üstüne açılır. 12 çekirdek metrik grafiği panele taşınır — silinmez.

### 5.6 Ülke sayısı: tam dünya

~100+ ülke, dinamik kurulma/ilhak. Kriz denklemleri ülke sayısından
bağımsızdır; `C` ve `L` genelleşir.

### 5.7 Tek oyunculu

Ağ katmanı, lockstep, oturum yönetimi yok.

### 5.8 Eyaletler: **yok**

Eyalet katmanı tamamen kaldırıldı. Sebebi tasarımsal değil olgusal: eyalet
sistemi her ülkede yoktur (üniter devletlerde karşılığı yok), oyunun hiçbir
mekanizması eyalet düzeyinde çalışmıyor, ve harita ülke düzeyinde de pekâlâ
okunuyor.

Ekonominin tek mekânsal birimi **ülkedir**. Harita ülkeleri gösterir;
tıklanan şey ülkedir.

### 5.8b Ülkeler: simüle edilen dünya ≠ oynanabilir küme

İki ayrı liste:

**Simüle edilen dünya** — Victoria 3 ölçeğinde bütün egemen devletler.
Hepsi kendi kriz çekirdeğini koşturur, ticaret yapar, savaşır, rejim
değiştirir. Oyuncu onları dışarıdan izler.

**Oynanabilir küme** — **G20 + 1836'daki tarihsel öncülleri**:

| bugünkü | 1836'daki öncülü |
|---|---|
| Türkiye | Osmanlı İmparatorluğu |
| Almanya | Prusya / Alman Konfederasyonu |
| Rusya | Rusya İmparatorluğu |
| Çin | Çing Hanedanı |
| Hindistan | Babür / Britanya Hindistanı |
| İtalya | Sardinya-Piemonte / İki Sicilya |
| Japonya | Tokugawa şogunluğu |
| İngiltere | Britanya İmparatorluğu |
| ABD, Fransa, Brezilya, Meksika, Arjantin | kendileri |
| Kanada, Avustralya, G.Afrika | Britanya sömürgesi (geç açılır) |
| Endonezya | Hollanda Doğu Hint Adaları |
| S.Arabistan | Necd / Osmanlı vilayeti |
| G.Kore | Choson |

Gerekçe: dünyanın zenginliği korunur ama oyuncu **anlamlı bir özneye**
bağlanır. Dünya sistemindeki konum oyunun zorluk ayarı olduğu için (§0),
oynanabilir kümenin merkez–yarı–çevre yelpazesini kapsaması yeterlidir;
G20 tam olarak bunu yapar.

### 5.9 Pop'lar: sınıf kohortları

Ülke başına **6–8 kohort**: sermayedar, küçük burjuva, ücretli işçi, örgütlü
işçi, işsiz, hapisteki nüfus, kır emeği. Victoria'nın tip × kültür × din ×
konum çarpımı **yok** — 100 ülkede yüzlerce nesne yerine ~800.

**Azınlık gruplarının çözümü.** Karanlık devlet (§4) etnik, dinsel ve
cinsiyet bölünmeleri üzerinde çalışır; kohort modeli bunları ayrı pop olarak
taşımaz. Çözüm:

- **azınlık grupları VERİ olarak** — ülke başına ad + nüfus payı listesi
- **`bolunme` SKALER olarak** — sınıfın kendi içine bölünmüşlük derecesi

Böylece §4.6'nın temsil ilkesi korunur (ekranda **kimin** hedef alındığı
yazılır, bedeli sayılır) ama pop sayısı patlamaz.

### 5.10 Mal piyasası: 4–6 kategori

**Tüketim malı, sermaye malı, hammadde, lüks** — Victoria'nın ~50 malı değil.

Mal katmanının bu oyundaki işi tek: **satılamayan mal yığınını görünür
kılmak.** Gerçekleşme krizi bir sayı olarak değil, depoda biriken bir kütle
olarak okunmalı. Bunun için elli mal gerekmez; dört kategori yeter ve piyasa
temizleme makinesi yönetilebilir kalır.

### 5.11 Binalar ve üretim yöntemleri: **pazarlık dışı**

Oyunun merkezî tuzağı burada yaşar (§2.4): üretim yöntemi yükseltmesi `q`'yu
yükseltir → `c/v` yükselir → `r` düşer. Oyuncunun asıl kolu budur ve
çıkarılamaz.

Bina **türü** azdır: sektör başına bir tane, ~6–8 tür. Zenginlik tür
sayısında değil, **üretim yöntemi merdiveninde**.

---

## 6. Aşamalar — **B0'dan sonra yeniden sıralandı**

B0'ın ölçümü planı değiştirdi. Eski sıra "mikro katman → kuplaj → dünya"
diyordu; ama §8.6'da ölçüldü ki kapalı bir ekonomi istikrarlı görünüyordu.
Eski sırayla ilerlemek, aylarca pop ve bina inşa edip en sonda "krizler hâlâ
yok" bulmak demekti.

> **GERİ ÇEKİLDİ — "kapalı ekonomi istikrarlıdır, kriz dünya sisteminin
> ürünüdür."** O ölçüm, iki mekanizması eksik bir çekirdek üzerinde alınmıştı:
> `deger_carpani` yazılıyor ama hiç okunmuyordu (kriz sermayeyi
> değersizleştirmiyor, yani kâr oranını onarmıyordu) ve `q_doyum` hiç
> taşınmamıştı (c/v çağ-6 çapası olan 15'i aşıp 112'ye kaçıyor, yıllık K/Y 21'e
> çıkıyor, yenileme talebi tek başına hasılanın %160'ını istiyordu — talep arzı
> kalıcı olarak aştığı için hiçbir departmanda mal yığılamıyordu).
>
> İkisi bağlanıp satın alma gücü değer bileşimine oturtulunca kapalı ekonomi
> **100 kapitalist yılda 19.2 ayrık kriz olayı** üretiyor; tarihsel kayıt aynı
> kümelemeyle 12.1. Yani kapalı ekonomi istikrarlı değil, **fazla** kriz-yatkın.
>
> Aşamaların sırası yine de doğruydu: riski öne almak kararı, gerekçesi
> yanlışlanmış olsa bile isabetliydi.

> **Yeni kural: kriz makinesinin canlı olduğu, üstüne bir şey inşa edilmeden
> ÖNCE kanıtlanır.** Risk öne alınır.

| aşama | iş | biter dediğimiz an |
|---|---|---|
| ~~B0~~ | ~~Kriz çekirdeği~~ | **BİTTİ** — 18/18 ölçek testi, LTRPF −%57 |
| ~~B1a~~ | ~~KAPALI EKONOMİ KRİZ ÜRETSİN~~ | **BİTTİ** — ölçüt "en az bir aşırı üretim krizi"ydi; 14 tescil edildi. `--v2-olcek` 23/23, `--v2-tarih` geçiyor |
| **B1b** | **DÜNYA.** Çok ülke, değer transferi (C, L) ✅, dış ticaret (B) ✅, ani duruş / moratoryum / döviz krizi (D, E, F) ✅ | **KURULDU** — beş kanal da yerinde, `--v2-dunya` 17/17 |
| **B2a** | **ÜRETİM KATMANI.** Sektör, bina, üretim yöntemi merdiveni (§5.11) | **KURULDU** — `--v2-uretim` 17/17, `--v2-tarih-mikro` geçiyor |
| **B2b** | **SINIF KOHORTLARI.** Pop'lar → `L`, `e`, `pay` (§5.9) | **KURULDU** — `--v2-nufus` 13/13, `--v2-tarih-mikro` iki katmanla geçiyor |
| **B2c** | **MAL PİYASASI.** Dört kategori, satılamayan yığın (§5.10) | **KURULDU** — `--v2-mal` 7/7 |
| **B3** | **Bölünme ve karşı hareket.** `bolunme`, rıza/zor kolları, sendika ve parti (§4) | **KURULDU** — `--v2-bolunme` 33/33; §4.3 ve §4.1'in birer iddiası ölçülüp düzeltildi (§6e) |
| **B4** | **Savaş ve diplomasi.** İttifak, abluka, ambargo — kriz çıkışı olarak (§3) | **SAVAŞ KURULDU** — `--v2-savas` 16/16; ittifak/abluka/ambargo kalan iş (§6f) |
| **B5** | **Harita.** Eyalet geometrisi, harita modları, ülke seçimi | 20+ ülke, dokuz mod, bağlar çizili |
| **B6** | **Ölçek.** Tam dünya, başarım ölçümü | ~100 ülke, kabul edilebilir tik süresi |
| **B7** | **Arayüz.** Victoria düzeni: harita ana ekran, paneller, günce | Ekran `--ss=` ile çizdirilip bakılmış |

**B1a bitti ve kendi ölçütünü fazlasıyla aştı.** Kriz teorisi bu mimaride
çalışıyor: kapalı ekonomi 100 kapitalist yılda 19.2 ayrık kriz olayı üretiyor.

### B1b'nin ölçütü artık ayırt etmiyor

Eski ölçüt "`--v2-tarih` geçer" idi. O test **B1b başlamadan geçiyor**,
dolayısıyla B1b'nin bittiğini söyleyemez: dünya katmanı eklendiğinde de
geçecek, eklenmediğinde de geçiyor. Bir kapı her iki durumda da yeşilse kapı
değildir.

B1b'nin asıl işi kriz ÜRETMEK değil, **krizden ÇIKIŞ yollarını** açmaktır
(§3.1 tablosu). Kapalı çekirdek krizi üretebiliyor ama çözemiyor: ihracat
pazarı, sermaye ihracı, eşitsiz mübadele, moratoryum ve savaş — hepsi eksik.
Fazla kriz-yatkınlığı (19.2'ye karşı 12.1) tam da bunun beklenen imzasıdır.

Bu yüzden B1b'nin ölçütü **çıkışların çalıştığını** göstermeli:

1. Kriz yoğunluğu tarihsel banda **yaklaşmalı** — kapalı koşuda 19.2, dünya
   katmanıyla 12.1'e doğru inmeli. Çıkışlar açılınca krizler seyrelir.
2. **Tür karışımı** tabloya yakınsamalı: kayıttaki 27 olayın 5'i finansal,
   3'ü kârlılık, 2'si aşırı birikim. Kapalı çekirdek bunları ayırt edemiyor.
3. **Çıkışın kendisi ölçülmeli**: değer transferi **alan** ülkede bunalım
   yoğunluğu azalmalı, **veren** ülkede artmalı — her ülke kendi kapalı
   hâliyle karşılaştırılarak. Emperyalizmin motordaki imzası budur ve tek
   ülkede tanımsızdır.

Üçüncüsü en önemlisi, çünkü yalnızca dünya katmanı varken anlamlıdır.

> **1. madde uyarısı — ölçüldü ve beklenti yanlış çıktı.** "Çıkışlar açılınca
> krizler seyrelir" cümlesi değer transferi çıkışı için **doğru değil**.
> Transfer açıkken dünya toplamı kıpırdamıyor (bunalım 4.3 ↔ 4.3, toplam
> 35.4 → 35.1); tek tek ülkeler ise onlarca kat oynuyor. Yani bu çıkış krizi
> seyreltmiyor, **yer değiştiriyor** — ve Marksist okumada beklenen de budur:
> emperyalizm krizi çözmez, erteler ve taşır.
>
> Madde 1 yine de yanlışlanmış sayılmaz, çünkü kalan çıkışlar (ihracat pazarı,
> sermaye ihracı, moratoryum, savaş) henüz yok. Ama artık **hangi çıkışın
> seyreltmesi beklendiği** ayrıca gerekçelendirilmeli; "çıkış açılınca seyrelir"
> genel kuralı bu motorda geçerli değil.

### Değer akışı kuruldu — ve üçüncü madde ölçüldü

`Dunya` (`godot/scripts/v2/core/dunya.gd`) ülkeler arası değer akışını
**korunumlu** hale getirdi: akım çift üzerinde tanımlı, iki uca ters işaretle
yazılıyor, dolayısıyla `sum(VT) == 0` bir kalibrasyon değil **özdeşlik**.
Ölçülen korunum hatası tam olarak `0.0`. Kapı: `--v2-dunya`.

> **v4.4'ün L bloğu korunmuyordu ve bu yüzden port edilmedi, düzeltildi.**
> Orada transfer her ülke için bağımsız hesaplanıyor (`motor.py:2162`),
> sapmalar `Y` ile çarpıldığı için ağırlıklı toplam sıfır çıkmıyor, ağırlıklar
> ülke tipine göre değişiyor ve `disa` tek taraflı kırpıyor. Ölçüldü (tohum 42,
> 20 ülke): **tur 25'te 20 ülkenin yirmisi de negatif**; tur 1000'de toplam
> **+14964**, korunum hatası **%57**. Değer önce dünyadan sızıp yok oluyor,
> sonra yoktan yaratılıyor. "Transfer" adı yanlıştı — varış yeri hiç
> modellenmemiş bir sızıntıydı.
>
> Merkez/çevre artık **formüle girmiyor**. v4.4 ağırlıkları `tip == "cevre"`
> ile seçiyordu; burada ülke tipi diye bir girdi yok. Kimin alıcı kimin verici
> olduğu organik bileşim farkından doğar — konum bir sonuçtur.

### Ölçüt derinlik cinsinden yeniden yazıldı — ve karşı-olgusal olarak

Ölçütün 3. maddesi artık şudur:

> **Değer ALAN ülkede bunalım yoğunluğu azalır, VEREN ülkede artar.**

İki değişiklik var, ikisi de zorunluydu.

**1. Sıklık değil derinlik.** Toplam kriz sayısı ayırt etmiyor (ALAN 34.7 ↔
VEREN 34.6): toplam resesyon baskın ve alan ülke yüksek organik bileşimi
yüzünden zaten daha sık kârlılık sıkışması yaşıyor. Değer girişi krizi
seyreltmiyor, **bunalıma dönüşmesini** engelliyor.

**2. Kesitsel değil karşı-olgusal.** "Azalır/artar" bir *değişim* iddiasıdır;
alan ve vereni yan yana koymak transferin etkisiyle bileşim farkının etkisini
karıştırır. Doğru tasarım aynı dünyayı aynı tohumla transfer **açık** ve
**kapalı** koşup her ülkeyi kendi kapalı hâliyle karşılaştırmaktır.

> **Bu ayrım bir yanlış sonucu yakaladı.** Kesitsel ölçüm ALAN 2.4 ↔ VEREN 5.6
> veriyordu ve bu "giriş derinliği düşürüyor" diye okunmuştu. Karşı-olgusal kol
> gösterdi ki o fark transferin eseri **değil**: kapalı koşuda da neredeyse
> aynı yerde duruyor. Transferin gerçek etkisi o noktada sıfırdı — VEREN'de
> altı tohumun altısında da değişim tam olarak **+0.0**.

### İki yönlü muhasebe — çekirdekteki tek yönlü hesap düzeltildi

Sebebi çekirdekte bulundu. `_efektif_talep` v4.4'ü izleyerek
`D_talep = C + I + G + max(VT, 0)` yazıyordu (`motor.py:1930`): **gelen değer
talebe ekleniyor, giden değer hiçbir yerden düşülmüyordu.** Bir ülke değer
kaybederken satın alma gücü kaybetmiyordu; negatif VT'nin tek kanalı `r_ef`
idi, o da VT/K ≈ 0.0006 mertebesinde kalıyordu.

Oysa eşitsiz mübadelede giden şey **gerçekleşmiş satın alma gücüdür** — çevre
ülke kendi ürününü satın alamaz hale gelir. Gerçekleşme krizinin emperyalizm
üzerinden çevreye taşınma kanalı tam olarak budur ve tek yönlü muhasebeyle
kapalıydı. Artık `D_talep = C + I + G + VT` (işaretiyle).

Yan etki: `--v2-tarih`'in VT taraması da düzlüğünü kaybetti (toplam 34 → 37,
bunalım 4 → 5). O düzlük bir zamanlar "krizler ülke-içidir"in ek kanıtı
sayılmıştı; kapalı ekonominin kriz ürettiği doğru, ama **transferin etkisiz
olduğu yanlıştı.**

### Şiddet kalibre edildi — görünür biçimde

Yön doğru olsa bile ağırlık küçükse mekanizma gürültüye gömülür. `--v2-dunya-siddet`
altı tohumun kaçında işaretin doğru çıktığını tarar (medyan değil **tutarlılık**):

| şiddet | \|VT\|/Y | ALAN doğru | VEREN doğru |
|---|---|---|---|
| 0.05 | 0.0053 | 5/6 | 6/6 |
| **0.10** | **0.0115** | **6/6** | **6/6** |
| 0.20 | 0.0239 | 6/6 | 5/6 |
| 0.80 | 0.1230 | 6/6 | 6/6 |

`siddet = 0.10` seçildi, iki bağımsız gerekçeyle: v4.4'ün varsayılan dünyada
ürettiği |VT|/Y ~ 0.01–0.03 bandının alt ucuna oturuyor (elimizdeki tek ampirik
çapa), ve kuralın altı tohumun altısında da tuttuğu **en düşük** şiddet. v4.4'ün
`vt_siddet = 0.05` sabiti buraya uymaz: o, ülke başına bağımsız hesaplanan
başka bir formülün kalibrasyonuydu, bu ise çift bazlı gravite — aynı sayı aynı
ağırlığı vermiyor.

**Sonuç (6 tohum, medyan, bunalım/100 kapitalist yıl):** ALAN **−0.65** (altı
tohumun altısında da negatif), VEREN **+0.10** (altısında da pozitif). Kural
çalışıyor.

### Toplam kriz dinamiği — kural çalışınca ne oldu

| | kapalı | açık | değişim |
|---|---|---|---|
| toplam kriz/100y | 35.4 | 35.1 | −0.3 |
| bunalım/100y | 4.3 | 4.3 | −0.0 |

> **Transfer krizi yok etmiyor, taşıyor.** Dünya neti −0.01 iken tek tek ülkeler
> çok daha fazla oynuyor. Marx'ta emperyalizm krizi çözmez, erteler ve taşır;
> ölçülen tam olarak bu.

Yükün nereye gittiği ise beklenmedik:

| ülke | Δ bunalım/100y | |
|---|---|---|
| Yuksek | −0.65 | rahatlıyor |
| Orta-üst | −0.02 | rahatlıyor |
| Orta | +0.01 | yükleniyor |
| **Orta-alt** | **+1.00** | yükleniyor |
| Düşük | +0.10 | yükleniyor |

> **En ağır bedeli en çok veren ödemiyor.** Düşük ülke net transferin en
> büyüğünü veriyor (−4769) ama bunalım yükü yalnızca +0.10 artıyor; sarsılan
> **Orta-alt** (+1.00). Sebebi taban etkisi: Düşük zaten bunalıma doymuş
> (5.6/100y), yükselecek yeri yok. Marjinal kurban en yoksul olan değil,
> **eşiğe en yakın olan** — yani yarı-çevre.

Bu, B3'ün (bölünme ve karşı hareket) hangi ülkelerde en sert oynayacağını da
söylüyor ve savaş/ittifak katmanı (B4) için doğal bir gerilim kaynağı.

### B bloğu: dış ticaret kuruldu — ve iki şeyi değiştirdi

Ticaret de **çift bazlı ve korunumlu**: `X_ij` hem i'nin ihracatı hem j'nin
ithalatıdır, dolayısıyla `sum(NX) == 0` özdeşlikle sağlanır (ölçülen hata
`0.0`). v4.4'te ticaret diye bir akım yoktu — `eps` ve `pi_m` her ülke için
dünya ortalamasından hesaplanıyordu, kimse kimsenin ithalatçısı değildi.

Yön rekabetten gelir: çiftin hacmi gravite, ikiye bölünüşü **Thirlwall oranı**
`eps/pi_m`. Yüksek üretkenlik hem ihracat esnekliğini yükseltir hem ithalat
esnekliğini düşürür, o yüzden ticaret fazlası bir girdi değil **üretkenlik
farkının sonucudur**. Ölçülen: NX/Y +%6.1 (Yuksek) … −%5.8 (Dusuk).

**1. Kuralın doğru değişkeni değişti.** Ticaret varken değer transferi tek
başına **ikinci derecede** kalıyor: NX/Y ~%6 iken VT/Y ~%0.5. Havuzlanmış
gradyan (30 gözlem) VT için −0.06…−0.16 arasında, yani gürültüden ayırt
edilemez. Ama kural yanlış değil — **eksik değişkenle** ölçülüyordu. Ticaret
fazlası da gelen değerdir; kural **toplam dış konuma** (NX + VT) uygulanınca:

> **gradyan −0.80 (30 gözlem).** Dış değer konumu bunalım dinamiğini
> belirliyor. "Birinden eksilen diğerine gider" kuralı, bütün akımlar
> sayıldığında güçlü biçimde tutuyor.

**2. §3.1'in "yeni pazar" iddiası ölçümle çelişiyor.**

> Belge diyor ki: aşırı üretim krizinin ilk çıkışı yeni pazar açmaktır.
> Ölçüm bunu **doğrulamıyor**. Ticaret açılınca aşırı üretim yoğunluğu ticaret
> **fazlası veren** ülkede bile artıyor (+0.39 / 100 kapitalist yıl); açık
> veren ülkede sıfır civarı. Yani dış pazar gerçekleşme sorununu hafifletmiyor.
>
> Olası okuma — ve Luxemburg'un kendi savı: ihracat talebi kapasite
> kullanımını yükseltir, hızlandırıcı üzerinden birikimi hızlandırır ve
> gerçekleşme sorununu **çözmez, daha büyük ölçekte tekrarlatır**. Dış pazar
> bir çıkış değil, bir erteleme olabilir.
>
> `--v2-dunya`'da bu denetim **kırmızı bırakıldı**. Yeşile boyamak için
> ne eşik gevşetildi ne mekanizma zorlandı: çelişki gerçek ve hangi tarafın
> yanlış olduğu (model mi, §3.1 mi) henüz belli değil. Kapı 8/9.

**Açık soru:** transfer şiddeti 0.60'ı geçince gradyanın işareti dönüyor.
Devrim zamanlaması değil (her ağırlıkta 30/30 devrim, ortalama 1932). B/D/E/F
tamamlanmadan kovalanmamalı.

### Pazar kavgası — §3.1 düzeltildi, çürütülmedi

Önceki ölçüm "dış pazar aşırı üretimi azaltmıyor" diyordu ve bu §3.1 ile
çelişki sayılmıştı. **Çelişki değildi, testin iddiası yanlıştı.** §3.1 dış
pazarı bir *çözüm* diye okumuştum; teori onu bir **zorunluluk** olarak koyar —
geçici rahatlama sağlar, sorunu ortadan kaldırmaz.

Ama modelde asıl eksik olan başkaydı: ticaret payları **yalnızca üretkenlikten**
geliyordu. Malları satılamayan ülke ihracata daha çok *asılmıyordu*. Zorlama
yoksa pazar kavgası da yok. Eklenen: `ihracat_itkisi` — gerçekleşme baskısı
rekabet gücünü çarpar,

```
k = (eps / pi_m) · (1 + itki · baski)
```

ve pay `k_i/(k_i+k_j)` olduğu için **itki sıfır toplamlıdır**: tek başına iten
kazanır, herkes itince paylar değişmez. Kavganın çıkmaz olması bir olay
tablosundan değil, `sum(NX) == 0` özdeşliğinden geliyor.

Ölçülen (6 tohum, karşı-olgusal: itki açık/kapalı):

| iddia | ölçüm |
|---|---|
| **Zorlama** — satılamayan mal ihracata iter | +0.219 ✅ |
| **Rahatlama gerçek** — ihracat açığı kapatır (ülke içi sapmalar) | −0.124 ✅ |
| **Konuma bağlı** — fazla tutulduğu sürece sürer, 4 yılda sönmez | −0.240 ✅ |
| **Sıfır toplam** — dünya ölçeğinde rahatlama yok (13.61 → 13.87) | ✅ |

> **Geçicilik rahatlamanın sönmesinden gelmiyor, konumun çekişmeli
> olmasından.** Bir ülke ticaret fazlasını tuttuğu sürece gerçekleşme açığı
> gerçekten kapanıyor — ve 4 yıl sonra daha da kapalı. Ama `sum(NX) == 0`
> olduğu için fazlayı herkes aynı anda tutamaz, ve itki sıfır toplamlı olduğu
> için herkes ittiğinde kimse kazanamaz. Çin fazlayı tuttuğu sürece rahatlıyor;
> ABD geri almaya çalışıyor; dünya toplamında rahatlama yok. Kampanya
> ortalamasının rahatlama göstermemesinin sebebi budur — sönme değil, çekişme.

**İtki kalibre edildi — tahmin edilen değer iki eksende birden yanlıştı.**

`ihracat_itkisi` önce 1.5 diye tahminle konmuştu. Eklendiğinde "dış değer konumu
bunalımı belirliyor" gradyanı **−0.80'den −0.11'e** çöktü. İlk teşhisim
içsellikti (sıkışan ülke çok ihraç eder → ters nedensellik) ve **yanlıştı**:
konumun yapısal bileşeniyle araç değişken kurunca da düzelmedi (−0.094).

Asıl sebep ölçekti. Ortalama itki **5.39**'a çıkıyordu, oysa yapısal rekabet
oranı `eps/pi_m` en fazla 3.58. **Zorlama üretkenlik yapısını eziyordu.**
Tarama (`--v2-dunya-siddet`, ikinci tablo):

| itki | ort. itki | ZORLAMA | YAPI gradyanı |
|---|---|---|---|
| 0.00 | 1.00 | 0.000 | −0.836 |
| 0.25 | 1.73 | 0.106 | −0.784 |
| **0.50** | **2.46** | **0.423** | **−0.551** |
| 1.00 | 3.93 | 0.536 | −0.418 |
| 1.50 | 5.38 | 0.371 | −0.218 |

1.5'te **zorlama bile düşüyor** (0.536 → 0.371): herkes doyuma ulaşıyor, paylar
sabitleniyor. Yani tahmin edilen değer hem yapıyı siliyor hem kendi mekanizmasını
boğuyordu. Ölçüt: itki yapısal oranı **ezmemeli, module etmeli** — 0.50'de itki
çarpanı 1.0–2.5 ile yapısal 3.2 katın altında kalır.

Kalibrasyondan sonra gradyan **−0.456**'ya döndü, zorlama **+0.573**'e çıktı.
`--v2-dunya` **13/13**.

### Kavga sıfır toplamlı değil, negatif toplamlı

Son ölçüm bir adı da düzeltti. "Dünya toplamı kıpırdamamalı" diye sınamıştım;
dünya aşırı üretimi **13.61 → 13.96** çıkıyor ve üç itki değerinde de pozitif.

> Sıfır toplamlı olan **paylardır** (`sum(NX) == 0`), sonuç değil. Payı kapan
> ülke kapasitesini genişletiyor, o kapasite sonra dünya gerçekleşme sorununa
> ekleniyor. Kavga yalnızca yeniden dağıtmıyor — **dünyayı biraz daha
> kötüleştiriyor.** Teorinin iddiası zaten "toplam sabit kalır" değil, "kavga
> rahatlama üretmez"di; yükselmesi bunun daha güçlü hâli.

### D / E / F — ve borcun alacaklısı

Ani duruş, moratoryum ve döviz krizi kuruldu. **Üçüncü korunum yasası** buradan
doğdu: dış borç `Dunya.borc` matrisinde, `borc[i][j]` = i'nin j'ye borcu, ve

```
sum(net dış varlık) == 0
```

özdeşlikle sağlanıyor (ölçülen hata `0.0`). v4.4'te `dis_borc` **alacaklısız bir
skalerdi** ve moratoryum onu çarpıp buharlaştırıyordu (`motor.py:1806`) — kimse
zarar etmiyordu, yani temerrüt bir kriz *kanalı* değil bir *muafiyetti*.

**Cari denge de proxy olmaktan çıkıp özdeşlik oldu.** v4.4 onu ülke başına
`-kats·Y·bop_asim·4 + 0.30·VT` diye hesaplıyordu; toplamı sıfır değildi.
Ölçüldü: o formülle bütün ülkeler aynı anda açık veriyor, açığı finanse edecek
fazla hiç oluşmuyor ve **borç matrisi kampanya boyunca boş kalıyordu** — D/E/F
ölü koddu. Artık `cari = NX + dış faiz + VT`, üçü de korunumlu, dolayısıyla
`sum(cari) == 0` kendiliğinden.

İki tuzak daha ölçümle yakalandı:

- **Çifte sayım.** Açık hem borçla finanse ediliyor hem rezervden düşülüyordu;
  rezerv hasılanın −5 katına inip döviz krizi neredeyse sürekli ateşleniyordu
  (198 yılda 173 kriz). Finanse edilen açık rezervi azaltmaz — borca döner.
  Rezerve yalnızca **kapatılamayan** kısım iner, ve bu D ile F'yi doğru sırayla
  bağlar: finansman kesilir → açık rezervi eritir → döviz krizi.
- **Borç geri ödenmiyordu.** Fazla veren bir borçlu, borcunu kapatacağına
  başkasına borç veriyordu; alt üç ülke tavana yapışıp **kalıcı** ani duruşta
  kalıyor ve sabit bir itki çarpanı taşıyordu. Zorlama sinyali bu yüzden işaret
  değiştirmişti (+0.383 → −0.154). Ani duruş bir epizot olmalı, bir kader değil.

### Temerrüt merkeze döner — artık ölçülüyor

Geri ödeme bağlanınca asıl iddia da tuttu. Karşı-olgusal (moratoryum
açık/kapalı, aynı tohum), toplam kriz yoğunluğu değişimi:

> **ALACAKLI ülkede +1.32.** Çevrenin ödeyememesi merkezin bilançosuna
> yazılıyor. v4.4'te bu ölçülemezdi çünkü alacaklı diye bir şey yoktu.

Borçlu için **yön iddia edilmiyor**: moratoryum borcu hafifletir ama `mor_ceza`
ülkeyi sermaye piyasasından atar (`BoP_R` +0.55). Meksika '82 ve Arjantin
'01'de olduğu gibi temerrüdü derin bir kriz izler; hangi etkinin bastığı
kalibrasyona bağlıdır ve tek yönlü bir kapı taşıyamaz.

### İki açık kırmızı

`--v2-dunya` **15/17**. Kalan ikisi de aynı olgunun sonucu — dış kanal sayısı
birden beşe çıktı:

1. ~~**"Dış değer konumu bunalımı belirliyor"**~~ — **ÇÖZÜLDÜ**, bileşik konumla ölçüldü,
   **düz çıktı.** Ayrıntı aşağıda.
2. ~~**"Negatif toplam"** −0.03'e döndü~~ — **ÇÖZÜLDÜ.** Aynı sayaç hatasıydı;
   düzeltmeden sonra +0.44.

### Bileşik dış konum ölçüldü — ve borç çevrimi üstünlüğü nötrlüyor

Bileşik konum dört korunumlu kanalın kümülatif toplamıdır (ticaret dengesi +
eşitsiz mübadele + dış faiz + temerrüt), hasılaya oranlanmış. Bu aynı zamanda
**dördüncü korunum özdeşliğidir**: `sum(toplam_dis) == 0`.

Dört bağımsız tahminci denendi:

| tasarım | sonuç |
|---|---|
| `NX + VT` (mutlak), karşı-olgusal | −0.006 |
| bileşik/Y, karşı-olgusal, bunalım | −0.100 |
| bileşik/Y, karşı-olgusal, toplam kriz | +0.014 |
| bileşik/Y, **ülke içi zaman serisi** | +0.032 |

Sonuncusu, §7'de aynı kurulumla −0.124 … −0.240 verdiği için tasarım
çalışır durumda. Yani sonuç gerçekten düz — ölçüm kusuru değil.

> ~~**Bulgu: borç çevrimi ticaret üstünlüğünü geri alıyor.**~~ **GERİ ÇEKİLDİ.**
> Bu okuma yanlıştı ve `--v2-dunya-ayrim` onu çürüttü.

### Ayrım: eserdi, ve sebebi tur→hafta tuzağıydı

Düzlüğün gerçek mi eser mi olduğu ayrı bir kapıyla ayrıştırıldı — borç kanalı
kapalıdan tam açığa, temerrüt sıklığı taranarak:

| borç kanalı | mor. çarpan | moratoryum | fx kriz | gradyan |
|---|---|---|---|---|
| kapalı | 0.0 | 0 | 0 | **−0.723** |
| açık | 0.0 | 0 | 325 | +0.064 |
| açık | 3.0 | 41 | 226 | +0.255 |
| **açık, F kapalı** | 0.0 | 0 | 0 | **−0.538** |
| **açık, F kapalı** | 1.0 | 0 | 0 | **−0.538** |

> **Suçlu temerrüt değil, döviz kriziydi.** Borç, faiz ve moratoryum açıkken
> ama F bloğu kapalıyken ilişki duruyor (−0.538); temerrüt tamamen sıfırken
> bile F açıksa çöküyor (+0.064). Yani düzlük borç çevriminin yapısal bir
> sonucu değildi.

Ve F'nin neden salgın hâline geldiği, bu deponun en çok uyardığı hataydı:
**v4.4'ün tur cinsinden sayaçları haftalık döngüye olduğu gibi kopyalanmıştı.**
`fx_baski >= 8` v4.4'te 8 tur, yani 2.16 yıl sürekli rezerv erimesi demek;
haftalık döngüde 8 hafta, yani 0.15 yıl. **14 kat hızlı.** Aynısı
`fx_kriz_sure` ve `mor_ceza_sure` için de geçerliydi.

`Oran.v44_sayac()` eklendi ve üçü de dönem cinsine çevrildi. Döviz krizi 325'ten
83'e indi, gradyan **−0.547**'ye döndü, kapı **17/17**.

> **Yan bulgu: temerrüt yük taşıyor.** Sayaç düzeltmesinden sonra bile
> `mor_carpan = 0` (hiç moratoryum yok) gradyanı +0.270'te bırakıyor; 1.0'da
> −0.580. Moratoryum olmayınca borç sonsuza kadar birikiyor, herkes kalıcı ani
> duruşa giriyor ve sistem donuyor. **Temerrüt gürültü değil, borç çevrimini
> açık tutan valf.**

### Ölçüt nerede duruyor — ve iki kez taşındı

Kapı karşı-olgusal tasarımdadır. Sırası kayda geçiyor çünkü **ikinci taşıma
hataydı**: ölçüm çökünce kapı ülke-içi zaman serisine taşınmıştı, oysa iki
tasarım aynı şeyi ölçmüyor. İddia kümülatif ve yapısaldır ("kampanya boyunca net
değer alan ülke dünya sisteminden daha az zarar görür"); ülke-içi tasarım ise
kısa vadeli bir zamanlama sorusu sorar ve krizler yığın hâlinde geldiği için
orada sıfır çıkması beklenir. §7'de çalışmasının sebebi oradaki çıktının sürekli
bir durum (`talep_acigi`) olmasıydı, ayrık bir olay değil.

Her aşamanın kabul ölçütü ortak üç maddeyle biter: `--v2-olcek` 23/23
(B1a onu 18'den büyüttü), `--v2-tarih` geçer (B1'den sonra), ve ekran
değişmişse `--ss=` ile gerçekten çizdirilip bakılmış olur.

---

## 6b. B2a — üretim katmanı

### B2'nin ölçütü de ayırt etmiyordu — ve aynı sebeple

§6'nın tablosu B2 için "`--v2-tarih` hâlâ geçer" diyordu. Bu, B1b'de
kapatılan kusurun **birebir aynısıdır**: o test B2 başlamadan geçiyor,
dolayısıyla B2'nin bittiğini söyleyemez. Kapı, iki durumda da yeşilse
kapı değildir.

Mikro katman olmadan **kurulamayan** tek cümle §2.4'ünkidir:

> Tek tek binalar kârlı görünürken toplam kâr oranı düşer.

"Bina kârlılığı" mikro, "toplam kâr oranı" makro bir büyüklüktür; tek
katmanlı bir motorda bu cümle telaffuz bile edilemez. B1b'nin üçüncü
maddesi ("tek ülkede tanımsızdır") ile aynı türden bir ölçüttür ve B2a'nın
kapısı odur: **`--v2-uretim`**.

### Otorite tablosu — §8.2 kapatıldı

Risk §8.2 mikro-makro tutarsızlığını işaret ediyordu: iki katman aynı alanı
yazarsa hangisinin kazandığı çağrı sırasına bağlı kalır. Her paylaşılan alan
bir kez karara bağlandı (`godot/scripts/v2/core/uretim.gd`):

| alan | otorite | gerekçe |
|---|---|---|
| `K` | mikro | binaların birikmiş inşaat maliyeti — **özdeşlik** |
| `q` | mikro | aktif üretim yöntemlerinin ağırlıklı seviyesi |
| `oto` | mikro | makine-ağırlıklı basamakların sermaye payı |
| `pay_I` | mikro | Dept I binalarının sermaye payı |
| `cv`, `kv` | çekirdek | `q`'dan türer — mikro katman c/v'yi **yazmaz** |
| `L`, `e`, `pay` | çekirdek | B2b'de pop katmanına geçer |
| `Y_yil` | çekirdek | efektif talep belirler; mikro yalnızca kapasite verir |
| `g`, `r` | çekirdek | §2.4: kâr oranı piyasadan **okunmaz**, hesaplanır |

**Sermaye yoğunluğu iki kez yazılmaz.** Bir basamağın "daha sermaye-yoğun"
olması elle girilmez; `kappa_v(cv, q)` zaten `q`'ya bakar. Basamak yalnızca
işçi başına çıktıyı taşır, sermaye ihtiyacı çekirdeğin `kv`'sinden türer.
Tuzak iki katmanın **bileşiminden** doğar, iki kez yazılmasından değil.

### Ölçülen — dört sonuç

Mikro katman takılı değilken çekirdek zerre değişmez; B1a/B1b'nin bütün
ölçümleri geçerliliğini korur (`--v2-olcek` 23/23, `--v2-dunya` 17/17,
`--v2-tarih` geçiyor — hepsi yeniden koşuldu).

**1. Sermaye özdeşliği.** `sum(bina.K) == d.K`, kampanyanın 10 400 adımının
her birinde ölçüldü: en büyük bağıl sapma **2.2e-16**. Kuruluşta hata tam
olarak `0.0`. B1b'nin korunum disiplini burada da geçerli — toplam bir
kalibrasyon değil özdeşliktir.

**2. Ortalama marj teknikten bağımsızdır — ve bu bir özdeşliktir.**

```
ort(marj) = sum(K_i·(1 − w/q_i))/sum(K_i) = 1 − w/q_toplam = 1 − pay
```

Ölçülen sapma **4.4e-16**. Yani ülke ortalaması marj yalnızca ücret payına
bakar, tekniğe **hiç** bakmaz. Tuzağın en keskin biçimi budur:

> **Teknik değişmenin toplam kaybı, kararın verildiği defterde görünmez.**

**3. Öncü kârı pozitif: +0.021.** Yükselten bina, yükseltme anında ülke
ortalamasının üstüne çıkıyor. Marx'ın göreli artı değeri: kazanç önce
davranana ait ve diğerleri yetiştikçe sönüyor.

**4. Karşı-olgusal (aynı tohum, yükseltme kolu açık/kapalı, 1836–2036):**

| | kapalı | açık | değişim |
|---|---|---|---|
| ort. c/v | 1.102 | 1.790 | **+0.689** |
| ort. kâr oranı `r` | 0.0682 | 0.0600 | **−0.0082** |
| ort. mikro marj | 0.5577 | 0.5576 | −0.0001 |

Kâr oranı **%12 düşüyor**, mikro marj kıpırdamıyor: `|Δmarj|/|Δr| = 0.011`.
Tuzak ölçüldü. `--v2-uretim` **17/17**.

### Üç hata ölçümle yakalandı — üçü de oynayarak fark edilmezdi

**1. "Mikro" marj makro tuzağı zaten içeriyordu.** Marj ilk yazımda sermaye
üzerinden tanımlanmıştı: `(Y_i − w·L_i)/K_i`. Bu cebirsel olarak
`(1 − w/q_i)/kv`'ye eşittir — yani içinde `kv` taşır, `kv` ise makro bir
büyüklüktür ve yükseltmeyle birlikte yükselir. Sonuç: iki katman **aynı**
işareti verdi (mikro −0.0033, makro −0.0123) ve tuzak ölçülemedi. Tek tek
kapitalist ekonominin `kv`'sini görmez; onun defterinde teknik değişme
**satış üzerinden marjdır**. Marx'ın kâr marjı ↔ kâr oranı ayrımı ve oyunun
tuzağı tam olarak o ayrımda yaşıyor.

**2. Toplu bedel ile haftalık akım karşılaştırılamaz.** Yükseltme bedeli
binanın sermayesine oranlı toplu bir tutar, yatırım ise haftalık bir akım:
haftalık yükseltme bütçesi ~0.17 iken en küçük binanın bedeli ~44 idi. Koşul
200 yılda **bir kez bile** sağlanmadı — merdiven kuruldu ama hiç tırmanılmadı.
Çözüm taksitlendirme, ve iktisadi olarak da doğrusu: yeni teknik yapı bir
günde satın alınmaz, parça parça inşa edilir. Ödenen her taksit anında
binanın sermayesine yazıldığı için özdeşlik kırılmaz.

**3. Merdiveni `era_min` ile kapılamak çağ tablosunu tersine çeviriyordu.**
İlk yazımda basamaklar elle yazılmış altı satırdı ve her biri bir çağ
istiyordu. Ölçüldü: 200 yılda 15 yükseltme, q 1.00 → **1.33** (aynı pencerede
kapalı form 55.4 veriyor). Çağ tablosu teknolojik gelişmeyi böyle kurmuyor:
her çağın bir `q_tavan`ı var ve q çağ **içinde** o tavana doğru doyarak
büyüyor. Yani çağ, hangi yöntemin açıldığını değil **üretkenliğin
ulaşabileceği tavanı** belirler. `era_min` kapıları 1836–1975 arası 139 yıl
boyunca merdiveni tek basamakta dondurmuştu. Merdiven artık **üretilmiş**
(72 basamak × %10) ve yukarıdan çağın kendi `q_tavan`ı kesiyor — yeni bir
kalibrasyon sabiti eklenmedi, kapı zaten var olan tablodan geliyor.

### Yükseltme maliyeti kalibre edildi — ve ilk değer çifte sayımdı

`yukseltme_maliyeti` başta 0.45 (binanın sermayesinin %45'i) yazılmıştı. Bu
**tekniğin maliyetini iki kez saymaktır**: asıl bedel değer katmanında zaten
ödeniyor (q ↑ → c/v ↑ → `kv` ↑ → aynı sermaye daha az kapasite). Buraya
yazılması gereken yalnızca **fark**tır — yeni tekniği kurmak, eskisini olduğu
gibi yenilemekten ne kadar pahalı.

Çapa olarak çekirdeğin **kapalı formu** alındı: o kalibrasyon `--v2-olcek`
23/23 ve `--v2-tarih`ten geçiyor, yani üretkenlik büyüme hızı bu motorda
zaten sınanmış. B1b'de `vt_siddet` için kullanılan gerekçenin aynısı.

**Tarama iki kez düzeltildi, çünkü ilk hâli yanlış şeyi ölçüyordu.**

*Yanlış konfigürasyon.* İlk tarama 1836/çağ-2 kurulumundan koşuyordu; oysa
üzerinde karar verilen ölçüt `--v2-tarih`tir ve o **1825'te çağ 1'den**
başlar. Çağ 1'in `q_tavan`ı 4.0, çağ 2'ninki 8.0 — merdivenin tavanı baştan
farklı. Başka bir kurulumda kalibre edilen sabit, karar verilen kurulumda
geçerli değildir.

*Yanlış ölçü.* Yalnızca **uç nokta** karşılaştırılıyordu. Uç nokta çapaya
0.88 oranıyla yakın çıkarken yörünge tamamen ayrışıyordu: mikro kol 1865'te
2.59'a, kapalı form 1.58'e varmıştı. **Bir eğriyi tek noktadan eşleştirmek
onu eşleştirmez.**

> **ÇAPA (mikro yok): devrim 1923, ort r 0.0653**
> **q yörüngesi: 1.27 1.58 1.90 2.24 3.23 4.33 5.69 8.58**

| maliyet | yükseltme | log-sapma | devrim | ort r | q(1885) | q(1965) |
|---|---|---|---|---|---|---|
| 0.050 | 177 | 0.694 | 1903 | 0.0401 | 3.70 | 15.86 |
| **0.100** | **81** | **0.340** | **1918** | **0.0594** | **1.61** | **3.29** |
| 0.200 | 35 | 0.764 | 1922 | 0.0660 | 1.21 | 1.69 |
| 0.350 | 20 | 0.906 | 1924 | 0.0674 | 1.10 | 1.33 |
| 0.500 | 15 | 0.954 | 1928 | 0.0700 | 1.09 | 1.26 |
| 0.800 | 10 | 0.997 | 1927 | 0.0670 | 1.06 | 1.16 |
| 1.200 | 7 | 1.036 | 1925 | 0.0684 | 1.00 | 1.10 |

0.100 seçildi: yörüngeye en yakın, ve devrim 1918 ile çapanın 1923'ünden
yalnızca beş yıl önce — tohum gürültüsünün içinde.

**Kalan sapma dürüstçe yazılıyor:** 0.340'lık log sapma sıfır değil. Mikro
kol geç on yıllarda çapadan **yavaş** kalıyor (q(1965) 3.29 / 5.69). Basamak
çarpanı ile çağ tavanının birlikte belirlediği bir şey; tarihsel ölçüt ve
devrim zamanlaması tuttuğu için B2b'den önce kovalanması gerekmiyor.

### Erken devrim: gerçek bir zincirdi, kalibrasyon hatasıydı

İlk kalibrasyonla (`maliyet = 0.05`) devrim 1903'e kayıyordu — kapalı formda
1923. `--v2-uretim-iz` zinciri gösterdi ve teşhis **eleme yoluyla** yapıldı:

| büyüklük | kapalı ↔ mikro | okuma |
|---|---|---|
| `pay` | 0.461 ↔ 0.461, 0.432 ↔ 0.435 | **aynı** — Goodwin kanalı değil |
| `PR` | ~0.99 ↔ ~0.99 | ikisinde de **doymuş** — protesto riski değil |
| `q` (1885) | 1.90 ↔ **3.70** | ayrışan bu |
| çağ (1885) | 1 ↔ **2** | ve sonucu bu |

Zincir: merdiven erken hızlı tırmanıyor → `q` çağın `q_esik`ini erken aşıyor
→ **çağ geçişi erkene kayıyor** → her geçiş `Omega`'yı zıplatıyor
(`gecis_omega`) → devrim erken geliyor.

> **Devrim `PR` üzerinden değil, ÇAĞ ZAMANLAMASI üzerinden kaymıştı.** İki
> aday kanalı (ücret pazarlığı, protesto riski) ölçüm eledi; ikisi de iki
> kolda aynıydı. Kalibrasyon düzeltilince devrim 1918'e döndü, yani çapadan
> beş yıl uzağa.

Bu, `q`'nun bu motorda yalnızca bir üretkenlik değişkeni olmadığını da
gösteriyor: **çağ tablosunun tetikleyicisi.** Mikro katmanın `q`'yu yazması,
farkında olmadan tarihin hızını da yazması demektir.

### Tarihsel kayıt mikro katmanla

`--v2-tarih-mikro` (aynı ölçüt, mikro katman takılı) **geçiyor**:

| | kapalı form | mikro katman | tarihsel |
|---|---|---|---|
| ham sicil toplamı (medyan) | 35.0 | **29.5** | 27 |
| ayrık olay, 2 yıl (medyan) | 21.0 | 21.0 | 24 |
| olay / 100 kapitalist yıl | 19.2 | 20.5 | 12.1 |
| devrim (tohum 42) | 1923 | 1918 | — |

Ham kriz toplamı 35.0'ten **29.5**'e iniyor, yani tarihsel 27'ye yaklaşıyor —
B1a'nın "fazla kriz-yatkın" fazlalığını mikro katman bir miktar kısıyor.
Sebebi muhtemelen sermayenin binalara gömülü ve departmanlar arası kaymanın
yavaş olmasıdır, ama **ölçülmedi**; iddia edilmiyor.

---

## 6c. B2b — sınıf kohortları

### Ölçüt üçüncü kez düzeltildi

Tablodaki ölçüt "Goodwin otoritesi pop katmanına geçer, salınım ölmez"di. Bu
da ayırt etmiyor: salınım B2b hiç yokken de var. Kohortlar olmadan
**kurulamayan** iddia şudur:

> Ücret payı pazarlanan bir skaler değildir. Pazarlık hiç olmasa bile **sınıf
> bileşimi** değiştiğinde ücret payı değişir.

`pay` bir skalerken "bileşim" diye bir şey yoktur; cümle telaffuz edilemez.
Kapı: **`--v2-nufus`**, 13/13.

### Saklanan dört, türetilen iki

§5.9 altı kohort sayıyor; burada dördü saklanır (`sermayedar`,
`kucuk_burjuva`, `kir_emegi`, `emek_gucu`), ikisi türer: `issiz =
emek_gucu·(1−e)` ve `hapis = emek_gucu·cezaevi_orani`. İşsizi saklamak bir
**döngü** kurardı — işsizlik istihdamdan, istihdam emek arzından, emek arzı da
işsizi içeren emek gücünden gelir. Türetmek o döngüyü yapısal olarak imkânsız
kılıyor.

**Geçişler çift üzerinde tanımlı**, `Dunya`nın kuralının aynısı: bir geçiş tek
yerde hesaplanır ve iki kohorta ters işaretle yazılır, yani `sum(kohort) ==
toplam_nufus` bir özdeşliktir. Ölçülen sapma **6.3e-15** (10 300 adım).

### Ölçülen

| iddia | ölçüm |
|---|---|
| kuruluşta emek arzı ve `pay` çekirdekle özdeş | **0.0** (ikisi de) |
| nüfus korunumu, kampanya boyunca | **6.3e-15** |
| küçük burjuva payı düşer (tasfiye) | 0.220 → 0.035 |
| kır emeği payı düşer (kentleşme) | 0.550 → 0.356 |
| emek gücü payı yükselir (**proleterleşme**) | 0.200 → **0.579** |
| **bileşim kanalı** (pazarlık donduruldu, karşı-olgusal) | **+0.0201** |

Bileşim kanalının ölçülme biçimi önemli: `pazarlik_sabit` bayrağı
`w_nom_buyume_yil`'i enflasyona eşitliyor, yani reel ücret düzeyi donuyor ve
`pay`ı hareket ettirebilecek **tek** şey bileşim kalıyor. Bayrak olmadan test
dışından dondurma işlemiyor — `_goodwin` her adımda yeniden hesaplıyor.

### Ücret payı bir DÜZEY değil, GÖRELİ ücret — bir kez yanlış kuruldu

İlk yazımda `pay = w · kütle / V` biçiminde, `w` bir ücret **düzeyi** olarak
kuruldu. Cebirsel olarak `pay ~ w/q` ediyor: `V` üretkenlikle büyüyor ama bir
düzey olarak `w` onu takip etmiyor. Ölçüldü — `pay` kampanyanın **%74'ünü**
`pay_taban`a çakılmış geçiriyor, bileşim kanalı ölü kalıyor (+0.00064) ve
**kapı yine de yeşil veriyordu**: yön doğru, mekanizma ölü.

Doğrusu: `w` bir **göreli** ücret (üretkenliğe oran), dinamiği çekirdeğin kendi
`d_pay`i, ve `pay = w · bileşim_çarpanı`. Bileşim dondurulunca çekirdeğe **tam
indirgeniyor** — "yeni katman eskisini özel durum olarak içerir" disiplini.
Düzeltmeden sonra bileşim etkisi 30 kat büyüdü (+0.0201) ve tabanda geçen süre
%74'ten **%23**'e indi.

> **Bir mekanizmanın YÖNÜ doğru çıkabilir ve mekanizma yine de ölü olabilir.**
> Yön denetimleri bunu yakalamaz. `--v2-nufus`'a bu yüzden **yozlaşma
> denetimleri** eklendi: ortalama işsizlik bandı, ve `pay`ın tabanda geçirdiği
> sürenin yarıyı aşmaması. Kapı ancak yozlaşmayı görebiliyorsa "yeşile boyamak
> için eşik gevşetilmedi" cümlesi anlam taşır.

### Yedek sanayi ordusu: yönü doğru, ADOPTE EDİLMEDİ

Marx'ta ücreti disipline eden şey istihdam düzeyi değil işsiz kütlesidir. Kanal
kuruldu ve yönü ölçüldü (açıkken ücret düzeyi daha düşük, −0.36). Ama çapaya
karşı tarandığında:

> **ÇAPA (nüfus katmanı yok): ort pay 0.4433**

| etki | ort pay | pay/çapa | tabanda | devrim |
|---|---|---|---|---|
| **0.00** | **0.3802** | **0.86** | **0.23** | **1926** |
| 0.05 | 0.3525 | 0.80 | 0.29 | 1924 |
| 0.20 | 0.3071 | 0.69 | 0.43 | 1924 |
| 0.60 | 0.2564 | 0.58 | 0.54 | 1925 |

Çapaya **en yakın olan 0.00**; her pozitif ağırlık ücret payını çapadan
uzaklaştırıyor.

> **Sebep çifte sayım — B2a'daki hatanın yeni kılığı.** Çekirdeğin Goodwin
> terimi `bos_e = emek_gerginlik − e_norm` üzerinden işsizlik kanalını **zaten**
> taşıyor. Üzerine ikinci bir işsizlik terimi eklemek aynı kuvveti iki kez
> saymaktır; B2a'da "sermaye yoğunluğu iki kez yazılmaz" diye kayda geçen
> kuralın aynısı.

Kanal **silinmedi, adopte edilmedi**: varsayılan 0.0, yönü ölçülmeye devam
ediyor. Goodwin'in kendi terimiyle **yer değiştirmesi** gerekir ve pazarlık
bloğunu yeniden yazmak B3'ün işi — örgütlü/örgütsüz ayrımı ve `bolunme` orada
kurulacak, özgün kanal orada tanımlanabilir hale gelecek.

Bir ara adım da denendi ve yetmedi: sabit `issiz_norm` yerine **hareketli**
norm (çekirdeğin `e_norm`u ile aynı gerekçe — kalıcı bir işsizlik kalıcı bir
kesinti değil yeni bir normal üretir). Ücret düzeyini 1.10'dan 1.15'e taşıdı,
yani sorunu çözmedi; hareketli norm yine de korundu çünkü kendi başına doğru.

### Kalan sapma

| | çapa | B2a+B2b |
|---|---|---|
| ort istihdam `e` | 0.6831 | **0.7752** |
| ort ücret payı | 0.4433 | **0.3802** (0.86) |
| devrim (tohum 42) | 1923 | 1926 |

İstihdam çapadan **daha iyi**, ücret payı çapanın %86'sı, devrim üç yıl geç.
Ücret payındaki fark kapatılmadı ve sebebi biliniyor: proleterleşme emek arzını
nüfus artışının üstünde büyütüyor (emek gücü nüfusun 0.75'inden 0.93'üne), yani
**yedek ordu kohortlardan kendiliğinden doğuyor**. Bu bir kusur değil B3'ün
zemini; orada `pay`ın tabanı `org` ile birlikte hareket edecek.

---

## 7. Doğrulama: ne taşınır, ne taşınmaz

| katman | v2'de |
|---|---|
| RNG akış paritesi, crc32, iz karşılaştırması | **düşer** — kâhin yok |
| 10 kabul bandı | **düşer** — eski kalibrasyonun kaydıydı |
| **9 mekanizma yön testi** | **TAŞINIR — tek ve birincil ölçüt** |

Sebep belgenin kendi epistemolojisinde (§9.14): *"kabul bantları kalibrasyonun
kaydıdır, bağımsız kriter değil; bağımsız olan yön testleridir"*. Yön testleri
**büyüklük değil yön** iddia eder, dolayısıyla yeni bir motorda da sınanabilir.

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

**Karanlık devlet için yeni yön testleri** (§4 mekanizması test edilebilir
olmalı, yoksa "çalışıyor" diyemeyiz):

| yeni test | iddia |
|---|---|
| Bölünme → örgütlenme | `bolunme↑` → `org` birikimi yavaşlar |
| Bölünme → ücret | `bolunme↑` → `pay` kazanımı düşer, `r` korunur |
| Rıza aygıtının bedeli | rıza kolu açık → `qg` düşer → uzun vadede `r` **daha çok** düşer |
| Zor aygıtının bedeli | zor kolu açık → `cezaevi_orani↑` → `l_etkin()↓` → `V↓` |
| Şehit etkisi | siyasi cinayet → kısa vadede `org↓`, orta vadede `Omega↑` |
| Karşı hareket | sendika/parti güçlü → `bolunme` birikimi tersine döner |

> **Kural:** B3 bitmeden B5'e geçilmez. Testleri geçmeyen bir motor Victoria
> kabuğuna sarıldığında **güzel görünen ama iktisadi olarak anlamsız** bir oyun
> olur — ve bu oynayarak fark edilmez.

---

## 8. Riskler

**8.1 Ölçekleme sessizliği.** §5.2. Tur→hafta dönüşümü her oran parametresini
etkiler; bazıları stok, bazıları akım — toplu çarpanla geçiştirilemez.

**8.2 Mikro-makro tutarsızlığı.** Mikro katman `pay` ve `e` üretiyor, Goodwin
bloğu `pay`'i **geri** yazıyor. Her alan için kimin otorite olduğu
kararlaştırılmalı, yoksa iki katman birbirini ezer.

**8.3 Başarım.** 5200 tik × ~100 ülke = 520 000 ülke-tik; v4.4'ün 1259 × 20'si
25 180'di, yani **~21 kat** ağır — üstelik bu yalnızca değer katmanı.

**8.4 Bölünme mekanizmasının dengesi.** §4 güçlü bir kol: yanlış kalibre
edilirse ya devrimi imkânsız kılar ya da etkisiz kalır. Karşı hareket (§4.4)
ve rıza aygıtının `qg` bedeli bu dengenin iki sigortasıdır; ikisi de yön
testiyle korunmalı.

**8.5 Kapsam.** B0–B3 iktisadi çekirdeği kurar ve tek başına anlamlı bir
oyundur; B4–B7 kademeli büyütülebilir.

**8.6 Kapalı ekonomi kriz üretmiyor — bu modelin KUSURU.**

B0 sonunda "bu modelde kriz uluslararasıdır, kapalı ekonomi istikrarlıdır"
diye yazmıştım. **Bu aşırı yorumdu ve geri alınıyor.**

Marx'ta kriz eğilimi sermayenin kendi içindedir: aşırı üretim işçilerin
toplam ürünü satın alamamasından, kâr oranının düşüşü organik bileşimin
yükselmesinden doğar. İkisi de dış ticaret gerektirmez. **Kapalı bir
kapitalist ekonomi krizsiz kalamaz.**

Ölçtüğüm ile çıkardığım ayrılmalı:

| ölçüm | çıkarım |
|---|---|
| Tek ülkeli koşu 198 yılda 0 kriz; v4.4'ün ABD'si de `talep_acigi=0` | ~~"kriz uluslararasıdır"~~ **yanlış** |
| | **doğrusu:** model, olması gereken krizi üretmiyor |

Kendi verim de bunu doğruluyordu ve okumamıştım: aynı dökümde, **çağ 1'de,
otomasyon yokken** Almanya `talep_acigi = 0.295`, Çin `0.303`. Yani v4.4'ün
19. yüzyıl aşırı üretim kanalı **vardır**; benim tek ülkeli parametrelemem
tesadüfen talebin bol olduğu bölgeye düşmüştü.

### B1a'da yapılanlar ve kalan

Üç mekanizma eklendi. **Üçü de gerekli, üçü birlikte hâlâ yeterli değil.**

**1. Yenileme yatırımı kârlılığa bağlandı.** v4.4'te brüt yatırım
`(g + δ)·K` idi; `δ·K` kârlılıktan bağımsız bir **talep tabanı** kuruyordu.
Marx'ta kârlılık kaybolunca kapitalist eskiyen sermayeyi yenilemez bile.
Artık `yenileme = taban + (1−taban)·sg(duyarlılık · (r−i)/i)`.

**2. Departman I / II kuruldu.** Bu **yapısal bir zorunluluktu**: tek mallı
bir modelde gerçekleşme krizi imkânsızdır, çünkü yatırım talebi ile tüketim
talebi aynı farksız hasılayı satın alır ve orantısızlık doğamaz. Artık
Departman I üretim aracı üretir (alıcısı yatırım), Departman II tüketim malı
(alıcısı ücret ve kamu), ve **ikisi birbirinin yerine geçemez**. Sermayenin
departmanlar arası yeniden dağılımı yavaştır — kriz tam da bu yavaşlığın
ürünüdür.

**3. Emek gerginliği eklendi.** `e` tanımı gereği 1.0'da doyar; emek bağlayıcı
kısıt olduğunda Goodwin terimi `bos_e = e − e_norm → 0` ile **ölür**.
Gerçekte tam istihdam ücret baskısının bittiği yer değil, en şiddetli olduğu
yerdir. Gerginlik 1.0'ı aşabilir ve pazarlığı yaşatır.

Sonuç: fiyat ve faiz artık **salınıyor** (`pi` 0.018→0.027→0.001→0.026,
`i` 0.005→0.023→0.032→0.005). Goodwin kanalı canlandı.

### Kalan sorun: salınım genliği trende göre çok küçük

Ölçüldü (1836–1956, haftalık):

| | değer |
|---|---|
| toplam talep / potansiyel hasıla | **1.27 → 1.86** |
| yatırım / potansiyel hasıla | 0.52 → **1.09** |
| kâr oranı | 0.098 → 0.053 |
| faiz | 0.005 → 0.032 |

Talep kapasiteyi kalıcı olarak aşıyor, dolayısıyla **hiçbir departmanda
satılamayan mal birikemiyor.** Kök neden nicel: `c/v` 8'e çıkınca yıllık
`K/Y ≈ 8` oluyor ve `δ = %7.6/yıl` ile **amortisman tek başına hasılanın
%60'ı** ediyor. Gerçek ekonomilerde bu oran %10–20'dir.

Ve `r` (0.05–0.10) faizin (0.005–0.03) çok üstünde kaldığı için kârlılık
sıkışması hiç bitmiyor; model kârlılık krizini ancak yayın **sonunda**
(2050–2100, `r → 0.005`) üretiyor. Yani **tek bir terminal kriz** çıkıyor,
tarihsel kayıt ise 198 yılda ~27 çevrimsel kriz istiyor.

> **Teşhis: mekanizmalar yerinde, genlik yetersiz.** Çevrim trendin
> etrafında salınmıyor, trendin üstünde düzgün ilerliyor.

Sıradaki adaylar, en umut vericiden başlayarak:

1. **Goodwin kazancı** (`phi`) ve **hızlandırıcı** çok zayıf — çevrimi
   büyütecek olan bunlar
2. **Kredi çevrimi** — `kredi_egilimi` ve borç limiti balonu besleyecek kadar
   büyük değil; Minsky hiç ateşlenmiyor (`varlik → 0`, çünkü `r > i_spec`)
3. **`kv`'nin sürüklenmesi** — `K/Y`'nin 8'e çıkması amortisman talebini
   şişiriyor; `kappa_v`'ye tavan ya da `δ`'nın sermaye kalitesiyle düşmesi


---

## 6d. B2c — mal piyasası

### Ölçüt dördüncü kez: "okunur" bir niyet, kapı değil

§6 B2c için "gerçekleşme krizi bir sayı değil kütle olarak okunur" diyordu.
Bu, öncekilerin aksine **ayırt ediyor** — stok olmadan cümle kurulamaz. Ama
"okunur" bir niyettir; kapıya çevrilmesi gerekti. Stok olmadan tanımsız olan
iddia:

> Aşırı üretim krizinin bir **süresi** vardır. Yığın birikince kapitalist dolu
> depoya üretim yapmaz; üretim kısılır, istihdam düşer, talep daha da düşer.

Bir akım bunu üretemez: "geçen dönem satılmadı" der ve susar. Bir stok "hâlâ
duruyor" demeye devam eder. Ölçüt bu yüzden **süre**dir, sıklık değil.

### Tek yapısal ekleme: `stok += uretim − satis`

Çekirdek satılamayan ürünü `satilamayan_I/II` diye tutuyordu ama bunlar
**akım**dı — dönem bitince buharlaşıyorlardı. Dört kategori (§5.10: tüketim,
sermaye, hammadde, lüks) artık stok taşıyor, satış `min(arz, talep)` ile
temizleniyor ve defter her dönem birebir kapanıyor. `max(0,…)` koruması
kampanya boyunca yalnızca **1.1e-15** mertebesinde ateşliyor — yani hiç.

### İlk iddia ters çıktı

"Stok krize süre kazandırır" diye yazmıştım. Ölçüldüğünde tam tersi çıktı:

| | stok yok | stok var, kısma yok | stok + kısma |
|---|---|---|---|
| aşırı üretim epizodu | 9 | 4 | **43** |
| ort. epizot süresi | **15.72 yıl** | 48.69 yıl | **2.07 yıl** |
| ort. talep açığı | 0.2247 | 0.7499 | 0.0881 |

Sebep anlaşılınca iddia da düzeldi. Stoksuz kolda `talep_acigi` bir akım
oranıdır ve onu geri çekecek hiçbir mekanizma yoktur: açık açılır ve
**onyıllarca açık kalır**. Yani orada "epizot" diye ölçülen şey bir kriz değil
**kalıcı bir durumdur** — tarihsel kayıtta öyle bir şey yok. Stok, yığını
üretimi kısarak temizliyor ve aşırı üretimi tekrar bir **olaya** çeviriyor.

> **Doğru ölçüt yön değil BANT.** İki kol da bandın dışındaydı — biri onlarca
> kat uzun, diğeri beş kat kısa. Tarihsel aşırı üretim krizleri 1–3 yıl sürer.

### Kalibrasyon — ve çapa bu kez tarihsel

B2a ve B2b'de çapa çekirdeğin kapalı formuydu. Burada olamazdı: kapalı formda
epizot 15.7 yıl sürüyor, yani çapa olacak büyüklük orada zaten bozuk.

| kısma | erime | epizot | ort süre | ort açık |
|---|---|---|---|---|
| 0.05 | 0.20 | 8 | 19.48 | 0.3504 |
| 0.20 | 0.20 | 13 | 9.30 | 0.1401 |
| 0.28 | 0.20 | 26 | 3.72 | 0.1026 |
| 0.30 | 0.20 | 27 | 3.65 | 0.0970 |
| **0.33** | **0.20** | **43** | **2.07** | **0.0881** |
| 0.36 | 0.20 | 50 | 1.46 | 0.0805 |
| 0.60 | 0.20 | 78 | 0.21 | 0.0349 |

> **İki çapa çelişiyor ve seçim kayda geçiyor.** Epizot **sayısı** için en iyi
> değer 0.30 (27 epizot, tarihsel 27 ile birebir); **süre** için 0.33 (2.07
> yıl). Süre seçildi çünkü B2c'nin iddiası süredir ve sayıyı `--v2-tarih`
> zaten kendi ölçütüyle kapılıyor. 43 epizot tarihsel 27'nin üstünde, ama bu
> B2c'nin getirdiği bir fazlalık değil: B1a'dan beri bilinen "model tarihten
> daha kriz-yatkın" özelliği.

### Orantısızlık ölçüldü

Kategoriler ayrışıyor: ortalama (en dolu − en boş) stok/üretim farkı **0.236**.
Biri dolarken diğeri boş — Marx'ın orantısızlık krizinin motordaki imzası, ve
tek bir `talep_acigi` skaleriyle **tanımsız**.

---

## 6e. B3 — karanlık devlet, bölünme ve karşı hareket

### Ölçüt beşinci kez düzeltilmedi — §7 baştan ayırt ediyordu

B1b, B2a, B2b ve B2c'de ölçüt dört kez düzeltilmek zorunda kalmıştı: eski
kapılar mekanizma eklenmeden de yeşil veriyordu. B3'te bu sorun yok. §7'nin
altı yön testinin altısı da `bolunme` olmadan **tanımsız** — bir kapı ancak
ölçtüğü şey yokken kurulamıyorsa gerçekten kapıdır.

Ama §7'nin listesi yön iddialarıdır ve B2b'nin dersi hâlâ geçerli (yönü doğru
bir mekanizma ölü olabilir). Kapı bu yüzden **üç kademelidir**: özdeşlik →
yön → canlılık. 33 denetim.

### Tek bir "karanlık devlet kadranı" yok — sekiz adlandırılmış taktik var

§4.6'nın temsil ilkesi bunu zaten şart koşuyordu ("mağdurları adlandırılmış,
bedelleri sayılmış politikalar; 'etkinlik' kolu gibi sunulmaz"). Ama gerekçe
temsilî olduğu kadar mekaniktir de: sekiz taktik tek ölçeğe indirgenseydi
hepsi aynı davranır ve **"bedeli kim ödüyor" sorusu motorda tanımsız kalırdı.**

| taktik | aygıt | bölünme | kendi kanalı |
|---|---|---|---|
| uyuşturucuya göz yumma | rıza | orta | `mafya_tolerans` → `uo` → lumpen → gasp → **spekülatif stok** (Minsky'yi besler) |
| cemaat / tarikat ağları | rıza | orta | eğitim tabanı aşınır |
| mistisizm, astroloji, evrim karşıtlığı, düz dünyacılık | rıza | düşük | **eğitim/bilim en ağır aşınma** → `qg` düşer |
| milliyetçilik, mülteci düşmanlığı, ırkçılık | rıza | **en yüksek** | topluluklar arası şiddet → `PR` sönümü |
| LGBT düşmanlığı, kadınlara baskı | rıza | yüksek | **katılım düşer** → canlı emek → `V` düşer |
| sendikal harekete baskı, grev kırma | zor | düşük | `org` doğrudan kırılır |
| muhalif tutuklama | zor | düşük | `cezaevi_orani` → `l_etkin`, `PC`, eğitim |
| paramiliter faşist gruplar, siyasi cinayet | zor | yüksek | **şehit stoku** → `org` kısa, `Omega` orta |

Milliyetçilik en ağır basar çünkü §4.1'in tarif ettiği şey tam olarak odur:
öfkenin **hedefini** sınıftan komşuya çevirmek. Ötekiler zemini hazırlar.

### v4.4'ün karanlık devleti dar değil TAMDI — taşınmamıştı

v2'nin ilk yazımında `uyusturucu_orani` ve `cezaevi_orani` **çıktı olarak**
taşınmış, onları **süren denklemler** taşınmamıştı. Yani iki alan çekirdekte
okunuyor ama hiçbir şey tarafından yazılmıyordu: lumpen kanalı, karseral
sönüm ve meşruiyet aşınması 198 yıl boyunca 0.0'da **ölü** duruyordu.

Taşınanlar (v4.4'ün kendi denklemleri, birim çevrimiyle): endojen mafya
toleransı, lojistik uyuşturucu yayılımı, karseral nüfus formülü, eğitim
birikimi (güvenlik harcamasının eğitimi dışlaması), nitelikli emek çarpanı.

Eklenenler (v4.4'te karşılığı yok): `bolunme` ve üç kanalı, sekiz taktik,
şehit stoku, **karşı hareket**, `topluluk_siddeti`, `sinif_basinci`.

### Çapa özdeşliği — ve neden gölge gerekti

Katman takılı değilken çekirdek **birebir** aynı (dokuz kapının dokuzu da
bayt bayt aynı çıktı verdi). Ama `nitelik` için bu yetmedi.

İlk yazımda `nitelik` **başlangıç değerine** göre normalize ediliyordu ve
özdeşlik kırıldı: taşınan eğitim denklemi kendi dengesine gidiyor (0.30 →
0.09), ham `nitelik` taktikler **kapalıyken bile** 0.9019'a düşüyordu. Yani
katmanı takmak tek başına `q` büyümesini %10 yavaşlatırdı — ve `q` yalnızca
üretkenlik değil **çağ tablosunun tetikleyicisidir**, yani bu sessiz yavaşlama
devrimin takvimini kaydırırdı. B2a'da tam olarak bu yaşanmıştı.

Çözüm dört **gölge değişken**: `tolerans_capa`, `uo_capa`, `cezaevi_capa`,
`egitim_capa`. Gerçekle aynı denklemleri koşarlar, tek fark taktik
terimlerinin sıfır olmasıdır. Böylece `nitelik` bir **düzey değil sapma**
ölçer ve taktikler kapalıyken oran birebir 1.0'dır.

### §4.3'ün kâr oranı iddiası ölçüldü ve TERS ÇIKTI

Belge şöyle diyordu:

> `q` büyümesi, LTRPF'ye karşı elindeki **tek karşı eğilimdir**. Karanlık
> devlet bugün devrimi öteler, **yarın kâr oranını daha da düşürür.**

**Bu motorda yanlış.** `qg` LTRPF'nin karşı eğilimi değil, **sebebidir**:
q yükselir → c/v yükselir → r **düşer**. Dolayısıyla q büyümesini aşındırmak
kâr oranını düşürmez, **yükseltir**.

| mistisizm 1.0 | çapa | taktik açık |
|---|---|---|
| eğitim (son) | 0.0882 | **0.0000** |
| `q` (son) | 20.01 | **15.87** |
| hasıla (ort) | 1570.5 | **1268.2** |
| **kâr oranı (son ⅓)** | 0.04915 | **0.06684** |

İddia düzeltildi: **rıza aygıtının bedeli kâr oranında değil, üretkenlik ve
hasıladadır.** Ortaya çıkan sonuç daha da çarpıcı — karanlık devlet, kârlılığı
aşındıran sürecin **kendisini** yavaşlatarak kâr oranını ayrıca korur; ödenen
bedel üretici güçlerin gelişimidir. §4.3'ün "geleceğini yiyerek satın alır"
tezi ayakta, ama yenen şey kâr oranı değil **hasıla**.

Rıza aygıtının kâr oranına giden asıl kanalı başkadır ve o tutuyor:
uyuşturucu → gasp → **spekülatif stok** (1955.65 → 2108.59), yani Minsky.

### §4.1'in "öfke yerinde kalır" iddiası — ölçüm iki kez düzeltildi

İlk kurulumda tam kapasite kol kullanıldı ve imza **tersine** çıktı: `Omega`
0.2377'den 0.0018'e çöküyordu. Sebep bölünme değil — uyuşturucu ve hapsetme
v4.4'ün **kendi yatıştırma kanallarıdır** (`lumpen_sonum`, `karseral_sonum`)
ve uyuşturulmuş ya da hapsedilmiş bir nüfus gerçekten öfkesini kaybeder.
Onlar öfkeyi **azaltır**; bölünme ise öfkeyi azaltmaz, **hedefini** değiştirir.

İkinci düzeltme: iddia `Omega` üzerinden kurulamaz. `Omega` bir **stoktur** ve
örgütlülükle **çarpılarak** birikir, dolayısıyla bölünmüş bir sınıfta daha
yavaş birikir. Ölçülmesi gereken **basınçtır**. Motora iki yeni çıktı eklendi:

```
sinif_basinci  ==  PR  +  topluluk_siddeti        (özdeşlik)
```

Saf bölünme (milliyetçilik 1.0) ile ölçüm:

| | çapa | bölünme |
|---|---|---|
| sınıfsal basınç | 0.7360 | **0.7853** (azalmıyor) |
| `PR` (sınıfsal ifade) | 0.7360 | **0.5939** (kırılıyor) |
| topluluklar arası şiddet | 0.0000 | **0.1914** |

`topluluk_siddeti` §4.6 gereği **görünür bir metriktir**, gizli bir çarpan
değil: sınıfsal kanaldan çekilen enerji yok olmaz, komşuya yönelir.

### §8.4'ün birinci riski gerçekleşti — ve mekanizmanın içinden çözüldü

§8.4: *"yanlış kalibre edilirse ya devrimi imkânsız kılar ya da etkisiz
kalır."* Birincisi gerçekleşti: bölünme devrimi ertelemiyor, **tümden
kapatıyordu**.

Sebep çekirdeğin eşik yapısının keskinliği: `pr_esik = 0.74`,
`pr_esik_omega = 0.06`, yani öfke tavana dayansa bile eşik ancak 0.68'e iner.
Çapa koşusunda `PR` 0.736 ile o eşiği **kıl payı** aşıyor — dolayısıyla `PR`'yi
%8'den fazla sönümleyen **herhangi** bir mekanizma devrimi sonsuza kadar kapatır.

Ölçüldü: sönüm tavanı 0.35'ten 0.05'e indirildiğinde bile (`PR` 0.580 → 0.728,
çapaya neredeyse eşit) devrim **575 yıllık ufukta bile** gelmiyordu. Yani
seçenek "mekanizmayı öldüresiye zayıflat" ile "devrimi imkânsız kıl"
arasındaydı; ikisi de kabul edilemez.

Üçüncü yol mekanizmanın kendi içindeydi ve Marx'ın kendi iddiasıdır:
**kriz sınıf çizgilerini gizlemez, görünür kılar.** Protesto sönümü `Omega`
ile zayıflar (`bolunme_omega_kirilma = 0.85`); yeterince derinleşmiş bir
öfkede bölünme anlatısı tutmaz.

> `pr_esik_omega`'yı büyütmek de bir seçenekti ve **reddedildi**: o sabit çapa
> koşusunu da değiştirir, yani B1/B2'nin bütün kalibrasyonunu kaydırırdı.
> Seçilen çözüm `bolunme = 0` iken özdeşlikle nötrdür.

Sonuç: devrim **1984 → 2241**, yani 258 yıl ertelendi ama olmaya devam ediyor.

### Bir mertebe hatası, ölçümle yakalandı

`sehit_org_yil` önce 0.30 seçilmişti. Çekirdeğin örgütlenme akımları yılda
**0.006–0.013** mertebesindedir (`org_kent_yil` 0.0059, `org_kriz_yil` 0.0081,
`org_baski_yil` 0.0130) — yani ilk değer otuz kat büyüktü. Sonucu: `org`
0.465'ten 0.04'e çöküyor, `Omega` onunla sönüyor ve devrim imkânsızlaşıyordu.

> **Yeni bir kanal eklerken büyüklüğü komşu terimlerle kıyasla.** Tek başına
> "makul görünen" bir sayı, motorun kendi ölçeğinde bir felaket olabilir.

### Karşı hareket dekor değil — iki katlı

§4.4 sendika ve partinin "karşı etkileri olmalı" diyordu. Motorda iki ayrı
katman olarak kuruldu:

1. **Geri çekme** — `bolunme` stokunu doğrudan eritirler. Ölçüldü: karşı
   hareket kapalıyken bölünme 1.0000'a dayanıyor, açıkken 0.7487'de duruyor.
2. **Direnç** — `parti_direnc` üç kanalın **üçünde birden** sönümlemeyi kırar,
   yani bilinçlendirme karanlık devletin kanallarını tek tek kapatır.

Canlılık denetimi: bölünme taktikler **açıkken bile** kampanyanın %85.1'inde
gerileyebiliyor. Yani yarış gerçekten iki taraflı.

### Tam kapasite — kapı değil kayıt

Sekiz taktiği birden tam kapasite kullanan bir devlet devrimi gerçekten
önler. Bedeli:

| | çapa | tam kapasite |
|---|---|---|
| `q` (son) | 20.0 | **15.0** |
| hasıla (ort) | 1571 | **916** |
| yeni değer `V` (ort) | 713 | **598** |
| devrim | 1984 | **yok** |

§4.3'ün tezi burada sayılarla duruyor: toplumsal barış satın alınabilir, ve
bedeli üretici güçlerin gelişimidir.

---

## 6f. B4 — savaş bir kriz çıkışı olarak

### Ölçüt beşinci kez düzeltilmedi

§6'nın tablosu B4 için tek cümle yazıyordu: **"savaş sonrası kâr oranı yukarı,
nüfus aşağı."** Bu, B1b/B2a/B2b/B2c'nin aksine baştan ayırt ediyor — savaş
katmanı olmadan kurulamaz bile, çünkü "savaş sonrası" diye bir an yoktur.

Ama tek başına yetmiyor, ve sebebi §3.2'nin kendi cümlesinde: *"savaş sermayeyi
imha eder, sermayenin imhası kâr oranını yükseltir."* Yani ölçüt bir **mekanizma
iddiasıdır**, bir sonuç gözlemi değil. `r = s/K` olduğu için `K`'yı yıkan
**herhangi** bir şey `r`'yi yükseltir; testin işi bunun savaş yıkımından
geldiğini göstermek. Kapı bu yüzden zinciri ayrı ayrı ölçüyor.

### Ana ölçüt — 3 tohum, 14 epizot

| | ölçüm |
|---|---|
| kâr oranı, savaş sonrası | **+0.02213**, 14/14 epizotta artıyor |
| nüfus, savaş sonrası | **−%13.20**, 14/14 epizotta azalıyor |
| sermaye stoku (karşı-olgusal) | savaşlı 666 239 < barışçı 868 674 |

Tek tohumda iki epizot bir ölçüm değil anekdottur; deponun kendi kuralı
(§10: "en az üç tohum gerekir") savaş için de geçerli.

### Savaş süresi v4.4'ten devralınmadı — tarihsel çapaya çekildi

v4.4 `sv_min_sure = 20`, `sv_max_sure = 70` **tur** diyor, yani 5.4–18.9 yıl.
Ölçüldü: ortalama savaş **15.3 yıl** sürdü ve epizot başına nüfus kaybı
**%31.8**'e çıktı — yönü doğru, büyüklüğü tarihin iki katından fazla. Çapa:
1. Dünya Savaşı 4 yıl (Fransa ~%4), 2. Dünya Savaşı 6 yıl (SSCB ~%13).

v2 v4.4'ün **kalibrasyonunu değil denklemlerini** devralır (§1). Süre 1.5–7
yıla çekildi; ortalama 6.4 yıl, kayıp %13.2 — 20. yüzyılın büyük savaşlarının
mertebesi.

> **Bir yön testi bandı olmadan yeşil verir.** İlk kalibrasyonda "nüfus aşağı"
> denetimi 14/14 geçiyordu — %31.8 kayıpla. Yön doğruydu, büyüklük saçmaydı.
> B2b'nin dersinin savaş biçimi: bant denetimi yön denetiminin yerini tutmaz.

### Muhasebe zinciri yanlış kuruldu, ölçümle düzeldi

İlk yazımda "savaş içinde `K` dip < `K` baş" diye ölçüldü ve **0/2 epizotta**
kaldı. Mekanizma yok değildi — ölçüm yanlış kurulmuştu: `K` savaş sırasında da
birikimle büyüyor, yani yıkım gerçek ama net düzey yine de yükselebiliyor.

Doğru soru "K düştü mü" değil, **"savaş olmasaydı K ne olurdu"** — yani
karşı-olgusal. Aynı tohum, savaş katmanı açık/kapalı: 666 239 vs 868 674.

### §3.1'in kanalları ölçüldü

| iddia | ölçüm |
|---|---|
| savaş **krizden doğar** (`sikisma = (sv_r_ref − r)/sv_r_ref`) | savaşa girenin kâr oranı 0.0586, girmeyenin 0.0662 |
| `saldirganlik` gerçekten o kol | 0.0'da **hiç** savaş yok, 0.35'te var |
| savaş **aşırı üretimi emer** | talep açığı savaşta 0.1455, barışta 0.2205 |

Üçüncüsü §3.1'in "aşırı üretim → yeni pazar, gerekirse zorla" satırının
motordaki en dolaysız biçimi: savaş gerçekleşme krizini **çözer**, çünkü
satılamayan ürün sorunu ortadan kalkar. Bedeli yıkımdır.

### Birim tuzağı denetimi

`sv_min_sure`/`sv_max_sure` tur cinsindendi; haftalık döngüye kopyalansaydı
savaşlar 14 kat kısa sürerdi. Haftalık ile aylık koşu aynı savaş yoğunluğunu
veriyor (%1.3 / %1.0), yani tuzağa düşülmemiş.

### Karşı-devrim kuruldu

Yenilen bir sosyalist rejimde kapitalizm zorla restore edilebiliyor
(`kd_askeri_olasilik`). §3.1'in "bir yerde devrim oldu → kuşatma, abluka,
müdahale" satırının en sert ucu. Emperyalist müdahale ayrıca ayrı bir kanal
olarak duruyor ve ayrı kapatılabiliyor — ikisi aynı kapıdan geçseydi hangi
kanalın sonucu ürettiği bilinemezdi.

### B3'ten devredilen ölçüm: karanlık devletin bedeli çok ülkeli dünyada

B3'te bir denge açığı ölçülmüştü — tek ülkeli koşuda karanlık devlet devrimi
önlüyor **ve** kâr oranını yükseltiyor, tek bedeli hasıla; zafer koşulu
olmadığı için kol neredeyse **bedavaydı**. Karar kayda geçmişti: *"önce
ölçelim, sonra karar."* B4 çok ülkeli dünyayı kurduğu için ölçüm artık yapıldı.

Ölçülen ülke "Orta", sekiz taktik tam kapasite, aynı tohum, aynı dünya:

| | karanlıksız | karanlık |
|---|---|---|
| ort kâr oranı | 0.0691 | **0.0983** |
| üretkenlik `q` | 20.01 | 14.22 |
| sermaye `K` | 50 136 | **3 773** |
| birikmiş `NX` | −4 790 | −3 328 |
| bileşik dış konum | −10 214 | −6 044 |
| devrim | 1922 | **yok** |
| **savaşta geçen dönem** | **0** | **160** |
| yenilgi | 0 | 0 |

**Karşı ağırlık doğdu ama zayıf.** Karanlık devlete sarılan ülke 13 kat
küçülüyor ve savaşa çekiliyor (0 → 160 dönem) — `guc() = K·q` çöktüğü için av
haline geliyor, `savas_karari`'nın hedef seçimi tam da zayıfı arıyor. Ama
henüz **yenilgi yok**, yani ceza fiilen kesilmiyor.

> **Karar hâlâ açık.** Ölçüm karşı ağırlığın var olduğunu gösteriyor ama
> yeterli olduğunu göstermiyor: kapitalist oyuncu için kâr oranı hâlâ yüksek,
> devrim hâlâ yok. Abluka ve ambargo (B4'ün kalan işi) bu tabloyu değiştirebilir
> — ülke zaten küçülmüşken dış pazarı da kesilirse ceza gerçekleşir. Tablo o
> mekanizmalar kurulduktan sonra tekrar okunmalı.

### B4'ün kalan işi

Savaş kuruldu. §3.3'ün ittifak/blok mekanizması (`muttefik` alanı hazır ama
işlenmiyor), abluka ve ambargo (`Dunya.aciklik` hazır ama savaşa bağlı değil),
ve himaye henüz yok.

### B4'ün kalanı kuruldu — abluka, ambargo, ittifak

**Abluka çift üzerinde tanımlıdır**, ve bu zorunluydu. Deponun kuralı açık:
"ülke başına çarpan uygulamak (abluka, açıklık) **çifte simetrik** olmalıdır",
ve v4.4'ün L bloğunu bozan şey tam olarak buydu (korunum hatası %57). Kesinti
çiftin **toplam hacmine** uygulanır; iki taraf aynı küçülmüş hacmi paylaştığı
için `sum(NX) == 0` kırılmaz. Ölçüldü: abluka açıkken bağıl korunum hatası
`< 1e-9`.

Üç kaynak, üçü de §3.1'in tablosundan: **savaş** (0.95 — tam kapanma değil,
kaçakçılık her savaşta vardır), **kuşatma** (devrim olan ülkeye, kuşatanın
saldırganlığıyla ölçeklenir), **ambargo** (rejim karşıtlığı + blok tehdidi).

İttifaklar: sosyalist pakt kendiliğinden kurulur; kapitalist ittifak **ortak
düşmana** bağlıdır. v4.4'ün `PYTHONHASHSEED` kusuru devralınmadı — dizi sıralı.

**§4.5 kapandı.** `otomatik` kolu artık sınanıyor: AI ülkeleri karanlık araca
kendiliğinden sarılıyor (en yüksek tolerans 0.887).

### Savaş sıklığı — çapa tutturulamadı, ve sebebi yapısal

Süre tarihsel çapaya çekilmişti; sıklık çekilmemişti. Ölçüldü ve **iki kez
şaşırttı**.

Önce `saldirganlik` tarandı: 0.20→0.90 aralığında sıklık 0.34 / 0.54 / 0.47 /
0.27 / 0.61 — **gradyan değil gürültü**. Sonra ayrı bir çarpan eklendi, 10 kat
büyütüldüğünde sıklık ancak 2 katına çıktı. Yani bağlayıcı kısıt **olasılık
değil**.

Hipotez ölçüldü: **hedef bulunabilirliği.** Hedef seçimi `guc < 1.15·guc`
istiyor; beş ülkeli ve ayrışmış bir dünyada zayıf ülkenin saldıracağı kimse
yok, güçlü ülke de savaşa girince kilitleniyor.

| ülke sayısı | zaman payı | savaş/ülke-yüzyıl |
|---|---|---|
| 5 | 0.013 | 0.27 |
| 10 | 0.016 | 0.34 |
| 20 | 0.033 | 0.79 |

Doğrulandı. Ve tarihsel çapanın (yüzyılda 1–4 savaş) kendisi zaten **50+
devletli** bir dünyadan geliyor.

> **Seçim 20 ülkelik kolda yapıldı, 5'te değil.** Kalibrasyon karar verilen
> kurulumda yapılır ve oyunun hedefi ~100 ülkedir (B6), test dünyası değil.
> `savas_siklik = 5.0` → 20 ülkede zamanın %6.9'u savaşta, yüzyılda 1.58 savaş
> — iki eksende de bantta. Beş ülkelik test kolunda oran daha düşük kalır ve
> bu beklenendir. **Ölçüt B6'da ~100 ülkeyle yeniden okunmalıdır.**

### Aynı ölçüm hatası üçüncü ve dördüncü kez

Sıklık 5'e çıkarılınca iki denetim düştü, ikisi de **ölçüm tasarımı** hatasıydı:

1. **Kâr oranı karşılaştırması trendi ölçüyordu.** İlan anındaki `r` kampanya
   geneli ortalamayla karşılaştırılıyordu; `r` 0.10'dan 0.04'e düştüğü ve
   ilanlar erken yıllarda kümelendiği için ilan edenler otomatik olarak yüksek
   çıkıyordu (0.0937 vs 0.0711). Eş-zamanlı kesitle ölçülünce **−0.0067**.
2. **Abluka dünya toplamıyla ölçülüyordu.** Abluka açıkken dünya hacmi *daha
   büyük* çıktı — abluka edilen ülkenin malları satılamayınca `_itki` onu kalan
   çiftlere daha sert asıyor, ve iki yörünge 198 yılda kaotik olarak ayrışıyor.
   Abluka edilen **çiftin kendi hacmiyle** ölçülünce: **1.9 / 61.6**.

> Bu ailenin dört üyesi oldu: mutlak `NX` yerine `NX/Y`, ham `l_etkin` yerine
> çarpan, kampanya ortalaması yerine eş-zamanlı kesit, dünya toplamı yerine
> çift hacmi. **Düzey karşılaştırması trendi ölçer, mekanizmayı değil.**
