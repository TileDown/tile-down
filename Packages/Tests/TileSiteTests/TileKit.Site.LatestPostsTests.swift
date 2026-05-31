import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Latest posts")
struct SiteLatestPostsTests {
    @Test("a page with latest: true lists the newest posts, newest first")
    func latestPostsOnOptedInPage() throws {
        let fileSystem = MemoryFileSystem(files: latestFixtureFiles())

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // Default count is 3: the three newest, newest first, on the home page.
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home == "<li>Newest</li><li>Middle</li><li>Older</li>")
    }

    @Test("latestPosts count caps how many are shown")
    func latestPostsCountCaps() throws {
        let fileSystem = MemoryFileSystem(files: latestFixtureFiles())

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil, latestPostCount: 2),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home == "<li>Newest</li><li>Middle</li>")
    }

    @Test("a page without latest: true shows no latest block")
    func noLatestBlockWhenNotOptedIn() throws {
        var files = latestFixtureFiles()
        files["content/index.md"] = "---\ntitle: Home\n---\n# Home"
        let fileSystem = MemoryFileSystem(files: files)

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home == "")
    }

    @Test("latestPosts in the configuration file parses and rejects bad values")
    func latestPostsParsing() throws {
        let file = try TileKit.Site.ConfigurationFile.parse("latestPosts: 5")
        #expect(file.configuration.latestPostCount == 5)

        let defaultFile = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(defaultFile.configuration.latestPostCount == 3)

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidLatestPosts("soon")) {
            try TileKit.Site.ConfigurationFile.parse("latestPosts: soon")
        }
    }

    private func latestFixtureFiles() -> [String: String] {
        [
            "content/index.md": "---\ntitle: Home\nlatest: true\n---\n# Home",
            "content/posts/index.md": "---\ntitle: Posts\n---\n# Posts",
            "content/posts/older/index.md": "---\ntitle: Older\ndate: 2026-05-01\n---\n# Older",
            "content/posts/middle/index.md": "---\ntitle: Middle\ndate: 2026-05-10\n---\n# Middle",
            "content/posts/newest/index.md": "---\ntitle: Newest\ndate: 2026-05-20\n---\n# Newest",
            "templates/page.html": [
                "{{#page.latest}}{{#site.latestPosts}}",
                "<li>{{ title }}</li>",
                "{{/site.latestPosts}}{{/page.latest}}",
            ].joined(),
        ]
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
