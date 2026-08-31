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

## Privacy

Transcription runs entirely on your machine using whisper.cpp and ffmpeg,
both bundled in this folder. Nothing is uploaded anywhere. Neither the
recording nor the transcript ever leaves your computer.

## Notes

- If a `.txt` output already exists: dropping a single file asks whether
  to overwrite it; dropping multiple files writes `Name.transcript.txt`
  instead so a batch run never stops to ask.
- The model used is `models\ggml-small.bin`. To use a different model,
  edit the `MODEL` line near the top of `transcribe.bat`.
- Language is auto-detected.
