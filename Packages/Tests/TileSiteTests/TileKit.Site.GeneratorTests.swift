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
                templatePath: "templates/page.html",
                outputRootPath: "dist",
            ),
        )

        #expect(result.outputPaths == ["dist/index.html", "dist/blog/index.html"])
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
            <style>.promo { color: #0f766e; }</style><h1>Home</h1>
            <aside data-promo="launch">Promo launch</aside>
            <p>After.</p><script>console.log("promo");</script>
            """,
        )
    }

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
        tileRegistry: TileKit.Tile.Registry = .init(),
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
