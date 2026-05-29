import TileCore

public extension TileKit.Service {
    /// An output declared by a provider integration manifest.
    struct Output: Codable, Equatable, Sendable {
        public var type: OutputCapability
        public var responsive: Bool
        public var origin: String?

        public init(
            type: OutputCapability,
            responsive: Bool = false,
            origin: String? = nil,
        ) {
            self.type = type
            self.responsive = responsive
            self.origin = origin
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceOutputCodingKeys.self)

            type = try container.decode(OutputCapability.self, forKey: .type)
            responsive = try container.decodeIfPresent(Bool.self, forKey: .responsive) ?? false
            origin = try container.decodeIfPresent(String.self, forKey: .origin)
        }
    }
}

private enum TileKitServiceOutputCodingKeys: String, CodingKey {
    case type
    case responsive
    case origin
}
