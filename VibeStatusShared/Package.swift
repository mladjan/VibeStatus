// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VibeStatusShared",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "VibeStatusShared",
            targets: ["VibeStatusShared"]),
    ],
    targets: [
        .target(
            name: "VibeStatusShared",
            dependencies: [])
    ]
)
