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
    @("rng", "crc32", "params", "formulas", "init", "turn400")
} else { @($Katman) }

Write-Host "godot  : $Godot"
Write-Host "python : $Python"
Write-Host "cikti  : $cikti`n"

$basarisiz = 0
foreach ($k in $katmanlar) {
    Write-Host ("=" * 62)
    Write-Host "KATMAN: $k"
    Write-Host ("=" * 62)

    $pyOut = Join-Path $cikti "py_$k.txt"
    $gdOut = Join-Path $cikti "gd_$k.txt"
    $gdHam = Join-Path $cikti "gd_${k}_ham.txt"
    $gdErr = Join-Path $cikti "gd_${k}_err.txt"

    # "turnN" katmani ayri arguman bicimi kullanir.
    if ($k -match '^turn(\d+)$') {
        $n = $Matches[1]
        $pyArg = @("--turn", $n)
        $gdArg = "--dump-turn=$n"
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

    & $Python (Join-Path $kok "tools\compare_dump.py") $pyOut $gdOut --max 8
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
