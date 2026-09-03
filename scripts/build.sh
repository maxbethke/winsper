#!/usr/bin/env bash
# Packages the src/ scripts into a distributable LocalTranscriber folder
# and zips it into dist/, ready to attach to a GitHub release.
#
# Usage:
#   ./scripts/build.sh        CPU build  -> dist/LocalTranscriber.zip
#   ./scripts/build.sh cuda   CUDA build -> dist/LocalTranscriber-CUDA.zip
#                              (GPU-accelerated, needs an NVIDIA GPU, falls
#                              back to CPU automatically if none is found)
#
# Dependencies (whisper.cpp, ffmpeg, the model) are NOT bundled here -
# setup.bat downloads those on the end user's machine on first run. This
# keeps the release zip tiny and always fetches the current model/binaries.
set -euo pipefail

VARIANT="${1:-cpu}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT/src"
DIST_DIR="$ROOT/dist"

case "$VARIANT" in
    cpu)
        STAGE_NAME="LocalTranscriber"
        SETUP_SRC="$SRC_DIR/internal/setup.bat"
        ;;
    cuda)
        STAGE_NAME="LocalTranscriber-CUDA"
        SETUP_SRC="$SRC_DIR/internal/setup-cuda.bat"
        ;;
    *)
        echo "Unknown variant: $VARIANT (expected 'cpu' or 'cuda')" >&2
        exit 1
        ;;
esac

STAGE_DIR="$DIST_DIR/$STAGE_NAME"
ZIP_PATH="$DIST_DIR/$STAGE_NAME.zip"

echo "Assembling runtime folder ($VARIANT)..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/internal"

cp "$SRC_DIR/transcribe.bat" "$STAGE_DIR/"
cp "$SRC_DIR/README.txt" "$STAGE_DIR/"
cp "$SETUP_SRC" "$STAGE_DIR/internal/setup.bat"
cp "$SRC_DIR/internal/download.ps1" "$STAGE_DIR/internal/"
cp "$SRC_DIR/internal/install-model.bat" "$STAGE_DIR/internal/"

echo "Creating zip..."
mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
(cd "$DIST_DIR" && zip -qr "$(basename "$ZIP_PATH")" "$(basename "$STAGE_DIR")")

echo ""
echo "Done: $ZIP_PATH"
du -h "$ZIP_PATH"
