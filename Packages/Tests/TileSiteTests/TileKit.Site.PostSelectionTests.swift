import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Post selection")
struct SitePostSelectionTests {
    @Test("a post with a malformed date is excluded from both the listing and the feed")
    func malformedDateExcludedFromBoth() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/good/index.md": "---\ntitle: Good Post\ndate: 2026-05-29\n---\n# Good",
                "content/posts/bad/index.md": "---\ntitle: Bad Post\ndate: soon\n---\n# Bad",
                "templates/page.html": [
                    "{{{ page.contents.html }}}",
                    "{{#page.postList}}{{#site.posts}}<li>{{ title }}</li>{{/site.posts}}{{/page.postList}}",
                ].joined(),
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(
                    baseURL: "https://example.com",
                    theme: nil,
                    feed: .init(path: "feed.xml"),
                ),
            ),
        )

        // The listing and the feed agree: the parseable-date post is in both,
        // the malformed-date post is in neither.
        let listing = try #require(fileSystem.files["dist/posts/index.html"])
        #expect(listing.contains("Good Post"))
        #expect(!listing.contains("Bad Post"))

        let feed = try #require(fileSystem.files["dist/feed.xml"])
        #expect(feed.contains("Good Post"))
        #expect(!feed.contains("Bad Post"))
    }

    @Test("parsedDate accepts yyyy-MM-dd and rejects anything else")
    func parsedDate() {
        #expect(TileKit.Site.PostSelection.parsedDate("2026-05-29") != nil)
        #expect(TileKit.Site.PostSelection.parsedDate("soon") == nil)
        #expect(TileKit.Site.PostSelection.parsedDate("") == nil)
        #expect(TileKit.Site.PostSelection.parsedDate(nil) == nil)
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
