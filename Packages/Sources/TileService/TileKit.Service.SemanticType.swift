import TileCore

public extension TileKit.Service {
    /// Tiledown-specific semantic type attached to a JSON Schema field.
    enum SemanticType: String, Codable, Equatable, Sendable {
        case decimal
        case positiveDecimal
        case markdown
        case image
        case video
        case color
    }
}
