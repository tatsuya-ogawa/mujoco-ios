#!/usr/bin/env bash
# Package the generated XCFramework for GitHub Releases and SwiftPM checksums.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
XCFRAMEWORK="${ROOT_DIR}/output/mujoco.xcframework"
DIST_DIR="${ROOT_DIR}/dist"
ZIP_PATH="${DIST_DIR}/mujoco.xcframework.zip"
CHECKSUM_PATH="${ZIP_PATH}.checksum"
SNIPPET_PATH="${DIST_DIR}/Package.binary-target.snippet.swift"

REPOSITORY="${GITHUB_REPOSITORY:-OWNER/REPO}"
RELEASE_TAG="${RELEASE_TAG:-${GITHUB_REF_NAME:-vX.Y.Z}}"

if [[ ! -d "${XCFRAMEWORK}" ]]; then
  printf '[error] Missing %s. Run `make build` first.\n' "${XCFRAMEWORK}" >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

ditto -c -k --sequesterRsrc --keepParent "${XCFRAMEWORK}" "${ZIP_PATH}"
swift package compute-checksum "${ZIP_PATH}" > "${CHECKSUM_PATH}"

CHECKSUM="$(cat "${CHECKSUM_PATH}")"
cat > "${SNIPPET_PATH}" <<EOF
.binaryTarget(
  name: "mujoco",
  url: "https://github.com/${REPOSITORY}/releases/download/${RELEASE_TAG}/mujoco.xcframework.zip",
  checksum: "${CHECKSUM}"
)
EOF

printf '[release] Wrote %s\n' "${ZIP_PATH}"
printf '[release] Wrote %s\n' "${CHECKSUM_PATH}"
printf '[release] Wrote %s\n' "${SNIPPET_PATH}"
