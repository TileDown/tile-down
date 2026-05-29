// swift-tools-version: 6.0
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency=complete"),
]

extension Product {
    static func singleTargetLibrary(
        _ name: String,
    ) -> Product {
        .library(name: name, targets: [name])
    }
}

let packageDependencies: [Package.Dependency] = []

let allProducts: [Product] = [
    .singleTargetLibrary("TileCore"),
    .singleTargetLibrary("TileContent"),
    .singleTargetLibrary("TileMarkdown"),
    .singleTargetLibrary("TileSite"),
    .singleTargetLibrary("TileSiteImpl"),
    .singleTargetLibrary("TileService"),
    .singleTargetLibrary("TileServiceForm"),
    .singleTargetLibrary("TileSource"),
    .singleTargetLibrary("TileTemplate"),
    .singleTargetLibrary("TileTile"),
    .singleTargetLibrary("TileKit"),
    .executable(name: "tiledown", targets: ["TiledownCLI"]),
]

let targets: [Target] = {
    // ---------- Foundation Layer ----------
    let tileCoreTarget = Target.target(
        name: "TileCore",
        swiftSettings: swiftSettings,
    )
    let tileCoreTestsTarget = Target.testTarget(
        name: "TileCoreTests",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileCoreTargets = [tileCoreTarget, tileCoreTestsTarget]

    // ---------- Domain Layer ----------
    let tileContentTarget = Target.target(
        name: "TileContent",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileContentTestsTarget = Target.testTarget(
        name: "TileContentTests",
        dependencies: [
            "TileContent",
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileContentTargets = [tileContentTarget, tileContentTestsTarget]

    let tileMarkdownTarget = Target.target(
        name: "TileMarkdown",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileMarkdownTestsTarget = Target.testTarget(
        name: "TileMarkdownTests",
        dependencies: [
            "TileCore",
            "TileMarkdown",
        ],
        swiftSettings: swiftSettings,
    )
    let tileMarkdownTargets = [tileMarkdownTarget, tileMarkdownTestsTarget]

    let tileSourceTarget = Target.target(
        name: "TileSource",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileSourceTestsTarget = Target.testTarget(
        name: "TileSourceTests",
        dependencies: [
            "TileCore",
            "TileSource",
        ],
        swiftSettings: swiftSettings,
    )
    let tileSourceTargets = [tileSourceTarget, tileSourceTestsTarget]

    let tileTemplateTarget = Target.target(
        name: "TileTemplate",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileTemplateTestsTarget = Target.testTarget(
        name: "TileTemplateTests",
        dependencies: [
            "TileCore",
            "TileTemplate",
        ],
        swiftSettings: swiftSettings,
    )
    let tileTemplateTargets = [tileTemplateTarget, tileTemplateTestsTarget]

    let tileTileTarget = Target.target(
        name: "TileTile",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileTileTestsTarget = Target.testTarget(
        name: "TileTileTests",
        dependencies: [
            "TileCore",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileTileTargets = [tileTileTarget, tileTileTestsTarget]

    let tileServiceTarget = Target.target(
        name: "TileService",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServiceTestsTarget = Target.testTarget(
        name: "TileServiceTests",
        dependencies: [
            "TileCore",
            "TileService",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServiceTargets = [tileServiceTarget, tileServiceTestsTarget]

    let tileServiceFormTarget = Target.target(
        name: "TileServiceForm",
        dependencies: [
            "TileCore",
            "TileService",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServiceFormTestsTarget = Target.testTarget(
        name: "TileServiceFormTests",
        dependencies: [
            "TileCore",
            "TileService",
            "TileServiceForm",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServiceFormTargets = [tileServiceFormTarget, tileServiceFormTestsTarget]

    let tileSiteTarget = Target.target(
        name: "TileSite",
        dependencies: [
            "TileCore",
            "TileMarkdown",
            "TileSource",
            "TileTemplate",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileSiteTestsTarget = Target.testTarget(
        name: "TileSiteTests",
        dependencies: [
            "TileCore",
            "TileMarkdown",
            "TileService",
            "TileServiceForm",
            "TileSite",
            "TileSource",
            "TileTemplate",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileSiteTargets = [tileSiteTarget, tileSiteTestsTarget]

    // ---------- Implementation Layer ----------
    let tileSiteImplTarget = Target.target(
        name: "TileSiteImpl",
        dependencies: [
            "TileCore",
            "TileSite",
        ],
        swiftSettings: swiftSettings,
    )
    let tileSiteImplTestsTarget = Target.testTarget(
        name: "TileSiteImplTests",
        dependencies: [
            "TileCore",
            "TileSite",
            "TileSiteImpl",
        ],
        swiftSettings: swiftSettings,
    )
    let tileSiteImplTargets = [tileSiteImplTarget, tileSiteImplTestsTarget]

    // ---------- Facade Layer ----------
    let tileKitTarget = Target.target(
        name: "TileKit",
        dependencies: [
            "TileContent",
            "TileCore",
            "TileMarkdown",
            "TileSite",
            "TileSiteImpl",
            "TileService",
            "TileServiceForm",
            "TileSource",
            "TileTemplate",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileKitTestsTarget = Target.testTarget(
        name: "TileKitTests",
        dependencies: [
            "TileKit",
        ],
        swiftSettings: swiftSettings,
    )
    let tileKitTargets = [tileKitTarget, tileKitTestsTarget]

    // ---------- Front Door ----------
    let tiledownCLITarget = Target.executableTarget(
        name: "TiledownCLI",
        dependencies: [
            "TileKit",
        ],
        swiftSettings: swiftSettings,
    )
    let frontDoorTargets = [tiledownCLITarget]

    return tileCoreTargets
        + tileContentTargets
        + tileMarkdownTargets
        + tileSourceTargets
        + tileTemplateTargets
        + tileTileTargets
        + tileServiceTargets
        + tileServiceFormTargets
        + tileSiteTargets
        + tileSiteImplTargets
        + tileKitTargets
        + frontDoorTargets
}()

let package = Package(
    name: "Tiledown",
    platforms: [
        .macOS(.v14),
    ],
    products: allProducts,
    dependencies: packageDependencies,
    targets: targets,
)
