class_name Tema
extends RefCounted

## Arayüzün tek renk ve ölçü kaynağı.
##
## SIFIR ASSET: her görsel `_draw()` çağrısıyla çizilir, hiçbir `.png` yok.
## Renkler burada toplanır ki panelin herhangi bir yerinde "bu neydi" diye
## sorulmasın ve rejim renkleri iki yerde ayrışmasın.

const ZEMIN := Color("11141a")
const PANEL := Color("181c25")
const PANEL_ACIK := Color("212736")
const CIZGI := Color("2c3346")
const METIN := Color("d6dbe6")
const METIN_SOLUK := Color("8a93a6")
const VURGU := Color("e8c25a")

## Rejim renkleri. Ülke listesinde ve grafik arka planında AYNI anlamı taşır.
const REJIM := {
	"kapitalist": Color("4a90d9"),
	"sosyalist": Color("d9534f"),
}

## Kurumsal rejimler. Polanyi'nin çifte hareketi ekranda da okunabilsin diye
## düzenli/neoliberal karşıt uçlarda.
const KURUM := {
	"liberal": Color("9b8ec4"),
	"duzenli": Color("5cb87a"),
	"neoliberal": Color("d98d4a"),
}

## Kriz olaylarının rengi. Motorun günlük tipleriyle birebir eşleşir.
const OLAY := {
	"DEVRIM": Color("d9534f"),
	"KARSI-DEVRIM": Color("d9534f"),
	"RESTORASYON": Color("d9534f"),
	"PIYASA SOS.": Color("d98d4a"),
	"COKME": Color("e07b39"),
	"BUYUK BUNALIM": Color("e0553b"),
	"DOVIZ KRIZI": Color("e0a03b"),
	"TEMERRUT": Color("e0553b"),
	"MORATORYUM": Color("e0a03b"),
	"ASIRI URETIM": Color("c9973f"),
	"SAVAS": Color("b5474a"),
	"YENILGI": Color("b5474a"),
	"KURUM": Color("5cb87a"),
	"CAG": Color("4a90d9"),
	"HEGEMONYA": Color("6ea8d9"),
	"SENARYO": Color("8a93a6"),
	"DUNYA DEVRIMI": Color("d9534f"),
	"KONTROL": Color("8a93a6"),
	"KONTROL BITTI": Color("8a93a6"),
}

const KENAR := 12.0
const SATIR := 20.0


static func rejim_rengi(rejim: String) -> Color:
	return REJIM.get(rejim, METIN_SOLUK)


static func kurum_rengi(kurum: String) -> Color:
	return KURUM.get(kurum, METIN_SOLUK)


static func olay_rengi(tip: String) -> Color:
	return OLAY.get(tip, METIN_SOLUK)
