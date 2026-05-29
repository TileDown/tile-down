import TileCore

public extension TileKit.Service {
    /// HTTP method used by a service operation transport.
    enum HTTPMethod: String, Codable, Equatable, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
}
