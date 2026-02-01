#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Check Zephyr version
# -----------------------------
if [[ -z "${ZEPHYR_VERSION:-}" ]]; then
    echo "Error: ZEPHYR_VERSION not set."
    echo "Example: export ZEPHYR_VERSION=4.2"
    exit 1
fi

# -----------------------------
# Paths
# -----------------------------
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
VERSION_DIR="$ROOT_DIR/versions/zephyr-$ZEPHYR_VERSION"
BUILD_DIR="$ROOT_DIR/.build/$ZEPHYR_VERSION"
VENV_DIR="$BUILD_DIR/venv"
SDK_DIR="$BUILD_DIR/sdk"
WEST_WS="$BUILD_DIR/west"
SDK_CACHE_DIR="$ROOT_DIR/Build/sdk_tarballs"

mkdir -p "$SDK_CACHE_DIR"

# -----------------------------
# Idempotency: skip if workspace exists
# -----------------------------
if [[ -d "$WEST_WS/../.west" ]]; then
    echo "Zephyr $ZEPHYR_VERSION workspace already initialized at $WEST_WS"
    exit 0
fi

mkdir -p "$BUILD_DIR"

# -----------------------------
# Create per-version Python virtualenv
# -----------------------------
echo "==> Creating virtualenv at $VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install west
pip install matplotlib
# -----------------------------
# Determine SDK version and minimal archive
# -----------------------------
case "$ZEPHYR_VERSION" in
  3.7.1)
      SDK_VERSION=0.16.8
      SDK_ARCHIVE="zephyr-sdk-${SDK_VERSION}_linux-x86_64_minimal.tar.xz"
      ;;
  4.0|4.1|4.2)
      SDK_VERSION=0.17.0
      SDK_ARCHIVE="zephyr-sdk-${SDK_VERSION}_linux-x86_64_minimal.tar.xz"
      ;;
  4.3)
      SDK_VERSION=0.17.4
      SDK_ARCHIVE="zephyr-sdk-${SDK_VERSION}_linux-x86_64_minimal.tar.xz"
      ;;
  *)
      echo "Unsupported Zephyr version $ZEPHYR_VERSION"
      exit 1
      ;;
esac

SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/${SDK_ARCHIVE}"
SDK_ARCHIVE_PATH="$SDK_CACHE_DIR/$SDK_ARCHIVE"

# -----------------------------
# Download SDK tarball if not present
# -----------------------------
if [[ ! -f "$SDK_ARCHIVE_PATH" ]]; then
    echo "==> Downloading Zephyr minimal SDK tarball $SDK_ARCHIVE"
    curl -L "$SDK_URL" -o "$SDK_ARCHIVE_PATH"
else
    echo "==> Using cached SDK tarball $SDK_ARCHIVE_PATH"
fi

# -----------------------------
# Extract SDK if not already installed
# -----------------------------
if [[ ! -d "$SDK_DIR" || ! -f "$SDK_DIR/.installed_arm" ]]; then
    echo "==> Extracting minimal SDK to $SDK_DIR"
    mkdir -p "$SDK_DIR"
    tar -xJf "$SDK_ARCHIVE_PATH" -C "$SDK_DIR" --strip-components=1

    echo "==> Installing ARM Zephyr toolchain"
    if [[ -x "$SDK_DIR/setup.sh" ]]; then
        bash "$SDK_DIR/setup.sh" -c -t arm-zephyr-eabi
    else
        echo "Error: setup.sh not found in $SDK_DIR"
        exit 1
    fi

    touch "$SDK_DIR/.installed_arm"
else
    echo "ARM Zephyr toolchain already installed at $SDK_DIR"
fi

export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="$SDK_DIR"

# -----------------------------
# Initialize West workspace
# -----------------------------
mkdir -p "$WEST_WS"
cp "$VERSION_DIR/west.yml" "$WEST_WS/west.yml"

cd "$WEST_WS"/..

west init -l "$WEST_WS"
west update -n -o=--depth=1
west zephyr-export

# -----------------------------
# Install Zephyr Python requirements
# -----------------------------
REQ_FILE="$WEST_WS/zephyr/scripts/requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    echo "==> Installing Zephyr Python requirements for $ZEPHYR_VERSION"
    pip install -r "$REQ_FILE"
fi

REQ_FILE="$WEST_WS/../zephyr/scripts/requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    echo "==> Installing Zephyr Python requirements for $ZEPHYR_VERSION"
    pip install -r "$REQ_FILE"
fi

# -----------------------------
# Done
# -----------------------------
echo "==> Zephyr $ZEPHYR_VERSION workspace ready at $WEST_WS"
echo "SDK path: $SDK_DIR"
echo "Virtualenv: $VENV_DIR"
echo "Cached minimal SDK: $SDK_ARCHIVE_PATH"

# -----------------------------
# Clean environment variables
# -----------------------------
deactivate || true
unset ZEPHYR_TOOLCHAIN_VARIANT
unset ZEPHYR_SDK_INSTALL_DIR
