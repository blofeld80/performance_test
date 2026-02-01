#!/usr/bin/env bash
set -e

ZEPHYR_VERSION="$1"

if [ -z "$ZEPHYR_VERSION" ]; then
  echo "Usage: ./build.sh <zephyr-version>"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${ROOT_DIR}/workspaces/${ZEPHYR_VERSION}"
APP_DIR="${ROOT_DIR}/../Device"
BUILD_DIR="${WORK_DIR}/build"
PRJ_CONF="${ROOT_DIR}/prj-conf/${ZEPHYR_VERSION}.conf"

if [ ! -f "${PRJ_CONF}" ]; then
  echo "Missing prj.conf: ${PRJ_CONF}"
  exit 1
fi

# Ensure environment exists
"${ROOT_DIR}/init.sh" "${ZEPHYR_VERSION}"

cd "${WORK_DIR}"
source venv/bin/activate
source env.sh

west build \
  -b nucleo_f767zi \
  -s "${APP_DIR}" \
  -d "${BUILD_DIR}" \
  --pristine \
  -- \
  -DCONF_FILE="${PRJ_CONF}"
