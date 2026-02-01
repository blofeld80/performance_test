#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Check version
# -----------------------------
if [[ -z "${ZEPHYR_VERSION:-}" ]]; then
    echo "Error: ZEPHYR_VERSION not set."
    echo "Example: export ZEPHYR_VERSION=4.2"
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="$ROOT_DIR/.build/$ZEPHYR_VERSION"
VENV_DIR="$BUILD_DIR/venv"
SDK_DIR="$BUILD_DIR/sdk"
WEST_WS="$BUILD_DIR/west"

# -----------------------------
# Exit if workspace already exists
# -----------------------------
if [[ -d "$WEST_WS/.west" ]]; then
    echo "Zephyr $ZEPHYR_VERSION workspace already initialized at $WEST_WS"
    exit 0
fi

mkdir -p "$BUILD_DIR"

# -----------------------------
# Python virtualenv per version
# -----------------------------
echo "==> Creating virtualenv at $VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install west

# -----------------------------
# Download ARM-only SDK (or full SDK for 3.7.1)
# -----------------------------
case "$ZEPHYR_VERSION" in
  3.7.1)
      SDK_VERSION=0.16.8
      SDK_ARCHIVE="zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.xz"
      ;;
  4.*)
      SDK_VERSION=0.17.0
      SDK_ARCHIVE="zephyr-sdk-${SDK_VERSION}-arm-zephyr-eabi_linux-x86_64.tar.xz"
      ;;
  *)
      echo "Unsupported version $ZEPHYR_VERSION"
      exit 1
      ;;
esac

SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/${SDK_ARCHIVE}"

if [[ ! -d "$SDK_DIR" || ! -f "$SDK_DIR/.installed" ]]; then
    echo "==> Downloading Zephyr SDK $SDK_VERSION"
    mkdir -p "$SDK_DIR"
    curl -L "$SDK_URL" -o "$BUILD_DIR/$SDK_ARCHIVE"

    echo "==> Extracting SDK"
    tar -xJf "$BUILD_DIR/$SDK_ARCHIVE" -C "$SDK_DIR" --strip-components=1

    touch "$SDK_DIR/.installed"
else
    echo "SDK already installed at $SDK_DIR"
fi

export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="$SDK_DIR"

# -----------------------------
# Initialize West workspace
# -----------------------------
mkdir -p "$WEST_WS"
cd "$WEST_WS"

west init -l "$ROOT_DIR/versions/zephyr-$ZEPHYR_VERSION"
west update
west zephyr-export

# -----------------------------
# Install Zephyr Python dependencies for this version
# -----------------------------
REQ_FILE="$WEST_WS/zephyr/scripts/requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    echo "==> Installing Zephyr Python requirements for $ZEPHYR_VERSION"
    pip install -r "$REQ_FILE"
else
    echo "Warning: requirements.txt not found in $REQ_FILE"
fi

echo "==> Workspace initialized at $WEST_WS"
