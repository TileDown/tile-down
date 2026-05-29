import TileCore

public extension TileKit.Tile {
    /// Dispatches tile instances to renderers by tile type id.
    struct Registry: Sendable {
        private var renderers: [String: any Rendering]
        private var unknownRenderer: any Rendering

        public init(
            renderers: [String: any Rendering] = [:],
            unknownRenderer: any Rendering = UnknownRenderer(),
        ) {
            self.renderers = renderers
            self.unknownRenderer = unknownRenderer
        }

        /// Returns a copy with the renderer registered for a tile type id.
        public func registering(
            _ renderer: any Rendering,
            for typeID: String,
        ) -> Self {
            var copy = self
            copy.renderers[typeID] = renderer
            return copy
        }

        /// Renders a tile using the registered renderer or the unknown fallback.
        public func render(
            _ tile: Instance,
        ) throws -> Rendered {
            try (renderers[tile.typeID] ?? unknownRenderer).render(tile)
        }
    }
}
