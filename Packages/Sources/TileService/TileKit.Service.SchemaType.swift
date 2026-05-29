import TileCore

public extension TileKit.Service {
    /// JSON Schema primitive kinds supported by generated service tiles.
    enum SchemaType: String, Codable, Equatable, Sendable {
        case string
        case number
        case integer
        case boolean
        case object
        case array
        case null
    }
}
