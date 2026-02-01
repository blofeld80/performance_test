#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)


VERSIONS=("3.7.1" "4.0" "4.1" "4.2" "4.3")

for VER in "${VERSIONS[@]}"; do
    echo "======================================"
    echo " Building Zephyr $VER "
    echo "======================================"

    export ZEPHYR_VERSION="$VER"

    # Call existing build.sh
    "$ROOT_DIR/Build/build.sh"

    # Deactivate virtualenv if active
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        deactivate || true
    fi

    # Unset all environment variables set during init/build
    unset ZEPHYR_VERSION
    unset ZEPHYR_TOOLCHAIN_VARIANT
    unset ZEPHYR_SDK_INSTALL_DIR
done

echo "All builds complete. Release folder: $RELEASE_DIR"
