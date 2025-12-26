// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sidrat",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Sidrat",
            targets: ["Sidrat"]),
    ],
    targets: [
        .target(
            name: "Sidrat",
            path: "Sidrat"),
        .testTarget(
            name: "SidratTests",
            dependencies: ["Sidrat"]),
    ]
)
