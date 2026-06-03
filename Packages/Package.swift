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

let packageDependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/apple/swift-markdown",
        from: "0.6.0",
    ),
    .package(
        url: "https://github.com/mihaelamj/MathTypeset.git",
        from: "0.6.0",
    ),
    .package(
        url: "https://github.com/mihaelamj/MarkdownPDF.git",
        from: "0.3.0",
    ),
]

let allProducts: [Product] = [
    .singleTargetLibrary("TileCore"),
    .singleTargetLibrary("TileContent"),
    .singleTargetLibrary("TileMarkdown"),
    .singleTargetLibrary("TileOutput"),
    .singleTargetLibrary("TileSite"),
    .singleTargetLibrary("TileSiteImpl"),
    .singleTargetLibrary("TileService"),
    .singleTargetLibrary("TileServiceForm"),
    .singleTargetLibrary("TileServiceImpl"),
    .singleTargetLibrary("TileServe"),
    .singleTargetLibrary("TileServeImpl"),
    .singleTargetLibrary("TileSource"),
    .singleTargetLibrary("TileTemplate"),
    .singleTargetLibrary("TileTile"),
    .singleTargetLibrary("TileMath"),
    .singleTargetLibrary("TilePDF"),
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
            .product(name: "Markdown", package: "swift-markdown"),
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

    let tileMathTarget = Target.target(
        name: "TileMath",
        dependencies: [
            "TileCore",
            .product(name: "MathTypeset", package: "MathTypeset"),
        ],
        resources: [
            .copy("Resources/latinmodern-math.otf"),
        ],
        swiftSettings: swiftSettings,
    )
    let tileMathTestsTarget = Target.testTarget(
        name: "TileMathTests",
        dependencies: [
            "TileCore",
            "TileMarkdown",
            "TileMath",
        ],
        resources: [
            .copy("Fixtures/math-formulas.md"),
        ],
        swiftSettings: swiftSettings,
    )
    let tileMathTargets = [tileMathTarget, tileMathTestsTarget]

    let tilePDFTarget = Target.target(
        name: "TilePDF",
        dependencies: [
            "TileCore",
            .product(name: "MarkdownPDF", package: "MarkdownPDF"),
        ],
        swiftSettings: swiftSettings,
    )
    let tilePDFTestsTarget = Target.testTarget(
        name: "TilePDFTests",
        dependencies: [
            "TilePDF",
        ],
        swiftSettings: swiftSettings,
    )
    let tilePDFTargets = [tilePDFTarget, tilePDFTestsTarget]

    let mathPlaygroundTarget = Target.executableTarget(
        name: "MathPlaygroundCLI",
        dependencies: [
            "TileCore",
            "TileMath",
        ],
        swiftSettings: swiftSettings,
    )
    let mathPlaygroundTargets = [mathPlaygroundTarget]

    let tileOutputTarget = Target.target(
        name: "TileOutput",
        dependencies: [
            "TileCore",
            "TileMarkdown",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileOutputTestsTarget = Target.testTarget(
        name: "TileOutputTests",
        dependencies: [
            "TileCore",
            "TileMarkdown",
            "TileOutput",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileOutputTargets = [tileOutputTarget, tileOutputTestsTarget]

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
            "TileOutput",
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
            "TileOutput",
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
    let tileServiceImplTarget = Target.target(
        name: "TileServiceImpl",
        dependencies: [
            "TileCore",
            "TileService",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServiceImplTestsTarget = Target.testTarget(
        name: "TileServiceImplTests",
        dependencies: [
            "TileCore",
            "TileService",
            "TileServiceForm",
            "TileServiceImpl",
            "TileTile",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServiceImplTargets = [tileServiceImplTarget, tileServiceImplTestsTarget]

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

    let tileServeTarget = Target.target(
        name: "TileServe",
        dependencies: [
            "TileCore",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServeTestsTarget = Target.testTarget(
        name: "TileServeTests",
        dependencies: [
            "TileCore",
            "TileServe",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServeTargets = [tileServeTarget, tileServeTestsTarget]

    let tileServeImplTarget = Target.target(
        name: "TileServeImpl",
        dependencies: [
            "TileCore",
            "TileServe",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServeImplTestsTarget = Target.testTarget(
        name: "TileServeImplTests",
        dependencies: [
            "TileCore",
            "TileServe",
            "TileServeImpl",
        ],
        swiftSettings: swiftSettings,
    )
    let tileServeImplTargets = [tileServeImplTarget, tileServeImplTestsTarget]

    // ---------- Facade Layer ----------
    let tileKitTarget = Target.target(
        name: "TileKit",
        dependencies: [
            "TileContent",
            "TileCore",
            "TileMarkdown",
            "TileOutput",
            "TileSite",
            "TileSiteImpl",
            "TileService",
            "TileServiceForm",
            "TileServiceImpl",
            "TileServe",
            "TileServeImpl",
            "TileSource",
            "TileTemplate",
            "TileTile",
            "TileMath",
            "TilePDF",
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
    let tiledownCLITestsTarget = Target.testTarget(
        name: "TiledownCLITests",
        dependencies: [
            "TiledownCLI",
        ],
        swiftSettings: swiftSettings,
    )
    let frontDoorTargets = [tiledownCLITarget, tiledownCLITestsTarget]

    return tileCoreTargets
        + tileContentTargets
        + tileMarkdownTargets
        + tileSourceTargets
        + tileTemplateTargets
        + tileTileTargets
        + tileMathTargets
        + tilePDFTargets
        + mathPlaygroundTargets
        + tileOutputTargets
        + tileServiceTargets
        + tileServiceFormTargets
        + tileServiceImplTargets
        + tileSiteTargets
        + tileSiteImplTargets
        + tileServeTargets
        + tileServeImplTargets
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
