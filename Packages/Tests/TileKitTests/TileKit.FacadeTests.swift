import Testing
import TileKit

@Suite("TileKit facade")
struct TileKitFacadeTests {
    @Test("exports domain modules and site implementation")
    func exportsModules() {
        let queryRunner = TileKit.Content.QueryRunner()
        let markdownRenderer = TileKit.Markdown.BasicHTMLRenderer()

        #expect(TileKit.Product.commandName == "tiledown")
        #expect(queryRunner.run(.init(), records: []) == [])
        #expect(markdownRenderer.renderHTML("# Hello") == "<h1>Hello</h1>")
    }
}
