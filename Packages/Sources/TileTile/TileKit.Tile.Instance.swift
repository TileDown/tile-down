import TileCore

public extension TileKit.Tile {
    /// A typed tile instance parsed from a structured directive block.
    struct Instance: Equatable, Sendable {
        public var typeID: String
        public var properties: [Property]
        public var children: [Block]

        public init(
            typeID: String,
            properties: [Property],
            children: [Block] = [],
        ) {
            self.typeID = typeID
            self.properties = properties
            self.children = children
        }

        /// Returns the first property value with the given key.
        public func property(
            named key: String,
        ) -> Value? {
            properties.first { $0.key == key }?.value
        }
    }
}
