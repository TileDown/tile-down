import TileCore

public extension TileKit.Tile {
    /// Renders a Markdown ` ```mermaid ` fenced block, matching the sibling
    /// MarkdownPDF project: a `pie`/`pie title ...` block renders to a static SVG
    /// chart, and every other diagram (`graph`/`flowchart`, ...) renders through
    /// the same client-side mermaid runtime as the property-authored mermaid tile.
    ///
    /// Diagrams are static content, so this is a Markdown capability, not a tile;
    /// a client runtime drawing the diagram does not make it interactive. It
    /// conforms to the ``TileKit/FencedBlockRendering`` seam and is injected at the
    /// composition root.
    struct MermaidFenceRenderer: TileKit.FencedBlockRendering {
        public init() {}

        public func rendered(
            language: String,
            source: String,
        ) -> TileKit.FencedBlock? {
            guard language.lowercased() == "mermaid" else {
                return nil
            }
            if ChartFence.isMermaidPie(source), let chart = try? ChartFence.parseMermaidPie(source) {
                return TileKit.FencedBlock(html: ChartSVGRenderer().render(chart), css: ChartRenderer.css)
            }
            return TileKit.FencedBlock(
                html: MermaidRenderer.html(definition: source, title: nil),
                css: MermaidRenderer.css,
                javascript: MermaidRenderer.javascript,
            )
        }
    }
}
