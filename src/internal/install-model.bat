@echo off
setlocal EnableDelayedExpansion

rem Lets the user pick and download an additional whisper.cpp model.
rem Called by transcribe.bat when launched without a dropped file. Can
rem also be run directly.

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "MODELS_DIR=%ROOT_DIR%\models"
set "DOWNLOAD_PS1=%SCRIPT_DIR%download.ps1"
set "MODEL_BASE_URL=https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

set "NAME_1=tiny"
set "SIZE_1=~75 MB, fastest, least accurate"
set "NAME_2=base"
set "SIZE_2=~140 MB"
set "NAME_3=small"
set "SIZE_3=~465 MB (default)"
set "NAME_4=medium"
set "SIZE_4=~1.5 GB"
set "NAME_5=large-v3"
set "SIZE_5=~3 GB, slowest, most accurate"
set /a MODEL_COUNT=5

echo ========================================
echo  Install an additional Whisper model
echo ========================================
echo.
echo Available models:
echo.

for /l %%i in (1,1,%MODEL_COUNT%) do (
    set "TAG="
    if exist "%MODELS_DIR%\ggml-!NAME_%%i!.bin" set "TAG=  [already installed]"
    echo   %%i^) ggml-!NAME_%%i!.bin  ^(!SIZE_%%i!^)!TAG!
)

echo.
set "CHOICE="
set /p CHOICE="Enter a number to download, or press Enter to cancel: "

if "%CHOICE%"=="" (
    echo Cancelled.
    echo.
    exit /b 0
)

set "SELECTED="
for /l %%i in (1,1,%MODEL_COUNT%) do (
    if "%CHOICE%"=="%%i" set "SELECTED=!NAME_%%i!"
)

if not defined SELECTED (
    echo Invalid choice.
    echo.
    exit /b 1
)

set "MODEL_FILE=%MODELS_DIR%\ggml-%SELECTED%.bin"

if exist "%MODEL_FILE%" (
    echo ggml-%SELECTED%.bin is already installed.
    echo.
    exit /b 0
)

if not exist "%DOWNLOAD_PS1%" (
    echo Error: download.ps1 was not found.
    echo Expected at: %DOWNLOAD_PS1%
    echo.
    exit /b 1
)

echo.
echo Downloading ggml-%SELECTED%.bin...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DOWNLOAD_PS1%" -Url "%MODEL_BASE_URL%/ggml-%SELECTED%.bin" -OutFile "%MODEL_FILE%.part"
if errorlevel 1 (
    echo Error: failed to download ggml-%SELECTED%.bin.
    del /q "%MODEL_FILE%.part" >nul 2>&1
    echo.
    exit /b 1
)

move /y "%MODEL_FILE%.part" "%MODEL_FILE%" >nul
echo Done. ggml-%SELECTED%.bin installed.
echo.
exit /b 0
