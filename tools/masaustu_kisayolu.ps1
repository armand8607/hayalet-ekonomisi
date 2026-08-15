# Masaustune "Hayalet Ekonomisi" kisayolu koyar.
#
# Kisayol tools\oyna.bat dosyasini hedefler; oyna.bat Godot'u bulur, gerekirse
# projeyi ice aktarir ve oyunu acar. Konsol penceresi KUCULTULMUS acilir
# (WindowStyle 7) -- baslatici bir arac, gosterilecek bir sey degil.
#
# Calistirmak icin bu dosyaya sag tikla > "PowerShell ile calistir", ya da:
#     powershell -ExecutionPolicy Bypass -File tools\masaustu_kisayolu.ps1

$ErrorActionPreference = "Stop"

$kok = Split-Path -Parent $PSScriptRoot
$bat = Join-Path $PSScriptRoot "oyna.bat"

if (-not (Test-Path $bat)) {
    throw "oyna.bat bulunamadi: $bat -- bu script deponun tools\ klasorunde durmali."
}

$masaustu = [Environment]::GetFolderPath("Desktop")
$lnk = Join-Path $masaustu "Hayalet Ekonomisi.lnk"

$kabuk = New-Object -ComObject WScript.Shell
$kisayol = $kabuk.CreateShortcut($lnk)
$kisayol.TargetPath       = $bat
$kisayol.WorkingDirectory = $kok
$kisayol.Description      = "Hayalet Ekonomisi -- Marksist deger teorisi simulasyonu (motor v4.4-Frozen)"
$kisayol.WindowStyle      = 7
$kisayol.Save()

Write-Host "Kisayol olusturuldu:"
Write-Host "  $lnk"
Write-Host "Hedef: $bat"
