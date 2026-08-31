#!/usr/bin/env bash
# Packages the src/ scripts into the distributable LocalTranscriber folder
# and zips it into dist/, ready to attach to a GitHub release.
#
# Dependencies (whisper.cpp, ffmpeg, the model) are NOT bundled here -
# setup.bat downloads those on the end user's machine on first run. This
# keeps the release zip tiny and always fetches the current model/binaries.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT/src"
DIST_DIR="$ROOT/dist"
STAGE_DIR="$DIST_DIR/LocalTranscriber"
ZIP_PATH="$DIST_DIR/LocalTranscriber.zip"

echo "Assembling runtime folder..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

cp "$SRC_DIR/transcribe.bat" "$STAGE_DIR/"
cp "$SRC_DIR/setup.bat" "$STAGE_DIR/"
cp "$SRC_DIR/README.md" "$STAGE_DIR/"

echo "Creating zip..."
mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
(cd "$DIST_DIR" && zip -qr "$(basename "$ZIP_PATH")" "$(basename "$STAGE_DIR")")

echo ""
echo "Done: $ZIP_PATH"
du -h "$ZIP_PATH"
