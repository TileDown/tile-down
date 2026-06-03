import Testing
import TileCore
@testable import TileMath

@Suite("Latin Modern Math font reader")
struct FontTests {
    private let font = TileKit.Math.Font.latinModern

    @Test("the bundled font loads and parses")
    func loads() {
        #expect(font != nil)
    }

    @Test("units-per-em and glyph count match the font")
    func headerValues() throws {
        let font = try #require(font)
        #expect(font.unitsPerEm == 1000)
        #expect(font.numGlyphs == 4802)
    }

    @Test("cmap maps known scalars to the expected glyph ids")
    func cmapLookup() throws {
        let font = try #require(font)
        #expect(font.glyphID(for: "x") == 89)
    }

    @Test("glyph advances match the font's hmtx in font units")
    func advances() throws {
        let font = try #require(font)
        // Ground truth read directly from latinmodern-math.otf.
        #expect(try font.advanceWidth(glyphID: 89) == 528) // x
        #expect(font.glyphID(for: "2").map { try? font.advanceWidth(glyphID: $0) } == 500)
        #expect(font.glyphID(for: "=").map { try? font.advanceWidth(glyphID: $0) } == 778)
    }

    @Test("string advance sums per-scalar advances scaled to points")
    func stringAdvance() throws {
        let font = try #require(font)
        // "2x" = (500 + 528) font units at unitsPerEm 1000, size 10 -> 10.28 pt.
        #expect(abs(font.advance(of: "2x", size: 10) - 10.28) < 0.0001)
    }

    @Test("the font exposes OpenType MATH metrics, not the heuristic default")
    func openTypeMetrics() throws {
        let font = try #require(font)
        #expect(font.mathConstants != nil)
    }
}
