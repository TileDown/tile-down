import TileCore

public extension TileKit.Service {
    /// Human-readable provider metadata for an integration manifest.
    struct Provider: Codable, Equatable, Sendable {
        public var name: String
        public var website: String?

        public init(
            name: String,
            website: String? = nil,
        ) {
            self.name = name
            self.website = website
        }
    }
}
