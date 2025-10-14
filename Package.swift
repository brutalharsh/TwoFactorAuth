// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TwoFactorAuth",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TwoFactorAuth",
            targets: ["TwoFactorAuth"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "TwoFactorAuth",
            dependencies: [],
            path: "TwoFactorAuth"
        ),
    ]
)