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
      path: "output/mujoco.xcframework"
    ),
    .target(
      name: "MuJoCo",
      dependencies: ["mujoco"],
      path: "Sources/MuJoCo"
    ),
  ]
)
