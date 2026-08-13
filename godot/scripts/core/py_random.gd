class_name PyRandom
extends RefCounted

## CPython'un `random.Random` sinifinin BIREBIR karsiligi (MT19937).
##
## NEDEN GODOT'UN KENDI RNG'SI KULLANILAMAZ: `RandomNumberGenerator` PCG32
## kullanir. Motorun butun tarihi -- hangi ulke ne zaman savas acar, hangi
## devrim tutar, politika AI'si hangi turda atesler -- bu akistan cekilen
## sayilara bagli. Ayni tohumun Python ve Godot'ta ayni tarihi uretmesi
## portun dogrulanabilir olmasinin on kosulu; farkli bir jenerator bunu
## bastan imkansiz kilar.
##
## Motorun kullandigi YUZEY cok kucuk (tarandi): `random()` x13,
## `randint()` x1, `choice()` x1. `gauss`/`normalvariate` HIC yok -- yani
## CPython'un Box-Muller/kutupsal yontemini ve onun "bir sonraki icin sakla"
## durumunu taklit etmek gerekmiyor. Tasinmasi gereken tek sey MT19937
## cekirdegi ve `_randbelow`'un reddetme ornekleme dongusudur.
##
## `random()` tam olarak yeniden uretilebilir: (a*2^26 + b) / 2^53 ifadesinin
## her adimi 2^53'un altinda kaldigi icin double aritmetigi KESINDIR, libm
## cagrisi yoktur. (Motorun geri kalanindaki `exp`/`log` icin ayni sey
## gecerli DEGIL -- bkz. CLAUDE.md, katmanli dogrulama.)

const N := 624
const M := 397
const MATRIX_A := 0x9908b0df
const UPPER_MASK := 0x80000000
const LOWER_MASK := 0x7fffffff
const MASK32 := 0xFFFFFFFF

var _mt := PackedInt64Array()   ## 624 adet isaretsiz 32-bit kelime
var _index := 0


func _init(tohum: int = 0) -> void:
	_mt.resize(N)
	seed_int(tohum)


## CPython `random_seed()`: tamsayi tohum MUTLAK degerine alinir, 32-bitlik
## kelimelere (little-endian) bolunur ve `init_by_array` ile yuklenir.
## Ornek: tohum 42 -> bits=6 -> tek kelime -> init_by_array([42]).
func seed_int(tohum: int) -> void:
	var n := absi(tohum)
	var anahtar := PackedInt64Array()
	if n == 0:
		anahtar.append(0)          # keyused = 1, key = [0]
	else:
		while n > 0:
			anahtar.append(n & MASK32)
			n = n >> 32
	_init_by_array(anahtar)


func _init_genrand(s: int) -> void:
	_mt[0] = s & MASK32
	for i in range(1, N):
		var prev: int = _mt[i - 1]
		_mt[i] = (1812433253 * (prev ^ (prev >> 30)) + i) & MASK32
	_index = N


func _init_by_array(anahtar: PackedInt64Array) -> void:
	_init_genrand(19650218)
	var i := 1
	var j := 0
	var key_len := anahtar.size()
	var k: int = N if N > key_len else key_len
	while k > 0:
		var prev: int = _mt[i - 1]
		_mt[i] = (((_mt[i] ^ ((prev ^ (prev >> 30)) * 1664525)) & MASK32)
				+ anahtar[j] + j) & MASK32
		i += 1
		j += 1
		if i >= N:
			_mt[0] = _mt[N - 1]
			i = 1
		if j >= key_len:
			j = 0
		k -= 1
	k = N - 1
	while k > 0:
		var prev2: int = _mt[i - 1]
		_mt[i] = (((_mt[i] ^ ((prev2 ^ (prev2 >> 30)) * 1566083941)) & MASK32)
				- i) & MASK32
		i += 1
		if i >= N:
			_mt[0] = _mt[N - 1]
			i = 1
		k -= 1
	_mt[0] = UPPER_MASK   # MSB 1: durum dizisinin sifir olmamasini garantiler


## Ham 32-bit cekilis. Butun ustteki metotlar bunun uzerine kurulu.
func genrand_uint32() -> int:
	if _index >= N:
		var y := 0
		for kk in range(0, N - M):
			y = (_mt[kk] & UPPER_MASK) | (_mt[kk + 1] & LOWER_MASK)
			_mt[kk] = _mt[kk + M] ^ (y >> 1) ^ (MATRIX_A if (y & 1) else 0)
		for kk in range(N - M, N - 1):
			y = (_mt[kk] & UPPER_MASK) | (_mt[kk + 1] & LOWER_MASK)
			_mt[kk] = _mt[kk + (M - N)] ^ (y >> 1) ^ (MATRIX_A if (y & 1) else 0)
		y = (_mt[N - 1] & UPPER_MASK) | (_mt[0] & LOWER_MASK)
		_mt[N - 1] = _mt[M - 1] ^ (y >> 1) ^ (MATRIX_A if (y & 1) else 0)
		_index = 0

	var v: int = _mt[_index]
	_index += 1
	v ^= (v >> 11)
	v ^= (v << 7) & 0x9d2c5680
	v ^= (v << 15) & 0xefc60000
	v ^= (v >> 18)
	return v & MASK32


## CPython `_random_Random_random_impl`: 53 bitlik cozunurluk, iki cekilisten.
## a 27 bit (>>5), b 26 bit (>>6). Butun ara degerler 2^53'un altinda kaldigi
## icin sonuc double olarak KESIN -- Python ile bit bit ayni cikar.
func random() -> float:
	var a: int = genrand_uint32() >> 5
	var b: int = genrand_uint32() >> 6
	return (a * 67108864.0 + b) * (1.0 / 9007199254740992.0)


## CPython `getrandbits`. Motor yalnizca `_randbelow` uzerinden, k <= 32 ile
## cagirir; 33..64 arasi yine de dogru uygulandi (little-endian kelimeler).
func getrandbits(k: int) -> int:
	assert(k >= 0 and k <= 64, "getrandbits: k 0..64 araliginda olmali")
	if k == 0:
		return 0
	if k <= 32:
		return genrand_uint32() >> (32 - k)
	var dusuk: int = genrand_uint32()
	var kalan := k - 32
	var yuksek: int = genrand_uint32() >> (32 - kalan)
	return dusuk | (yuksek << 32)


## CPython `_randbelow_with_getrandbits`: [0, n) araliginda tamsayi.
## Reddetme ornekleme dongusu AYNEN korunmali -- "mod n" gibi bir kisayol
## hem yanli dagilim verir hem de akisi Python'dan ayirir.
func randbelow(n: int) -> int:
	if n <= 0:
		return 0
	var k := _bit_length(n)   # n-1 degil n: n == 1 durumu icin
	var r := getrandbits(k)
	while r >= n:
		r = getrandbits(k)
	return r


## CPython `randint(a, b)` -> `randrange(a, b+1)` -> a + _randbelow(b-a+1).
func randint(a: int, b: int) -> int:
	return a + randbelow(b - a + 1)


## CPython `choice(seq)` -> seq[_randbelow(len(seq))].
func choice(dizi: Array):
	assert(dizi.size() > 0, "choice: bos diziden secim yapilamaz")
	return dizi[randbelow(dizi.size())]


func _bit_length(n: int) -> int:
	var u := absi(n)
	var b := 0
	while u > 0:
		b += 1
		u = u >> 1
	return b
