import TileCore

public extension TileKit.Service {
    /// Error response format declared by a service operation.
    enum ErrorFormat: String, Codable, Equatable, Sendable {
        case problemDetails = "problem-details"
        case json
        case text
    }
}
