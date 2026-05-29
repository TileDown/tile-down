import Testing
import TileKit

@Suite("TileKit facade")
struct TileKitFacadeTests {
    @Test("exports domain modules and site implementation")
    func exportsModules() throws {
        let queryRunner = TileKit.Content.QueryRunner()
        let markdownRenderer = TileKit.Markdown.BasicHTMLRenderer()
        let manifestValidator = TileKit.Service.ManifestValidator()
        let tileParser = TileKit.Tile.DirectiveParser()

        #expect(TileKit.Product.commandName == "tiledown")
        #expect(queryRunner.run(.init(), records: []) == [])
        #expect(markdownRenderer.renderHTML("# Hello") == "<h1>Hello</h1>")
        #expect(manifestValidator.validate(typeformManifest()).isEmpty)
        #expect(try tileParser.parseBlocks("Text") == [.markdown("Text")])
    }

    private func typeformManifest() -> TileKit.Service.Manifest {
        .init(
            id: "quiz.typeform",
            provider: .init(name: "Typeform"),
            inputs: [
                "formId": .init(
                    type: .text,
                    required: true,
                ),
            ],
            outputs: [
                "embed": .init(
                    type: .iframe,
                    origin: "https://form.typeform.com",
                ),
            ],
            layout: .init(mode: .block),
            build: .init(strategy: .providerEmbed),
        )
    }
}
