class_name TohumVerisi
extends RefCounted

# =============================================================
# BU DOSYA URETILMISTIR -- ELLE DUZENLEMEYIN.
# Kaynak : Maddison Project Database 2020
#          (Bolt & van Zanden 2020), CC BY 4.0
#          Our World in Data aynasindan
#          sha256 23a67c11f70112730d74e716841350540184b1682fcffc2860bf3ea76dff92fd
#          ISO3 eslemesi: datasets/country-codes (PDDL)
#          sha256 67b009b529330b0a6043551189f43faa785c9c3cc0011ad2bdb4eac876356c43
# Ureten : tools/gen_tohumlama.py
# Yeniden uretmek icin: python tools/gen_tohumlama.py
# =============================================================

## 1836'nin nufus tohumu: 111 toprak.
##
## NEDEN VAR: olculdu ki `L_etkin` butun ulkelerde 110.0 ve
## kampanya boyunca duz kaliyor -- ABD ile Bolivya ayni boyda,
## ve 2100'de dunyanin en buyuk ekonomisi Bulgaristan cikiyor.
## Ayrisma vardi ama ulke KIMLIGINE oturmuyordu.
##
## TOHUMLANAN TEK ALAN `L_etkin`. `K` cekirdekte ondan turetilir,
## `NufusKatmani` onu bozmaz, `q`yu konum merdiveni verir.
##
## 1836'da ayri devlet olmayan topraklar tarihsel butunun 1950
## payiyla bolusturulur (bkz. ureticideki MIRAS notu); hangi
## topragin nereden geldigi `KAYNAK`ta yazilidir.

## Tohumun cekildigi yil.
const YIL := 1836

## Medyan ulkenin `L_etkin`i. Motorun kalibre edildigi deger.
const MEDYAN_L := 110.0

## Ham nufusun medyani -- normalizasyon boleni. SAKLANIR,
## yeniden hesaplanmaz: `NUFUS` bir kez duzenlense (ki
## duzenlenmemeli) bolen sessizce kayardi.
const MEDYAN_NUFUS := 2110948.0

## Maddison'da karsiligi olmayan topraklar. Bunlar medyan
## buyuklukte baslar ve bu bir EKSIKLIK olarak kayda gecer.
const TOHUMSUZ := ["PNG", "SOM"]

## kod -> 1836 nufusu (kisi).
const NUFUS := {
	"AFG": 3551938,  # Afganistan
	"AGO": 1419999,  # Angola
	"ARE": 27066,  # Birleşik Arap Emirlikleri
	"ARG": 785107,  # Arjantin
	"AUS": 367000,  # Avustralya
	"AUT": 3614000,  # Avusturya
	"AZE": 1031337,  # Azerbaycan
	"BEL": 3945000,  # Belçika
	"BGD": 22909722,  # Bangladeş
	"BGR": 2348717,  # Bulgaristan
	"BLR": 2760219,  # Beyaz Rusya
	"BOL": 1238538,  # Bolivya
	"BRA": 5800731,  # Brezilya
	"CAN": 1461958,  # Kanada
	"CHE": 2171000,  # İsviçre
	"CHL": 1093000,  # Şili
	"CHN": 410797000,  # Çin Halk Cumhuriyeti
	"CIV": 986397,  # Fildişi Sahili
	"CMR": 1685532,  # Kamerun
	"COD": 4679316,  # Demokratik Kongo Cumhuriyeti
	"COL": 1606643,  # Kolombiya
	"CRI": 81033,  # Kosta Rika
	"CUB": 866292,  # Küba
	"CZE": 6101185,  # Çek Cumhuriyeti
	"DEU": 29702000,  # Almanya
	"DNK": 1315000,  # Danimarka
	"DOM": 365051,  # Dominik Cumhuriyeti
	"DZA": 2997588,  # Cezayir
	"ECU": 649263,  # Ekvador
	"EGY": 4952085,  # Mısır
	"ESP": 13571000,  # İspanya
	"EST": 391616,  # Estonya
	"ETH": 3973595,  # Etiyopya
	"FIN": 1399000,  # Finlandiya
	"FRA": 34178000,  # Fransa
	"GBR": 25715000,  # Birleşik Krallık
	"GEO": 1256622,  # Gürcistan
	"GHA": 1579000,  # Gana
	"GRC": 2677000,  # Yunanistan
	"GTM": 719667,  # Guatemala
	"HND": 224384,  # Honduras
	"HRV": 1323195,  # Hırvatistan
	"HUN": 4659633,  # Macaristan
	"IDN": 20464000,  # Endonezya
	"IND": 180182199,  # Hindistan
	"IRL": 8146000,  # İrlanda
	"IRN": 7104147,  # İran
	"IRQ": 1229793,  # Irak
	"ISR": 486716,  # İsrail
	"ITA": 22358000,  # İtalya
	"JOR": 231609,  # Ürdün
	"JPN": 31529000,  # Japonya
	"KAZ": 2392438,  # Kazakistan
	"KEN": 2110948,  # Kenya
	"KHM": 2166948,  # Kamboçya
	"KOR": 9474704,  # Güney Kore
	"LAO": 546978,  # Laos
	"LBY": 577840,  # Libya
	"LKA": 1673183,  # Sri Lanka
	"LTU": 912605,  # Litvanya
	"LVA": 692185,  # Letonya
	"MAR": 2997588,  # Fas
	"MDG": 1905748,  # Madagaskar
	"MEX": 7140085,  # Meksika
	"MLI": 1271722,  # Mali
	"MMR": 3727115,  # Myanmar
	"MNG": 634276,  # Moğolistan
	"MOZ": 2397694,  # Mozambik
	"MRT": 346929,  # Moritanya
	"MYS": 398069,  # Malezya
	"NAM": 159921,  # Namibya
	"NER": 1128061,  # Nijer
	"NGA": 10965476,  # Nijerya
	"NIC": 240014,  # Nikaragua
	"NLD": 2762000,  # Hollanda
	"NOR": 1202000,  # Norveç
	"NPL": 4125480,  # Nepal
	"NZL": 80734,  # Yeni Zelanda
	"OMN": 332923,  # Umman
	"PAK": 19799079,  # Pakistan
	"PAN": 135000,  # Panama
	"PER": 1646159,  # Peru
	"PHL": 2851278,  # Filipinler
	"POL": 11728021,  # Polonya
	"PRK": 4397444,  # Kuzey Kore
	"PRT": 3617000,  # Portekiz
	"PRY": 230494,  # Paraguay
	"ROU": 7203054,  # Romanya
	"RUS": 36436450,  # Rusya
	"SAU": 2167060,  # Suudi Arabistan
	"SDN": 5287469,  # Sudan
	"SRB": 2053776,  # Sırbistan
	"SVK": 2367601,  # Slovakya
	"SWE": 3042000,  # İsveç
	"SYR": 1410962,  # Suriye
	"TCD": 899314,  # Çad
	"THA": 4958287,  # Tayland
	"TKM": 430386,  # Türkmenistan
	"TUN": 961824,  # Tunus
	"TUR": 10594906,  # Türkiye
	"TZA": 2736434,  # Tanzanya
	"UKR": 13144859,  # Ukrayna
	"URY": 87729,  # Uruguay
	"USA": 15753000,  # Amerika Birleşik Devletleri
	"UZB": 2249307,  # Özbekistan
	"VEN": 995096,  # Venezuela
	"VNM": 7625000,  # Vietnam
	"YEM": 2669609,  # Yemen
	"ZAF": 1817000,  # Güney Afrika Cumhuriyeti
	"ZMB": 880426,  # Zambiya
	"ZWE": 983936,  # Zimbabve
}

## kod -> tohumun NEREDEN geldigi. Tani icin saklanir: bir
## sayinin dogrudan mi bolusturulerek mi geldigi, o sayiya
## ne kadar guvenilecegini belirler.
const KAYNAK := {
	"AFG": "ara 1820-1870",
	"AGO": "Sub-Sahara Africa ara 1820-1850, pay 0.0227",
	"ARE": "Middle East ara 1820-1850, pay 0.0007",
	"ARG": "ara 1820-1850",
	"AUS": "dogrudan",
	"AUT": "dogrudan",
	"AZE": "Former USSR ara 1820-1850, pay 0.0161",
	"BEL": "dogrudan",
	"BGD": "India dogrudan, pay 0.1028",
	"BGR": "ara 1820-1850",
	"BLR": "Former USSR ara 1820-1850, pay 0.0430",
	"BOL": "ara 1820-1850",
	"BRA": "ara 1820-1850",
	"CAN": "ara 1830-1840",
	"CHE": "dogrudan",
	"CHL": "dogrudan",
	"CHN": "dogrudan",
	"CIV": "Sub-Sahara Africa ara 1820-1850, pay 0.0158",
	"CMR": "Sub-Sahara Africa ara 1820-1850, pay 0.0269",
	"COD": "Sub-Sahara Africa ara 1820-1850, pay 0.0747",
	"COL": "ara 1820-1850",
	"CRI": "ara 1820-1850",
	"CUB": "ara 1820-1850",
	"CZE": "Czechoslovakia ara 1820-1850, pay 0.7204",
	"DEU": "dogrudan",
	"DNK": "dogrudan",
	"DOM": "Latin America ara 1820-1850, pay 0.0148",
	"DZA": "ara 1820-1870",
	"ECU": "ara 1820-1850",
	"EGY": "ara 1820-1870",
	"ESP": "dogrudan",
	"EST": "Former USSR ara 1820-1850, pay 0.0061",
	"ETH": "ara 1820-1950",
	"FIN": "dogrudan",
	"FRA": "dogrudan",
	"GBR": "dogrudan",
	"GEO": "Former USSR ara 1820-1850, pay 0.0196",
	"GHA": "en yakin 1870",
	"GRC": "dogrudan",
	"GTM": "ara 1820-1850",
	"HND": "ara 1820-1850",
	"HRV": "Former Yugoslavia ara 1820-1850, pay 0.2354",
	"HUN": "ara 1820-1850",
	"IDN": "dogrudan",
	"IND": "India dogrudan, pay 0.8084",
	"IRL": "dogrudan",
	"IRN": "ara 1820-1870",
	"IRQ": "ara 1820-1870",
	"ISR": "Middle East ara 1820-1850, pay 0.0125",
	"ITA": "dogrudan",
	"JOR": "ara 1820-1870",
	"JPN": "dogrudan",
	"KAZ": "Former USSR ara 1820-1850, pay 0.0373",
	"KEN": "Sub-Sahara Africa ara 1820-1850, pay 0.0337",
	"KHM": "ara 1820-1870",
	"KOR": "ara 1820-1850",
	"LAO": "ara 1820-1870",
	"LBY": "ara 1820-1950",
	"LKA": "ara 1820-1850",
	"LTU": "Former USSR ara 1820-1850, pay 0.0142",
	"LVA": "Former USSR ara 1820-1850, pay 0.0108",
	"MAR": "ara 1820-1870",
	"MDG": "ara 1820-1950",
	"MEX": "ara 1820-1850",
	"MLI": "Sub-Sahara Africa ara 1820-1850, pay 0.0203",
	"MMR": "ara 1820-1850",
	"MNG": "ara 1820-1870",
	"MOZ": "ara 1820-1950",
	"MRT": "Sub-Sahara Africa ara 1820-1850, pay 0.0055",
	"MYS": "ara 1820-1850",
	"NAM": "Sub-Sahara Africa ara 1820-1850, pay 0.0026",
	"NER": "Sub-Sahara Africa ara 1820-1850, pay 0.0180",
	"NGA": "Sub-Sahara Africa ara 1820-1850, pay 0.1751",
	"NIC": "ara 1820-1850",
	"NLD": "dogrudan",
	"NOR": "dogrudan",
	"NPL": "ara 1820-1850",
	"NZL": "ara 1830-1840",
	"OMN": "ara 1820-1870",
	"PAK": "India dogrudan, pay 0.0888",
	"PAN": "en yakin 1850",
	"PER": "ara 1820-1850",
	"PHL": "ara 1820-1850",
	"PNG": "kaynakta yok",
	"POL": "ara 1820-1850",
	"PRK": "ara 1820-1870",
	"PRT": "dogrudan",
	"PRY": "ara 1820-1850",
	"ROU": "ara 1820-1850",
	"RUS": "Former USSR ara 1820-1850, pay 0.5677",
	"SAU": "ara 1820-1870",
	"SDN": "ara 1820-1950",
	"SOM": "kaynakta yok",
	"SRB": "Former Yugoslavia ara 1820-1850, pay 0.3654",
	"SVK": "Czechoslovakia ara 1820-1850, pay 0.2796",
	"SWE": "dogrudan",
	"SYR": "ara 1820-1870",
	"TCD": "Sub-Sahara Africa ara 1820-1850, pay 0.0144",
	"THA": "ara 1820-1850",
	"TKM": "Former USSR ara 1820-1850, pay 0.0067",
	"TUN": "ara 1820-1870",
	"TUR": "ara 1820-1870",
	"TZA": "Sub-Sahara Africa ara 1820-1850, pay 0.0437",
	"UKR": "Former USSR ara 1820-1850, pay 0.2048",
	"URY": "ara 1820-1850",
	"USA": "dogrudan",
	"UZB": "Former USSR ara 1820-1850, pay 0.0350",
	"VEN": "ara 1820-1850",
	"VNM": "ara 1820-1870",
	"YEM": "ara 1820-1870",
	"ZAF": "ara 1820-1870",
	"ZMB": "Sub-Sahara Africa ara 1820-1850, pay 0.0141",
	"ZWE": "Sub-Sahara Africa ara 1820-1850, pay 0.0157",
}


## Bir topragin baslangic `L_etkin`i. Tohumsuzlar medyani alir.
static func l_etkin(kod: String) -> float:
	if not NUFUS.has(kod):
		return MEDYAN_L
	return MEDYAN_L * float(NUFUS[kod]) / MEDYAN_NUFUS

