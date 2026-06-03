public extension TileKit {
    /// A protocol seam for rendering TeX math (recognized from `$...$` inline and
    /// `$$...$$` display Markdown) into page markup, instead of leaving the source
    /// as inert text.
    ///
    /// The Markdown renderer consumes this seam and the composition root supplies
    /// the concrete renderer, so the Markdown layer never imports a math engine.
    /// `display` distinguishes block display math from inline math; the renderer
    /// returns `nil` for input it cannot typeset, which falls back to the escaped
    /// source so a formula never disappears.
    ///
    /// The result reuses ``TileKit/FencedBlock``: `html` is the page-local markup
    /// (an inline `<span>` for inline math, a block element for display), `css`
    /// and `javascript` are the page-local assets to include once.
    protocol MathRendering: Sendable {
        func rendered(
            tex: String,
            display: Bool,
        ) -> TileKit.FencedBlock?
    }
}
