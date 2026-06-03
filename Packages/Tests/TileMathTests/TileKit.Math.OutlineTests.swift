import Testing
import TileCore
@testable import TileMath

/// Verifies the CFF Type2 interpreter against outlines extracted from
/// latinmodern-math.otf with fontTools (the reference). Coordinates are exact
/// integers in font units, so equality is exact.
@Suite("CFF glyph outlines")
struct OutlineTests {
    private typealias Point = TileKit.Math.Point
    private typealias Element = TileKit.Math.PathElement

    private func point(_ xPosition: Double, _ yPosition: Double) -> Point {
        .init(xPosition: xPosition, yPosition: yPosition)
    }

    private func outline(_ glyph: Int) throws -> [Element] {
        let font = try #require(TileKit.Math.Font.latinModern)
        return try #require(try font.outline(glyphID: glyph)).elements
    }

    @Test("a line-only glyph (hyphen) matches the reference rectangle")
    func hyphen() throws {
        // gid 14, the hyphen: a closed rectangle of four straight edges.
        #expect(try outline(14) == [
            .move(point(276, 187)),
            .line(point(276, 245)),
            .line(point(11, 245)),
            .line(point(11, 187)),
            .close,
        ])
    }

    @Test("a curved glyph (period) matches the reference cubics")
    func period() throws {
        // gid 15, the period: one contour of four cubic curves.
        #expect(try outline(15) == [
            .move(point(192, 53)),
            .curve(control1: point(192, 82), control2: point(168, 106), end: point(139, 106)),
            .curve(control1: point(110, 106), control2: point(86, 82), end: point(86, 53)),
            .curve(control1: point(86, 24), control2: point(110, 0), end: point(139, 0)),
            .curve(control1: point(168, 0), control2: point(192, 24), end: point(192, 53)),
            .close,
        ])
    }

    @Test("a two-contour glyph (colon) has two closed contours")
    func colon() throws {
        let elements = try outline(27)
        let moves = elements.count(where: { if case .move = $0 { true } else { false } })
        let closes = elements.count(where: { $0 == .close })
        #expect(moves == 2)
        #expect(closes == 2)
        #expect(elements.first == .move(point(192, 378)))
    }

    /// Control-point bounds (min/max over every on- and off-curve point) for a
    /// spread of glyphs, read from latinmodern-math.otf with fontTools. This
    /// exercises the alternating curve operators and subroutines across letters,
    /// digits, delimiters, and large math symbols (sum, integral, radical, pi).
    @Test("glyph control bounds match the reference", arguments: [
        (9, 101.0, -248.0, 332.0, 748.0), // (
        (80, 28.0, -11.0, 471.0, 448.0), // o
        (52, 56.0, -22.0, 499.0, 705.0), // S
        (25, 42.0, -22.0, 457.0, 666.0), // 8
        (56, 18.0, -22.0, 1009.0, 683.0), // W
        (3060, 56.0, -250.0, 999.0, 750.0), // sum
        (3049, 56.0, -306.0, 609.0, 805.0), // integral
        (3077, 73.0, -960.0, 853.0, 40.0), // radical
        (4193, 2.0, -11.0, 524.0, 431.0), // pi
        (4208, 40.0, -22.0, 551.0, 716.0), // partial
    ])
    func controlBounds(glyph: Int, minX: Double, minY: Double, maxX: Double, maxY: Double) throws {
        var points: [Point] = []
        for element in try outline(glyph) {
            switch element {
            case let .move(point), let .line(point):
                points.append(point)
            case let .curve(control1, control2, end):
                points.append(contentsOf: [control1, control2, end])
            case .close:
                break
            }
        }
        #expect(points.map(\.xPosition).min() == minX)
        #expect(points.map(\.yPosition).min() == minY)
        #expect(points.map(\.xPosition).max() == maxX)
        #expect(points.map(\.yPosition).max() == maxY)
    }
}
