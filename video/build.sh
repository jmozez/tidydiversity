#!/usr/bin/env bash
# Build the tidydiversity marketing video. Run from the package root:
#   bash video/build.sh <build-dir> <kokoro-dir>
# <kokoro-dir> holds kokoro-v1.0.onnx and voices-v1.0.bin from
# https://github.com/thewh1teagle/kokoro-onnx/releases (model-files-v1.0).
set -euo pipefail
B=$(realpath -m "${1:-video/build}"); K=$(realpath "${2:?kokoro dir}")
mkdir -p "$B/fig"; cp man/figures/logo.png "$B/logo.png"
Rscript video/figures.R "$B/fig"
python3 video/narration.py "$B" "$K/kokoro-v1.0.onnx" "$K/voices-v1.0.bin"
node video/render.mjs "$B" 30
python3 video/mix.py "$B" video/tidydiversity.mp4
