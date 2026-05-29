import TileCore

public extension TileKit.Service {
    /// A credential requirement declared by a provider integration.
    struct CredentialRequirement: Codable, Equatable, Sendable {
        public var id: String
        public var type: CredentialType
        public var exposure: CredentialExposure
        public var environmentVariable: String?

        public init(
            id: String,
            type: CredentialType,
            exposure: CredentialExposure,
            environmentVariable: String? = nil,
        ) {
            self.id = id
            self.type = type
            self.exposure = exposure
            self.environmentVariable = environmentVariable
        }
    }
}
