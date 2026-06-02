import TileCore

public extension TileKit.Markdown {
    /// The HTML and collected page-local assets produced by rendering a Markdown
    /// body. `css` and `javascript` carry the assets of any fenced capability
    /// blocks (charts, mermaid diagrams) so the page assembler includes each once.
    struct RenderedBody: Equatable, Sendable {
        public var html: String
        public var css: [String]
        public var javascript: [String]

        public init(
            html: String,
            css: [String] = [],
            javascript: [String] = [],
        ) {
            self.html = html
            self.css = css
            self.javascript = javascript
        }
    }
}
