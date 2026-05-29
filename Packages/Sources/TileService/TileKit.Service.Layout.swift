import TileCore

public extension TileKit.Service {
    /// Layout requirements declared by a provider integration manifest.
    struct Layout: Codable, Equatable, Sendable {
        public var mode: LayoutMode

        public init(
            mode: LayoutMode,
        ) {
            self.mode = mode
        }
    }
}
