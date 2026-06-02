import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site metadata")
struct SiteMetadataTests {
    @Test("built-in layouts emit page metadata")
    func pageMetadata() throws {
        try assertPageMetadata(layout: .topNav, outputPath: "dist-top/about/index.html")
        try assertPageMetadata(layout: .leftSidebar, outputPath: "dist-side/about/index.html")
    }

    @Test("dated posts emit article metadata")
    func articleMetadata() throws {
        let fileSystem = makeArticleFileSystem()
        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    title: "Metadata Site",
                    baseURL: "https://example.com/docs",
                ),
            ),
        )

        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        #expect(post.contains(#"<link rel="canonical" href="https://example.com/docs/posts/first/">"#))
        #expect(post.contains(#"<meta property="og:type" content="article">"#))
        #expect(post.contains(#"<meta property="article:published_time" content="2026-05-28T00:00:00Z">"#))
        let articleImage = "https://example.com/docs/posts/first/media/hero.png"
        #expect(post.contains(#"<meta property="og:image" content="\#(articleImage)">"#))
        #expect(post.contains(#"<meta name="twitter:image" content="\#(articleImage)">"#))
        #expect(post.contains(#"<meta name="twitter:card" content="summary_large_image">"#))
    }

    @Test("metadata uses explicit output slugs")
    func customSlugMetadata() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/renamed/index.md": """
                ---
                title: Renamed Post
                date: 2026-05-28
                description: Custom slug summary.
                image: media/hero.png
                slug: posts/custom-slug
                ---
                # Renamed
                """,
            ],
        )
        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    title: "Metadata Site",
                    baseURL: "https://example.com/docs",
                ),
            ),
        )

        let post = try #require(fileSystem.files["dist/posts/custom-slug/index.html"])
        let canonicalURL = "https://example.com/docs/posts/custom-slug/"
        let imageURL = "https://example.com/docs/posts/custom-slug/media/hero.png"
        #expect(fileSystem.files["dist/posts/renamed/index.html"] == nil)
        #expect(post.contains(#"<link rel="canonical" href="\#(canonicalURL)">"#))
        #expect(post.contains(#"<meta property="og:url" content="\#(canonicalURL)">"#))
        #expect(post.contains(#"<meta property="og:type" content="article">"#))
        #expect(post.contains(#"<meta property="og:image" content="\#(imageURL)">"#))
        #expect(post.contains(#"<meta name="twitter:image" content="\#(imageURL)">"#))
    }

    @Test("optional metadata is omitted when no absolute public URL is available")
    func optionalMetadataOmittedWithoutBaseURL() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /assets/hero.png
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
        #expect(home.contains(#"<meta property="og:type" content="website">"#))
        #expect(home.contains(#"<meta name="twitter:card" content="summary">"#))
        #expect(!home.contains(#"rel="canonical""#))
        #expect(!home.contains(#"name="description""#))
        #expect(!home.contains(#"property="og:url""#))
        #expect(!home.contains(#"property="og:image""#))
        #expect(!home.contains(#"name="twitter:image""#))
        #expect(!home.contains(#"article:published_time"#))
    }

    @Test("malformed absolute metadata image URLs are omitted")
    func malformedAbsoluteImageURLsAreOmitted() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: https:/assets/hero.png
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
        #expect(home.contains(#"<link rel="canonical" href="https://example.com/">"#))
        #expect(home.contains(#"<meta name="twitter:card" content="summary">"#))
        #expect(!home.contains(#"property="og:image""#))
        #expect(!home.contains(#"name="twitter:image""#))
        #expect(!home.contains(#"property="og:image" content="https:/assets/hero.png""#))
        #expect(!home.contains(#"name="twitter:image" content="https:/assets/hero.png""#))
    }

    private func assertPageMetadata(
        layout: TileKit.Site.Layout,
        outputPath: String,
    ) throws {
        let fileSystem = makePageFileSystem()
        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(layout),
                outputRootPath: outputPath.replacingOccurrences(
                    of: "/about/index.html",
                    with: "",
                ),
                configuration: .init(
                    title: "Metadata Site",
                    baseURL: "https://example.com/docs",
                ),
            ),
        )

        let page = try #require(fileSystem.files[outputPath])
        #expect(page.contains(#"<title>About &amp; Work</title>"#))
        #expect(page.contains(#"<meta name="description" content="A page about &quot;work&quot; &amp; writing.">"#))
        #expect(page.contains(#"<link rel="canonical" href="https://example.com/docs/about/">"#))
        #expect(page.contains(#"<meta property="og:title" content="About &amp; Work">"#))
        #expect(page.contains(#"<meta property="og:type" content="website">"#))
        let description = "A page about &quot;work&quot; &amp; writing."
        #expect(page.contains(#"<meta property="og:description" content="\#(description)">"#))
        #expect(page.contains(#"<meta property="og:url" content="https://example.com/docs/about/">"#))
        #expect(page.contains(#"<meta property="og:site_name" content="Metadata Site">"#))
        #expect(page.contains(#"<meta property="og:image" content="https://example.com/docs/assets/about.png">"#))
        #expect(page.contains(#"<meta name="twitter:card" content="summary_large_image">"#))
        #expect(page.contains(#"<meta name="twitter:title" content="About &amp; Work">"#))
        #expect(page.contains(#"<meta name="twitter:description" content="\#(description)">"#))
        #expect(page.contains(#"<meta name="twitter:image" content="https://example.com/docs/assets/about.png">"#))
        #expect(!page.contains(#"article:published_time"#))
    }

    private func makePageFileSystem() -> MemoryFileSystem {
        MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/about/index.md": """
                ---
                title: About & Work
                description: A page about "work" & writing.
                image: /assets/about.png
                ---
                # About
                """,
            ],
        )
    }

    private func makeArticleFileSystem() -> MemoryFileSystem {
        MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/first/index.md": """
                ---
                title: First Post
                date: 2026-05-28
                description: Post summary.
                image: media/hero.png
                ---
                # First
                """,
            ],
        )
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
