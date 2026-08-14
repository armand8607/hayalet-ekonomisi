# CLAUDE.md

Bu depoda çalışan Claude Code oturumları için kılavuz. Önce bunu oku — koddan
anlaşılmayanları anlatır. Modelin kendi tam dokümantasyonu
[docs/hayalet_ekonomisi_v44_frozen.md](docs/hayalet_ekonomisi_v44_frozen.md)
içindedir; burada tekrarlama.

## Bu ne

"Hayalet Ekonomisi" — Marksist değer teorisini simüle eden çok ülkeli bir
makroekonomi oyunu. Motor **v4.4-Frozen**: 20 ülke, 1760–2100 arası 1259 tur,
LTRPF (kâr oranlarının düşme eğilimi) çekirdekli.

Godot 4.7 + GDScript, GL Compatibility. Halihazırda **motorun GDScript portu
sürüyor**; Python sürümü doğrulama kâhini olarak depoda durur ve oyuna girmez.

## Üç katmanlı depo

> **Godot proje kökü `godot/` alt klasörüdür, depo kökü değil.**

| klasör | ne |
|---|---|
| `docs/` | **Tek doğruluk kaynağı.** `hayalet_ekonomisi_v44_frozen.md` — model dokümantasyonu + iki Python dosyasının tam kaynağı |
| `python/` | Kâhin. Belgeden **türetilmiş** motor + dört kabul testi. Oyuna girmez, export'a dahil değil |
| `godot/` | Godot projesi. `project.godot`, `scripts/`, `scenes/` burada |
| `tools/` | Üretim ve karşılaştırma araçları |

**`python/hayalet_ekonomi_motoru_v43.py` ve `hayalet_ekonomisi_oyunu_v32.py`
TÜRETİLMİŞ DOSYADIR — elle düzenleme.** Frozen markdown'daki ` ```python `
bloklarından üretilirler:

```bash
python tools/extract_sources.py          # yeniden üret
python tools/extract_sources.py --check  # belgeyle aynı mı
```

Satır haritası (port sırasında referans çevirmek için):
`hayalet_ekonomi_motoru_v43.py:N` == `frozen.md:N+1891`

Aynı şekilde `godot/scripts/core/param_set.gd` ve `godot/scripts/tables.gd`
de **üretilmiştir** (`python tools/gen_gdscript.py`). 355 kalibrasyon sabitini
elle kopyalamak kabul edilemez bir risktir — tek basamak hatası motoru sessizce
değiştirir ve oynayarak fark edilmez.

## Nasıl çalıştırılır

```bash
python python/hayalet_ekonomisi_oyunu_v32.py turkey_2001 endojen 42 120
```

Godot tarafı (doğrulama koşuları). `--` sonrası her şey
`OS.get_cmdline_user_args()` ile `scripts/main.gd`'ye ulaşır:

```bash
"C:\Program Files\Godot\Godot.exe.exe" --headless --path godot res://scenes/Main.tscn -- --self-test
```

Argüman kapıları: `--self-test`, `--dump-rng`, `--dump-crc32`, `--dump-params`,
`--dump-formulas`, `--dump-agg`, `--dump-init`, `--dump-turn=N[:senaryo]`,
`--dump-scenario=AD`, `--dump-report=N[:senaryo]`, `--kabul=N`,
`--yon-testleri=N[:baş[:yalnızca]]`.

**Döküm kapıları yavaştır, motor değil.** Ölçüldü: maliyetin neredeyse tamamı
stdout'a satır basmaktan geliyor (~3 ms/satır), simülasyondan değil. Gerçek
maliyet **tur başına ~6,6 ms**, yani tam kampanya ~6–8 sn (CPython'un 2,4
katı). `--dump-turn=800` 24 sn sürerken `--yon-testleri` kampanya başına 6 sn
harcıyor; fark tamamen çıktı hacmi. Performans ölçerken bunu ayırmazsanız
olmayan bir darboğazı kovalarsınız.

## MOTORUN KENDİ KUSURU: `socialist_siege` yeniden üretilebilir DEĞİL

Bu bir port hatası değildir, **v4.4-Frozen'ın kendi kusurudur** ve belgenin
"Determinizm (aynı tohum, 3 süreç) GEÇTİ" iddiası bunu kaçırıyor.

`ittifak_isle` şu satırı içeriyor (`motor.py:3051`):

```python
a.muttefik.discard(self.rng.choice(list(a.muttefik)))
```

`muttefik` bir Python `set`'idir; `list(set)` sırası string hash'lerine, o da
`PYTHONHASHSEED` ile **sürece özgü** rastgeleliğe bağlıdır. Hangi müttefiğin
atıldığı bu yüzden koşudan koşuya değişebilir.

Ölçüldü (tohum 42, 200 tur, `socialist_siege`):

| PYTHONHASHSEED | 0 | 1 | 42 | 999 | 31337 |
|---|---|---|---|---|---|
| ekonomik çökme | 45 | 45 | **44** | **44** | 45 |

Beş tohumun **beşi de farklı** sonuç veriyor. Buna karşılık **varsayılan dünya
tutarlıdır** (4 hash tohumu × 1259 tur, birebir aynı) — çünkü orada sosyalist
`muttefik` her tur `sos` listesinden yeniden kuruluyor ve kapitalist ittifaklar
`choice` anına kadar nadiren birden çok üye taşıyor. `socialist_siege` ise
kümeyi **önceden dolduruyor** (`{"ABD", "Ingiltere"}`), tuzağı açan bu.

Sonuçları:

- Bu senaryoda **bit-birebir parite imkânsızdır**. İlk sapma tur 10,
  `Ingiltere.muttefik` (ikiye bölerek bulundu). Port doğru; kâhin kararsız.
- `mekanizma_testleri.py::test_sos_bolluk` — 9 yön testinden biri, yani
  belgenin **birincil** ölçütü — bu senaryoda koşuyor. Aşama 2'de o test
  bit-parite ile değil, tohum bazında yön/işaret ile değerlendirilmeli.
- Motor **DONDURULMUŞ** olduğu için düzeltilmedi. Düzeltmesi tek satırdır
  (`choice(sorted(a.muttefik))`) ama davranışı değiştirir, yani kalibrasyonu
  geçersiz kılar — bu kararı vermek bize düşmez.

## Nasıl yayına çıkar

İki iş akışı da `main`'e push'ta çalışır:

| iş akışı | çıktı |
|---|---|
| `.github/workflows/deploy.yml` | Web export → GitHub Pages |
| `.github/workflows/android.yml` | Debug APK → koşu **Artifacts**'ı, `v*` etiketinde **GitHub Release** |

- İkisi de `barichello/godot-ci:4.7` kabında derlenir. Android'e dair hiçbir şey
  yerel makinede kurulu değil; APK'yı yerelde derlemeye çalışma.
- **`godot/export_presets.cfg` BİLEREK izleniyor.** Godot'un standart
  `.gitignore`'u onu dışarıda bırakır (keystore parolası taşıyabilir diye) ama
  bizimki taşımıyor. İzlenmezse iş akışı "Web adlı ön ayar bulunamadı" ile
  düşer — bir kez böyle kuruldu, tekrar etme.
- Her iki iş akışı da export'tan önce `--import` ve `--self-test` koşar.
  `--import` şart çünkü depoda `.godot/` yok ve `class_name` çözümü taramaya
  bağlı; `--self-test` üretilmiş veri katmanı belgeden kaymışsa **yayımlamadan
  önce** durdurur.
- **`python/` kâhini export'a sızmaz**: Godot yalnızca `res://` altını, yani
  `godot/`u paketler. Alt klasör düzeninin bedava faydası.
- APK **yalnızca arm64** (`armeabi-v7a=false`), 2017 öncesi 32-bit telefonlar
  düşer.
- Web export tek iş parçacıklı; COOP/COEP başlığı gerekmiyor.
- `godot/web/orientation.js` ön ayarın `html/head_include`'u ile enjekte edilir
  ve `deploy.yml` tarafından `index.html`'in yanına **elle kopyalanır** — Godot
  kaynağı olmadığı için export onu taşımaz. Yeni web dosyası eklersen iş
  akışına da eklemen gerekir.
- **Depoda henüz git remote yok.** İş akışları ancak GitHub'a push edildikten
  sonra çalışır.

## Doğrulama — bu projenin omurgası

Motor, 100 doğrulama tohumuyla 10/10 kabul bandı ve 9/9 yön testi geçmiş
**donmuş** bir kalibrasyondur. Portun tek işi onu bozmamaktır. Her yapısal
değişiklikten sonra:

```bash
powershell -ExecutionPolicy Bypass -File tools\run_parity.ps1
```

Katmanlar, belgenin kendi epistemolojisine göre (§9.14, §10 — "kabul bantları
kalibrasyonun kaydıdır, bağımsız kriter değil; bağımsız olan yön testleridir"):

| katman | ne ölçer | durum |
|---|---|---|
| 1 | RNG akışı (`random`/`randint`/`choice`/`getrandbits`) | **GEÇTİ** — 12 451 satır birebir |
| 2 | crc32, 355 parametre, saf fonksiyonlar | **GEÇTİ** — 427 satır birebir |
| 3a | Dünya kurulumu (`--dump-init`) | **GEÇTİ** — 2765 satır birebir |
| 3b | Tur-tur iz (`--dump-turn=N`) | **tur 1–407 birebir** (tohum 42); 408'den sonra libm sapması — aşağıya bak |
| 3c | Senaryo odaları (`--dump-scenario=AD`) | **GEÇTİ** — 4 oda × 2771 satır birebir |
| 3d | Raporlama (`--dump-report=N`) | **GEÇTİ** — ≤1e-9 tolerans içinde (`statistics.mean` farkı) |
| 4 | 9 mekanizma yön testi (**birincil**) | **GEÇTİ** — 9/9, tohum 1–6, Python'la aynı |
| 5 | 10 kabul bandı (`--kabul=N`) | **GEÇTİ** — aşağıya bak |

**Katman 4 (`--yon-testleri=N[:baş[:yalnızca]]`)** — 6 tohum, ~7 dk. İki motor
aynı tohumlarda dokuz testin dokuzunu da geçiyor
(`python/baseline/yon_testleri_gdscript_6tohum.txt` ↔
`mekanizma_testleri_6tohum.txt`). Bu, belgenin kendi birincil ölçütüdür:
bantlar ayarlanabilir, yön ayarlanamaz.

İki test bu katmanın neden asıl kanıt olduğunu gösteriyor:

- **Minsky** parametreyi örnek bazında değiştiriyor (`P.fin_stok = 0`,
  `P.fin_pay = 0`) ve iki motoru aynı tohumla karşılaştırıyor. `ParamSet`'in
  `const` değil `var` olması bu yüzden zorunlu; tek paylaşılan sabit blok
  olsaydı test kendi kendini bozardı.
- **Sosyalist bolluk**, bit-paritesi *imkânsız* olan `socialist_siege`
  senaryosunda koşuyor (aşağıdaki `PYTHONHASHSEED` notu) — ve yine de 6/6
  geçiyor. Yön iddiası kâhinin kararsızlığına bağışık; ölçüt olarak bantlardan
  üstün olmasının sebebi tam olarak bu.

Katman 3b'nin 407 tur boyunca (5000+ alan × 407 tur) birebir tutması,
aktarımın doğru olduğunun asıl kanıtıdır.

**Katman 5, tohum 101–106, 1259 tur** — iki motor yan yana
(`python/baseline/*_kabul_6tohum.txt`):

| tohum | Python ↔ GDScript |
|---|---|
| 104, 105 | **tam kampanya boyunca BİREBİR AYNI** — libm sapması bu tohumlarda hiç tetiklenmiyor |
| 102 | pratikte aynı (LTRPF −0.9327/−0.9329, devrim 11/11) |
| 101, 103, 106 | aynı aralıkta; tek ulp'lik libm farkı kaotik olarak büyümüş |

Bantlar: LTRPF −%92.8, işsizlik 0.402, resesyon 11.6 yıl, Minsky 72.3 yıl,
kurumsal geçiş ~171, otomasyon 0.513, canlı emek 0.305, Polanyi her iki yönde
(81–85 ileri / 86–91 geri), liberale endojen dönüş 0. Hepsi bantta.

**Devrim ölçütü uyarısı:** 6 tohumda medyan 8.5 ile [0,8] bandının hemen
üstünde çıkıyor — ama **Python aynı 6 tohumda 9.0 veriyor**, yani bu bandın
dışına çıkmak portun değil örneklem büyüklüğünün sonucu. Belge de bunu söylüyor
(§10: "devrim sayısı tohuma duyarlı, en az üç tohum gerekir"). 20 tohumla
Python 7.0 veriyor ve bant tutuyor. **Bu ölçütü 6 tohumla değerlendirme.**

## Bit-birebir paritenin sınırı — ölçüldü

**Tam kampanya boyunca bit-birebir parite ULAŞILAMAZ**, ve bu bir port hatası
değildir: CPython ile Godot'un `libm` çağrıları son bitte ayrışıyor.
Deterministik bir ızgarada ölçüldü (`--dump-libm`):

| fonksiyon | örnek | ayrışan | oran |
|---|---|---|---|
| `exp` | 4000 | 31 | %0.78 |
| `log` | 2000 | 1 | %0.05 |
| `pow` | 2000 | 2 | %0.10 |

Hepsi **1 ulp**. Motor kaotik olduğu için tek bir ulp yüzlerce tur sonra
yüzlerce alana yayılır: tohum 42'de ilk sapma `G.Kore.BoP_R`'de, **tur 408**'de,
`sg()` içindeki `exp` çağrısından doğuyor.

Sonuç: **kabul ölçütü katman 4 ve 5'tir** (belgenin kendi ölçütleri, §9.14),
katman 3b değil. 3b bir *aktarım hatası dedektörüdür* ve işini yapmıştır —
aşağıdaki iki hatayı yakaladı, ikisi de oynayarak asla fark edilmezdi.

## Port sırasında yakalanan iki sessiz hata

Bunlar bu projenin en pahalı tuzaklarıdır; tekrar keşfetme.

- **`sum()` naif toplama DEĞİLDİR.** CPython 3.12 float dizileri için
  **Neumaier telafili toplama** kullanır. Motorun bütün dünya ortalamaları
  (`ort_cv`, `ort_sv`, `y_dunya`, `tot_L`, plan normalizasyonu…) `sum()` ile
  kuruluyor ve `VT_net` bunlara bölünüyor. Naif toplamayla port 1–3 ulp sapıyordu.
  `Formulas.py_sum()` kullan — **her yerde**. Ölçüldü: aynı 20 terim için
  `sum()` ile naif toplama `ort_cv_ham`/`ort_sv_ham`'da farklı,
  `top`/`ort_q_ham`/`tot_L`'de *tesadüfen* aynı çıkıyor; yani "çoğu yerde
  tutuyor" aldatıcıdır. **Bu davranış Python sürümüne bağlıdır** — 3.11 ve
  öncesi naif toplar, kâhin başka sürümle koşulursa parite kırılır.
- **`round(x, n)` ≠ `snappedf(x, 10^-n)`.** CPython sayıyı doğru yuvarlanmış
  ondalık metne çevirip geri okur (yarımda çifte yuvarlama); `snappedf` ise
  `floor(x/s + 0.5)*s` yapar. `Formulas.py_round()` kullan. Önemsiz görünür ama
  `bunalimlar` kaydındaki yuvarlanmış derinlik `kurumsal_gecis_isle` içinde
  `derin >= P.kg_derin_bunalim` eşiğine giriyor — bir ulp kurumsal rejim
  geçişini çevirebilir.

## Kaçınılmaz tek yapısal fark: `muttefik`

Python'da `muttefik` bir `set`, GDScript'te Set yok → `Array`. **Üyelik**
birebir aynı, **sıra** değil. `ittifak_isle` içinde
`rng.choice(list(a.muttefik))` sıraya bakar, yani hangi müttefiğin düşürüldüğü
ayrışabilir (RNG akışı aynı kalır — bir `_randbelow` çağrısı). Ölçüldü: motor
`PYTHONHASHSEED`'den bağımsız (4 hash tohumu × 1259 tur, birebir aynı), yani
sıra sonucu belirlemiyor. Parite dökümü bu alanı **sıralayarak** karşılaştırır.
Bir iz sapması savaş/ittifak olayında çıkarsa ilk şüpheli budur.

## Portun durumu

**Motor portu bitti.** `step()`, 13 yardımcısı, `load_scenario`, politika
API'si ve raporlama katmanı taşındı; doğrulama merdiveninin yedi basamağının
hepsi geçiyor. Kalan iş oyun katmanıdır (gösterge paneli, kalıcılık, CI).

`Sim` otoload'u oyun katmanının motora **tek kapısıdır** ve kendi duman testi
vardır (`--sim-test`, 31 denetim). Motorla karşılaştırılacak bir kâhini yok:
`Sim` motorda olmayan bir kavram, oyun katmanının kendi sözleşmesi.

Taban ölçümler `python/baseline/` altında. Belgenin §9.19'daki yayımlanmış
tablosuyla karşılaştırıldı ve tutuyor (LTRPF −93.0% / −93.0%, kurumsal geçiş
174 / 174, otomasyon 0.517 / 0.517).

Float karşılaştırmaları **IEEE754 bit deseni** üzerinden yapılır, ondalık
biçimlendirme üzerinden değil — yoksa "eşit mi" sorusu "nasıl yazdırdın"
sorusuna dönüşür.

## Bilinen tuzaklar

Her biri gerçek zamana mal oldu; yeniden keşfetme.

- **`zlib.crc32` teşhis değil MEKANİZMADIR.** `hayalet_ekonomi_motoru_v43.py:2711`
  (== `frozen.md:4602`) her ülkenin politika AI'sinin **hangi turda
  ateşleyeceğini** ülke adının crc32'siyle belirliyor. Atlanırsa bütün politika
  zamanlaması kayar. Kaynak yorumun notu: önce `hash()` kullanılıyormuş,
  `PYTHONHASHSEED` yüzünden aynı tohum ayrı süreçlerde ayrı sonuç veriyormuş.
- **Godot'un `RandomNumberGenerator`'ı kullanılamaz** — PCG32'dir. Motor
  CPython'un MT19937'sine bağlı. `PyRandom` (`scripts/core/py_random.gd`)
  zorunludur. Motorun RNG yüzeyi küçük: `random()`, `randint()`, `choice()`;
  `gauss` **yok**, o yüzden Box-Muller durumunu taklit etmek gerekmiyor.
- **`class_name` taşıyan yeni script headless koşuda görünmez.** Godot global
  sınıfları `.godot/global_script_class_cache.cfg` üzerinden çözer ve onu
  yalnızca editörün taraması kurar. `Identifier "Foo" not declared` alırsan bir
  kez: `Godot.exe.exe --headless --path godot --import`
- **`--headless` hiçbir şey çizmez, `_draw()` koşmaz.** Bozuk bir çizim
  headless koşuyu sessizce geçer. Gösterge paneli testleri bayraksız koşulmalı.
- **Android export ETC2/ASTC ister**: `project.godot` içinde
  `textures/vram_compression/import_etc2_astc=true` — oyunda hiç doku olmasa
  bile. Yoksa export "configuration error" ile durur.
- **Politika AI'sı test edilen politikayı ezer.** `set_plan_profili` ya da
  `set_temel_gelir` ile ölçüm yapılacaksa ya `oyuncu_ulkesi()` ile o ülke muaf
  tutulmalı ya da `P.ai_acik = false` yapılmalı (belge §10).
- **Politika kuyruğu adımın BAŞINDA boşalır, `t` ise SONUNDA artar.** `t=0`'da
  ilan edilen bir politika `etkin_t = 8` alır; `politika_kuyrugu_isle` her
  adımın başında `t >= etkin_t` diye bakar ve k'ıncı adım `t = k-1` ile başlar.
  Yani koşul ancak **9. adımda** sağlanır — 8 adım sonra hedef hâlâ eskidir.
  Arayüzde "gecikme 8 tur" yazarken bu bir tur kayması akılda tutulmalı.
- **GDScript lambda'ları DEĞERE göre yakalar.** `var x = {}; sinyal.connect(
  func(r): x = r)` dıştaki `x`'i değiştirmez — sinyal testleri sessizce hep
  "boş" görür. Sözlük/dizi gibi referans tiplerinin *içini* doldurmak gerekir.
- **`exp`/`log`/`pow` şu an bit-birebir uyuşuyor** (CPython 3.12 x86-64 Windows
  ↔ Godot 4.7 aynı makinede, 36 noktalık ızgarada). Bu **garanti değildir**:
  ızgara küçük ve wasm/ARM hedeflerinde ayrışabilir. Katman 3'ün toleransları
  bu yüzden yine de tanımlı kalmalı; "byte-identical" diye bir vaat verme.

## Mimari

Motor **veri güdümlüdür** ve otoload sırası yük taşır — her biri yalnızca
kendisinden öncekilere bağlıdır:

| # | otoload | sahibi olduğu şey |
|---|---|---|
| 1 | `Params` [params.gd](godot/scripts/params.gd) | donmuş kalibrasyonun fabrikası. Hiçbir şeye bağlı değil |
| 2 | `Tables` [tables.gd](godot/scripts/tables.gd) | ERAS, KURUMLAR, PLAN_PROFILLERI, dünya tohum tablosu (**üretilmiş**) |
| 3 | `Save` [save_service.gd](godot/scripts/save_service.gd) | `user://` erişen tek yer. Sürümlü, atomik, asla ölümcül değil |
| 4 | `Sim` [sim.gd](godot/scripts/sim.gd) | oyuncunun aktif koşusu + arayüz sinyalleri |

**Motorun kendisi otoload DEĞİLDİR** (`RefCounted` sınıf): Monte Carlo ve parite
koşuları aynı anda onlarca bağımsız örnek çalıştırır. `Params` de bu yüzden
`const` blok değil **fabrika** — testler parametreleri örnek bazında değiştirir
(`e.P.fin_stok = 0.0`), tıpkı Python'daki `self.P = Params()` gibi.

`core/` altındaki sınıflar: `PyRandom`, `Crc32`, `Formulas`, `History`,
`ParamSet` — ve portun hedefi olan `GhostEngine`.

`History` **sütun deposudur**, satır deposu değil: bir kampanya 20 ülke × 1259
tur × ~60 alan ≈ 1.5M değer eder. `PackedFloat64Array` kullanılır,
`Float32` değil — parite karşılaştırması binary64 gerektiriyor.

## Oyun tasarımı — sabit kararlar

- **Zafer koşulu yoktur** (§9.8). Koşu ufuk dolunca biter ve `tarihsel_rapor()`
  bir **tarihsel sonuç raporu** üretir. Devrim bir kayıp değil, oyuncunun
  elindeki politika setinin değişmesidir.
- **Bilgi katmanları bilinçli olarak düşürülmüştür** — sis yok, her şey görünür.
  Oyunun amacı mekanizmaların görünür olması; bilgi kıtlığı öğretici değeri
  düşürürdü. Arayüz bu yüzden **gösterge paneli + grafik**, harita değil.
- Bütün oyuncu API'si bir **ilandır**, anlık durum değişikliği değil:
  `pol_gecikme` (8 tur) sonra etkisi başlar, yerleşme hızı rejime göre değişir.
- Gösterge panelinin ekseni 12 çekirdek metriktir — `Sim.CEKIRDEK_METRIKLER`
  tek listedir, panel kendi listesini tutmaz.

## Konvansiyonlar

- Tipli GDScript, **tab** girinti, `##` doc yorumları.
- **Sıfır asset**, tower-defense projesindeki gibi: her görsel `_draw()` kodu.
  `.png`/`.wav` eklemeden önce sor.
- Yorumlar ASCII (Türkçe karaktersiz), kullanıcıya görünen metinler tam Türkçe.
- **Motorda mekanizma değişikliği yapma.** Belge "v4.4 ÖZELLİK AÇISINDAN
  DONDURULDU" diyor (§10). Port sırasında davranış düzeltmesi yapılmaz;
  birebir aktarılır, sapma bulunursa rapor edilir.
