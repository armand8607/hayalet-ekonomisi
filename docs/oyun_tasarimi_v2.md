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

---

## 6. Aşamalar

| aşama | iş |
|---|---|
| **B0** | **Kriz çekirdeğinin ayıklanması.** A–T blokları saf modül haline gelir, oran parametreleri haftalığa ölçeklenir |
| **B1** | **Mikro katman iskeleti.** Eyalet, pop, bina, üretim yöntemi, mal piyasası — tek ülkede, haritasız |
| **B2** | **Kuplaj.** §2.3 tablosunun bağlanması |
| **B2b** | **Bölünme ve karşı hareket.** `bolunme` değişkeni, rıza/zor kolları, sendika ve parti karşı kuvvetleri (§4) |
| **B3** | **Yön testleri yeşile.** Dokuz iddia + karanlık devlet için yeni yön testleri |
| **B4** | **Dış katman.** İttifak, abluka, ambargo, savaş — kriz çıkışı olarak (§3) |
| **B5** | **Harita.** Eyalet geometrisi, harita modları, ülke seçimi |
| **B6** | **Ölçek.** Tam dünya, başarım ölçümü |
| **B7** | **Arayüz.** Victoria düzeni: harita ana ekran, paneller, günce, diplomasi |

**B0 ve B3 en kritik ikilidir.** B0 yanlış yapılırsa motor sessizce yanlış
koşar; B3 onu yakalayan tek şeydir.

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

**8.6 Konjonktür dalgası ülke-içi değil, ULUSLARARASI — B0'da ölçüldü.**

Ülke-içi çekirdek tek başına koşturulduğunda **sıfır kriz** tescil ediyor.
İlk teşhisim "yatırım talebi kaçıyor" idi; **yanlıştı**. v4.4'ün kendisiyle
karşılaştırıldı (`--dump-turn=200`, `=1000`):

| | v4.4 ABD (merkez) | v4.4 Almanya | v4.4 Çin |
|---|---|---|---|
| istihdam | `e = 1.000` | `e = 0.429` | `e = 0.537` |
| talep açığı | `0.0000` | `0.295` | `0.303` |
| kriz sayacı | `0` | `18` | `147` |

Tur 200'de 20 ülkenin **yalnızca 9'unda** talep açığı var; ABD'de yok. Tur
1000'de ABD hâlâ `e = 0.978`. Yatırım payı da eşleşiyor: v4.4 ABD `I/Y = 0.478`.

> **Yani v4.4'ün merkez ülkesi de sakindir.** Tek ülkeli, savaşsız, ticaretsiz
> bir koşu v4.4'ün en sakin ülkesini üretir — çekirdek tam da onu üretiyor.
> Kusur çekirdekte değil, **eksik olan dünyada**.

Krizleri üretenler: ülke heterojenliği, değer transferi, savaş, abluka,
ticaret şoku ve politika AI'si. Hepsi B2'de gelir.

**`--v2-tarih` B2 bitmeden geçemez ve geçmesi beklenmemelidir.** O test bir
kalibrasyon hedefi değil, **dünya katmanının gerekliliğinin kanıtıdır.**

**Teorik sonuç — ve bu tasarımı doğruluyor:** bu modelde kriz
**uluslararasıdır**. §3'te savaşı ve emperyalizmi "krizden çıkış yolu" diye
koymuştuk; ölçüm daha güçlüsünü söylüyor: emperyalizm dekor değil,
**krizlerin doğduğu yerdir**. Tek bir kapalı ekonomi istikrarlıdır; kriz
dünya sisteminin ürünüdür.
