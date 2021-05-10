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
        targets: ["Utility", "CxxUtility"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
      .target(
        name: "CxxUtility",
        path: "Sources/CxxUtility/"),
      .target(
        name: "Utility",
        dependencies: ["CxxUtility"],
        path: "Sources/Utility//"),
      .testTarget(
        name: "UtilityTests",
        dependencies: ["Utility"]),
    ]
)
