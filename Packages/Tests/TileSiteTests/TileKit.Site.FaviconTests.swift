import Testing
import TileCore
@testable import TileSite

@Suite("Site favicon")
struct SiteFaviconTests {
    @Test("configuration parses favicon paths")
    func parsesFaviconPath() throws {
        let file = try TileKit.Site.ConfigurationFile.parse("favicon: /favicon.ico")
        #expect(file.configuration.faviconPath == "/favicon.ico")

        let alias = try TileKit.Site.ConfigurationFile.parse("faviconPath: /assets/icon.svg")
        #expect(alias.configuration.faviconPath == "/assets/icon.svg")

        let bare = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(bare.configuration.faviconPath.isEmpty)
    }

    @Test("built-in layouts emit configured favicon links")
    func faviconLink() throws {
        for layout in [TileKit.Site.Layout.topNav, .leftSidebar] {
            let html = try built(layout: layout, faviconPath: "/favicon.ico")
            let icon = try #require(
                html.range(of: #"<link rel="icon" href="https://example.com/docs/favicon.ico">"#),
            )
            let headClose = try #require(html.range(of: "</head>"))
            #expect(icon.upperBound <= headClose.lowerBound)
        }
    }

    @Test("built-in layouts omit favicon links by default")
    func noFaviconByDefault() throws {
        let html = try built(layout: .topNav, faviconPath: "")
        #expect(!html.contains(#"rel="icon""#))
    }

    private func built(
        layout: TileKit.Site.Layout,
        faviconPath: String,
    ) throws -> String {
        let fileSystem = MemoryFileSystem(
            files: ["content/index.md": "---\ntitle: Home\n---\n# Home"],
        )
        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(layout),
                outputRootPath: "dist",
                configuration: .init(
                    baseURL: "https://example.com/docs",
                    faviconPath: faviconPath,
                ),
            ),
        )
        return try #require(fileSystem.files["dist/index.html"])
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
