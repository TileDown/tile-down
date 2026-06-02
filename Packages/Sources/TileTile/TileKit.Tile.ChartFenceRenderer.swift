import TileCore

public extension TileKit.Tile {
    /// Renders a Markdown ` ```chart ` fenced block to static SVG, reusing the
    /// same parser and SVG renderer as the property-authored chart tile.
    ///
    /// A static chart is a Markdown capability, not a tile (a tile is reserved for
    /// interactive, backend-bound content). This conforms to the
    /// ``TileKit/FencedBlockRendering`` seam so the Markdown renderer can dispatch
    /// the fence without importing this package; the composition root injects it.
    /// An unparseable fence returns `nil`, falling back to the default code block
    /// so the author sees their source rather than a broken render.
    struct ChartFenceRenderer: TileKit.FencedBlockRendering {
        public init() {}

        public func rendered(
            language: String,
            source: String,
        ) -> TileKit.FencedBlock? {
            guard language.lowercased() == ChartFence.infoLanguage else {
                return nil
            }
            guard let chart = try? ChartFence.parse(source) else {
                return nil
            }
            return TileKit.FencedBlock(html: ChartSVGRenderer().render(chart), css: ChartRenderer.css)
        }
    }
}
