import TileCore

public extension TileKit.Markdown {
    protocol Rendering: Sendable {
        func renderHTML(
            _ markdown: String,
        ) -> String

        /// Renders the body and surfaces any page-local stylesheets from fenced
        /// capability blocks. Defaults to `renderHTML` with no collected CSS.
        func renderBody(
            _ markdown: String,
        ) -> TileKit.Markdown.RenderedBody
    }
}

public extension TileKit.Markdown.Rendering {
    func renderBody(
        _ markdown: String,
    ) -> TileKit.Markdown.RenderedBody {
        .init(html: renderHTML(markdown))
    }
}
