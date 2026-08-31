# Handover: Simple Local Windows Audio/Video Transcriber

## Goal

Build a **very simple, fully local Windows transcription utility**.

The user should be able to take a Zoom recording (audio or video), **drag it onto a `.bat` file**, and have the recording transcribed locally.

The transcript should:

1. Be saved as a `.txt` file next to the original recording.
2. Optionally be copied automatically to the Windows clipboard.

No cloud APIs or third-party transcription services should be used.

---

## Scope

### In scope

* Windows
* Drag-and-drop interface using a `.bat` file
* Audio/video input files such as:

    * `.mp4`
    * `.m4a`
    * `.mp3`
    * `.wav`
    * `.mov`
    * `.webm`
* Fully local speech-to-text
* Whisper-based transcription
* `.txt` output next to source file
* Clipboard support
* Multiple files dropped onto the `.bat` should ideally be supported
* Simple error handling and progress/status output

### Explicitly out of scope

Do NOT build:

* GUI
* Electron/Tauri application
* Docker application
* Web application
* Recording functionality
* Google Meet integration
* Zoom integration/API
* Ollama integration
* Summarization
* Meeting notes
* Speaker identification
* Cloud transcription
* User accounts
* Automatic uploads
* Database

Keep the implementation deliberately simple.

---

# Recommended technical approach

Use **whisper.cpp** rather than Python/faster-whisper for the first version.

The reason is deployment simplicity.

The target should ideally be a self-contained directory containing:

```text
Transcriber/
├── transcribe.bat
├── whisper-cli.exe
├── ffmpeg.exe
└── models/
    └── ggml-small.bin
```

The user should not need to install:

* Python
* pip
* virtual environments
* Docker
* Node.js
* CUDA
* any cloud service

The application should work by running `transcribe.bat`.

---

# User experience

The primary workflow should be:

```text
Zoom recording.mp4
        │
        │ drag onto
        ▼
 transcribe.bat
        │
        ▼
 local Whisper transcription
        │
        ├── Zoom recording.txt
        │
        └── transcript copied to clipboard
```

Example:

```text
C:\Meetings\
    Team Meeting.mp4
    Team Meeting.txt
```

The user can then open `Team Meeting.txt` or paste the transcript elsewhere using `Ctrl+V`.

---

# Drag-and-drop behaviour

Windows passes dropped files to a batch file as arguments.

For example:

```bat
transcribe.bat "C:\Meetings\Team Meeting.mp4"
```

The script should process `%~1`.

Ideally support multiple files:

```bat
transcribe.bat "meeting1.mp4" "meeting2.mp4" "meeting3.m4a"
```

The batch file should loop over all supplied arguments.

For each file:

1. Validate that it exists.
2. Determine output path.
3. Run transcription.
4. Write transcript next to source.
5. Optionally copy transcript to clipboard.
6. Continue with the next file.

---

# Output naming

Given:

```text
C:\Meetings\Team Meeting.mp4
```

produce:

```text
C:\Meetings\Team Meeting.txt
```

Do not overwrite an existing transcript silently.

Possible behaviour:

```text
Team Meeting.txt already exists.
Overwrite? [Y/N]
```

Alternatively, use a suffix such as:

```text
Team Meeting.transcript.txt
```

Choose whichever produces the cleanest user experience.

---

# Whisper model

Use a Whisper model compatible with whisper.cpp.

Start with:

```text
small
```

For example:

```text
ggml-small.bin
```

The implementation should make the model path configurable near the top of the script:

```bat
set MODEL=models\ggml-small.bin
```

Do not hard-code an absolute path.

A future version could allow:

```bat
transcribe.bat --model medium recording.mp4
```

but this is **not required for version 1**.

---

# Language

Ideally allow Whisper to auto-detect the language.

If this makes the initial implementation unnecessarily complicated, default to **german**.

Do not assume that recordings are always English or german.

---

# Audio extraction / decoding

Zoom recordings may be video files such as `.mp4`.

Whisper needs audio.

Use `ffmpeg.exe` to handle input decoding/extraction as necessary.

The implementation should not require the user to manually extract audio first.

Conceptually:

```text
input.mp4
   │
   ▼
ffmpeg
   │
   ▼
audio stream
   │
   ▼
whisper.cpp
   │
   ▼
transcript
```

If whisper.cpp can directly consume the relevant input format reliably, use that; otherwise use ffmpeg to produce a temporary WAV file.

Temporary files should be removed after transcription.

---

# Transcript format

A simple `.txt` file is sufficient.

Prefer timestamps because they make the transcript useful for long meetings.

For example:

```text
[00:00:04] Hello everyone, thanks for joining.

[00:00:12] Today I'd like to discuss the project timeline.

[00:00:24] The first milestone is scheduled for next Friday.
```

Exact formatting can be adjusted according to whisper.cpp's output capabilities.

Do not attempt speaker diarization in version 1.

---

# Clipboard

After successfully generating the transcript, copy the text to the Windows clipboard.

The simplest approach is to use the built-in Windows command:

```bat
clip
```

For example:

```bat
type "%OUTPUT%" | clip
```

The user should then be able to paste the transcript with:

```text
Ctrl+V
```

If multiple files are processed, the clipboard behaviour should be clearly defined.

Recommended:

* For a single input file: copy that transcript to clipboard.
* For multiple files: disable clipboard behaviour.

---

# Console UX

The batch file should be understandable to a non-technical user.

Example:

```text
========================================
 Local Meeting Transcriber
========================================

Input:
C:\Meetings\Team Meeting.mp4

Model:
small

Transcribing...

[Whisper output / progress]

Transcript saved:
C:\Meetings\Team Meeting.txt

Transcript copied to clipboard.

Done.
Press any key to exit...
```

For multiple files:

```text
Processing file 1 of 3...
...
Processing file 2 of 3...
...
Processing file 3 of 3...
...
All files processed.
```

---

# Error handling

Handle at least these cases:

### No file supplied

If the user launches the `.bat` directly:

```text
No recording was supplied.

Drag a recording onto transcribe.bat.
```

Then exit.

### File does not exist

Display an error and continue with other files if applicable.

### ffmpeg missing

Display:

```text
Error: ffmpeg.exe was not found.
```

Explain that it must exist in the expected directory.

### Whisper executable missing

Display a clear error.

### Model missing

Display:

```text
Error: Whisper model not found:
models\ggml-small.bin
```

### Transcription failure

Do not delete the original recording.

Clean up temporary files and continue with remaining inputs.

---

# Privacy requirement

This is a core requirement.

The utility must perform transcription **entirely locally**.

There must be:

* no network requests
* no cloud API
* no telemetry
* no analytics
* no automatic upload
* no external transcription API

The input recording and transcript should remain on the user's machine.

If whisper.cpp itself has no network functionality, the application should not add any.

---

# Distribution

The ideal result should be a folder that can simply be copied to another Windows machine.

For example:

```text
LocalTranscriber/
│
├── transcribe.bat
├── whisper-cli.exe
├── ffmpeg.exe
│
└── models/
    └── ggml-small.bin
```

The user can then drag a recording onto:

```text
transcribe.bat
```

No installer is required for the first version.

---

# Important implementation consideration

Do not assume the exact whisper.cpp executable name or command-line syntax without checking the current whisper.cpp release.

The agent should inspect the version being used and construct the command appropriately.

Likewise, obtain compatible model files for the chosen whisper.cpp version.

The goal is a **working reproducible package**, not merely pseudocode.

---

# Suggested development steps

1. Obtain/build a Windows-compatible whisper.cpp executable.
2. Obtain a compatible `ggml-small.bin` model.
3. Obtain a Windows ffmpeg executable.
4. Test whisper.cpp manually against a Zoom `.mp4`.
5. Confirm transcription quality.
6. Create `transcribe.bat`.
7. Add drag-and-drop handling.
8. Add output naming.
9. Add temporary audio handling if required.
10. Add clipboard support using `clip`.
11. Add error handling.
12. Test with:

* MP4
* M4A
* MP3
* WAV
* filenames containing spaces
* filenames containing parentheses
* multiple dropped files

13. Package the resulting directory.

---

# Definition of done

The project is successful when a user can:

1. Copy the `LocalTranscriber` directory to a Windows machine.
2. Obtain/install nothing else.
3. Drag:

```text
Zoom Meeting.mp4
```

onto:

```text
transcribe.bat
```

4. Wait for transcription.
5. Find:

```text
Zoom Meeting.txt
```

next to the recording.
6. Press `Ctrl+V` in another application and get the transcript.
7. Have performed the entire operation without the recording or transcript leaving the machine.

Keep the implementation focused on this workflow. Do not introduce a GUI, cloud services, Ollama, summarization, recording, or other functionality at this stage.
