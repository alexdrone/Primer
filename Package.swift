// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utility",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
      .library(
        name: "Utility",
        targets: ["Utility"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-atomics.git", from: "0.0.3"),
      .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
      .target(
        name: "Utility",
        dependencies: [
          .product(name: "Atomics", package: "swift-atomics"),
          .product(name: "Logging", package: "swift-log")
        ],
        path: "Sources/Utility//"),
      .testTarget(
        name: "UtilityTests",
        dependencies: ["Utility"]),
    ]
)
