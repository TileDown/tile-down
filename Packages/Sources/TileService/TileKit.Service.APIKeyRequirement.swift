import TileCore

public extension TileKit.Service {
    /// Compatibility shorthand for declaring an API key environment reference.
    struct APIKeyRequirement: Codable, Equatable, Sendable {
        public var environmentVariable: String

        public init(
            environmentVariable: String,
        ) {
            self.environmentVariable = environmentVariable
        }
    }
}
