import TileCore

public extension TileKit.Tile {
    /// A property value parsed from a tile directive.
    enum Value: Equatable, Sendable {
        case string(String)
        case list([String])

        /// The underlying string for string values, or `nil` for list values.
        public var stringValue: String? {
            guard case let .string(value) = self else {
                return nil
            }
            return value
        }
    }
}
