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
| **B1b** | **DÜNYA.** Çok ülke, değer transferi (C, L) ✅, dış ticaret (B) ✅, ani duruş / moratoryum / döviz krizi (D, E, F) ✅ | **KURULDU** — beş kanal da yerinde, `--v2-dunya` 15/17 (iki açık kırmızı) |
| **B2** | **MİKRO KATMAN.** Sektör, sınıf kohortları, bina, üretim yöntemi, mal kategorileri (§5.8–5.11) | Mikro toplamlar değer katmanını besler; `--v2-tarih` hâlâ geçer |
| **B3** | **Bölünme ve karşı hareket.** `bolunme`, rıza/zor kolları, sendika ve parti (§4) | Altı yeni yön testi yeşil |
| **B4** | **Savaş ve diplomasi.** İttifak, abluka, ambargo — kriz çıkışı olarak (§3) | Savaş sonrası kâr oranı yukarı, nüfus aşağı |
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

1. **"Dış değer konumu bunalımı belirliyor"** −0.006'ya indi (tek kanal varken
   −0.80'di). Artık bunalımı belirleyen tek şey dış konum değil: borç yükü,
   temerrüt, döviz krizi ve ani duruş da aynı sonucu sürüklüyor. Ölçüt
   muhtemelen tek bir dış değişkene değil, **bileşik dış konuma** karşı
   yazılmalı — ama bu bir tasarım kararı.
2. **"Negatif toplam"** −0.03'e döndü, yani kavganın dünya toplamındaki etkisi
   D/E/F eklenince kayboldu. Borç kanalı kavganın etkisini yutuyor olabilir.

Her aşamanın kabul ölçütü ortak üç maddeyle biter: `--v2-olcek` 23/23
(B1a onu 18'den büyüttü), `--v2-tarih` geçer (B1'den sonra), ve ekran
değişmişse `--ss=` ile gerçekten çizdirilip bakılmış olur.

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
