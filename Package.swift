// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ServerlessLogger",
    platforms: [
        .macOS(.v10_11),.iOS(.v9),
    ],
    products: [
        .library(
            name: "ServerlessLogger",
            targets: ["ServerlessLogger"]),
    ],
    dependencies: [
        .package(name: "XCGLogger", url: "https://github.com/DaveWoodCom/XCGLogger.git", .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "ServerlessLogger",
            dependencies: ["XCGLogger"]),
        .testTarget(
            name: "ServerlessLoggerTests",
            dependencies: ["ServerlessLogger"]),
    ]
)
