import TileCore

public extension TileKit.Service {
    /// Requirements declared by a provider integration manifest.
    struct Requirements: Codable, Equatable, Sendable {
        public var credentials: [CredentialRequirement]
        public var apiKey: APIKeyRequirement?

        public init(
            credentials: [CredentialRequirement] = [],
            apiKey: APIKeyRequirement? = nil,
        ) {
            self.credentials = credentials
            self.apiKey = apiKey
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceRequirementsCodingKeys.self)

            credentials = try container.decodeIfPresent(
                [CredentialRequirement].self,
                forKey: .credentials,
            ) ?? []
            apiKey = try container.decodeIfPresent(
                APIKeyRequirement.self,
                forKey: .apiKey,
            )
        }

        /// Credential requirements after compatibility shorthands are expanded.
        public var credentialRequirements: [CredentialRequirement] {
            guard let apiKey else {
                return credentials
            }

            return credentials + [
                .init(
                    id: "apiKey",
                    type: .apiKey,
                    exposure: .server,
                    environmentVariable: apiKey.environmentVariable,
                ),
            ]
        }
    }
}

private enum TileKitServiceRequirementsCodingKeys: String, CodingKey {
    case credentials
    case apiKey
}
