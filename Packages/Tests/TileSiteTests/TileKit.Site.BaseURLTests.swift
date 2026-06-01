import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site baseURL")
struct SiteBaseURLTests {
    @Test("generated root-relative content URLs are prefixed by the configured base URL")
    func rootRelativeContentURLsUseBaseURL() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                # Home

                ![Logo](/assets/logo.svg)

                [Guide](/files/guide.pdf)

                ![Relative](assets/local.svg)

                [CDN](//cdn.example.com/file.css)

                <img src="/raw-html.png">
                """,
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(baseURL: "https://example.com/docs"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<img src="https://example.com/docs/assets/logo.svg" alt="Logo">"#))
        #expect(home.contains(#"<a href="https://example.com/docs/files/guide.pdf">Guide</a>"#))
        #expect(home.contains(#"<img src="assets/local.svg" alt="Relative">"#))
        #expect(home.contains(#"<a href="//cdn.example.com/file.css">CDN</a>"#))
        #expect(home.contains(#"&lt;img src="/raw-html.png"&gt;"#))
    }

    @Test("built-in layouts prefix root-relative hero images with baseURL")
    func heroImagesUseBaseURL() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /assets/hero-light.png
                imageDark: /assets/hero-dark.png
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
                configuration: .init(baseURL: "https://example.com/docs"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        let light = #"<img class="td-theme-image-light" src="https://example.com/docs/assets/hero-light.png""#
        let dark = #"<img class="td-theme-image-dark" src="https://example.com/docs/assets/hero-dark.png""#
        #expect(home.contains(light))
        #expect(home.contains(dark))
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
