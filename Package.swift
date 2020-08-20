// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mariachi",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "mariachiLib"),
        .target(
            name: "mariachi",
            dependencies: [
              .target(name: "mariachiLib"),
              .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
        .testTarget(
            name: "mariachiEndToEndTests",
            dependencies: ["mariachi"]),
        .testTarget(
            name: "mariachiUnitTests",
            dependencies: ["mariachi", "mariachiLib"])
    ]
)
