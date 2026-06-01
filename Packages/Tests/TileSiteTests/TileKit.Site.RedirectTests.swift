import Testing
import TileCore
@testable import TileSite

extension SiteGeneratorTests {
    @Test("redirect content writes a static redirect and stays out of site pages")
    func redirectContentWritesStaticRedirect() throws {
        let fileSystem = redirectFixture()

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(
                    theme: nil,
                    feed: .init(
                        path: "feed.xml",
                        title: "Feed",
                        description: "Updates",
                    ),
                ),
            ),
        )

        #expect(
            result.outputPaths == [
                "dist/feed.xml",
                "dist/index.html",
                "dist/posts/index.html",
                "dist/posts/live/index.html",
                "dist/tags/release/index.html",
                "dist/old-post/index.html",
            ],
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        let listing = try #require(fileSystem.files["dist/posts/index.html"])
        let feed = try #require(fileSystem.files["dist/feed.xml"])
        let redirect = try #require(fileSystem.files["dist/old-post/index.html"])

        #expect(home.contains("Old Post") == false)
        #expect(listing.contains("Old Post") == false)
        #expect(feed.contains("Old Post") == false)
        #expect(fileSystem.files["dist/tags/legacy/index.html"] == nil)
        #expect(redirect.contains(#"rel="canonical" href="/posts/live/""#))
        #expect(redirect.contains(#"content="0; url=/posts/live/""#))
        #expect(redirect.contains(#"<a href="/posts/live/">/posts/live/</a>"#))
        #expect(redirect.contains("<nav>") == false)
    }

    @Test("redirect content requires a target")
    func redirectContentRequiresTarget() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/old-post/index.md": "---\ntype: redirect\n---\n# Old Post",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        #expect(throws: TileKit.Site.RedirectError.missingTarget("content/old-post/index.md")) {
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

    @Test("redirect content rejects blank target values")
    func redirectContentRejectsBlankTargetValues() {
        let fileSystem = MemoryFileSystem(files: [:])
        let page = TileKit.Site.Page(
            sourcePath: "content/old-post/index.md",
            outputPath: "dist/old-post/index.html",
            slug: "old-post",
            document: .init(
                frontMatter: [
                    "type": "redirect",
                    "to": "   \n\t",
                ],
                body: "",
            ),
            html: "",
        )

        #expect(throws: TileKit.Site.RedirectError.missingTarget("content/old-post/index.md")) {
            try makeGenerator(fileSystem: fileSystem).contentRedirects(
                [page],
                outputRootPath: "dist",
            )
        }
    }

    @Test("redirect content skips unused body tile parsing")
    func redirectContentSkipsUnusedBodyTileParsing() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/old-post/index.md": """
                ---
                type: redirect
                to: /posts/live/
                ---
                :::tile counter
                id: stale-counter
                """,
                "templates/page.html": "{{{ page.contents.html }}}",
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

        #expect(result.outputPaths == ["dist/old-post/index.html"])
        #expect(fileSystem.files["dist/old-post/index.html"]?.contains("/posts/live/") == true)
    }

    @Test("redirect output cannot be overwritten by an outbound link shim")
    func redirectContentRejectsOutboundShimCollision() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/out/github/index.md": """
                ---
                title: Old GitHub
                type: redirect
                to: /github/
                ---
                # Old GitHub
                """,
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        #expect(
            throws: TileKit.Site.ConfigurationFileError.duplicateOutputPath(
                "dist/out/github/index.html",
            ),
        ) {
            try makeGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .file(path: "templates/page.html"),
                    outputRootPath: "dist",
                    configuration: .init(
                        theme: nil,
                        outboundLinks: ["github": "https://github.com/"],
                    ),
                ),
            )
        }
    }

    private func redirectFixture() -> MemoryFileSystem {
        let template = [
            #"<nav>{{#pages}}<a href="{{ url }}">{{ title }}</a>{{/pages}}</nav>"#,
            #"{{{ page.contents.html }}}"#,
            #"<section>{{# site.posts }}<a class="post" href="{{ url }}">{{ title }}</a>{{/ site.posts }}</section>"#,
        ].joined()
        return MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/live/index.md": """
                ---
                title: Live Post
                date: 2026-05-20
                tags: release
                ---
                # Live Post
                """,
                "content/old-post/index.md": """
                ---
                title: Old Post
                type: redirect
                to: /posts/live/
                date: 2026-05-19
                tags: legacy
                ---
                # Old Post
                """,
                "templates/page.html": template,
            ],
        )
    }
}
