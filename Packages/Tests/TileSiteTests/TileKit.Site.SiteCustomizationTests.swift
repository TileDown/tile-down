import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site customization")
struct SiteCustomizationTests {
    @Test("built-in layouts render configured social settings")
    func socialSettingsRender() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/tiledown.yml": """
                social.bluesky: https://bsky.app/profile/tiledown.com
                social.mastodon: https://mastodon.social/@tiledown
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: TileKit.Site.ConfigurationFile.parse(
                    fileSystem.files["content/tiledown.yml"] ?? "",
                ).configuration,
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<a href="https://bsky.app/profile/tiledown.com">Bluesky</a>"#))
        #expect(home.contains(#"<a href="https://mastodon.social/@tiledown" rel="me">Mastodon</a>"#))
    }

    @Test("postsLabel renames the posts landing page in nav and heading")
    func postsLabelOverride() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/blog/index.md": "---\ntitle: Blog\n---\n# Blog",
                "templates/page.html": [
                    "<h1>{{ page.title }}</h1>",
                    "<nav>{{#site.sections}}<a>{{ title }}</a>{{/site.sections}}</nav>",
                ].joined(),
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil, postsDirectory: "blog", postsLabel: "Writings"),
            ),
        )

        // The landing page heading uses the label, not "Blog".
        let landing = try #require(fileSystem.files["dist/blog/index.html"])
        #expect(landing.contains("<h1>Writings</h1>"))
        #expect(!landing.contains(">Blog<"))
        // Navigation on the home page shows the label too.
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains("<a>Writings</a>"))
    }

    @Test("fontScale emits a root font-size and parses/validates")
    func fontScaleEmitted() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(fontScale: 1.25),
            ),
        )

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains("html { font-size: 125%; }"))

        // Parsing and validation.
        #expect(try TileKit.Site.ConfigurationFile.parse("fontScale: 1.1").configuration.fontScale == 1.1)
        #expect(try TileKit.Site.ConfigurationFile.parse("title: X").configuration.fontScale == 1)
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidFontScale("big")) {
            try TileKit.Site.ConfigurationFile.parse("fontScale: big")
        }
    }

    @Test("the default font scale emits no root font-size rule")
    func defaultFontScaleNoRule() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(),
            ),
        )

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(!css.contains("html { font-size:"))
    }

    @Test("theme property overrides reskin the shared stylesheet")
    func themePropertyOverrides() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home\n\n:::callout\nmessage: Hello\n:::",
                "content/tiledown.yml": """
                theme.light.accent: #0057d8
                theme.light.radius: 6px
                theme.dark.accent: #66aaff
                theme.dark.surface: #101820
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: TileKit.Site.ConfigurationFile.parse(
                    fileSystem.files["content/tiledown.yml"] ?? "",
                ).configuration,
            ),
        )

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains(":root {\n--td-accent: #0057d8;\n--td-radius: 6px;\n}"))
        #expect(css.contains(#".td-dark-tokens, [data-theme="dark"] {"#))
        #expect(css.contains("--td-accent: #66aaff;\n--td-surface: #101820;"))
        #expect(css.contains(#"[data-theme="dark"]"#))
        #expect(css.contains("@layer reset, theme, tile-override;"))
        #expect(css.contains("var(--td-accent)"))
    }

    @Test("the current section is marked with aria-current in the nav")
    func navMarksCurrentSection() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/about/index.md": "---\ntitle: About\n---\n# About",
                "content/blog/index.md": "---\ntitle: Blog\n---\n# Blog",
                "content/blog/first/index.md": "---\ntitle: First\ndate: 2026-05-01\n---\n# First",
                "templates/page.html": [
                    #"{{#site.sections}}<a href="{{ url }}""#,
                    #"{{#isCurrent}} aria-current="page"{{/isCurrent}}>{{ title }}</a>{{/site.sections}}"#,
                ].joined(),
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

        // On the About page, only About is current.
        let about = try #require(fileSystem.files["dist/about/index.html"])
        #expect(about.contains(#"<a href="/about/" aria-current="page">About</a>"#))
        #expect(about.contains(#"<a href="/blog/">Blog</a>"#))

        // On a post under blog/, the Blog section is current (ancestor match).
        let post = try #require(fileSystem.files["dist/blog/first/index.html"])
        #expect(post.contains(#"<a href="/blog/" aria-current="page">Blog</a>"#))
        #expect(post.contains(#"<a href="/about/">About</a>"#))
    }

    @Test("latestPosts at zero hides the recent-posts block")
    func zeroLatestPostsHidesBlock() throws {
        func built(latestPostCount: Int) throws -> String {
            let fileSystem = MemoryFileSystem(
                files: [
                    "content/index.md": "---\ntitle: Home\nlatest: true\n---\n# Home",
                    "content/posts/first/index.md": "---\ntitle: First\ndate: 2026-05-01\n---\n# First",
                    "templates/page.html": [
                        #"{{#page.latest}}{{#site.hasLatestPosts}}"#,
                        #"<ul class="td-posts"></ul>{{/site.hasLatestPosts}}{{/page.latest}}"#,
                    ].joined(),
                ],
            )
            _ = try makeGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .file(path: "templates/page.html"),
                    outputRootPath: "dist",
                    configuration: .init(theme: nil, latestPostCount: latestPostCount),
                ),
            )
            return try #require(fileSystem.files["dist/index.html"])
        }

        // At zero the block (and its wrapper) is gone; with a positive count it shows.
        #expect(try !built(latestPostCount: 0).contains(#"<ul class="td-posts">"#))
        #expect(try built(latestPostCount: 3).contains(#"<ul class="td-posts">"#))
    }

    @Test("analytics snippets are injected into head and body, and absent by default")
    func analyticsSnippets() throws {
        func built(_ configuration: TileKit.Site.Configuration) throws -> String {
            let fileSystem = MemoryFileSystem(
                files: ["content/index.md": "---\ntitle: Home\n---\n# Home"],
            )
            _ = try makeGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: configuration,
                ),
            )
            return try #require(fileSystem.files["dist/index.html"])
        }

        // Configured: each snippet appears, the head one before </head> and the
        // body one before </body>.
        let withAnalytics = try built(.init(
            analyticsHead: "<script>HEAD_PIXEL</script>",
            analyticsBodyEnd: "<script>BODY_PIXEL</script>",
        ))
        let headSnippet = try #require(withAnalytics.range(of: "HEAD_PIXEL"))
        let headClose = try #require(withAnalytics.range(of: "</head>"))
        #expect(headSnippet.upperBound <= headClose.lowerBound)
        let bodySnippet = try #require(withAnalytics.range(of: "BODY_PIXEL"))
        let bodyClose = try #require(withAnalytics.range(of: "</body>"))
        #expect(bodySnippet.upperBound <= bodyClose.lowerBound)

        // Default: no analytics markup at all.
        let off = try built(.init())
        #expect(!off.contains("HEAD_PIXEL"))
        #expect(!off.contains("BODY_PIXEL"))
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
