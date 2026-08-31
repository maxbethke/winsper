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
- Default model is `ggml-small.bin`. Language is auto-detected.

## Installing more models

Run `transcribe.bat` with nothing dropped onto it (just double-click
it). After the component check, it asks "Install another model? [Y/N]".
Answer Y to pick from a list (tiny/base/small/medium/large-v3, with
sizes) and it downloads the chosen one into `models\`.

Larger models are slower but more accurate; smaller ones are faster but
less accurate.

If more than one model is installed, `transcribe.bat` asks which one to
use each time you drop files onto it.
