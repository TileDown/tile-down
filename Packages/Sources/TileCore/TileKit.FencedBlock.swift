public extension TileKit {
    /// The rendered result of a fenced code block that a capability renderer
    /// claims (for example a ` ```chart ` block rendered to SVG, or a ` ```mermaid `
    /// block rendered to a client-runtime container). `html` is the page-local
    /// markup; `css` and `javascript` are the page-local assets to include once.
    struct FencedBlock: Equatable, Sendable {
        public var html: String
        public var css: String
        public var javascript: String

        public init(
            html: String,
            css: String = "",
            javascript: String = "",
        ) {
            self.html = html
            self.css = css
            self.javascript = javascript
        }
    }
}
