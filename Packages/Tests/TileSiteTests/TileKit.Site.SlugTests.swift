import Testing
import TileCore
@testable import TileSite

extension SiteGeneratorTests {
    @Test("a slug front-matter value overrides the folder-derived output path")
    func slugOverrideMovesOutput() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/renamed/index.md": "---\ntitle: Renamed\nslug: posts/custom-slug\n---\n# Renamed",
                "templates/page.html": "{{{ contents }}}",
            ],
        )

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // The override decides the output path; the folder slug no longer does.
        #expect(fileSystem.files["dist/posts/custom-slug/index.html"] != nil)
        #expect(fileSystem.files["dist/posts/renamed/index.html"] == nil)
        #expect(result.outputPaths.contains("dist/posts/custom-slug/index.html"))
    }

    @Test("surrounding slashes in a slug override are trimmed")
    func slugOverrideTrimsSlashes() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/about/index.md": "---\ntitle: About\nslug: /info/\n---\n# About",
                "templates/page.html": "{{{ contents }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        #expect(fileSystem.files["dist/info/index.html"] != nil)
        #expect(fileSystem.files["dist/about/index.html"] == nil)
    }

    @Test("two pages resolving to the same slug are a typed error")
    func duplicateSlugThrows() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/a/index.md": "---\ntitle: A\nslug: shared\n---\n# A",
                "content/b/index.md": "---\ntitle: B\nslug: shared\n---\n# B",
                "templates/page.html": "{{{ contents }}}",
            ],
        )

        #expect(throws: TileKit.Site.ConfigurationFileError.duplicateSlug("shared")) {
            try makeGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .file(path: "templates/page.html"),
                    outputRootPath: "dist",
                    configuration: .init(theme: nil),
                ),
            )
        }
    }

    @Test("an explicit slug colliding with a folder slug is a typed error")
    func duplicateSlugAgainstFolderSlugThrows() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/a/index.md": "---\ntitle: A\nslug: b\n---\n# A",
                "content/b/index.md": "---\ntitle: B\n---\n# B",
                "templates/page.html": "{{{ contents }}}",
            ],
        )

        #expect(throws: TileKit.Site.ConfigurationFileError.duplicateSlug("b")) {
            try makeGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .file(path: "templates/page.html"),
                    outputRootPath: "dist",
                    configuration: .init(theme: nil),
                ),
            )
        }
    }

    @Test("a post can publish outside the posts directory and remain a post")
    func migratedPostSlugRemainsPost() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/writings/index.md": "---\ntitle: Writings\npostList: true\n---\n# Writings",
                "content/writings/legacy/index.md": """
                ---
                title: Legacy Post
                date: 2026-05-20
                tags: Swift
                slug: blog/legacy
                ---
                # Legacy Post
                """,
                "templates/page.html": [
                    "{{{ page.contents.html }}}",
                    "{{# site.posts }}<a class=\"post\" href=\"{{ url }}\">{{ title }}</a>{{/ site.posts }}",
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
                    feed: .init(
                        path: "feed.xml",
                        title: "Feed",
                        description: "Updates",
                    ),
                    postsDirectory: "writings",
                ),
            ),
        )

        let listing = try #require(fileSystem.files["dist/writings/index.html"])
        let tag = try #require(fileSystem.files["dist/tags/swift/index.html"])
        let feed = try #require(fileSystem.files["dist/feed.xml"])

        #expect(fileSystem.files["dist/blog/legacy/index.html"] != nil)
        #expect(fileSystem.files["dist/writings/legacy/index.html"] == nil)
        #expect(listing.contains(#"<a class="post" href="https://example.com/blog/legacy/">Legacy Post</a>"#))
        #expect(tag.contains(#"<a class="post" href="https://example.com/blog/legacy/">Legacy Post</a>"#))
        #expect(feed.contains("<link>https://example.com/blog/legacy/</link>"))
    }
}
