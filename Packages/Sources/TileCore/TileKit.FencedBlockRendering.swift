public extension TileKit {
    /// A protocol seam for rendering fenced code blocks whose info string names
    /// a static capability (charts, diagrams) into page markup, instead of the
    /// default escaped `<pre><code>`.
    ///
    /// The Markdown renderer consumes this seam and the composition root supplies
    /// the concrete renderer, so the Markdown layer never imports a capability
    /// producer. A renderer returns `nil` for languages it does not handle, which
    /// falls back to the default code-block rendering.
    protocol FencedBlockRendering: Sendable {
        func rendered(
            language: String,
            source: String,
        ) -> TileKit.FencedBlock?
    }
}
