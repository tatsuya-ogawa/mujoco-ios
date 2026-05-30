// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MuJoCo",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(name: "MuJoCo", targets: ["MuJoCo"]),
    .library(name: "CMuJoCo", targets: ["mujoco"]),
  ],
  targets: [
    .binaryTarget(
      name: "mujoco",
      url: "https://github.com/tatsuya-ogawa/mujoco-ios/releases/download/v0.1.0/mujoco.xcframework.zip",
      checksum: "c60d1f0a6bacd1dd89c4d04567f9eb85372c57c8ff0c5664814bc113be588082"
    ),
    .target(
      name: "MuJoCo",
      dependencies: ["mujoco"],
      path: "Sources/MuJoCo"
    ),
  ]
)
