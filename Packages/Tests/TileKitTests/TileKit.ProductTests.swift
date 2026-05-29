import Testing
@testable import TileKit

@Suite("Product metadata")
struct ProductTests {
    @Test("uses the chosen command name")
    func commandName() {
        #expect(TileKit.Product.commandName == "tiledown")
    }
}
