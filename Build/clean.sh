#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_ROOT="$ROOT_DIR/.build"

if [[ -d "$BUILD_ROOT" ]]; then
    echo "==> Removing all build artifacts in $BUILD_ROOT"
    rm -rf "$BUILD_ROOT"
fi

# Remove prj.conf copied to Device/
if [[ -f "$ROOT_DIR/Device/prj.conf" ]]; then
    rm -f "$ROOT_DIR/Device/prj.conf"
fi

echo "Clean complete."
