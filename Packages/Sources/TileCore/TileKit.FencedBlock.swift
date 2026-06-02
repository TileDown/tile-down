public extension TileKit {
    /// The rendered result of a fenced code block that a capability renderer
    /// claims (for example a ` ```chart ` block rendered to SVG). `html` is the
    /// page-local markup; `css` is the stylesheet the page must include once.
    struct FencedBlock: Equatable, Sendable {
        public var html: String
        public var css: String

        public init(
            html: String,
            css: String = "",
        ) {
            self.html = html
            self.css = css
        }
    }
}
