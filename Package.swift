// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Primer",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
      .library(
        name: "Primer",
        targets: ["Primer"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-atomics.git", from: "0.0.3"),
      .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
      .target(
        name: "Primer",
        dependencies: [
          .product(name: "Atomics", package: "swift-atomics"),
          .product(name: "Logging", package: "swift-log")
        ],
        path: "Sources/Primer//"),
      .testTarget(
        name: "PrimerTests",
        dependencies: ["Primer"]),
    ]
)
