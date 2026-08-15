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
REM Ilk calistirmada projeyi bir kez ICE AKTARIR: depoda .godot/ yok ve
REM class_name cozumu o taramaya bagli. Atlanirsa oyun "Identifier not
REM declared" ile duser.
REM
REM --headless BILEREK YOK. Headless hicbir sey cizmez, _draw() kosmaz --
REM yani oyun acilmis gorunur ama ekranda hicbir sey olmaz.
REM
REM Godot'un yeri su sirayla aranir: %GODOT% ortam degiskeni, bilinen kurulum
REM yollari, en son PATH.
REM ==========================================================================

set "KOK=%~dp0.."
set "PROJE=%KOK%\godot"

if not exist "%PROJE%\project.godot" (
    echo HATA: Godot projesi bulunamadi: "%PROJE%"
    echo Bu dosya deponun tools\ klasorunde durmali.
    pause
    exit /b 1
)

set "EXE="
if defined GODOT if exist "%GODOT%" set "EXE=%GODOT%"

if not defined EXE (
    for %%P in (
        "C:\Program Files\Godot\Godot.exe.exe"
        "C:\Program Files\Godot\Godot.exe"
        "C:\Program Files (x86)\Godot\Godot.exe"
        "%LOCALAPPDATA%\Programs\Godot\Godot.exe"
        "%USERPROFILE%\Godot\Godot.exe"
    ) do (
        if not defined EXE if exist %%P set "EXE=%%~P"
    )
)

if not defined EXE (
    for /f "delims=" %%G in ('where godot 2^>nul') do (
        if not defined EXE set "EXE=%%G"
    )
)

if not defined EXE (
    echo HATA: Godot bulunamadi.
    echo.
    echo Godot 4.7 kurulu degilse: https://godotengine.org/download/windows/
    echo Kuruluysa ama baska bir yerdeyse, yolunu bir kez tanit:
    echo     setx GODOT "C:\yol\Godot.exe"
    echo ve bu pencereyi kapatip yeniden dene.
    pause
    exit /b 1
)

echo Godot   : "%EXE%"
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
