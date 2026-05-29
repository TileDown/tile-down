import TileCore

public extension TileKit.Tile {
    /// A tile property in source order.
    struct Property: Equatable, Sendable {
        public var key: String
        public var value: Value

        public init(
            key: String,
            value: Value,
        ) {
            self.key = key
            self.value = value
        }
    }
}
