// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MujocoExample",
  platforms: [
    .iOS(.v16)
  ],
  dependencies: [
    .package(path: "../.."),
  ],
  targets: [
    .executableTarget(
      name: "MujocoExample",
      dependencies: [
        .product(name: "MuJoCo", package: "mujoco-ios"),
      ],
      path: "Sources"
    ),
  ]
)
