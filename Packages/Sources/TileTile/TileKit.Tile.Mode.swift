import TileCore

public extension TileKit.Tile {
    /// Runtime behavior mode selected by an interactive tile request.
    enum Mode: String, Codable, Equatable, Sendable {
        case `static`
        case local
        case remote
        case proxy
        case build
    }
}
