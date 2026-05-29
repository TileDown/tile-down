import Testing
import TileKit

@Suite("TileKit facade")
struct TileKitFacadeTests {
    @Test("exports domain modules and site implementation")
    func exportsModules() throws {
        let queryRunner = TileKit.Content.QueryRunner()
        let markdownRenderer = TileKit.Markdown.BasicHTMLRenderer()
        let tileParser = TileKit.Tile.DirectiveParser()

        #expect(TileKit.Product.commandName == "tiledown")
        #expect(queryRunner.run(.init(), records: []) == [])
        #expect(markdownRenderer.renderHTML("# Hello") == "<h1>Hello</h1>")
        #expect(try tileParser.parseBlocks("Text") == [.markdown("Text")])
    }
}
