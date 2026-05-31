import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTile

@Suite("Site references")
struct ReferenceTests {
    @Test("page, post, and tag references resolve to engine-owned URLs")
    func referencesResolve() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": [
                    "---\ntitle: Home\n---\n",
                    "See my [talks](page:speaking), [that piece](post:first), ",
                    "and [Swift posts](tag:Swift).",
                ].joined(),
                "content/speaking/index.md": "---\ntitle: Speaking\n---\n# Speaking",
                "content/blog/first/index.md": "---\ntitle: First Post\ndate: 2026-05-01\ntags: Swift\n---\n# First",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil, postsDirectory: "blog"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<a href="/speaking/">talks</a>"#))
        #expect(home.contains(#"<a href="/blog/first/">that piece</a>"#))
        #expect(home.contains(#"<a href="/tags/swift/">Swift posts</a>"#))
        // No reference scheme leaks into the output.
        #expect(!home.contains("page:"))
        #expect(!home.contains("tag:"))
    }

    @Test("a social reference resolves to the configured external URL")
    func socialReferenceResolves() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\nFind me on [GitHub](social:github).",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(
                    theme: nil,
                    socialLinks: [.init(label: "GitHub", url: "https://github.com/me")],
                ),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<a href="https://github.com/me">GitHub</a>"#))
    }

    @Test("a link reference resolves to a generated out/ redirect shim")
    func outboundLinkShim() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\nShipping [Cupertino](link:cupertino).",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(
                    theme: nil,
                    outboundLinks: ["cupertino": "https://github.com/me/cupertino"],
                ),
            ),
        )

        // The reference points at the stable local shim, not the external URL.
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<a href="/out/cupertino/">Cupertino</a>"#))
        // The shim page forwards to the external target.
        let shim = try #require(fileSystem.files["dist/out/cupertino/index.html"])
        #expect(shim.contains(#"url=https://github.com/me/cupertino"#))
        #expect(shim.contains(#"rel="canonical" href="https://github.com/me/cupertino""#))
    }

    @Test("an empty anchor fills with the target's display name")
    func emptyAnchorFillsDisplayName() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\nGo to [](page:speaking).",
                "content/speaking/index.md": "---\ntitle: Speaking\n---\n# Speaking",
                "templates/page.html": "{{{ page.contents.html }}}",
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

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<a href="/speaking/">Speaking</a>"#))
    }

    @Test("an unknown reference fails the build")
    func unknownReferenceFails() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\nBroken [link](page:nope).",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        #expect(throws: TileKit.Site.ReferenceError.self) {
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

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(
                    passthroughSchemes: TileKit.Site.Reference.schemes,
                ),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
