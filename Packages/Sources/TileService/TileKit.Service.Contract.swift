import TileCore

public extension TileKit.Service {
    /// A provider-neutral contract for service-backed tile operations.
    struct Contract: Codable, Equatable, Sendable {
        public var id: String
        public var name: String
        public var version: String
        public var health: Health?
        public var requirements: Requirements
        public var operations: [Operation]

        public init(
            id: String,
            name: String,
            version: String,
            health: Health? = nil,
            requirements: Requirements = .init(),
            operations: [Operation],
        ) {
            self.id = id
            self.name = name
            self.version = version
            self.health = health
            self.requirements = requirements
            self.operations = operations
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceContractCodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            version = try container.decode(String.self, forKey: .version)
            health = try container.decodeIfPresent(Health.self, forKey: .health)
            requirements = try container.decodeIfPresent(
                Requirements.self,
                forKey: .requirements,
            ) ?? .init()
            operations = try container.decode([Operation].self, forKey: .operations)
        }
    }
}

private enum TileKitServiceContractCodingKeys: String, CodingKey {
    case id
    case name
    case version
    case health
    case requirements
    case operations
}
