import TileCore

public extension TileKit.Service {
    /// Build-time behavior requested by a provider integration.
    struct Build: Codable, Equatable, Sendable {
        public var strategy: BuildStrategy

        public init(
            strategy: BuildStrategy,
        ) {
            self.strategy = strategy
        }
    }
}
