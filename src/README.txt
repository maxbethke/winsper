# Local Meeting Transcriber

Fully local, offline speech-to-text. No cloud, no accounts, no upload —
the recording and transcript never leave this machine.

## Usage

Drag one or more recordings onto `transcribe.bat`:

    Team Meeting.mp4  -->  transcribe.bat

Produces `Team Meeting.txt` next to the recording. For a single dropped
file, the transcript is also copied to the clipboard (Ctrl+V to paste).
Supports `.mp4`, `.m4a`, `.mp3`, `.wav`, `.mov`, `.webm` (anything ffmpeg
can decode).

## First run

The first time you use `transcribe.bat`, it downloads whisper.cpp,
ffmpeg, and the speech model (~500 MB, with a progress bar) into `bin\`
and `models\`. This is the only time internet access is used; every
transcription after that runs fully offline. The `internal\` folder just
holds setup machinery — no need to open it.

## Notes

- If a `.txt` already exists: a single dropped file asks to overwrite;
  multiple files write `Name.transcript.txt` instead.
- Model used is `models\ggml-small.bin` — change the `MODEL` line near
  the top of `transcribe.bat` to use a different one.
- Language is auto-detected.
