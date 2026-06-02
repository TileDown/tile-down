public extension TileKit {
    /// Composes several ``FencedBlockRendering`` renderers into one, trying each
    /// in order and returning the first that claims the fence. The composition
    /// root builds this from the per-capability renderers (charts, mermaid) and
    /// injects it into the Markdown renderer, which stays unaware of the set.
    struct CompositeFencedBlockRenderer: FencedBlockRendering {
        private let renderers: [any FencedBlockRendering]

        public init(
            _ renderers: [any FencedBlockRendering],
        ) {
            self.renderers = renderers
        }

        public func rendered(
            language: String,
            source: String,
        ) -> TileKit.FencedBlock? {
            for renderer in renderers {
                if let block = renderer.rendered(language: language, source: source) {
                    return block
                }
            }
            return nil
        }
    }
}
