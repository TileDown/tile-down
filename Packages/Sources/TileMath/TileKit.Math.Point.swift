import TileCore

public extension TileKit.Math {
    /// A point in font units (em space), y-axis up, as glyph outlines use.
    struct Point: Equatable, Sendable {
        public var xPosition: Double
        public var yPosition: Double

        public init(xPosition: Double, yPosition: Double) {
            self.xPosition = xPosition
            self.yPosition = yPosition
        }
    }
}
