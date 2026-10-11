// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swiftui-backdrop-blur",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "BackdropBlur", targets: ["BackdropBlur"])
  ],
  targets: [
    .target(name: "BackdropBlur"),
    .testTarget(name: "BackdropBlurTests", dependencies: ["BackdropBlur"])
  ],
  swiftLanguageModes: [.v6]
)
