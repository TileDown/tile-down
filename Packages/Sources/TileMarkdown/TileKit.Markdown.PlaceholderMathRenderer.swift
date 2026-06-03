import TileCore

public extension TileKit.Markdown {
    /// A fallback ``TileKit/MathRendering`` that preserves the TeX source in a
    /// styled container instead of typesetting it. It lets the recognition layer
    /// and the math seam ship and be exercised end to end before the real
    /// typesetting engine is wired in; the composition root replaces it with the
    /// engine-backed renderer behind the same seam, with no change to the Markdown
    /// layer. A formula is never dropped: unrecognized or un-typeset input still
    /// renders its source legibly.
    struct PlaceholderMathRenderer: TileKit.MathRendering {
        public init() {}

        public func rendered(
            tex: String,
            display: Bool,
        ) -> TileKit.FencedBlock? {
            let trimmed = tex.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return nil
            }
            let source = TileKit.HTML.escapeText(trimmed)
            let label = TileKit.HTML.escapeAttribute(trimmed)
            let tag = display ? "div" : "span"
            let kind = display ? "td-math-display" : "td-math-inline"
            let html = "<\(tag) class=\"td-math \(kind)\" role=\"math\""
                + " aria-label=\"math: \(label)\">\(source)</\(tag)>"
            return .init(html: html, css: Self.css)
        }

        /// Page-local styling for placeholder math. Display math is a centered,
        /// horizontally scrollable block; inline math stays on the text baseline.
        /// The real engine renderer ships its own CSS, so this is replaced wholesale.
        static let css = """
        .td-math { font-family: var(--td-mono, ui-monospace, SFMono-Regular, Menlo, monospace); }
        .td-math-display { display: block; margin: 1.1rem 0; text-align: center; overflow-x: auto; }
        .td-math-inline { white-space: nowrap; }
        """
    }
}
