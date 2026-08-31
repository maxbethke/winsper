# Local Meeting Transcriber

Fully local, offline speech-to-text for Zoom (or any) recordings. No cloud
services, no accounts, no internet access required to transcribe.

## Usage

Drag one or more recordings onto `transcribe.bat`:

```text
Team Meeting.mp4  -->  transcribe.bat
```

This produces `Team Meeting.txt` next to the recording. For a single
dropped file, the transcript is also copied to the clipboard (`Ctrl+V`
to paste it anywhere).

Supported input formats: `.mp4`, `.m4a`, `.mp3`, `.wav`, `.mov`, `.webm`
(anything ffmpeg can decode).

You can also run it from a command prompt:

```bat
transcribe.bat "C:\Meetings\Team Meeting.mp4" "C:\Meetings\Standup.m4a"
```

## First run / setup

The first time you use `transcribe.bat`, it detects that whisper.cpp,
ffmpeg, and the speech model aren't installed yet and automatically runs
`setup.bat` to download them (~500 MB total) into `bin\` and `models\`
next to the scripts. This is the only time internet access is used - it's
a one-time step, and every transcription afterwards runs fully offline.
You can also run `setup.bat` yourself ahead of time if you'd rather not
wait on first use.

## Privacy

Transcription runs entirely on your machine using whisper.cpp and ffmpeg.
Nothing is uploaded anywhere. Neither the recording nor the transcript
ever leaves your computer. The only network access this tool ever makes
is the one-time setup download described above.

## Notes

- If a `.txt` output already exists: dropping a single file asks whether
  to overwrite it; dropping multiple files writes `Name.transcript.txt`
  instead so a batch run never stops to ask.
- The model used is `models\ggml-small.bin`. To use a different model,
  edit the `MODEL` line near the top of `transcribe.bat`.
- Language is auto-detected.
