import TileCore

public extension TileKit.Math {
    /// One step of a glyph's outline path, in font units (y-up). Type2
    /// charstrings produce cubic curves, so `curve` carries two control points.
    enum PathElement: Equatable, Sendable {
        case move(TileKit.Math.Point)
        case line(TileKit.Math.Point)
        case curve(control1: TileKit.Math.Point, control2: TileKit.Math.Point, end: TileKit.Math.Point)
        case close
    }

    /// A glyph's outline as a sequence of path elements, in font units (y-up).
    /// The SVG emitter scales it by `size / unitsPerEm` and flips into y-down.
    struct GlyphOutline: Equatable, Sendable {
        public var elements: [TileKit.Math.PathElement]

        public init(elements: [TileKit.Math.PathElement]) {
            self.elements = elements
        }
    }
}
