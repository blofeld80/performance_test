#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Check Zephyr version
# -----------------------------
if [[ -z "${ZEPHYR_VERSION:-}" ]]; then
    echo "Error: ZEPHYR_VERSION not set"
    echo "Example: export ZEPHYR_VERSION=4.2"
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
VERSION_DIR="$ROOT_DIR/versions/zephyr-$ZEPHYR_VERSION"
BUILD_DIR="$ROOT_DIR/.build/$ZEPHYR_VERSION"
WEST_WS="$BUILD_DIR/west"
VENV_DIR="$BUILD_DIR/venv"
DEVICE_DIR="$ROOT_DIR/Device"

# -----------------------------
# Ensure workspace initialized
# -----------------------------
"$ROOT_DIR/Build/init.sh"

# -----------------------------
# Activate virtualenv
# -----------------------------
source "$VENV_DIR/bin/activate"

# -----------------------------
# Set Zephyr environment variables locally
# -----------------------------
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="$BUILD_DIR/sdk"

# -----------------------------
# Copy version-specific prj.conf into Device/
# -----------------------------
cp "$VERSION_DIR/prj.conf" "$DEVICE_DIR/prj.conf"

# -----------------------------
# Build the project
# -----------------------------
cd "$WEST_WS"
west build -b nucleo_f767zi "$DEVICE_DIR"
west build -b nucleo_f767zi "$DEVICE_DIR" -t ram_report
west build -b nucleo_f767zi "$DEVICE_DIR" -t rom_report


RELEASE_DIR="$ROOT_DIR/Release"
mkdir -p "$RELEASE_DIR"


# -----------------------------
# Copy artifacts to Release
# -----------------------------
BUILD_OUT="$BUILD_DIR/west/build"


cp "$BUILD_OUT/zephyr/zephyr.elf" "$RELEASE_DIR/zephyr-$ZEPHYR_VERSION.elf"
cp "$BUILD_OUT/zephyr/zephyr.map" "$RELEASE_DIR/zephyr-$ZEPHYR_VERSION.map"
cp "$BUILD_OUT/zephyr/.config" "$RELEASE_DIR/zephyr-$ZEPHYR_VERSION.config"
cp "$BUILD_OUT/ram.json" "$RELEASE_DIR/zephyr-$ZEPHYR_VERSION-ram.json"
cp "$BUILD_OUT/rom.json" "$RELEASE_DIR/zephyr-$ZEPHYR_VERSION-rom.json"


echo "=> Build and reports for Zephyr $ZEPHYR_VERSION copied to Release/"


# -----------------------------
# Deactivate virtualenv and unset env vars
# -----------------------------
deactivate || true
unset ZEPHYR_TOOLCHAIN_VARIANT
unset ZEPHYR_SDK_INSTALL_DIR







