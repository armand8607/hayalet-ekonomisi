# Parite kosusu: Python kahini <-> Godot portu.
#
# Dort katmani da uretir ve karsilastirir. Portun her asamasinda YENIDEN
# KOSULMALIDIR -- ozellikle `engine.gd`'ye her yeni blok tasindiginda.
#
# Kullanim:
#     powershell -ExecutionPolicy Bypass -File tools\run_parity.ps1
#     powershell -ExecutionPolicy Bypass -File tools\run_parity.ps1 -Katman rng

param(
    [string]$Katman = "hepsi",
    [string]$Godot  = "C:\Program Files\Godot\Godot.exe.exe",
    [string]$Python = ""
)

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$proj = Join-Path $kok "godot"
$env:PYTHONIOENCODING = "utf-8"

if ($Python -eq "") {
    $aday = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    if (Test-Path $aday) { $Python = $aday }
    else { $Python = (Get-Command python -ErrorAction Stop).Source }
}

$cikti = Join-Path $kok "python\baseline\parity"
New-Item -ItemType Directory -Force -Path $cikti | Out-Null

# "turn400" bilerek en son DOGRULANMIS-KESIN kontrol noktasidir. Tur 408'den
# sonra CPython ile Godot'un exp() fonksiyonu son bitte ayrisiyor ve motor
# kaotik oldugu icin fark yayiliyor; bu bir port hatasi DEGILDIR (bkz.
# CLAUDE.md, --dump-libm olcumu). Daha uzun ufuklarin olcutu kabul bantlaridir.
$katmanlar = if ($Katman -eq "hepsi") {
    @("rng", "crc32", "params", "formulas", "init", "turn400",
      "scenario:turkey_2001", "scenario:golden_age_1950",
      "scenario:neoliberal_1995", "scenario:socialist_siege",
      "report200")
} else { @($Katman) }

# Raporlama katmani BIT-BIREBIR DEGIL, siki toleranslidir: kaynak
# `statistics.mean` kullaniyor (Fraction tabanli tam rasyonel toplama) ve
# GDScript'te birebir uretmenin karsiligi yok -- bu degerler motora geri
# beslenmiyor. Motor katmanlarinda tolerans DAIMA 0'dir.
function Tolerans($k) { if ($k -like "report*") { "1e-9" } else { "0" } }

Write-Host "godot  : $Godot"
Write-Host "python : $Python"
Write-Host "cikti  : $cikti`n"

$basarisiz = 0
foreach ($k in $katmanlar) {
    Write-Host ("=" * 62)
    Write-Host "KATMAN: $k"
    Write-Host ("=" * 62)

    $guvenliAd = $k -replace '[:]', '_'
    $pyOut = Join-Path $cikti "py_$guvenliAd.txt"
    $gdOut = Join-Path $cikti "gd_$guvenliAd.txt"
    $gdHam = Join-Path $cikti "gd_${guvenliAd}_ham.txt"
    $gdErr = Join-Path $cikti "gd_${guvenliAd}_err.txt"

    # Katmanlarin arguman bicimleri farkli.
    if ($k -match '^turn(\d+)$') {
        $pyArg = @("--turn", $Matches[1])
        $gdArg = "--dump-turn=$($Matches[1])"
    } elseif ($k -match '^report(\d+)$') {
        $pyArg = @("--report", $Matches[1])
        $gdArg = "--dump-report=$($Matches[1])"
    } elseif ($k -match '^scenario:(.+)$') {
        $pyArg = @("--scenario", $Matches[1])
        $gdArg = "--dump-scenario=$($Matches[1])"
    } else {
        $pyArg = @("--$k")
        $gdArg = "--dump-$k"
    }

    & $Python (Join-Path $kok "python\tools\dump_trace.py") @pyArg |
        Out-File -FilePath $pyOut -Encoding utf8

    # Godot'un surum banner'i cikti degil gurultudur; ayiklanir.
    Start-Process -FilePath $Godot -NoNewWindow -Wait `
        -ArgumentList @("--headless", "--path", $proj, "res://scenes/Main.tscn", "--", $gdArg) `
        -RedirectStandardOutput $gdHam -RedirectStandardError $gdErr | Out-Null

    Get-Content $gdHam -Encoding utf8 |
        Where-Object { $_ -notmatch '^Godot Engine v' -and $_.Trim() -ne '' } |
        Out-File -FilePath $gdOut -Encoding utf8

    & $Python (Join-Path $kok "tools\compare_dump.py") $pyOut $gdOut --max 8 --tol (Tolerans $k)
    if ($LASTEXITCODE -ne 0) { $basarisiz++ }
    Write-Host ""
}

Write-Host ("=" * 62)
if ($basarisiz -eq 0) {
    Write-Host "PARITE: TUM KATMANLAR GECTI" -ForegroundColor Green
    exit 0
}
Write-Host "PARITE: $basarisiz KATMAN KALDI" -ForegroundColor Red
exit 1
