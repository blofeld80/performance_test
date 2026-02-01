#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ZEPHYR_VERSION:-}" ]]; then
    echo "Error: ZEPHYR_VERSION not set"
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
VERSION_DIR="$ROOT_DIR/versions/zephyr-$ZEPHYR_VERSION"
BUILD_DIR="$ROOT_DIR/.build/$ZEPHYR_VERSION"
WEST_WS="$BUILD_DIR/west"
DEVICE_DIR="$ROOT_DIR/Device"

# Check required files
[[ -f "$VERSION_DIR/west.yml" ]] || { echo "Missing west.yml"; exit 1; }
[[ -f "$VERSION_DIR/prj.conf" ]] || { echo "Missing prj.conf"; exit 1; }

# Ensure workspace initialized
"$ROOT_DIR/Build/init.sh"

# Activate venv
source "$BUILD_DIR/venv/bin/activate"

# Copy version-specific west.yml and prj.conf
cp "$VERSION_DIR/west.yml" "$WEST_WS/west.yml"
cp "$VERSION_DIR/prj.conf" "$DEVICE_DIR/prj.conf"

# Build
cd "$WEST_WS"
west build -b nucleo_f767zi "$DEVICE_DIR"
