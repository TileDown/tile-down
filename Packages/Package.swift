// swift-tools-version: 6.0
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency=complete"),
]

let package = Package(
    name: "Tiledown",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "TileKit", targets: ["TileKit"]),
        .executable(name: "tiledown", targets: ["TiledownCLI"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TileKit",
            swiftSettings: swiftSettings,
        ),
        .executableTarget(
            name: "TiledownCLI",
            dependencies: [
                "TileKit",
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "TileKitTests",
            dependencies: [
                "TileKit",
            ],
            swiftSettings: swiftSettings,
        ),
    ],
)
