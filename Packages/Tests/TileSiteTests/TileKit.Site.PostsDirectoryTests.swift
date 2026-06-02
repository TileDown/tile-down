import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Posts directory")
struct SitePostsDirectoryTests {
    @Test("a configured postsDir drives both the listing and the feed")
    func customPostsDirectory() throws {
        let fileSystem = MemoryFileSystem(files: postsFixtureFiles())

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(
                    baseURL: "https://example.com",
                    theme: nil,
                    feed: .init(path: "feed.xml"),
                    postsDirectory: "blog",
                ),
            ),
        )

        // The listing on the blog landing page lists the dated blog post.
        let listing = try #require(fileSystem.files["dist/blog/index.html"])
        #expect(listing.contains("Blog Post"))
        // A dated page under the default posts/ dir is not a blog post.
        #expect(!listing.contains("Stray Post"))

        // The feed agrees with the listing: blog post in, posts/ page out.
        let feed = try #require(fileSystem.files["dist/feed.xml"])
        #expect(feed.contains("Blog Post"))
        #expect(!feed.contains("Stray Post"))
    }

    @Test("the posts directory defaults to posts when unset")
    func defaultPostsDirectory() throws {
        let fileSystem = MemoryFileSystem(files: postsFixtureFiles())

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

        // With the default, the posts/ page is a post and the blog/ page is not.
        let feed = try #require(fileSystem.files["dist/feed.xml"])
        #expect(feed.contains("Stray Post"))
        #expect(!feed.contains("Blog Post"))
    }

    @Test("postList false suppresses built-in listing sections")
    func postListFalseSuppressesListing() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\npostList: false\n---\n# Home",
                "content/empty/index.md": "---\ntitle: Empty\npostList: false\ntag: missing\n---\n# Empty",
                "content/posts/entry/index.md": "---\ntitle: Listed Post\ndate: 2026-05-29\n---\n# Entry",
                "templates/page.html": [
                    "{{{ page.contents.html }}}",
                    "{{#page.postList}}{{#site.posts}}<li>{{ title }}</li>{{/site.posts}}{{/page.postList}}",
                    "{{#page.emptyPosts}}EMPTY{{/page.emptyPosts}}",
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
                ),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(!home.contains("Listed Post"))

        let empty = try #require(fileSystem.files["dist/empty/index.html"])
        #expect(!empty.contains("EMPTY"))
    }

    @Test("postsDir in the configuration file is parsed and slash-normalized")
    func postsDirParsing() throws {
        let file = try TileKit.Site.ConfigurationFile.parse("postsDir: /blog/")
        #expect(file.configuration.postsDirectory == "blog")

        let defaultFile = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(defaultFile.configuration.postsDirectory == "posts")
    }

    private func postsFixtureFiles() -> [String: String] {
        [
            "content/index.md": "---\ntitle: Home\n---\n# Home",
            "content/blog/index.md": "---\ntitle: Blog\npostList: true\n---\n# Blog",
            "content/blog/entry/index.md": "---\ntitle: Blog Post\ndate: 2026-05-29\n---\n# Entry",
            "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
            "content/posts/entry/index.md": "---\ntitle: Stray Post\ndate: 2026-05-29\n---\n# Stray",
            "templates/page.html": [
                "{{{ page.contents.html }}}",
                "{{#page.postList}}{{#site.posts}}<li>{{ title }}</li>{{/site.posts}}{{/page.postList}}",
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
