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
