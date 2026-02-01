#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Removing all Zephyr workspaces"
rm -rf "${ROOT_DIR}/workspaces"

echo "Clean complete"
