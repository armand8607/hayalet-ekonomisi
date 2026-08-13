# Sapmanin ILK turunu ikili aramayla bulur.
#
# Motor kaotiktir: bir ulp'lik fark yuzlerce tur sonra yuzlerce alana yayilir.
# "Hangi alan farkli" sorusu o noktada ise yaramaz; anlamli soru "fark ILK
# hangi turda ve hangi alanda dogdu"dur. Bu betik onu bulur.
#
# Kullanim:
#   powershell -ExecutionPolicy Bypass -File tools\bisect_turn.ps1 -Alt 400 -Ust 800

param(
    [int]$Alt = 0,
    [int]$Ust = 1259,
    [string]$Godot  = "C:\Program Files\Godot\Godot.exe.exe",
    [string]$Python = ""
)

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$proj = Join-Path $kok "godot"
$env:PYTHONIOENCODING = "utf-8"

if ($Python -eq "") {
    $aday = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    if (Test-Path $aday) { $Python = $aday } else { $Python = (Get-Command python).Source }
}

$d = Join-Path $env:TEMP "ge_bisect"
New-Item -ItemType Directory -Force -Path $d | Out-Null

function Ayni($n) {
    & $Python (Join-Path $kok "python\tools\dump_trace.py") --turn $n |
        Out-File "$d\py.txt" -Encoding utf8
    Start-Process -FilePath $Godot -NoNewWindow -Wait `
        -ArgumentList @("--headless", "--path", $proj, "res://scenes/Main.tscn", "--", "--dump-turn=$n") `
        -RedirectStandardOutput "$d\gdh.txt" -RedirectStandardError "$d\gde.txt" | Out-Null
    Get-Content "$d\gdh.txt" -Encoding utf8 |
        Where-Object { $_ -notmatch '^Godot Engine v' -and $_.Trim() -ne '' } |
        Out-File "$d\gd.txt" -Encoding utf8
    & $Python (Join-Path $kok "tools\compare_dump.py") "$d\py.txt" "$d\gd.txt" --max 1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

Write-Host "ikili arama: [$Alt, $Ust]"
if (Ayni $Ust) { Write-Host "tur $Ust zaten ayni -- sapma yok."; exit 0 }
if (-not (Ayni $Alt)) { Write-Host "tur $Alt ZATEN farkli -- alt siniri dusurun."; exit 1 }

while ($Ust - $Alt -gt 1) {
    $orta = [int](($Alt + $Ust) / 2)
    if (Ayni $orta) { Write-Host "  tur $orta : ayni";  $Alt = $orta }
    else            { Write-Host "  tur $orta : FARKLI"; $Ust = $orta }
}

Write-Host "`nSapmanin dogdugu ILK tur: $Ust  (tur $Alt hala ayni)"
Write-Host "Ayrinti icin:"
Write-Host "  python python\tools\dump_trace.py --turn $Ust > py.txt"
& $Python (Join-Path $kok "python\tools\dump_trace.py") --turn $Ust | Out-File "$d\py.txt" -Encoding utf8
Start-Process -FilePath $Godot -NoNewWindow -Wait `
    -ArgumentList @("--headless", "--path", $proj, "res://scenes/Main.tscn", "--", "--dump-turn=$Ust") `
    -RedirectStandardOutput "$d\gdh.txt" -RedirectStandardError "$d\gde.txt" | Out-Null
Get-Content "$d\gdh.txt" -Encoding utf8 |
    Where-Object { $_ -notmatch '^Godot Engine v' -and $_.Trim() -ne '' } |
    Out-File "$d\gd.txt" -Encoding utf8
& $Python (Join-Path $kok "tools\compare_dump.py") "$d\py.txt" "$d\gd.txt" --max 10
