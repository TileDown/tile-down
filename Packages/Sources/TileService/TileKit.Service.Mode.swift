import TileCore

public extension TileKit.Service {
    /// Runtime mode supported by a tile or service operation.
    enum Mode: String, Codable, Equatable, Sendable {
        case `static`
        case local
        case remote
        case proxy
        case build
    }
}
