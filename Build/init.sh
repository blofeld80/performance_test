#!/usr/bin/env bash
set -e

ZEPHYR_VERSION="$1"

if [ -z "$ZEPHYR_VERSION" ]; then
  echo "Usage: ./init.sh <zephyr-version>"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${ROOT_DIR}/workspaces/${ZEPHYR_VERSION}"
VENV_DIR="${WORK_DIR}/venv"
MANIFEST="${ROOT_DIR}/west-manifests/zephyr-${ZEPHYR_VERSION}.yml"

if [ ! -f "${MANIFEST}" ]; then
  echo "Missing manifest: ${MANIFEST}"
  exit 1
fi

mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

echo "=== init: Zephyr ${ZEPHYR_VERSION} ==="

# Python venv
if [ ! -d "${VENV_DIR}" ]; then
  echo "Creating Python virtual environment"
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install west
else
  source venv/bin/activate
fi

# West workspace
if [ ! -d "${WORK_DIR}/.west" ]; then
  echo "Initializing west workspace"
  west init -m "${MANIFEST}"
  west update
else
  echo "West workspace already initialized"
fi

# Python requirements
pip install -r zephyr/scripts/requirements.txt >/dev/null

# Zephyr SDK
SDK_VERSION=$(grep -E "ZEPHYR_SDK_VERSION" zephyr/CMakeLists.txt | sed -E 's/.*\"(.*)\"/\1/')
SDK_DIR="${WORK_DIR}/zephyr-sdk-${SDK_VERSION}"

if [ ! -d "${SDK_DIR}" ]; then
  echo "Installing Zephyr SDK ${SDK_VERSION}"
  wget -q https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.gz
  tar xf zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.gz
  "${SDK_DIR}/setup.sh" -h -c
else
  echo "Zephyr SDK already installed"
fi

# Environment file
ENV_FILE="${WORK_DIR}/env.sh"
if [ ! -f "${ENV_FILE}" ]; then
  cat <<EOF > "${ENV_FILE}"
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=${SDK_DIR}
export ZEPHYR_BASE=${WORK_DIR}/zephyr
EOF
fi

echo "=== init complete ==="
