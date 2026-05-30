#!/usr/bin/env bash
# Build MuJoCo as an iOS xcframework (static library) for Swift Package Manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${ROOT_DIR}/mujoco"
BUILD_ROOT="${ROOT_DIR}/build"
OUTPUT_DIR="${ROOT_DIR}/output"
XCFRAMEWORK="${OUTPUT_DIR}/mujoco.xcframework"
PATCH_FILE="${SCRIPT_DIR}/ios-patches.diff"
MODULEMAP="${SCRIPT_DIR}/module.modulemap"

IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"
CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"
MUJOCO_REF="${MUJOCO_REF:-7667e7110e8cc56135080624d0cac021edcb1ae7}"

# Verify the generator is available; otherwise fall back to Unix Makefiles.
if ! command -v ninja >/dev/null 2>&1; then
  CMAKE_GENERATOR="Unix Makefiles"
fi

log() { printf '\033[1;34m[build]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

if [[ ! -d "${SRC_DIR}/.git" ]]; then
  err "mujoco source not found at ${SRC_DIR}. Run 'make download' first."
  exit 1
fi

apply_patch() {
  log "Resetting mujoco source tree to HEAD"
  git -C "${SRC_DIR}" checkout -- .
  git -C "${SRC_DIR}" clean -fd >/dev/null

  if [[ -n "${MUJOCO_REF}" ]]; then
    if ! git -C "${SRC_DIR}" rev-parse --verify --quiet "${MUJOCO_REF}^{commit}" >/dev/null; then
      log "Fetching MuJoCo ref ${MUJOCO_REF}"
      git -C "${SRC_DIR}" fetch --tags origin "${MUJOCO_REF}"
    fi
    log "Checking out MuJoCo ref ${MUJOCO_REF}"
    git -C "${SRC_DIR}" checkout --detach "${MUJOCO_REF}"
    git -C "${SRC_DIR}" clean -fd >/dev/null
  fi

  log "Applying iOS patches"
  git -C "${SRC_DIR}" apply --whitespace=nowarn "${PATCH_FILE}"
}

# Configure + build a single (sysroot, archs) slice. Produces:
#   ${slice_build}/lib/libmujoco-combined.a
#   ${slice_build}/include/{module.modulemap,mujoco/*.h}
build_slice() {
  local slice_name="$1"
  local sysroot="$2"
  local archs="$3"

  local slice_build="${BUILD_ROOT}/${slice_name}"
  local slice_install="${BUILD_ROOT}/${slice_name}-install"

  log "[${slice_name}] Configuring (sysroot=${sysroot}, archs=${archs})"
  rm -rf "${slice_build}" "${slice_install}"
  mkdir -p "${slice_build}"

  cmake -S "${SRC_DIR}" -B "${slice_build}" -G "${CMAKE_GENERATOR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="${sysroot}" \
    -DCMAKE_OSX_ARCHITECTURES="${archs}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET}" \
    -DCMAKE_MACOSX_BUNDLE=OFF \
    -DCMAKE_C_FLAGS="-Wno-error" \
    -DCMAKE_CXX_FLAGS="-Wno-error" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DMUJOCO_BUILD_IOS_STATIC=ON \
    -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF \
    -DMUJOCO_BUILD_TESTS=OFF \
    -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DMUJOCO_ENABLE_AVX=OFF \
    -DMUJOCO_ENABLE_AVX_INTRINSICS=OFF \
    -DMUJOCO_HARDEN=OFF

  log "[${slice_name}] Building"
  cmake --build "${slice_build}" --parallel --target mujoco

  log "[${slice_name}] Merging static archives"
  local lib_dir="${slice_build}/lib"
  if [[ ! -d "${lib_dir}" ]]; then
    err "Expected lib directory ${lib_dir} not found"
    exit 1
  fi

  # Collect all .a files produced under build/lib (mujoco + bundled deps).
  local archives=()
  while IFS= read -r -d '' a; do
    archives+=("$a")
  done < <(find "${lib_dir}" -maxdepth 1 -type f -name '*.a' -print0)

  if [[ ${#archives[@]} -eq 0 ]]; then
    err "No static libraries produced in ${lib_dir}"
    exit 1
  fi

  log "[${slice_name}] Archives: ${archives[*]##*/}"

  local combined="${slice_build}/libmujoco-combined.a"
  rm -f "${combined}"
  libtool -static -no_warning_for_no_symbols -o "${combined}" "${archives[@]}"

  log "[${slice_name}] Staging headers"
  local include_dst="${slice_build}/include"
  rm -rf "${include_dst}"
  mkdir -p "${include_dst}/mujoco"
  cp -R "${SRC_DIR}/include/mujoco/." "${include_dst}/mujoco/"
  # Remove non-public clang-format file if present.
  rm -f "${include_dst}/mujoco/.clang-format"
  # Drop experimental headers that aren't part of the public C API surface.
  rm -rf "${include_dst}/mujoco/experimental"
  cp "${MODULEMAP}" "${include_dst}/module.modulemap"

  log "[${slice_name}] Slice ready: ${combined}"
}

create_xcframework() {
  log "Creating xcframework at ${XCFRAMEWORK}"
  rm -rf "${XCFRAMEWORK}"
  mkdir -p "${OUTPUT_DIR}"

  local args=()
  for slice in ios-arm64 ios-arm64_x86_64-simulator; do
    args+=( -library "${BUILD_ROOT}/${slice}/libmujoco-combined.a" \
            -headers "${BUILD_ROOT}/${slice}/include" )
  done
  args+=( -output "${XCFRAMEWORK}" )

  xcodebuild -create-xcframework "${args[@]}"
}

main() {
  apply_patch

  build_slice "ios-arm64"                 "iphoneos"        "arm64"
  build_slice "ios-arm64_x86_64-simulator" "iphonesimulator" "arm64;x86_64"

  create_xcframework

  log "Done. xcframework: ${XCFRAMEWORK}"
  ls -la "${XCFRAMEWORK}"
}

main "$@"
