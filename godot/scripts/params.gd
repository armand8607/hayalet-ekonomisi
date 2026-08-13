extends Node

## Otoload 1 -- donmus kalibrasyonun fabrikasi. Hicbir seye bagli degildir.
##
## Sabitlerin kendisi `core/param_set.gd` icindedir ve URETILMISTIR
## (`tools/gen_gdscript.py`). Bu otoload yalnizca ornek uretir ve kimlik
## dogrulamasi yapar; sayi TASIMAZ.
##
## Neden fabrika: Python'da her motorun kendi `self.P = Params()` ornegi var ve
## test kosulari onu ornek bazinda degistiriyor (`e.P.fin_stok = 0.0`,
## `e.P.ai_acik = False`). Tek bir paylasilan sabit blogu bu kosulari
## birbirine sizdirirdi -- Monte Carlo ayni anda onlarca motor calistiriyor.


## Donmus varsayilanlarla yeni bir parametre seti.
func make() -> ParamSet:
	return ParamSet.new()


## Belgede yayimlanan (§9.18) parametre karmasi. Python tarafindaki
## `deney_kimligi()["parametre_karmasi"]` ile ayni olmali.
func beklenen_karma() -> String:
	return ParamSet.BEKLENEN_KARMA


## Veri katmaninin kendi ic tutarliligi. Motor kurulmadan once cagrilir;
## uretim adimi atlanmis ya da yarim kalmis bir agaci erken yakalar.
func dogrula() -> Dictionary:
	var p := make()
	var hatalar: Array[String] = []

	var sayi := p.alanlar_sirali().size()
	if sayi != ParamSet.ALAN_SAYISI:
		hatalar.append("ParamSet alan sayisi %d, beklenen %d" % [sayi, ParamSet.ALAN_SAYISI])

	if ParamSet.BEKLENEN_KARMA != "7ac8c1e1":
		hatalar.append("parametre karmasi %s, belgede yayimlanan 7ac8c1e1 degil"
				% ParamSet.BEKLENEN_KARMA)

	if not Formulas.kampanya_turu_dogru():
		hatalar.append("KAMPANYA_TURU turetimle uyusmuyor")

	if Tables.ULKELER.size() != 20:
		hatalar.append("ulke sayisi %d, beklenen 20" % Tables.ULKELER.size())

	if Tables.ERAS.size() != 6:
		hatalar.append("cag sayisi %d, beklenen 6" % Tables.ERAS.size())

	return {"gecti": hatalar.is_empty(), "hatalar": hatalar}
