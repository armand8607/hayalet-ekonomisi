# CLAUDE.md

Bu depoda çalışan Claude Code oturumları için kılavuz. Önce bunu oku — koddan
anlaşılmayanları anlatır. İki referans belge var, ikisi de burada tekrarlanmaz:

| belge | ne |
|---|---|
| [hayalet_ekonomisi_v44_frozen.md](docs/hayalet_ekonomisi_v44_frozen.md) | v4.4 motorunun tam dokümantasyonu + iki Python dosyasının kaynağı |
| [oyun_tasarimi_v2.md](docs/oyun_tasarimi_v2.md) | **v2 oyununun karar kaydı** — mimari, aşamalar, ölçütler |

## Bu ne

"Hayalet Ekonomisi" — Marksist değer teorisini simüle eden çok ülkeli bir
makroekonomi oyunu. Godot 4.7 + GDScript, GL Compatibility.

**Depoda iki motor var ve karıştırılmamalı.**

**v4.4-Frozen** — 20 ülke, 1760–2100 arası 1259 tur, LTRPF çekirdekli.
Portu **bitti**, oyunu oynanabilir ve yayında (Pages + APK). Python sürümü
doğrulama kâhini olarak durur, oyuna girmez.

**v2** — `godot/scripts/v2/` altında kurulmakta olan **yeni** oyun: Victoria
biçiminde büyük strateji, haftalık tik, 1836–2100. v4.4'ün denklemlerini
kullanır ama kalibrasyonunu, tur yapısını ve ülke kümesini kullanmaz. v2 için
**v4.4 artık otorite değil, denklem kaynağıdır** (bkz. tasarım belgesi §1).

> Aktif geliştirme v2'dedir. v4.4 dondurulmuştur ve öyle kalır — v2'de bir
> mekanizma değiştirmek v4.4'te değiştirmek anlamına GELMEZ; v2'nin kendi
> dosyaları vardır ve v4.4'e dokunmadan değişir.

## Üç katmanlı depo

> **Godot proje kökü `godot/` alt klasörüdür, depo kökü değil.**

| klasör | ne |
|---|---|
| `docs/` | **Tek doğruluk kaynağı.** `hayalet_ekonomisi_v44_frozen.md` (v4.4 + Python kaynağı) ve `oyun_tasarimi_v2.md` (v2 karar kaydı) |
| `python/` | Kâhin. Belgeden **türetilmiş** motor + dört kabul testi. Oyuna girmez, export'a dahil değil |
| `godot/` | Godot projesi. `project.godot`, `scripts/`, `scenes/` burada. `scripts/v2/` **ayrı motordur** — v4.4 dosyalarına dokunmaz |
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

Üçüncü üretilmiş dosya **`godot/scripts/v2/data/harita_verisi.gd`**
(`python tools/gen_harita.py`) — B5'in harita geometrisi, kaynağı **Natural
Earth 110m** (kamu malı). Elle çizilmiş bir dünya haritası hem binlerce sayı
hem de **kaynaksız** olurdu. `--check` kaynağı yeniden indirip karşılaştırır
ama **CI'da koşmaz**: denetim bizim dışımızdaki bir deponun `master` dalına
bağlanırdı. Verinin doğruluğunu `--v2-harita` **yapısal** olarak sınar.

## Nasıl çalıştırılır

Oyunu **oynamak** için (Windows): `tools\oyna.bat`. Godot'u `%GODOT%` →
bilinen kurulum yolları → PATH sırasıyla arar, `.godot/` yoksa bir kez
`--import` koşar ve oyunu açar. Masaüstüne kısayol:
`powershell -ExecutionPolicy Bypass -File tools\masaustu_kisayolu.ps1`.

Kâhin:

```bash
python python/hayalet_ekonomisi_oyunu_v32.py turkey_2001 endojen 42 120
```

Godot tarafı (doğrulama koşuları). `--` sonrası her şey
`OS.get_cmdline_user_args()` ile `scripts/main.gd`'ye ulaşır:

```bash
"C:\Program Files\Godot\Godot.exe.exe" --headless --path godot res://scenes/Main.tscn -- --self-test
```

Argüman kapıları — **v4.4**: `--self-test`, `--sim-test`, `--dump-rng`,
`--dump-crc32`, `--dump-params`, `--dump-formulas`, `--dump-libm`,
`--dump-agg`, `--dump-init`, `--dump-turn=N[:senaryo]`, `--dump-scenario=AD`,
`--dump-report=N[:senaryo]`, `--kabul=N`, `--yon-testleri=N[:baş[:yalnızca]]`.

**Oyun**: `--oyna[=kayıt:tohum:ülke:tur]`, `--menu`, `--ss=DOSYA`.

**v2** (hiçbiri v4.4'e dokunmaz): `--v2-olcek` (ölçek değişmezliği, 23 denetim),
`--v2-tarih` (1825–2023 tarihsel kayıt), `--v2-tarih-mikro` (aynısı, iki mikro
katman takılı), `--v2-dunya` (dünya katmanı, 17 denetim), `--v2-uretim`
(üretim katmanı, 17 denetim), `--v2-nufus` (sınıf kohortları, 13 denetim),
`--v2-mal` (mal piyasası, 7 denetim), `--v2-bolunme` (karanlık devlet,
bölünme ve karşı hareket, 33 denetim), `--v2-savas` (savaş bir kriz çıkışı
olarak, 23 denetim), `--v2-dunya-siddet`, `--v2-dunya-ayrim`,
`--v2-uretim-tarama`, `--v2-nufus-tarama`, `--v2-mal-tarama`,
`--v2-bolunme-tarama` ve `--v2-savas-tarama` (kalibrasyon taramaları — tanı,
ana kapıdan yavaş), `--v2-harita` (harita, 44 denetim — **tam kampanya koşar,
~4 dk**), `--v2-harita-veri` (yalnızca geometri/izdüşüm/isabet, ~2 sn — tanı),
`--v2-harita-goster[=yıl[:tohum[:mod]]]` (haritayı **çizer**, `--ss=` ile
birlikte; `--headless` çizmez), `--v2-b6` (ölçek: tam kadro 113 ülke,
7 denetim — **~5 dk**), `--v2-olcek-tarama` ve
`--v2-savas-siklik=DEĞER[:ülke]` (B6 tanıları),
`--v2-iz[=YIL[:baş[:dönem]]]`, `--v2-uretim-iz` ve `--v2-oyun-iz[=YIL]`
(teşhis izleri).

**Oyun kabuğu (B7).** `--v2-oyun` kapıyı koşar (35 denetim, ~1 dk).
`--v2-menu` kampanya kurulum ekranını,
`--v2-oyna[=KOD[:tohum[:yıl[:kadro[:panel]]]]]` doğrudan oyun ekranını açar;
`panel` = `ulke|politika|gunce|yok`. **İkisi de `--headless` ile anlamsızdır**
(`_draw()` koşmaz) — `--ss=` ile birlikte `xvfb-run` altında koşulmalı:

```bash
xvfb-run -a -s "-screen 0 1600x900x24" ./Godot_v4.7-stable_linux.x86_64 \
    --path godot res://scenes/Main.tscn --resolution 1600x900 \
    -- --v2-oyna=TUR:42:60:16:politika --ss=/tmp/b7.png
```

> **`kadro` verilirse oyuncunun ülkesi kadroya ZORLA eklenir.**
> `Harita.kapi_kodlar(n)` sabit bir alt kümedir ve TUR'u içermiyordu; görsel
> kapı sessizce **gözlemci** kipine düşüyor, bütün kollar kapalı çıkıyordu —
> yani sınanmak istenen ekran hiç çizilmiyordu.

**Godot yoksa (Linux / uzak oturum):** binary'yi indirmek yeterli, kurulum
gerekmiyor. Ölçüldü — `--headless` için xvfb bile gerekmez:

```bash
curl -sSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
unzip -q godot.zip && chmod +x Godot_v4.7-stable_linux.x86_64
./Godot_v4.7-stable_linux.x86_64 --headless --path godot --import   # bir kez
./Godot_v4.7-stable_linux.x86_64 --headless --path godot res://scenes/Main.tscn -- --v2-savas
```

`--import` şart ve depoda `.godot/` olmadığı için ilk iş odur. Sekiz v2
kapısının tamamı ~7 dakika sürer. **Ekranı görmek** için `--ss=` kapısı hâlâ
`xvfb-run` ister (aşağıya bak); yalnızca headless doğrulama koşuları
gerektirmez.

> **v2'de SAYAÇLAR dönem cinsindendir, tur cinsinden DEĞİL.** v4.4'ün bütün
> `*_sure` sabitleri 0.27 yıllık tur cinsindendir; haftalık döngüye olduğu gibi
> kopyalanırsa **14 kat hızlı** dolar. Bir kez yaşandı: `fx_baski >= 8` (v4.4'te
> 2.16 yıl, haftalıkta 0.15 yıl) döviz krizini salgına çevirdi — 198 yılda ülke
> başına 22 kriz — ve dünya katmanının ana ölçütünü sessizce yok etti.
> `Oran.v44_sayac(tur, donem_yil)` kullan.

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

| iş akışı | ne zaman | çıktı |
|---|---|---|
| `.github/workflows/v2-kapilar.yml` | **her dala** push + PR | on v2 kapısı + iki v4.4 kapısı + türetilmiş dosya denetimi (~17 dk) |
| `.github/workflows/deploy.yml` | `main`'e push | Web export → GitHub Pages |
| `.github/workflows/android.yml` | `main`'e push | Debug APK → koşu **Artifacts**'ı, `v*` etiketinde **GitHub Release** |

**Kapılar gerçekten düşebiliyor — doğrulandı.** `_dogrula`ya kasten
`kosul = false` konup koşuldu: `SONUC: 0 geçti, 7 kaldı` ve `rc=1`.
`main.gd` `get_tree().quit(cikis)` ile çıkış kodunu taşıyor. Bu denetim
olmadan yeşil bir CI hiçbir şey iddia etmez; yeni bir kapı eklerken aynı
şekilde bir kez bozup kırmızıya döndüğünü gör.

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

**v4.4 bitti — motor da, oyun katmanı da.** `step()`, 13 yardımcısı,
`load_scenario`, politika API'si ve raporlama katmanı taşındı; doğrulama
merdiveninin yedi basamağının hepsi geçiyor. Gösterge paneli, menü, rapor
ekranı, kalıcılık ve CI da yerinde: oyun oynanabiliyor ve iki iş akışıyla
yayına çıkıyor. **v4.4 tarafında kalan iş yok**; yeni geliştirme v2'dedir.

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
  Ekranı **görmenin** yolu `--ss=` kapısıdır; başsız bir makinede bile
  `xvfb-run -a -s "-screen 0 1280x720x24" Godot --path godot
  res://scenes/Main.tscn -- --oyna=:42:Turkiye:600 --ss=panel.png` ile çalışır
  (Mesa llvmpipe yeter). Rapor ekranının sol boşluğunun hiç uygulanmadığı
  böyle yakalandı — beş doğrulama kapısının hepsi o hatayı geçiyordu.
- **v4.4'ün metrik listesini v2'ye KOPYALAMA — birimler aynı değil.**
  v2'de `borc` ve `varlik` mutlak **stoktur**; v4.4'te normalize edilmişti.
  Panel "Hanehalkı borcu / Y" etiketiyle ham stoku gösteriyordu: Osmanlı'da
  **244.34**, düzeltince 1.90. Çekirdek ikisini de her kullandığı yerde
  `Y_yil`'e bölüyor (`kriz_cekirdegi.gd:499, 550, 966`). `Gecmis` metriğine
  `"payda"` verilir. Beş headless kapının beşi de bu hatayı geçiyordu; ekrana
  bakınca yakalandı.
- **Türetilmiş metrikler `t=0`'da YOKTUR.** `r_yil`, `u`, `PR`, `Omega` alan
  değil çekirdeğin çıktısıdır ve ilk `adim()` koşmadan 0.0'dır. Başlangıç
  satırı örneklenirse her kâr oranı grafiği olmayan bir çöküşle başlar — ve
  hata **metriğin türüne göre** değişir (`pay`, `q` gerçek başlangıç alanı
  olduğu için onlarda görünmez). `Gecmis` ilk örneği ilk yılın sonunda alır.
- **`yil` kayan noktada birikir: 52 tik sonra 1836.9999999999998.** `int()`
  bunu 1836'ya kırpar ve grafiğin, güncenin, üst şeridin bütün yıl etiketleri
  bir yıl geri kayar. Takvim yılı **tik sayısından** türetilir
  (`Oyun.takvim_yili()` epsilon toleransı taşır).
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
- **v2'de MİKRO ile MAKRO büyüklüğü aynı formülle yazma.** "Bina kârlılığı"
  sermaye üzerinden (`(Y_i − w·L_i)/K_i`) tanımlanırsa cebirsel olarak
  `(1 − w/q_i)/kv` eder — yani içine `kv` girer, o da makro bir büyüklüktür.
  Ölçüldü: iki katman aynı işareti verdi ve §2.4'ün tuzağı ölçülemedi.
  Kapitalistin defterindeki büyüklük **satış üzerinden marjdır**; kâr oranı
  makro defterde durur. Ayrım Marx'ın kendi ayrımıdır, kozmetik değildir.
- **v2'de çağ tablosu `q_tavan` demektir, `era_min` değil.** `Tables.ERAS`
  teknolojik gelişmeyi "her çağın bir üretkenlik tavanı var, q çağ içinde ona
  doğru doyar" diye kurar. Yeni mekanizmaları çağ **numarasıyla** kapılamak bu
  mantığı tersine çevirir: üretim yöntemi merdiveni bir kez öyle yazıldı ve
  1836–1975 arası 139 yıl tek basamakta dondu (200 yılda q 1.00 → 1.33, kapalı
  form 55.4 verirken). Kapı `q_tavan` olmalı — tabloyu tekrarlamaz, okur.
- **v2'de `q` yalnızca üretkenlik değil, ÇAĞ TABLOSUNUN TETİKLEYİCİSİDİR.**
  Çağ geçişi `q > E["q_esik"]` şartına bakar ve her geçiş `Omega`'yı zıplatır
  (`gecis_omega`). Yani `q`'nun büyüme hızını değiştiren her mekanizma, farkında
  olmadan **devrimin zamanlamasını** da değiştirir. Bir kez yaşandı: mikro
  katmanın merdiveni erken hızlı tırmanınca devrim 1923'ten 1903'e kaydı. Teşhis
  eleme ile yapıldı — `pay` ve `PR` iki kolda da aynıydı, ayrışan `q` ve çağdı
  (`--v2-uretim-iz`).
- **Kalibrasyonu KARAR VERİLEN kurulumda ve YÖRÜNGE üzerinden yap.** Bu ikisi
  ayrı ayrı hataya yol açtı. `--v2-uretim-tarama` önce 1836/çağ-2'den koşuyordu
  ama ölçüt `--v2-tarih` ve o 1825/çağ-1'den başlıyor — çağların `q_tavan`ı
  farklı olduğu için sabit taşınmıyor. Ve tarama yalnızca uç noktaya bakıyordu:
  uç nokta çapaya %88 yakınken yörünge iki kat ayrışıyordu. **Bir eğriyi tek
  noktadan eşleştirmek onu eşleştirmez.**
- **v2'de bir AKIM ile bir STOK aynı şeyi ölçmez.** `satilamayan_I/II` akım
  olarak yazılıydı ve dönem bitince buharlaşıyordu; sonucu ölçüldü — aşırı
  üretim epizodu ortalama **15.7 yıl** sürüyordu, yani bir kriz değil kalıcı
  bir durum. Stoka çevrilince 2.07 yıla indi. Bir mekanizmanın hafızası
  olmalıysa onu akımla kurma.
- **Toplu bedeli haftalık akımla karşılaştırma.** Bir yatırım kararının bedeli
  stok cinsindense (binanın sermayesinin şu kadarı) ve bütçe akım cinsindense
  (haftalık yatırımın şu kadarı), koşul hiç sağlanmaz. Bir kez yaşandı:
  yükseltme 200 yılda sıfır kez ateşledi. Taksitlendir — ve taksiti anında
  sermayeye yaz, yoksa korunum özdeşliği kırılır.
- **`barichello/godot-ci:4.7` kabında `python3` YOK.** CI'da kâhin denetimi
  (`extract_sources.py --check`) o kapta `exit 127` ile düştü — on iki kapının
  on ikisi de geçtikten sonra. Godot gerektirmeyen adımlar kapsız bir runner'da
  ayrı iş olarak koşmalı.
- **v2'de MERDİVEN İLE ÇAĞ TABLOSU ZIT YÖNLÜ, ve tek sabit ikisini tutmaz.**
  Üretim merdiveninin tırmanma hızı yapısal olarak birikim oranıyla
  orantılıdır (`basamak/yıl = yatırım·pay / (K_bina·bedel)`), birikim oranı da
  kâr oranıyla birlikte **düşer** — LTRPF'nin kendisi. Çağ tablosunun `qg`si
  ise **yükselir** (0.0045 → 0.0175). Ölçüldü: tek bir bedel ya erken on
  yılları iki kat hızlandırıyor ya geç kampanyayı bir mertebe geride
  bırakıyor; 2100'de q 12.4 kalırken kapalı form 156.3 veriyordu ve otomasyon
  (mutlak q ≥ 36 ister) **hiç başlamıyordu**. Çözüm yeni bir sabit değil,
  `q_tavan` kapısındaki ilkenin aynısı: basamak bedeli çağın kendi `qg`siyle
  ölçeklenir — **tablo tekrarlanmaz, okunur** (`cag_esneklik = 1.0`).
- **Kalibrasyon penceresi OYUNUN UFKUNU kapsamalı.** Merdiven taraması
  1985'te bitiyordu ve tam bu yüzden asıl sapmayı göremiyordu: iki kol erken
  on yıllarda yakın duruyor, ayrışma geç kampanyada açılıyor. "Bir eğriyi tek
  noktadan eşleştirmek onu eşleştirmez" dersinin zaman eksenindeki hâli —
  **yarım pencerede eşleştirmek de eşleştirmez.**
- **KAPI DÜNYASI KADRODAN AYRI TUTULUR.** B6 kadroyu 54'ten 113'e çıkarınca
  tam kampanya koşan kapıların maliyeti üçe katlandı (harita kapısı 227 →
  ~620 sn). `Harita.kapi_kodlar()` sabit bir alt küme verir. Ayrım iş
  bölümüdür: harita kapısı **mod canlılığı ve bağ kapsamı** ölçer, ölçeği
  değil — ölçek `--v2-b6`nın işidir ve o tam kadroda koşar.
- **OPTİMİZASYON SONUCU DEĞİŞTİRMEMELİ, ve bu ÖLÇÜLEREK gösterilir.**
  `ticaret()`in iç döngüsünde üç ifade yalnızca `i`'ye bağlıydı ve n² kez
  hesaplanıyordu (113 ülkede tik başına 6328 gereksiz `_itki` çağrısı);
  dışarı alınınca karesel katsayı %39 düştü. **İfade sırası korunmalı**:
  `(yog·Ya)·Yb / Yd` ile `(yog·Ya/Yd)·Yb` kayan noktada aynı sayı değildir.
  Kanıt `--v2-dunya` çıktısının bayt bayt karşılaştırılmasıdır.
- **Bir BANDIN neyi ölçtüğünü, düştüğü gün ÇAPALARI ölçerek anla.** B2b'nin
  `iss_ort < 0.25` yozlaşma bandı merdiven kalibre edilince düştü. Bandı
  gevşetmek yerine çapalar ölçüldü: çekirdeğin kendi kapalı formu 0.3169,
  yalnız-nüfus kolu 0.3015 — yani bandı sağlayan **tek** kol yavaş merdivenli
  koldu ve bant bağımsız bir ölçüt değil, o yavaşlığın parmak iziydi. Bant
  çapaya göre yeniden yazıldı (`< çapa + 0.10`) ve ayırt ediciliği ayrıca
  doğrulandı: kalibre kol 0.3815 geçiyor, aşırı kol (esneklik 1.5) 0.4706 ile
  kalıyor.
- **v2'de bir DÜZEY karşılaştırması trendi ölçer, mekanizmayı değil.** Bu
  ailenin dört üyesi oldu: mutlak `NX` yerine `NX/Y` (ekonomi küçülünce mutlak
  akım da küçülür), ham `l_etkin` yerine çarpan (nüfus sürükleniyor), kampanya
  ortalaması yerine eş-zamanlı kesit (`r` 0.10'dan 0.04'e düşüyor ve olaylar
  erken kümeleniyor), dünya toplamı yerine çift hacmi (iki yörünge kaotik
  ayrışıyor). Yeni bir karşılaştırma yazarken sor: **ölçtüğüm fark mekanizmadan
  mı, yoksa iki kolun zaten ayrıştığı yerden mi geliyor?**
- **v2'de v4.4'ün SÜRE sabitleri tarihsel çapaya karşı sınanmalı.** Birim
  çevrimi doğru olsa bile değerin kendisi v4.4'ün kalibrasyonudur ve v2 onu
  devralmaz. B4'te yaşandı: `sv_min_sure`/`sv_max_sure` doğru çevrildi ama
  savaşlar 15.3 yıl sürdü ve nüfus kaybı %31.8'e çıktı — yön testi 14/14
  **geçerek**. Tarihsel çapa (büyük savaşlarda %4–13) süreyi 1.5–7 yıla çekti.
- **v2'de YENİ BİR KANALIN BÜYÜKLÜĞÜNÜ KOMŞU TERİMLERLE KIYASLA.** Tek başına
  "makul görünen" bir sayı motorun kendi ölçeğinde felaket olabilir. B3'te
  yaşandı: `sehit_org_yil = 0.30` seçilmişti, oysa çekirdeğin bütün örgütlenme
  akımları yılda **0.006–0.013** mertebesinde (`org_kent_yil` 0.0059,
  `org_baski_yil` 0.0130) — yani otuz kat büyüktü. Sonucu: `org` 0.465'ten
  0.04'e çöktü, `Omega` onunla söndü ve devrim imkânsızlaştı.
- **v2'de bir mekanizmayı ölçerken TAKTİĞİ değil MEKANİZMAYI aç/kapa.** B3'te
  iki test bu yüzden yanlış sebeple kaldı. Paramiliter taktiği aynı anda
  `bolunme`yi de itiyor, o da `org`u kırıyor, o da `Omega`nın birikim çarpanını
  küçültüyor; taktiği açıp `Omega`ya bakmak şehit etkisini değil **üç kanalın
  bileşkesini** ölçer. Doğru karşı-olgusal `sehit_omega_yil = 0` ile kurulur.
- **v4.4'ün karanlık devlet çıktıları taşındı ama DENKLEMLERİ taşınmamıştı.**
  `uyusturucu_orani` ve `cezaevi_orani` çekirdekte okunuyor ama hiçbir şey
  tarafından yazılmıyordu — lumpen kanalı, karseral sönüm ve meşruiyet aşınması
  198 yıl boyunca 0.0'da **ölü** durdu. Bir alanın var olması sürüldüğü anlamına
  gelmez; `grep` ile "kim yazıyor" diye bakmak ucuz bir denetimdir.
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

### v2 — `godot/scripts/v2/`

Ayrı ağaç, ayrı sınıflar, **otoload yok**. v4.4 dosyalarından yalnızca
`ParamSet`, `Formulas`, `PyRandom` ve `Tables`'ı okur; hiçbirini değiştirmez.

| sınıf | ne |
|---|---|
| `KrizParam` | v2 parametreleri. Düzeyler `P.v44`'ten **okunur**, elle yazılmaz |
| `KrizDurumu` | ülke durumu. **Akımlar YILLIK, stoklar düzey, sayaçlar dönem** |
| `KrizCekirdegi` | ülke-içi kriz teorisi. `adim(d, donem_yil, dis)` |
| `Dunya` | ülkeler arası **korunumlu** değer akışı (C/L blokları) |
| `UretimKatmani` | mikro katman: sektör, bina, üretim yöntemi merdiveni (B2a) |
| `NufusKatmani` | sınıf kohortları: emek arzı, istihdam, ücret payı (B2b) |
| `MalKatmani` | mal piyasası: dört kategori, satılamayan **stok** (B2c) |
| `KaranlikDevlet` | rıza/zor aygıtları, `bolunme`, karşı hareket (B3) |
| `SavasKatmani` | savaş: ilan, seferberlik, yıkım, yenilgi, karşı-devrim (B4) |
| `Oran` | dönem↔yıl dönüşümleri. Tur→hafta tuzağının tek savunması |
| `HaritaVerisi` | **üretilmiş** geometri: 156 ülke, 201 halka, 1/16° tam sayı ızgara |
| `Harita` | izdüşüm (Miller), isabet testi, ülke kaydı, dünya kurulumu, bağlar (B5) |
| `HaritaModu` | dokuz harita modu: değer, aralık, renk, efsane (B5) |
| `HaritaGorunum` | `ui/` — haritayı `_draw()` ile çizer. Tek `Control`, sıfır asset |
| `BasarimTesti` | `harness/` — B6: ölçek altında maliyet, korunum, savaş sıklığı |
| `Oyun` | `oyun/` — oturum: dünya + oyuncu + tik + politika kolları (B7) |
| `Gecmis` | `oyun/` — **yıllık** örneklenen sütun deposu; panelin grafikleri |
| `Gunce` | `oyun/` — kriz tescillerinden **türetilen** günce (§0) |
| `OyunEkrani` | `ui/` — Victoria düzeni: harita ana ekran, paneller üstüne |
| `UlkePaneli` | `ui/` — 12 çekirdek metrik + karanlık devletin bedelleri |
| `PolitikaPaneli` | `ui/` — oyuncunun kolları; §4.6'nın temsil ilkesi burada yaşar |
| `GuncePaneli` | `ui/` — günce akışı, ülke süzgeciyle |
| `ZamanGrafigi` | `ui/` — tek metriğin serisi; `Chart`ın aksine otoloada bağlı değil |
| `OyunMenusu` | `ui/` — kampanya kurulumu: özne seçimi (senaryo yok, §5.3) |
| `OyunTesti` | `harness/` — B7: kabuk motoru değiştirmiyor mu, kollar canlı mı |

**Katmanlar TAKILI DEĞİLKEN çekirdek zerre değişmez.** `cekirdek.mikro`,
`cekirdek.nufus`, `cekirdek.mal` ve `cekirdek.karanlik` `null` ise bütün kapalı
formlar eskisi gibi koşar; B1a/B1b ölçümleri geçerliliğini korur. Ölçüldü:
B3 eklendikten sonra dokuz kapının dokuzu da **bayt bayt aynı** çıktı verdi.
**Dördü birbirinden bağımsız takılır** — etkileri ancak öyle ayrı ölçülebilir;
B2a'da devrimin 20 yıl kaymasının sebebi tam da bu ayrılabilirlik sayesinde
eleme yoluyla bulundu. Takılıysa otorite geçer: `mikro` → `K`, `q`, `oto`,
`pay_I`; `nufus` → `L_etkin`, `e`, `emek_gerginlik`, `pay`; `mal` →
`talep_acigi`, `satilamayan_I/II`; `karanlik` → `bolunme`, `mafya_tolerans`,
`uyusturucu_orani`, `cezaevi_orani`, `egitim`, `nitelik`, `sehit`.
**Otorite tabloları katman dosyalarının başındadır.** Açık/kapalı olması bir
test kolaylığı değil deney tasarımıdır (B1b'de kesitsel ölçüm bir kez yanlış
sonuç verdi).

**Bir mekanizmanın YÖNÜ doğru çıkabilir ve mekanizma yine de ÖLÜ olabilir.**
B2b'de yaşandı: `pay` kampanyanın %74'ünü tabana çakılmış geçiriyordu, bileşim
kanalı hiç iş görmüyordu, ve kapı yön denetimleriyle **yeşil veriyordu**. Yön
testleri bunu yakalamaz; **bant denetimleri** yakalar. Yeni bir kapı yazarken
"mekanizma canlı mı" denetimini ayrıca koy — yoksa "eşik gevşetilmedi" cümlesi
boş kalır.

**Birim sözleşmesi v4.4'ten en önemli ayrılıktır.** v4.4'te akımlar *tur
başına* tanımlıydı ve dönem uzunluğu değişince sessizce yanlışlanan tek şey
buydu. v2'de akımlar yıllık sabitlenmiştir; `P.v44.x` diye okumak "bu büyüklük
zamana bağlı DEĞİL" iddiasıdır ve yanlışsa motor 14 kat hızlı koşar.

**`Dunya`nın tek kuralı: birinden eksilen diğerine gider.** Akım çift üzerinde
tanımlıdır ve iki uca ters işaretle yazılır, yani `sum(VT) == 0` bir
kalibrasyon değil özdeşliktir. Ülke başına çarpan uygulamak (abluka, açıklık)
**çifte simetrik** olmalıdır — tek tarafa uygulanan çarpan korunumu kırar ve
v4.4'ün L bloğunu bozan şey tam olarak buydu (ölçüldü: korunum hatası %57).

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
  `.png`/`.wav` eklemeden önce sor. **Tek istisna vektör geometri verisidir**
  (§5.1): harita poligonları `.png` değil, **üretilmiş** bir tablodur.
- Yorumlar ASCII (Türkçe karaktersiz), kullanıcıya görünen metinler tam Türkçe.
- **Motorda mekanizma değişikliği yapma.** Belge "v4.4 ÖZELLİK AÇISINDAN
  DONDURULDU" diyor (§10). Port sırasında davranış düzeltmesi yapılmaz;
  birebir aktarılır, sapma bulunursa rapor edilir.
