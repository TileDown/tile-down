import TileCore

public extension TileKit.Service {
    /// A build strategy supported by the manifest runtime.
    enum BuildStrategy: String, Codable, Equatable, Sendable {
        case providerEmbed = "provider-embed"
    }
}
