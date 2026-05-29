import TileCore

public extension TileKit.Service {
    /// Credential requirement selected by a service operation.
    struct OperationAuth: Codable, Equatable, Sendable {
        public var credentialID: String
        public var exposure: CredentialExposure

        public init(
            credentialID: String,
            exposure: CredentialExposure,
        ) {
            self.credentialID = credentialID
            self.exposure = exposure
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceOperationAuthCodingKeys.self)

            credentialID = try container.decode(String.self, forKey: .credentialID)
            exposure = try container.decode(CredentialExposure.self, forKey: .exposure)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: TileKitServiceOperationAuthCodingKeys.self)

            try container.encode(credentialID, forKey: .credentialID)
            try container.encode(exposure, forKey: .exposure)
        }
    }
}

private enum TileKitServiceOperationAuthCodingKeys: String, CodingKey {
    case credentialID = "credential"
    case exposure
}
