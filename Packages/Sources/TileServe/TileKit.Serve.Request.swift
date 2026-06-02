import TileCore

public extension TileKit.Serve {
    /// A minimal HTTP request shape used by the static preview server.
    struct Request: Equatable, Sendable {
        public var method: String
        public var target: String

        public init(
            method: String,
            target: String,
        ) {
            self.method = method
            self.target = target
        }
    }
}
