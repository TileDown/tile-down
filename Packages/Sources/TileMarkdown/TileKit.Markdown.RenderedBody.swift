import TileCore

public extension TileKit.Markdown {
    /// The HTML and collected page-local stylesheets produced by rendering a
    /// Markdown body. `css` carries the styles of any fenced capability blocks
    /// (for example charts) so the page assembler can include them once.
    struct RenderedBody: Equatable, Sendable {
        public var html: String
        public var css: [String]

        public init(
            html: String,
            css: [String] = [],
        ) {
            self.html = html
            self.css = css
        }
    }
}
