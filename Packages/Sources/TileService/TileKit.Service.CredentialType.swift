import TileCore

public extension TileKit.Service {
    /// A credential mechanism requested by a provider integration.
    enum CredentialType: String, Codable, Equatable, Sendable {
        case apiKey = "api-key"
        case bearer
        case publicKey = "public-key"
    }
}
