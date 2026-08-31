@echo off
setlocal EnableDelayedExpansion

rem Model path is configurable here (relative to this script's folder).
set "SCRIPT_DIR=%~dp0"
set "MODEL=%SCRIPT_DIR%models\ggml-small.bin"
set "WHISPER_EXE=%SCRIPT_DIR%bin\whisper-cli.exe"
set "FFMPEG_EXE=%SCRIPT_DIR%bin\ffmpeg.exe"

echo ========================================
echo  Local Meeting Transcriber
echo ========================================
echo.

set "SETUP_BAT=%SCRIPT_DIR%setup.bat"

if not exist "%WHISPER_EXE%" goto :run_setup
if not exist "%FFMPEG_EXE%" goto :run_setup
if not exist "%MODEL%" goto :run_setup
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

if not exist "%MODEL%" (
    echo Error: Whisper model not found:
    echo %MODEL%
    echo.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo All required components are installed.
    echo.
    echo No recording was supplied.
    echo.
    echo Drag a recording onto transcribe.bat.
    echo.
    pause
    exit /b 1
)

call :count_args %*

echo Model: ggml-small.bin
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
"%WHISPER_EXE%" -m "%MODEL%" -f "%TEMPWAV%" -l auto -otxt -nt -of "%OUTNOEXT%"
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
