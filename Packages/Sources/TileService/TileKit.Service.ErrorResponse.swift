import TileCore

public extension TileKit.Service {
    /// Error response contract for a service operation.
    struct ErrorResponse: Codable, Equatable, Sendable {
        public var format: ErrorFormat

        public init(
            format: ErrorFormat,
        ) {
            self.format = format
        }
    }
}
