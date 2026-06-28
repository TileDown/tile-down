import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site generator")
struct SiteGeneratorTests {
    @Test("exposes site configuration to templates under site")
    func exposesSiteConfiguration() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "# Hi",
                "templates/page.html": "{{{ site.title }}} | {{{ site.baseURL }}}",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.build(
            .init(
                sourcePath: "content/index.md",
                templatePath: "templates/page.html",
                outputPath: "dist/index.html",
                configuration: .init(
                    title: "My Site",
                    baseURL: "https://example.com",
                ),
            ),
        )

        #expect(fileSystem.files["dist/index.html"] == "My Site | https://example.com")
    }

    @Test("builds one page from markdown and a template")
    func buildsOnePage() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Hello <Tiledown>
                ---
                # Welcome

                This is the first page.
                """,
                "templates/page.html": """
                <html><head><title>{{ page.title }}</title></head><body>{{{ page.contents.html }}}</body></html>
                """,
            ],
        )

        let generator = makeGenerator(fileSystem: fileSystem)

        let result = try generator.build(
            .init(
                sourcePath: "content/index.md",
                templatePath: "templates/page.html",
                outputPath: "dist/index.html",
            ),
        )

        #expect(result.outputPath == "dist/index.html")
        #expect(
            fileSystem.files["dist/index.html"] == """
            <html><head><title>Hello &lt;Tiledown&gt;</title></head><body><h1>Welcome</h1>
            <p>This is the first page.</p></body></html>
            """,
        )
    }

    @Test("collects tile css into one shared stylesheet linked from every page")
    func sharedStylesheet() throws {
        let template = [
            #"<link rel="stylesheet" href="{{ site.stylesheetPath }}">"#,
            #"{{{ page.contents.html }}}"#,
        ].joined()
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "# Home\n\n:::tile promo\nid: a\n:::",
                "content/blog/index.md": "# Blog\n\n:::tile promo\nid: b\n:::",
                "templates/page.html": template,
            ],
        )
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: .init(renderers: ["promo": PromoRenderer()]),
        )

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // The promo CSS is written once for the whole site despite two pages.
        #expect(
            fileSystem.files["dist/styles.css"]
                == "@layer reset, theme, tile-override;\n@layer theme {\n.promo { color: #0f766e; }\n}",
        )
        // Every page links the shared stylesheet and inlines no tile CSS.
        let home = try #require(fileSystem.files["dist/index.html"])
        let blog = try #require(fileSystem.files["dist/blog/index.html"])
        #expect(home.contains(#"<link rel="stylesheet" href="/styles.css">"#))
        #expect(blog.contains(#"<link rel="stylesheet" href="/styles.css">"#))
    }

    @Test("builds content directory pages from index markdown files")
    func buildsContentDirectoryPages() throws {
        let template = [
            #"<nav>{{#pages}}<a href="{{ url }}">{{ title }}</a>{{/pages}}</nav>"#,
            #"<title>{{ page.title }}</title>{{{ page.contents.html }}}"#,
        ].joined()

        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home
                """,
                "content/blog/index.md": """
                ---
                title: Blog
                ---
                # Blog
                """,
                "content/blog/draft.md": """
                # Draft
                """,
                "templates/page.html": template,
            ],
        )

        let generator = makeGenerator(fileSystem: fileSystem)

        let result = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        #expect(result.outputPaths == [
            "dist/sitemap.xml",
            "dist/index.html",
            "dist/blog/index.html",
            "dist/404.html",
        ])
        let navigation = #"<nav><a href="/">Home</a><a href="/blog/">Blog</a></nav>"#
        #expect(
            fileSystem.files["dist/index.html"] ==
                navigation + #"<title>Home</title><h1>Home</h1>"#,
        )
        #expect(
            fileSystem.files["dist/blog/index.html"] ==
                navigation + #"<title>Blog</title><h1>Blog</h1>"#,
        )
        #expect(fileSystem.files["dist/blog/draft/index.html"] == nil)
        // No styled tiles, so no shared stylesheet is written.
        #expect(fileSystem.files["dist/styles.css"] == nil)
    }

    @Test("the shared stylesheet link is prefixed by the configured base URL")
    func sharedStylesheetUsesBaseURL() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "# Home\n\n:::tile promo\nid: a\n:::",
                "templates/page.html": #"<link href="{{ site.stylesheetPath }}">"#,
            ],
        )
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: .init(renderers: ["promo": PromoRenderer()]),
        )

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(baseURL: "https://example.com"),
            ),
        )

        #expect(fileSystem.files["dist/index.html"] == #"<link href="https://example.com/styles.css">"#)
    }

    @Test("renders tile directives through injected registry")
    func rendersTileDirectivesThroughInjectedRegistry() throws {
        let template = [
            #"<style>{{{ page.assets.css }}}</style>"#,
            #"{{{ page.contents.html }}}"#,
            #"<script>{{{ page.assets.javascript }}}</script>"#,
        ].joined()
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home

                :::tile promo
                id: launch
                :::

                After.
                """,
                "templates/page.html": template,
            ],
        )
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: .init(
                renderers: [
                    "promo": PromoRenderer(),
                ],
            ),
        )

        _ = try generator.build(
            .init(
                sourcePath: "content/index.md",
                templatePath: "templates/page.html",
                outputPath: "dist/index.html",
            ),
        )

        #expect(
            fileSystem.files["dist/index.html"] == """
            <style>@layer reset, theme, tile-override;
            @layer theme {
            .promo { color: #0f766e; }
            }</style><h1>Home</h1>
            <aside data-promo="launch">Promo launch</aside>
            <p>After.</p><script>console.log("promo");</script>
            """,
        )
    }

    func makeGenerator(
        fileSystem: MemoryFileSystem,
        tileRegistry: TileKit.Tile.Registry = .init(),
        tilePageGenerators: [any TileKit.Site.TilePageGenerating] = [],
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
                tileRegistry: tileRegistry,
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
            tilePageGenerators: tilePageGenerators,
        )
    }
}

private struct PromoRenderer: TileKit.Tile.Rendering {
    func render(
        _ tile: TileKit.Tile.Instance,
    ) -> TileKit.Tile.Rendered {
        let id: String = if case let .string(value) = tile.property(named: "id") {
            value
        } else {
            "unknown"
        }

        return .init(
            html: #"<aside data-promo="\#(id)">Promo \#(id)</aside>"#,
            css: ".promo { color: #0f766e; }",
            javascript: #"console.log("promo");"#,
        )
    }
}

extension SiteGeneratorTests {
    @Test("left sidebar layout includes page JavaScript assets")
    func leftSidebarIncludesPageJavaScriptAssets() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                :::tile promo
                id: launch
                :::
                """,
            ],
        )
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: .init(
                renderers: [
                    "promo": PromoRenderer(),
                ],
            ),
        )

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.leftSidebar),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        #expect(fileSystem.files["dist/index.html"]?.contains(#"<script>console.log("promo");</script>"#) == true)
    }

    @Test("excludes draft pages from the build by default")
    func excludesDrafts() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/published/index.md": "---\ntitle: Live\ndate: 2026-05-20\n---\n# Live",
                "content/posts/wip/index.md": "---\ntitle: WIP\ndate: 2026-05-21\ndraft: true\n---\n# WIP",
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

        // The draft produces no page anywhere in the output.
        #expect(fileSystem.files["dist/posts/wip/index.html"] == nil)
        #expect(!result.outputPaths.contains("dist/posts/wip/index.html"))
        // The published post still builds.
        #expect(fileSystem.files["dist/posts/published/index.html"] != nil)
    }

    @Test("includeDrafts builds draft pages for preview")
    func includeDraftsPreview() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/wip/index.md": "---\ntitle: WIP\ndate: 2026-05-21\ndraft: true\n---\n# WIP",
                "templates/page.html": "{{{ contents }}}",
            ],
        )

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
                includeDrafts: true,
            ),
        )

        // With includeDrafts the draft is built like any other page.
        #expect(fileSystem.files["dist/posts/wip/index.html"] != nil)
        #expect(result.outputPaths.contains("dist/posts/wip/index.html"))
    }
}
