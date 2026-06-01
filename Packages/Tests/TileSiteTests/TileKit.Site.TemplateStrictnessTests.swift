import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site template strictness")
struct SiteTemplateStrictnessTests {
    @Test("custom template section typos throw while optional page fields stay falsey")
    func customTemplateSectionsAreStrictExceptDeclaredOptionals() throws {
        let optionalFileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "templates/page.html": "{{#page.heroImage}}IMAGE{{/page.heroImage}}{{{ page.contents.html }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: optionalFileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let optionalOutput = try #require(optionalFileSystem.files["dist/index.html"])
        #expect(!optionalOutput.contains("IMAGE"))
        #expect(optionalOutput.contains("<h1>Home</h1>"))

        let typoFileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "templates/page.html": "{{#site.postss}}Post{{/site.postss}}",
            ],
        )

        #expect(throws: TileKit.Template.SimpleMustacheRendererError.missingValue("site.postss")) {
            _ = try makeGenerator(fileSystem: typoFileSystem).buildContent(
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
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
