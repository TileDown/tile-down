import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site metadata hero images")
struct SiteMetadataHeroTests {
    @Test("metadata uses hero front matter fallback")
    func heroFrontMatterMetadataFallback() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                hero: /assets/home-hero.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(baseURL: "https://example.com"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        let imageURL = "https://example.com/assets/home-hero.png"
        #expect(home.contains(#"<meta property="og:image" content="\#(imageURL)">"#))
        #expect(home.contains(#"<meta name="twitter:image" content="\#(imageURL)">"#))
        #expect(home.contains(#"<meta name="twitter:card" content="summary_large_image">"#))
    }

    @Test("metadata image front matter wins over hero fallback")
    func imageFrontMatterMetadataPrecedence() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /assets/canonical.png
                hero: /assets/migration.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(baseURL: "https://example.com"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(
            #"<meta property="og:image" content="https://example.com/assets/canonical.png">"#,
        ))
        #expect(home.contains(
            #"<meta name="twitter:image" content="https://example.com/assets/canonical.png">"#,
        ))
        #expect(!home.contains("migration.png"))
    }

    @Test("metadata omits hero fallback when no absolute base URL is available")
    func heroFrontMatterMetadataOmittedWithoutBaseURL() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                hero: /assets/home-hero.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(baseURL: "/docs"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<meta name="twitter:card" content="summary">"#))
        #expect(!home.contains(#"property="og:image""#))
        #expect(!home.contains(#"name="twitter:image""#))
    }

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
