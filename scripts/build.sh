#!/usr/bin/env bash
# Builds the distributable LocalTranscriber runtime folder and zips it into
# dist/, ready to attach to a GitHub release.
#
# Downloads are cached in .build-cache/ and skipped if already present, so
# re-running this script is fast and idempotent. Delete .build-cache/ to
# force fresh downloads.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT/src"
CACHE_DIR="$ROOT/.build-cache"
DIST_DIR="$ROOT/dist"
STAGE_DIR="$DIST_DIR/LocalTranscriber"
ZIP_PATH="$DIST_DIR/LocalTranscriber.zip"

WHISPER_URL="https://github.com/ggml-org/whisper.cpp/releases/latest/download/whisper-bin-x64.zip"
FFMPEG_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"

WHISPER_ZIP="$CACHE_DIR/whisper-bin-x64.zip"
FFMPEG_ZIP="$CACHE_DIR/ffmpeg-win64-gpl.zip"
MODEL_FILE="$CACHE_DIR/ggml-small.bin"

mkdir -p "$CACHE_DIR"

download() {
  local url="$1" dest="$2"
  if [ -f "$dest" ]; then
    echo "Cached, skipping download: $(basename "$dest")"
  else
    echo "Downloading: $(basename "$dest")"
    curl -fSL -o "$dest.part" "$url"
    mv "$dest.part" "$dest"
  fi
}

download "$WHISPER_URL" "$WHISPER_ZIP"
download "$FFMPEG_URL" "$FFMPEG_ZIP"
download "$MODEL_URL" "$MODEL_FILE"

echo "Assembling runtime folder..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/bin" "$STAGE_DIR/models"

cp "$SRC_DIR/transcribe.bat" "$STAGE_DIR/transcribe.bat"
cp "$SRC_DIR/README.md" "$STAGE_DIR/README.md"

WHISPER_EXTRACT="$CACHE_DIR/whisper-extract"
rm -rf "$WHISPER_EXTRACT"
mkdir -p "$WHISPER_EXTRACT"
unzip -q "$WHISPER_ZIP" -d "$WHISPER_EXTRACT"
cp "$WHISPER_EXTRACT/Release/whisper-cli.exe" "$STAGE_DIR/bin/"
cp "$WHISPER_EXTRACT"/Release/ggml*.dll "$STAGE_DIR/bin/"

FFMPEG_EXTRACT="$CACHE_DIR/ffmpeg-extract"
rm -rf "$FFMPEG_EXTRACT"
mkdir -p "$FFMPEG_EXTRACT"
unzip -q "$FFMPEG_ZIP" -d "$FFMPEG_EXTRACT"
FFMPEG_EXE_PATH="$(find "$FFMPEG_EXTRACT" -type f -name ffmpeg.exe | head -1)"
cp "$FFMPEG_EXE_PATH" "$STAGE_DIR/bin/"

cp "$MODEL_FILE" "$STAGE_DIR/models/"

echo "Creating zip..."
mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
(cd "$DIST_DIR" && zip -qr "$(basename "$ZIP_PATH")" "$(basename "$STAGE_DIR")")

echo ""
echo "Done: $ZIP_PATH"
du -h "$ZIP_PATH"
