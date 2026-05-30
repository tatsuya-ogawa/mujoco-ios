# MuJoCo iOS

<p align="center">
  <strong>Build MuJoCo as an iOS-ready XCFramework and use it from Swift.</strong>
</p>

<p align="center">
  <img alt="iOS 13+" src="https://img.shields.io/badge/iOS-13%2B-111111">
  <img alt="Swift 5.9+" src="https://img.shields.io/badge/Swift-5.9%2B-F05138">
  <img alt="License Apache 2.0" src="https://img.shields.io/badge/license-Apache--2.0-blue">
  <img alt="MuJoCo" src="https://img.shields.io/badge/MuJoCo-pinned%20upstream-3A7AFE">
</p>

`mujoco-ios` is a small Swift Package wrapper and build pipeline for using
[MuJoCo](https://github.com/google-deepmind/mujoco) on iOS. It builds a static
`mujoco.xcframework`, exposes the C API through Swift Package Manager, and ships
with a SwiftUI + SceneKit sample app.

This repository is not an official Google DeepMind project.

## What Is Included

- A pinned MuJoCo source checkout workflow.
- An iOS device slice and iOS Simulator slice packaged as `output/mujoco.xcframework`.
- A Swift package product named `MuJoCo` that re-exports the MuJoCo C module.
- `examples/MujocoExample`, a runnable iOS sample app.
- GitHub Actions workflows for CI and dependency review.

## Quick Start

Build the local XCFramework:

```sh
make download
make build
```

Verify the Swift wrapper and example sources:

```sh
make typecheck
```

Open the example app:

```sh
open examples/MujocoExample/MujocoExample.xcodeproj
```

In Xcode, select the `MujocoExample` scheme and run it on an iPhone Simulator or
connected iPhone. For a physical device, set your Team in `Signing & Capabilities`.

## Swift Usage

After `output/mujoco.xcframework` exists, the root package exposes:

```swift
import MuJoCo

print(MuJoCo.version)
```

The wrapper intentionally keeps the MuJoCo C API visible, so existing MuJoCo C
examples can be ported incrementally.

## Distribution Modes

Pushing `main` to GitHub does not create a GitHub Release by itself. This
repository currently works in source-first mode:

1. Clone the repository.
2. Run `make download`.
3. Run `make build`.
4. Use the local Swift package or run the example app.

That means a clean GitHub clone is usable after the local build step. It is not a
drop-in SwiftPM binary dependency until either:

- `output/mujoco.xcframework` is committed to the repository, or
- `Package.swift` is changed to a `binaryTarget(url:checksum:)` that points at a
  published release asset.

The included release workflow helps with the second path by producing the
release zip and checksum, but a maintainer still needs to update `Package.swift`
for a fully remote SwiftPM binary package.

## Repository Layout

```text
Sources/MuJoCo/              Swift wrapper that re-exports the MuJoCo C module
scripts/build_xcframework.sh Builds the iOS XCFramework
scripts/ios-patches.diff     Minimal patch set for iOS static builds
examples/MujocoExample/      SwiftUI + SceneKit demo app
output/                      Generated XCFramework, not committed
mujoco/                      Downloaded upstream source, not committed
```

## Publishing Notes

`output/mujoco.xcframework` is generated and intentionally ignored by Git. A clean
clone should run:

```sh
make download
make build
```

The MuJoCo upstream revision is pinned in `Makefile` via `MUJOCO_REF`. To test a
new upstream revision:

```sh
make download MUJOCO_REF=<commit-or-tag>
make build MUJOCO_REF=<commit-or-tag>
```

Update `scripts/ios-patches.diff` only when the pinned upstream source changes
and the iOS patch no longer applies cleanly.

## GitHub Releases

GitHub Releases are created from tags, not normal pushes to `main`.

```sh
git tag v0.1.0
git push origin v0.1.0
```

The `Release XCFramework` workflow builds `output/mujoco.xcframework`, packages
it as `mujoco.xcframework.zip`, computes the SwiftPM checksum, and uploads:

- `mujoco.xcframework.zip`
- `mujoco.xcframework.zip.checksum`
- `Package.binary-target.snippet.swift`

Locally, the same release artifacts can be generated with:

```sh
make build
make package-release
```

## Requirements

- macOS with Xcode and iOS SDK installed.
- CMake.
- Ninja is optional; the build script falls back to Unix Makefiles if Ninja is
  unavailable.

## Security

Please see [SECURITY.md](SECURITY.md). In short: do not report exploitable
details in public issues, keep generated binaries out of commits, and review
changes to upstream pins, build scripts, and GitHub Actions carefully.

## License

This repository is licensed under the [Apache License 2.0](LICENSE). MuJoCo is
developed by Google DeepMind and is also distributed under Apache-2.0; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
