@echo off
setlocal EnableDelayedExpansion

rem One-time dependency installer, called by transcribe.bat (one folder up).
rem Downloads whisper.cpp, ffmpeg, and the speech model into bin\ and
rem models\ next to transcribe.bat, using only tools built into Windows
rem (PowerShell). Safe to re-run: it skips anything already present.
rem Internet access is only needed here, never during transcription itself.

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "BIN_DIR=%ROOT_DIR%\bin"
set "MODELS_DIR=%ROOT_DIR%\models"

set "WHISPER_EXE=%BIN_DIR%\whisper-cli.exe"
set "FFMPEG_EXE=%BIN_DIR%\ffmpeg.exe"
set "MODEL_FILE=%MODELS_DIR%\ggml-small.bin"

set "WHISPER_URL=https://github.com/ggml-org/whisper.cpp/releases/latest/download/whisper-bin-x64.zip"
set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
set "MODEL_URL=https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
set "DOWNLOAD_PS1=%SCRIPT_DIR%download.ps1"

echo ========================================
echo  Local Meeting Transcriber - Setup
echo ========================================
echo.

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

if exist "%WHISPER_EXE%" if exist "%FFMPEG_EXE%" if exist "%MODEL_FILE%" (
    echo Everything is already installed. Nothing to do.
    echo.
    exit /b 0
)

if not exist "%DOWNLOAD_PS1%" (
    echo Error: download.ps1 was not found.
    echo Expected at: %DOWNLOAD_PS1%
    echo.
    exit /b 1
)

echo This one-time setup downloads the transcription engine ^(whisper.cpp^),
echo ffmpeg, and the speech model ^(~465 MB^) into this folder. Internet
echo access is needed now; transcription itself will run fully offline
echo afterwards.
echo.

if not exist "%WHISPER_EXE%" call :install_whisper
if not exist "%FFMPEG_EXE%" call :install_ffmpeg
if not exist "%MODEL_FILE%" call :install_model

set "FAILED=0"
if not exist "%WHISPER_EXE%" (
    echo Error: whisper-cli.exe is still missing after setup.
    set "FAILED=1"
)
if not exist "%FFMPEG_EXE%" (
    echo Error: ffmpeg.exe is still missing after setup.
    set "FAILED=1"
)
if not exist "%MODEL_FILE%" (
    echo Error: the speech model is still missing after setup.
    set "FAILED=1"
)

if "%FAILED%"=="1" (
    echo.
    echo Setup did not complete. Check your internet connection and re-run setup.bat.
    exit /b 1
)

echo Setup complete.
echo.
exit /b 0

rem ---------------------------------------------------------
:install_whisper
echo Downloading whisper.cpp...
set "TMPZIP=%TEMP%\whisper-bin-x64_%RANDOM%.zip"
set "TMPDIR=%TEMP%\whisper-extract_%RANDOM%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%DOWNLOAD_PS1%" -Url "%WHISPER_URL%" -OutFile "%TMPZIP%"
if errorlevel 1 (
    echo Error: failed to download whisper.cpp.
    echo.
    goto :eof
)

powershell -NoProfile -Command "try { Expand-Archive -Path '%TMPZIP%' -DestinationPath '%TMPDIR%' -Force } catch { exit 1 }"
if errorlevel 1 (
    echo Error: failed to extract whisper.cpp.
    echo.
    del /q "%TMPZIP%" >nul 2>&1
    goto :eof
)

copy /y "%TMPDIR%\Release\whisper-cli.exe" "%BIN_DIR%\whisper-cli.exe" >nul
copy /y "%TMPDIR%\Release\ggml*.dll" "%BIN_DIR%\" >nul

del /q "%TMPZIP%" >nul 2>&1
rd /s /q "%TMPDIR%" >nul 2>&1
echo Done.
echo.
goto :eof

rem ---------------------------------------------------------
:install_ffmpeg
echo Downloading ffmpeg...
set "TMPZIP=%TEMP%\ffmpeg-win64-gpl_%RANDOM%.zip"
set "TMPDIR=%TEMP%\ffmpeg-extract_%RANDOM%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%DOWNLOAD_PS1%" -Url "%FFMPEG_URL%" -OutFile "%TMPZIP%"
if errorlevel 1 (
    echo Error: failed to download ffmpeg.
    echo.
    goto :eof
)

powershell -NoProfile -Command "try { Expand-Archive -Path '%TMPZIP%' -DestinationPath '%TMPDIR%' -Force } catch { exit 1 }"
if errorlevel 1 (
    echo Error: failed to extract ffmpeg.
    echo.
    del /q "%TMPZIP%" >nul 2>&1
    goto :eof
)

for /r "%TMPDIR%" %%F in (ffmpeg.exe) do copy /y "%%F" "%BIN_DIR%\ffmpeg.exe" >nul

del /q "%TMPZIP%" >nul 2>&1
rd /s /q "%TMPDIR%" >nul 2>&1
echo Done.
echo.
goto :eof

rem ---------------------------------------------------------
:install_model
echo Downloading speech model ^(ggml-small.bin, ~465 MB^)...

powershell -NoProfile -ExecutionPolicy Bypass -File "%DOWNLOAD_PS1%" -Url "%MODEL_URL%" -OutFile "%MODEL_FILE%.part"
if errorlevel 1 (
    echo Error: failed to download the speech model.
    echo.
    del /q "%MODEL_FILE%.part" >nul 2>&1
    goto :eof
)

move /y "%MODEL_FILE%.part" "%MODEL_FILE%" >nul
echo Done.
echo.
goto :eof
