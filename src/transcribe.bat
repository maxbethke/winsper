@echo off
setlocal EnableDelayedExpansion

rem setup.bat/download.ps1/install-model.bat live under internal\ so top
rem level only shows this script and README.txt; bin\ and models\ stay at
rem top level too. Any number of ggml-*.bin files can sit in models\ -
rem see :select_model below.
set "SCRIPT_DIR=%~dp0"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "MODELS_DIR=%SCRIPT_DIR%models"
set "WHISPER_EXE=%BIN_DIR%\whisper-cli.exe"
set "FFMPEG_EXE=%BIN_DIR%\ffmpeg.exe"
set "SETUP_BAT=%SCRIPT_DIR%internal\setup.bat"
set "INSTALL_MODEL_BAT=%SCRIPT_DIR%internal\install-model.bat"

echo ========================================
echo  Local Meeting Transcriber
echo ========================================
echo.

set "HAVE_MODEL=0"
if exist "%MODELS_DIR%\*.bin" set "HAVE_MODEL=1"

if not exist "%WHISPER_EXE%" goto :run_setup
if not exist "%FFMPEG_EXE%" goto :run_setup
if "%HAVE_MODEL%"=="0" goto :run_setup
goto :deps_ready

:run_setup
if not exist "%SETUP_BAT%" (
    echo Error: required components are missing and setup.bat was not found.
    echo Expected at: %SETUP_BAT%
    echo.
    pause
    exit /b 1
)
echo Required components are missing. Running setup...
echo.
call "%SETUP_BAT%"
if errorlevel 1 (
    echo Setup failed. Cannot continue.
    echo.
    pause
    exit /b 1
)

:deps_ready
if not exist "%FFMPEG_EXE%" (
    echo Error: ffmpeg.exe was not found.
    echo Expected at: %FFMPEG_EXE%
    echo.
    pause
    exit /b 1
)

if not exist "%WHISPER_EXE%" (
    echo Error: whisper-cli.exe was not found.
    echo Expected at: %WHISPER_EXE%
    echo.
    pause
    exit /b 1
)

if not exist "%MODELS_DIR%\*.bin" (
    echo Error: no Whisper model found in:
    echo %MODELS_DIR%
    echo.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo All required components are installed.
    echo.
    set "INSTALL_MORE=N"
    set /p INSTALL_MORE="Install another model? [Y/N]: "
    if /i "!INSTALL_MORE!"=="Y" (
        echo.
        if exist "%INSTALL_MODEL_BAT%" (
            call "%INSTALL_MODEL_BAT%"
        ) else (
            echo Error: install-model.bat was not found.
        )
    )
    echo.
    echo No recording was supplied.
    echo.
    echo Drag a recording onto transcribe.bat.
    echo.
    pause
    exit /b 1
)

call :select_model
if not defined MODEL (
    echo No model selected. Cannot continue.
    echo.
    pause
    exit /b 1
)

call :count_args %*

echo Model: %MODEL_NAME%
echo Files to process: %TOTAL%
echo.

set /a INDEX=0

:process
if "%~1"=="" goto :all_done
set /a INDEX+=1
call :transcribe_one "%~1"
shift
goto :process

:all_done
echo All files processed.
echo.
pause
exit /b 0

rem ---------------------------------------------------------
rem Picks the model to use for this run. If only one ggml-*.bin file is
rem installed, use it silently. If several are installed, ask which one.
:select_model
set "MODEL="
set "MODEL_NAME="
set /a MODEL_COUNT=0
for %%F in ("%MODELS_DIR%\*.bin") do (
    set /a MODEL_COUNT+=1
    set "MODEL_PATH_!MODEL_COUNT!=%%~fF"
    set "MODEL_NAME_!MODEL_COUNT!=%%~nxF"
)

if %MODEL_COUNT%==1 (
    set "MODEL=!MODEL_PATH_1!"
    set "MODEL_NAME=!MODEL_NAME_1!"
    goto :eof
)

echo Multiple models are installed:
echo.
for /l %%i in (1,1,%MODEL_COUNT%) do echo   %%i^) !MODEL_NAME_%%i!
echo.
set "MODEL_CHOICE="
set /p MODEL_CHOICE="Which model would you like to use? [1-%MODEL_COUNT%]: "

for /l %%i in (1,1,%MODEL_COUNT%) do (
    if "%MODEL_CHOICE%"=="%%i" (
        set "MODEL=!MODEL_PATH_%%i!"
        set "MODEL_NAME=!MODEL_NAME_%%i!"
    )
)

if not defined MODEL (
    echo Invalid choice, using !MODEL_NAME_1! by default.
    set "MODEL=!MODEL_PATH_1!"
    set "MODEL_NAME=!MODEL_NAME_1!"
)
echo.
goto :eof

rem ---------------------------------------------------------
:count_args
set /a TOTAL=0
:count_loop
if "%~1"=="" goto :eof
set /a TOTAL+=1
shift
goto :count_loop

rem ---------------------------------------------------------
:transcribe_one
set "INPUT=%~1"
echo ----------------------------------------
echo Processing file %INDEX% of %TOTAL%
echo Input: %INPUT%
echo.

if not exist "%INPUT%" (
    echo Error: file does not exist:
    echo %INPUT%
    echo.
    goto :eof
)

set "OUTDIR=%~dp1"
set "BASENAME=%~n1"
set "OUTPUT=%OUTDIR%%BASENAME%.txt"

if exist "%OUTPUT%" (
    if %TOTAL%==1 (
        set "OVERWRITE=N"
        set /p OVERWRITE="%BASENAME%.txt already exists. Overwrite? [Y/N]: "
        if /i not "!OVERWRITE!"=="Y" (
            echo Skipped.
            echo.
            goto :eof
        )
    ) else (
        set "OUTPUT=%OUTDIR%%BASENAME%.transcript.txt"
        echo %BASENAME%.txt already exists, writing to %BASENAME%.transcript.txt instead.
    )
)

set "TEMPDIR=%TEMP%\transcriber_%RANDOM%"
mkdir "%TEMPDIR%" >nul 2>&1
set "TEMPWAV=%TEMPDIR%\audio.wav"

echo Extracting audio...
"%FFMPEG_EXE%" -y -i "%INPUT%" -ar 16000 -ac 1 -c:a pcm_s16le "%TEMPWAV%" >nul 2>&1
if errorlevel 1 (
    echo Error: ffmpeg failed to extract audio from this file.
    echo The original recording was not modified.
    echo.
    rd /s /q "%TEMPDIR%" >nul 2>&1
    goto :eof
)

echo Transcribing...
set "OUTNOEXT=%TEMPDIR%\transcript"
"%WHISPER_EXE%" -m "%MODEL%" -f "%TEMPWAV%" -l auto -otxt -nt -t %NUMBER_OF_PROCESSORS% -of "%OUTNOEXT%"
if errorlevel 1 (
    echo Error: transcription failed for this file.
    echo The original recording was not modified.
    echo.
    rd /s /q "%TEMPDIR%" >nul 2>&1
    goto :eof
)

if not exist "%OUTNOEXT%.txt" (
    echo Error: transcription produced no output for this file.
    echo.
    rd /s /q "%TEMPDIR%" >nul 2>&1
    goto :eof
)

copy /y "%OUTNOEXT%.txt" "%OUTPUT%" >nul
rd /s /q "%TEMPDIR%" >nul 2>&1

echo Transcript saved:
echo %OUTPUT%

if %TOTAL%==1 (
    type "%OUTPUT%" | clip
    echo Transcript copied to clipboard.
)
echo.
goto :eof
