# Oyun Tasarımı v2 — Büyük Strateji Katmanı

**Durum: TASLAK — karar kaydı, kod değil.** Bu belge oyun katmanının nereye
gideceğini yazar. Hiçbir maddesi `godot/scripts/core/` altını değiştirmeyi
gerektirmez; gerektiriyorsa §10'a taşınır.

| belge | neyi anlatır |
|---|---|
| [hayalet_ekonomisi_v44_frozen.md](hayalet_ekonomisi_v44_frozen.md) | **modeli** — iktisadi mekanizmalar, kalibrasyon, doğrulama |
| **bu belge** | **oyunu** — ekranlar, oyuncunun kolları, aşamalar |

İkisi birbirine karışmamalı. Model donmuştur; oyun değildir.

---

## 1. Hedef

Victoria 3 biçiminde bir büyük strateji oyunu kurmak — **ekonomik altyapısı
v4.4-Frozen motoru** olacak şekilde. Yani harita, ülke panelleri, diplomasi ve
güncе Victoria'nın kavradığı biçimde; ama arkada arz/talep dengesi değil
**kâr oranlarının düşme eğilimi** çalışacak.

### 1.1 Neden Victoria 3'ün kendisi değil

Victoria 3 kapalı kaynaktır. Mallar, üretim yöntemleri, kanunlar ve olaylar
script'tir ve moddanabilir; ama **ekonomik çekirdek derlenmiş C++ içindedir**:
pop davranışı, mal piyasası, fiyat oluşumu, birikim. Mod ile parametre
değiştirilir, **denklem değiştirilemez**.

Dolayısıyla "LTRPF'yi Victoria 3'e koymak" teknik olarak mümkün değildir. Bu
belgenin hedefi tersidir: **Victoria biçimini bu motorun etrafına kurmak.**

### 1.2 Ölçek dürüstlüğü

Victoria 3 yüzlerce insan-yılıdır. Bu belge onu hedeflemez. §8'deki Aşama A
tek başına oyunu tanınmayacak kadar zenginleştirir ve haftalar işidir. §10'daki
maddeler (pop, mal piyasası, bina, eyalet) **bilinçli olarak kapsam dışıdır**
ve neden olduğu orada yazılıdır.

---

## 2. Değişmez kısıt: motor donmuş

Motorun değeri kodunda değil, arkasındaki kanıttadır:

- Python kâhini ↔ GDScript portu, **407 tur bit-birebir**
- RNG akışı **12 451 satır** birebir
- **9/9** mekanizma yön testi (belgenin birincil ölçütü, §9.14)
- **10/10** kabul bandı, 100 doğrulama tohumu
- 355 kalibrasyon sabiti, belgeden **üretilmiş**

> **KURAL.** Aşama A ve B boyunca `engine.gd`, `country.gd`, `param_set.gd`,
> `tables.gd`, `formulas.gd` **değişmez.**

### 2.1 Bunun bedava verdiği regresyon testi

Motora dokunulmadığı sürece **yön testleri ve kabul bantları bit düzeyinde
aynı kalmalıdır.** Değiştiler mi, oyun katmanı yanlışlıkla motora sızmış
demektir.

Bu, oyun katmanı için bedava ve çok güçlü bir denetimdir; her aşamanın kabul
ölçütüne konuyor (§8):

```bash
Godot --headless --path godot res://scenes/Main.tscn -- --yon-testleri=6
# cikti python/baseline/yon_testleri_gdscript_6tohum.txt ile AYNI olmali
```

---

## 3. Ters çevrilen karar: harita

`CLAUDE.md` şu kararı taşıyor:

> **Bilgi katmanları bilinçli olarak düşürülmüştür** — sis yok, her şey
> görünür. Arayüz bu yüzden **gösterge paneli + grafik**, harita değil.

v2 bunun **yarısını** tersine çevirir, yarısını korur — ve ayrım kritik:

| eski karar | v2'de |
|---|---|
| Sis yok, bilgi kıtlığı yok | **AYNEN KORUNUR** |
| Harita yok | **kaldırılır** — harita gelir |

Gerekçe: harita bu oyunda bir **bilgi saklama** aracı değil, bir **bilgi
düzenleme** aracıdır. Victoria'nın harita modları (renk katmanları) tam olarak
budur — aynı görünür veriyi uzamsal olarak dizerler. 20 ülkenin kâr oranını
yan yana bir listede okumak ile haritada renk olarak görmek arasındaki fark
bilgi miktarı değil, **kavranabilirliktir**.

Sis, keşif, istihbarat belirsizliği gibi mekanikler **hâlâ yasaktır.** Oyunun
amacı mekanizmaların görünür olmasıdır.

---

## 4. Motorun elinde ne var

Tasarımın dayanabileceği zemin. Hepsi bugün mevcut, hiçbiri eklenmeyecek.

### 4.1 Dünya

20 ülke, **dünya sistemi konumuyla birlikte** (`tip`):

| konum | ülkeler |
|---|---|
| **merkez** | ABD, Almanya, İngiltere, Fransa, Japonya, Kanada, Avustralya, AB-blok |
| **yarı** | İtalya, G.Kore, Rusya |
| **çevre** | Çin, Hindistan, Brezilya, Meksika, Endonezya, Türkiye, S.Arabistan, G.Afrika, Arjantin |

Bu üçlü ayrım haritanın **birincil düzenleyici ilkesidir** (§6.1) — merkez/
çevre ilişkisi zaten motorun içinde çalışıyor, sadece görünmüyor.

**6 çağ:** 1.0 Buhar · 2.0 Elektrik · 3.0 Otomasyon · 4.0 Siber-fiz. ·
5.0 İnsan-YZ · 6.0 Tam otom.

**2 rejim** (kapitalist / sosyalist) × **3 kurumsal rejim** (liberal / düzenli
/ neoliberal).

### 4.2 Ülke başına ~120 alan

Tasarımda doğrudan kullanılacak olanlar:

| alan | ne |
|---|---|
| `r`, `q`, `K`, `Y`, `u`, `g` | kâr oranı, üretkenlik, sermaye, hasıla, kapasite, büyüme |
| `pay`, `e`, `org`, `canli_pay`, `oto` | ücret payı, istihdam, örgütlenme, canlı emek, otomasyon |
| `L_max`, `katilim`, `cezaevi_orani` | nüfus, katılım, hapis oranı |
| `Omega`, `PC`, `PR` | siyasi öfke, siyasi sermaye, protesto riski |
| `borc`, `varlik`, `i_ef`, `minsky_sayac` | hanehalkı borcu, spekülatif varlık, efektif faiz, Minsky |
| `FX`, `eps`, `pi_m`, `cari`, `BoP_R`, `deval` | kur, ihracat/ithalat esneklikleri, cari, rezerv, devalüasyon |
| `muttefik`, `savas`, `abluka`, `ambargo`, `hegemon` | diplomasi durumu |
| `kurum`, `rejim`, `parti_iktidari`, `pakt_durusu` | rejim durumu |
| `kriz`, `delev`, `stagflasyon`, `fx_kriz` | kriz sayaçları |

**Hazır türetilmiş metotlar** (`country.gd`):

```gdscript
l_etkin()         # L_max * katilim * (1 - min(0.90, cezaevi_orani))
iss_duzeltilmis() # ETG'ye gore duzeltilmis issizlik
guc()             # K * q  -- iktisadi/askeri guc
savasta()         # savas.size() > 0
atil_endeks()     # hapis / serbest orani
```

### 4.3 Olay güncesi — 23 tip, hazır

`motor.log` zaten Victoria'nın journal'ı gibi akıyor:

```
ASIRI URETIM · BUYUK BUNALIM · CAG · COKME · DEGISMEZ IHLALI · DEVRIM
DOVIZ KRIZI · DUNYA DEVRIMI · HEGEMONYA · KARSI-DEVRIM · KONTROL
KONTROL BITTI · KURUM · MORATORYUM · PIYASA SOS. · RESTORASYON · SAVAS
SENARYO · TEMERRUT · YENILGI
```

### 4.4 `Sim` API'si — arayüzün tek kapısı

Okuma: `ulke()`, `ulke_adlari()`, `seri()`, `metrik()`, `olaylar()`,
`bekleyen_politikalar()`, `kurumsal_insa_durumu()`, `tur()`, `yil()`,
`ilerleme()`, `bitti()`.

Yazma (hepsi **ilandır**, 8 tur gecikmeli): `temel_gelir_ilan()`,
`etg_finansman_ilan()`, `plan_profili_ilan()`, `pakt_durusu_ayarla()`,
`kurumsal_insa_ilan()`, `mafya_kilidi_ayarla()`.

Sinyaller: `kosu_basladi`, `tur_ilerledi`, `olay_eklendi`, `rejim_degisti`,
`kosu_bitti`.

---

## 5. Motorda olmayan ve bu tasarımda da olmayacak

Dürüstlük bölümü. Victoria 3'ün omurgası olan şu dört şey **yoktur**:

| Victoria 3 | motorda |
|---|---|
| Eyaletler, coğrafya | **yok** — hiç mekânsal boyut yok |
| Pop'lar (servet, ihtiyaç, meslek, siyaset) | **yok** — `pay`/`e`/`org` toplam oranlardır |
| ~50 mal, arz/talep, piyasa fiyatı | **yok** — tek toplam hasıla `Y` |
| Binalar, üretim yöntemleri, inşaat kuyruğu | **yok** — `K` ve `c/v` |

### 5.1 Neden eklenmiyor — teorik sebep

LTRPF denklemleri **toplam büyüklükler üzerine** yazılmıştır: `r`, `q`, `c/v`,
`pay`, `u` arasındaki ilişkiler. Pop ve mal piyasası eklenirse kâr oranı artık
*hesaplanan* değil, mikro katmandan **doğması gereken** bir büyüklük olur.

O noktada iki seçenek kalır:

- **(a)** motor otoriter makro katman kalır, mikro katman **türetilmiş görünüm**
  olur → kalibrasyon ve yön testleri sağlam kalır → **bu belgenin yolu**
- **(b)** ekonomi mikro-öncelikli yeniden kurulur, LTRPF'nin kendiliğinden
  çıkması umulur → yeni motor, yeni kalibrasyon, yeni kâhin → **§10**

(b) meşru bir araştırma programıdır ama **port değil, yeniden inşadır** ve
bugünkü doğrulama merdiveninin tamamını sıfırlar.

---

## 6. Ekranlar

### 6.1 Dünya haritası — yeni ana ekran

**Sıfır asset kuralı geçerli**: `.png` yok, her şey `_draw()`. Bu, gerçek
coğrafi kıyı çizgilerini dışarıda bırakır (§9.1 açık karar).

Önerilen biçim: **soyut dünya sistemi haritası.** 20 ülke düğüm olarak, üç
eşmerkezli kuşakta dizilir — merkez içte, yarı ortada, çevre dışta. Bu,
gerçek coğrafyanın veremeyeceği bir şeyi verir: **sömürü ilişkisi görünür
hale gelir.**

**Harita modları** (renk katmanı seçici — Victoria'nın kendi fikri):

| mod | kaynak |
|---|---|
| Rejim | `rejim` + `parti_iktidari` |
| Kurumsal rejim | `kurum` |
| Kâr oranı | `r` |
| İşsizlik | `iss_duzeltilmis()` |
| Örgütlenme | `org` |
| Siyasi öfke | `Omega` |
| Çağ | `era` |
| Dış denge | `BoP_R`, `cari` |
| Güç | `guc()` = `K·q` |

**Bağlar** düğümler arası çizgi olarak: ittifak (`muttefik`), savaş (`savas`),
abluka (`abluka`), ambargo (`ambargo`), hegemonya (`hegemon`).

### 6.2 Ülke paneli — sınıf diliyle

Victoria'nın pop panelinin karşılığı. **Yeni simülasyon değil, türetilmiş
görünüm** — her satır mevcut alanlardan hesaplanır:

| gösterilen | formül |
|---|---|
| Etkin emek gücü | `l_etkin()` |
| Çalışan | `l_etkin() · e` |
| İşsiz | `l_etkin() · (1 − e)` |
| Örgütlü emek | `l_etkin() · e · org` |
| Örgütsüz emek | `l_etkin() · e · (1 − org)` |
| Hapisteki nüfus | `L_max · katilim · min(0.90, cezaevi_orani)` |
| Emeğin hasıla payı | `pay` |
| Sermayenin hasıla payı | `1 − pay` |
| Canlı emek / ölü emek | `canli_pay` ↔ `oto` |

> Son satır **hapis oranını görünür kılar** — karanlık devlet kolunun insani
> bedeli bugün hiçbir ekranda yok, oysa motorda hesaplanıyor.

### 6.3 Kabine — politika ekranı

Mevcut beş kol korunur. **Eklenecek olan:**

- **`pakt_durusu`** ("ittifak" / "rekabet") — motorda var, arayüzde **yok**
- **Bekleyen ilanlar kuyruğu** — `bekleyen_politikalar()` hazır, arayüzde yok.
  Her ilan için "N tur sonra yürürlükte" gösterilecek.

> Kuyruğu göstermek §44'ün ("sis yok") gereğidir. Şu anki sessiz gecikme
> Aşama 4'te bilinçli bir tercihti; v2 onu görünür kılar, çünkü oyuncunun
> **ne zaman** ne olacağını bilmemesi bilgi kıtlığıdır, zorluk değil.
>
> **Bir tur kayması unutulmayacak:** kuyruk adımın BAŞINDA boşalır, `t` ise
> SONUNDA artar. `t=0`'da ilan edilen politika 9. adımda yürürlüğe girer,
> 8'incide değil.

### 6.4 Diplomasi

Motorda çalışan ama hiç görünmeyen katman: `muttefik`, `savas`, `abluka`,
`ambargo`, `ideolojik_mesafe`, `saldirganlik`, `hegemon`, `guc()`.

Aşama A'da **salt okunur** — kim kiminle, kim kime karşı, güç dengesi ne.
Oyuncu kolu yok; savaş kararı motorun AI'sinde.

> `muttefik` GDScript'te `Array`, Python'da `set`. **Üyelik** aynı, **sıra**
> değil. Arayüz bu diziyi sıralayarak göstermeli, yoksa aynı tohumda liste
> koşudan koşuya farklı sırada görünür.

### 6.5 Günce

23 olay tipi, tipe göre filtre, ülkeye göre filtre. Rejim kopuşları (`DEVRIM`,
`KARSI-DEVRIM`, `RESTORASYON`, `PIYASA SOS.`) ayrı vurgulanır — `Sim.kopuslar`
bunları zaten ayrı tutuyor.

### 6.6 Grafik paneli ve rapor

**Korunur.** 12 çekirdek metrik ve koşu sonu raporu bu oyunun öğretici
omurgasıdır; harita onların yerine değil **yanına** gelir.

---

## 7. Oyuncunun kolları

| kol | motor API | arayüzde | siyasi sermaye |
|---|---|---|---|
| Temel gelir hedefi | `set_temel_gelir` | ✅ | bedava |
| ETG finansmanı | `set_etg_finansman` | ✅ | bedava |
| Plan profili | `set_plan_profili` | ✅ (yalnız planlı) | bedava |
| Kurumsal inşa | `set_kurumsal_insa` | ✅ | **PC ≥ 0.8, maliyet 0.45, 60 tur arayla** |
| Karanlık devlet | `mafya_kilit` | ✅ | bedava |
| **Pakt duruşu** | `set_pakt_durusu` | ❌ **eklenecek** | bedava |

§9.8: siyasi sermaye **yalnızca yapısal değişiklikleri** kısıtlar. ETG düzeyi,
finansmanı ve plan payları siyaseten bedavadır.

---

## 8. Aşamalar

Her aşamanın kabul ölçütü aynı üç maddeyle biter:

1. `--sim-test` **31/31** geçer
2. `--yon-testleri=6` çıktısı taban ölçümle **birebir aynı** (motora
   dokunulmadığının kanıtı, §2.1)
3. Ekran `--ss=` ile **gerçekten çizdirilip bakılmış** olur — headless kapılar
   `_draw()` koşturmaz, bozuk yerleşim beş kapıyı da geçer

| aşama | iş | biter dediğimiz an |
|---|---|---|
| **A1** | Pakt duruşu + bekleyen ilanlar kuyruğu | Kabine ekranı altı kolu da gösterir, her ilanın kalan turu görünür |
| **A2** | Sınıf paneli (§6.2) | Ülke paneli dokuz satırı da türetir; hiçbir yeni durum alanı yok |
| **A3** | Dünya haritası + harita modları (§6.1) | 20 düğüm, üç kuşak, dokuz mod, bağlar çizili |
| **A4** | Diplomasi ekranı (salt okunur) | İttifak/savaş/abluka/ambargo ve güç dengesi okunur |
| **A5** | Günce filtreleri | Tipe ve ülkeye göre süzme |

**Aşama B** (§10'a girmeden): sunum düzeyinde sektör ya da kohort kırılımı —
birikim çekirdeğine dokunmadan. Tasarımı A bittikten sonra yazılacak.

---

## 9. Açık kararlar

Bunlar **karar bekliyor**; tahminle ilerlenmeyecek.

**9.1 Harita biçimi.** Soyut dünya sistemi (üç kuşak) mı, kabaca coğrafi
yerleşim mi? Sıfır asset kuralı gerçek kıyı çizgilerini dışarıda bırakıyor;
coğrafi görünüm istenirse ya elle girilmiş poligon verisi gerekir ya da
kuralın gevşetilmesi. **Öneri: soyut kuşak haritası** — hem kuralı korur hem
merkez/çevre ilişkisini görünür kılar.

**9.2 Zaman ölçeği.** 1 tur = 0.27 yıl, 1259 tur. Victoria haftalık tikler.
Tur uzunluğu **motorun kalibrasyonuna gömülüdür, değiştirilemez.** Soru şu:
arayüz turu mu gösterecek, yılı mı, yoksa ikisini mi?

**9.3 Zaman aralığı.** 1760–2100. Victoria 1836–1936. Senaryo odaları
(`golden_age_1950`, `neoliberal_1995`, `turkey_2001`, `socialist_siege`) daha
kısa kampanyalar sunuyor — büyük strateji için varsayılan hangisi olmalı?

**9.4 Ülke değiştirme.** Şu an bir koşuda tek ülke oynanıyor (`ai_muaf`).
Devrim sonrası ülke değiştirme ya da blok yönetimi düşünülmeli mi?

**9.5 Panel mi harita mı ana ekran?** Harita gelince 12 grafik nereye gider —
ayrı sekme mi, yan panel mi?

---

## 10. Aşama C'ye ertelenenler

Şunlar **bu belgenin kapsamı dışındadır** ve yapılmak istenirse §5.1'deki (b)
yolu, yani **yeni bir motor** demektir:

- Eyalet/bölge kırılımı ve gerçek coğrafya
- Pop'lar (servet, ihtiyaç, meslek, siyasi tutum taşıyan nesneler)
- Mal piyasası, arz/talep, piyasa fiyatı
- Binalar, üretim yöntemleri, inşaat kuyruğu
- Ticaret rotaları

Bunlara girilecekse **v4.4 silinmez, v5 açılır**: donmuş sürüm referans olarak
durur, yeni model onun yanına kurulur ve aynı yön testleriyle sınanır.
Karşılaştırılabilirlik kaybedilirse "değişikliğim iyileştirdi mi bozdu mu"
sorusu **cevapsız** kalır — bu projede en pahalı kayıp budur.
