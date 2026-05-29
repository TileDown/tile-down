import TileCore

public extension TileKit.Source {
    /// Selects source documents from a list of paths produced by a storage layer.
    protocol ContentDiscovering: Sendable {
        /// Returns the content locations that should become site pages.
        func discover(
            relativePaths: [String],
        ) -> [ContentLocation]
    }
}
