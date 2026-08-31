# winsper — Local Windows Meeting Transcriber

Fully local, offline transcription for Windows. Drag a recording onto
`transcribe.bat`, get a `.txt` transcript next to it. Uses
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) and ffmpeg — no
cloud APIs, no accounts. See `specs/requirements.md` for the full spec.

## Repo layout

```
winsper/
├── src/                     # source of truth for the shipped scripts
│   ├── transcribe.bat       # drag-and-drop entry point
│   ├── README.txt           # end-user docs, bundled into the release
│   ├── internal/            # setup.bat, install-model.bat, download.ps1 (not user-facing)
│   ├── bin/                 # populated by setup.bat
│   └── models/              # populated by setup.bat
├── scripts/build.sh         # packages src/ into the release zip
├── dist/                    # build output — gitignored
└── specs/requirements.md
```

Only `transcribe.bat` and `README.txt` sit at top level in the release,
so it's obvious what to drag onto. `whisper-cli.exe`, `ffmpeg.exe`, and
the model are not bundled — `setup.bat` fetches them on first run.
Always edit `src/`, never `dist/`.

## Build / Release

```bash
./scripts/build.sh
```

Zips `src/` into `dist/LocalTranscriber.zip`. To publish:

```bash
gh release create v1.0.0 dist/LocalTranscriber.zip --title "v1.0.0" --notes "..."
```

## Setup (end users)

Download `LocalTranscriber.zip` from Releases, extract anywhere on
Windows. Nothing else to install — the first run of `transcribe.bat`
downloads whisper.cpp, ffmpeg, and the model (~500 MB, one-time,
progress bar shown) before transcribing.

## Run / Use

Drag one or more recordings onto `transcribe.bat`. Produces `Name.txt`
next to each; a single dropped file also gets copied to the clipboard.
An existing `.txt` triggers an overwrite prompt (single file) or a
`Name.transcript.txt` fallback (multiple files).

Running `transcribe.bat` with nothing dropped on it offers to install
another model (a size-annotated list to pick from); if multiple models
are installed, dropping files asks which one to use. See `src/README.txt`
for full end-user details.
