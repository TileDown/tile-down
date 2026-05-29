import TileCore

public extension TileKit.Service {
    /// Describes whether a credential may be emitted to generated browser output.
    enum CredentialExposure: String, Codable, Equatable, Sendable {
        case none
        case browser
        case server
        case build
    }
}
