@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Hayalet Ekonomisi

REM ==========================================================================
REM Hayalet Ekonomisi -- Windows baslaticisi.
REM
REM Godot proje koku DEPO KOKU DEGIL, godot/ alt klasorudur; baslatici bu
REM yuzden --path ile oraya isaret eder.
REM
REM SURUM DENETIMI SART. Proje Godot 4.7 icindir (config_version=5). Godot 3.x
REM boyle bir projeyi acamaz ve sessizce PROJE YONETICISINI acar -- disaridan
REM "oyun acilmadi ama bir sey acildi" gibi gorunur, sebebi hic soylenmez.
REM Bu yuzden bulunan her aday --version ile sinanir ve 4.x olmayan reddedilir.
REM
REM Ilk calistirmada projeyi bir kez ICE AKTARIR: depoda .godot/ yok ve
REM class_name cozumu o taramaya bagli. Atlanirsa oyun "Identifier not
REM declared" ile duser.
REM
REM --headless BILEREK YOK. Headless hicbir sey cizmez, _draw() kosmaz --
REM yani oyun acilmis gorunur ama ekranda hicbir sey olmaz.
REM ==========================================================================

set "KOK=%~dp0.."
set "PROJE=%KOK%\godot"
set "SURUM_DOSYA=%TEMP%\hayalet_godot_surum.txt"

if not exist "%PROJE%\project.godot" (
    echo HATA: Godot projesi bulunamadi: "%PROJE%"
    echo.
    echo Bu dosya DEPONUN tools\ klasorunde durmali ve depoyla birlikte
    echo kopyalanmali. Tek basina masaustune tasinirsa projeyi bulamaz.
    pause
    exit /b 1
)

set "EXE="
set "SURUM="
set "YANLIS="

REM 1) Elle tanitilmis yol
if defined GODOT call :dene "%GODOT%"

REM 2) Bilinen kurulum yollari
if not defined EXE (
    for %%P in (
        "C:\Program Files\Godot\Godot.exe.exe"
        "C:\Program Files\Godot\Godot.exe"
        "C:\Program Files (x86)\Godot\Godot.exe"
        "%LOCALAPPDATA%\Programs\Godot\Godot.exe"
        "%USERPROFILE%\Godot\Godot.exe"
    ) do if not defined EXE call :dene "%%~P"
)

REM 3) Godot Windows'ta genelde TEK DOSYA olarak indirilir ve kurulmaz:
REM    Godot_v4.7-stable_win64.exe. Muhtemel yerlere bak.
if not defined EXE (
    for %%D in ("C:\Program Files\Godot" "%LOCALAPPDATA%\Programs") do (
        if exist %%D (
            for /f "delims=" %%G in ('dir /b /s "%%~D\Godot*.exe" 2^>nul') do (
                if not defined EXE call :dene "%%G"
            )
        )
    )
)
if not defined EXE (
    for %%D in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Desktop") do (
        if exist %%D (
            for /f "delims=" %%G in ('dir /b "%%~D\Godot*.exe" 2^>nul') do (
                if not defined EXE call :dene "%%~D\%%G"
            )
        )
    )
)

REM 4) PATH
if not defined EXE (
    for /f "delims=" %%G in ('where godot 2^>nul') do if not defined EXE call :dene "%%G"
)

if not defined EXE (
    echo.
    if defined YANLIS (
        echo HATA: Godot bulundu ama SURUMU UYMUYOR.
        echo   bulunan : !YANLIS!
        echo   gereken : 4.7
        echo.
        echo Bu proje Godot 4.7 icindir. Godot 3.x onu ACAMAZ; denerse proje
        echo yoneticisini acar ve oyun hic baslamaz.
    ) else (
        echo HATA: Godot bulunamadi.
    )
    echo.
    echo Godot 4.7 indir ^(tek dosya, kurulum istemez^):
    echo     https://godotengine.org/download/windows/
    echo.
    echo Indirdikten sonra yerini bir kez tanit:
    echo     setx GODOT "C:\yol\Godot_v4.7-stable_win64.exe"
    echo ve BU PENCEREYI KAPATIP yeniden dene ^(setx yalnizca yeni
    echo pencerelerde gecerli olur^).
    pause
    exit /b 1
)

echo Godot   : "%EXE%"
echo Surum   : %SURUM%
echo Proje   : "%PROJE%"

if not exist "%PROJE%\.godot\global_script_class_cache.cfg" (
    echo.
    echo Ilk calistirma: proje ice aktariliyor. Bu bir kereye mahsustur,
    echo bir dakika surebilir...
    "%EXE%" --headless --path "%PROJE%" --import
)

echo.
echo Oyun baslatiliyor...
"%EXE%" --path "%PROJE%"

if errorlevel 1 (
    echo.
    echo Oyun hata koduyla kapandi: !errorlevel!
    pause
)
exit /b 0


REM --------------------------------------------------------------------------
REM Bir adayi sinar. 4.x ise kabul eder; degilse ilkini YANLIS'a yazar ki
REM hata mesaji "bulunamadi" yerine gercek sebebi soyleyebilsin.
REM --------------------------------------------------------------------------
:dene
if defined EXE exit /b 0
if not exist "%~1" exit /b 0
set "SRM="
"%~1" --version > "%SURUM_DOSYA%" 2>nul
if exist "%SURUM_DOSYA%" (
    set /p SRM=<"%SURUM_DOSYA%"
    del "%SURUM_DOSYA%" >nul 2>&1
)
if not defined SRM exit /b 0
if "!SRM:~0,2!"=="4." (
    set "EXE=%~1"
    set "SURUM=!SRM!"
) else (
    if not defined YANLIS set "YANLIS=%~1  ^(surum !SRM!^)"
)
exit /b 0
