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
`--dump-formulas`.

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
| 3 | Tur-tur iz karşılaştırması | motor portunu bekliyor |
| 4 | 9 mekanizma yön testi (**birincil**) | Python'da 9/9; GDScript portu bekliyor |
| 5 | 10 kabul bandı | Python'da 10/10; GDScript portu bekliyor |

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
