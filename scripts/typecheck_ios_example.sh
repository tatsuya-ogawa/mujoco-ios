#!/usr/bin/env bash
# Typecheck the Swift wrapper and iOS example without requiring a simulator runtime.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"
MODULE_CACHE="${ROOT_DIR}/build/swift-module-cache"
MODULE_DIR="${ROOT_DIR}/build/swift-modules"
MUJOCO_HEADERS="${ROOT_DIR}/output/mujoco.xcframework/ios-arm64_x86_64-simulator/Headers"

if [[ ! -d "${MUJOCO_HEADERS}" ]]; then
  printf '[error] Missing %s. Run `make build` first.\n' "${MUJOCO_HEADERS}" >&2
  exit 1
fi

mkdir -p "${MODULE_CACHE}" "${MODULE_DIR}"

swiftc \
  -target arm64-apple-ios16.0-simulator \
  -sdk "${SDK_PATH}" \
  -module-cache-path "${MODULE_CACHE}" \
  -I "${MUJOCO_HEADERS}" \
  -emit-module \
  -parse-as-library \
  -module-name MuJoCo \
  "${ROOT_DIR}/Sources/MuJoCo/MuJoCo.swift" \
  -emit-module-path "${MODULE_DIR}/MuJoCo.swiftmodule"

swiftc \
  -target arm64-apple-ios16.0-simulator \
  -sdk "${SDK_PATH}" \
  -module-cache-path "${MODULE_CACHE}" \
  -I "${MODULE_DIR}" \
  -I "${MUJOCO_HEADERS}" \
  -typecheck \
  -parse-as-library \
  "${ROOT_DIR}/examples/MujocoExample/Sources/"*.swift

printf '[typecheck] iOS Swift wrapper and example passed.\n'
