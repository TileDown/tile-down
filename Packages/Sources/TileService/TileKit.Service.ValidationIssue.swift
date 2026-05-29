import TileCore

public extension TileKit.Service {
    /// A validation problem with a recovery suggestion.
    struct ValidationIssue: Equatable, Sendable {
        public var reason: String
        public var recovery: String

        public init(
            reason: String,
            recovery: String,
        ) {
            self.reason = reason
            self.recovery = recovery
        }
    }
}
