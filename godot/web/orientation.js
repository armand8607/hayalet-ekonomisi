/*
 * Web yapısı için yatay ekran kapısı.
 *
 * Mobil tarayıcılar bir sayfanın kendiliğinden döndürme yapmasına izin vermez:
 * Chrome screen.orientation.lock() çağrısını yalnızca tam ekranda kabul eder,
 * iOS Safari hiç desteklemez. Bu yüzden burada gerçekten işe yarayan iki şey
 * yapılıyor:
 *
 *   1. Cihaz dikey tutulduğu sürece sayfayı "telefonu çevir" paneliyle kapat.
 *   2. Dokunulduğunda önce tam ekrana geç, SONRA yatay kilit iste — Android'de
 *      bu gerçekten döndürüp sabitler. Reddedildiği yerde (iOS) 1. adımdaki
 *      panel yine yol gösterir, yani geri düşüş zarif.
 *
 * BU OYUN İÇİN KAPI ÖZELLİKLE GEREKLİ: ekran 12 grafik, ülke listesi, politika
 * paneli ve olay günlüğünü aynı anda gösteriyor. Dikey bir şeritte hiçbiri
 * okunmaz.
 *
 * Web export ön ayarının html/head_include'u ile enjekte edilir, index.html'in
 * yanına .github/workflows/deploy.yml tarafından kopyalanır (Godot kaynağı
 * değildir, export onu kendiliğinden taşımaz).
 */
(function () {
	"use strict";

	// Yalnızca dokunmatik cihazlarda: dar bir masaüstü penceresi telefon
	// değildir, tarayıcısını küçültene panel göstermek can sıkıcı olur.
	if (!window.matchMedia || !window.matchMedia("(pointer: coarse)").matches) {
		return;
	}

	var style = document.createElement("style");
	style.textContent =
		"#rotate-gate{position:fixed;top:0;left:0;right:0;bottom:0;z-index:99999;" +
		"display:none;align-items:center;justify-content:center;flex-direction:column;" +
		"background:#11141a;color:#d6dbe6;text-align:center;padding:24px;" +
		"font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;}" +
		"#rotate-gate.show{display:flex;}" +
		"#rotate-gate .icon{font-size:64px;margin-bottom:18px;" +
		"animation:rg-tilt 1.8s ease-in-out infinite;}" +
		"#rotate-gate h1{font-size:22px;margin:0 0 10px;font-weight:600;color:#e8c25a;}" +
		"#rotate-gate p{font-size:15px;margin:0;opacity:.75;line-height:1.5;}" +
		"@keyframes rg-tilt{0%,55%{transform:rotate(0)}80%,100%{transform:rotate(-90deg)}}";
	document.head.appendChild(style);

	var gate = document.createElement("div");
	gate.id = "rotate-gate";
	gate.innerHTML =
		'<div class="icon">&#128241;</div>' +
		"<h1>Telefonu yan çevir</h1>" +
		"<p>Hayalet Ekonomisi yatay ekranda oynanır.<br>Tam ekran için dokun.</p>";

	function isPortrait() {
		return window.matchMedia("(orientation: portrait)").matches;
	}

	function update() {
		gate.classList.toggle("show", isPortrait());
	}

	// Önce tam ekran: Chrome'un yatay kilit için koştuğu ön koşul bu.
	function goFullscreenLandscape() {
		var el = document.documentElement;
		var request = el.requestFullscreen || el.webkitRequestFullscreen;
		var pending = request ? request.call(el) : null;
		Promise.resolve(pending)
			.then(function () {
				if (window.screen && screen.orientation && screen.orientation.lock) {
					return screen.orientation.lock("landscape");
				}
			})
			.catch(function () {
				// Reddedildi (iOS Safari ya da tam ekran verilmedi). Panel yine
				// ne yapılacağını söylüyor, telafi edilecek bir şey yok.
			});
	}

	function mount() {
		document.body.appendChild(gate);
		gate.addEventListener("click", goFullscreenLandscape);
		update();
	}

	window.addEventListener("orientationchange", update);
	window.addEventListener("resize", update);
	var mq = window.matchMedia("(orientation: portrait)");
	if (mq.addEventListener) {
		mq.addEventListener("change", update);
	} else if (mq.addListener) {
		mq.addListener(update); // eski WebKit
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", mount);
	} else {
		mount();
	}
})();
