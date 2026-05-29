import TileCore

public extension TileKit.Service {
    /// Build-time health check endpoint for a service contract.
    struct Health: Codable, Equatable, Sendable {
        public var path: String
        public var timeoutMilliseconds: Int

        public init(
            path: String,
            timeoutMilliseconds: Int = 1000,
        ) {
            self.path = path
            self.timeoutMilliseconds = timeoutMilliseconds
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceHealthCodingKeys.self)

            path = try container.decode(String.self, forKey: .path)
            timeoutMilliseconds = try container.decodeIfPresent(
                Int.self,
                forKey: .timeoutMilliseconds,
            ) ?? 1000
        }
    }
}

private enum TileKitServiceHealthCodingKeys: String, CodingKey {
    case path
    case timeoutMilliseconds
}
