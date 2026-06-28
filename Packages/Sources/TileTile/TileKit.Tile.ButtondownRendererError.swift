import TileCore

public extension TileKit.Tile {
    /// Validation failures for the built-in `buttondown` tile.
    enum ButtondownRendererError: Error, Equatable, CustomStringConvertible, Sendable {
        case invalidTileType(actual: String)
        case missingProperty(String)
        case invalidUsername(String)
        case invalidBoolean(property: String, value: String)
        case invalidMetadataKey(String)
        case invalidMetadataValue(String)

        public var description: String {
            switch self {
            case let .invalidTileType(actual):
                "Tile type \(actual) is not buttondown."
            case let .missingProperty(name):
                "Add the \(name) property to the buttondown tile."
            case let .invalidUsername(username):
                "Buttondown username must contain only letters, numbers, underscores, or hyphens, not \(username)."
            case let .invalidBoolean(property, value):
                "Buttondown \(property) must be true or false, not \(value)."
            case let .invalidMetadataKey(key):
                "Buttondown metadata key must be non-empty and URL form safe, not \(key)."
            case let .invalidMetadataValue(key):
                "Buttondown metadata property metadata.\(key) must be a string value."
            }
        }
    }
}
