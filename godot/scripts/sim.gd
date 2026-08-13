extends Node

## Otoload 4 -- aktif kosunun sahibi ve arayuzun tek veri kapisi.
##
## Motorun kendisi (GhostEngine) otoload DEGILDIR; bu dugum yalnizca OYUNCUNUN
## kosusuna ait ornegi tutar. Monte Carlo ve parite kosulari kendi bagimsiz
## orneklerini dogrudan yaratir -- boylece test kosusu oyuncunun kosusunu
## bozamaz.
##
## Arayuz motora HIC dokunmaz, yalnizca bu sinyalleri dinler. Politika
## degisiklikleri de ters yonde buradan gecer: `set_temel_gelir` gibi cagrilar
## bir ILANDIR, anlik durum degisikligi degil -- motorda `pol_gecikme` (8 tur)
## sonra etkisi baslar ve yerlesme hizi rejime gore degisir.

## DURUM: GhostEngine portu bu turun kapsaminda degil (bkz. plan). Bu otoload
## simdilik yalnizca arayuzun bagli olacagi sozlesmeyi sabitler; `_motor`
## baglandiginda govde doldurulacak.

signal tur_ilerledi(t: int)
signal olay_eklendi(t: int, tip: String, mesaj: String)
signal kosu_bitti(rapor: Dictionary)

## Gosterge panelinin ekseni: belgenin kendi 12 cekirdek metrigi
## (`python/hassasiyet.py` icindeki `olc()` fonksiyonu). Panel bu listeyi
## okur, kendi listesini tutmaz -- iki yerin birbirinden kaymasi boylece
## imkansiz olur.
const CEKIRDEK_METRIKLER := [
	{"anahtar": "r", "ad": "Kâr oranı", "biçim": "oran"},
	{"anahtar": "cv", "ad": "Organik bileşim c/v", "biçim": "sayı"},
	{"anahtar": "u", "ad": "Kapasite kullanımı", "biçim": "yüzde"},
	{"anahtar": "e", "ad": "İşsizlik", "biçim": "yüzde", "ters": true},
	{"anahtar": "pay", "ad": "Ücret payı", "biçim": "yüzde"},
	{"anahtar": "borc", "ad": "Hanehalkı borcu / Y", "biçim": "oran"},
	{"anahtar": "varlik", "ad": "Spekülatif varlık / Y", "biçim": "oran"},
	{"anahtar": "Om", "ad": "Siyasi öfke (Omega)", "biçim": "yüzde"},
	{"anahtar": "org", "ad": "Örgütlenme", "biçim": "yüzde"},
	{"anahtar": "oto", "ad": "Otomasyon payı", "biçim": "yüzde"},
	{"anahtar": "canli_pay", "ad": "Canlı emek payı", "biçim": "yüzde"},
	{"anahtar": "PR", "ad": "Protesto riski", "biçim": "yüzde"},
]

var _motor = null           ## GhostEngine (port tamamlanınca bağlanacak)
var _oyuncu_ulkesi := ""
var t: int = 0


## Veri katmanini dogrular. Uretim adimi atlanmis bir agaci ILK ACILISTA
## yakalar; motor kurulduktan sonra degil.
func _ready() -> void:
	var sonuc: Dictionary = Params.dogrula()
	if not sonuc["gecti"]:
		for h in sonuc["hatalar"]:
			push_error("Veri katmani dogrulamasi: " + str(h))


func kosu_baslat(_senaryo: String, _tohum: int, _ulke: String) -> void:
	push_warning("Sim.kosu_baslat: GhostEngine portu henüz tamamlanmadı.")


func ilerle(_tur_sayisi: int = 1) -> void:
	push_warning("Sim.ilerle: GhostEngine portu henüz tamamlanmadı.")
