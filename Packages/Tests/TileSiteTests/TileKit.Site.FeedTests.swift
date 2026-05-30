import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site feed")
struct SiteFeedTests {
    @Test("writes an RSS feed for dated post pages when configured")
    func writesRSSFeed() throws {
        let fileSystem = MemoryFileSystem(
            files: feedFixtureFiles(),
        )
        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: feedConfiguration(),
            ),
        )

        #expect(result.outputPaths.first == "dist/feed.xml")
        try assertHomeLinks(fileSystem.files["dist/index.html"])
        try assertFeed(fileSystem.files["dist/feed.xml"])
    }

    private func feedFixtureFiles() -> [String: String] {
        [
            "content/index.md": "---\ntitle: Home\n---\n# Home",
            "content/posts/index.md": "---\ntitle: Posts\n---\n# Posts",
            "content/posts/first/index.md": """
            ---
            title: First Post
            date: 2026-05-28
            description: The first post.
            ---
            # First
            """,
            "content/posts/second/index.md": """
            ---
            title: Second Post
            date: 2026-05-30
            description: The second post.
            ---
            # Second
            """,
            "content/posts/draft/index.md": """
            ---
            title: Draft Post
            description: Missing a publish date.
            ---
            # Draft
            """,
            "content/posts/undated/index.md": """
            ---
            title: Undated Post
            date: coming soon
            description: Invalid publish date.
            ---
            # Undated
            """,
            "templates/page.html": [
                #"<a href="{{ site.feedPath }}">RSS</a>"#,
                #"{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}"#,
            ].joined(),
        ]
    }

    private func feedConfiguration() -> TileKit.Site.Configuration {
        .init(
            title: "Demo",
            baseURL: "https://example.com",
            theme: nil,
            socialLinks: [
                .init(label: "GitHub", url: "https://github.com/TileDown/tile-down"),
            ],
            feed: .init(
                path: "feed.xml",
                title: "Demo Feed",
                description: "Demo posts.",
            ),
        )
    }

    private func assertHomeLinks(
        _ output: String?,
    ) throws {
        let home = try #require(output)
        #expect(home.contains(#"<a href="https://example.com/feed.xml">RSS</a>"#))
        #expect(home.contains(#"<a href="https://github.com/TileDown/tile-down">GitHub</a>"#))
    }

    private func assertFeed(
        _ output: String?,
    ) throws {
        let feed = try #require(output)
        #expect(feed.contains("<title>Demo Feed</title>"))
        #expect(feed.contains("<link>https://example.com/</link>"))
        #expect(feed.contains("<description>Demo posts.</description>"))
        #expect(feed.contains("<pubDate>Sat, 30 May 2026 00:00:00 +0000</pubDate>"))
        let secondPostIndex = try #require(feed.range(of: "Second Post")?.lowerBound)
        let firstPostIndex = try #require(feed.range(of: "First Post")?.lowerBound)
        #expect(secondPostIndex < firstPostIndex)
        #expect(!feed.contains("/posts/</link>"))
        #expect(!feed.contains("Draft Post"))
        #expect(!feed.contains("Undated Post"))
        // The feed carries the whole rendered post body, not just the summary,
        // through the content extension in a CDATA section.
        #expect(feed.contains(#"xmlns:content="http://purl.org/rss/1.0/modules/content/""#))
        #expect(feed.contains("<content:encoded><![CDATA[<h1>First</h1>"))
        #expect(feed.contains("<content:encoded><![CDATA[<h1>Second</h1>"))
    }

    @Test("rejects feed paths outside the output directory")
    func rejectsEscapingFeedPath() {
        let fileSystem = MemoryFileSystem(
            files: feedFixtureFiles(),
        )

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath("../feed.xml")) {
            _ = try makeGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .file(path: "templates/page.html"),
                    outputRootPath: "dist",
                    configuration: .init(
                        title: "Demo",
                        theme: nil,
                        feed: .init(path: "../feed.xml"),
                    ),
                ),
            )
        }
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
