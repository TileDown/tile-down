import TileCore

public extension TileKit.Service {
    /// Cache behavior declared by a service operation.
    struct CachePolicy: Codable, Equatable, Sendable {
        public var enabled: Bool
        public var maxAgeSeconds: Int?

        public init(
            enabled: Bool,
            maxAgeSeconds: Int? = nil,
        ) {
            self.enabled = enabled
            self.maxAgeSeconds = maxAgeSeconds
        }
    }
}
