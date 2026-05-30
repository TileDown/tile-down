import TileCore
import TileMarkdown
import TileTile

public extension TileKit.Output {
    /// Renders a parsed document's body to static HTML and collects its assets.
    ///
    /// The first output renderer. It projects the block tree in source order:
    /// Markdown blocks through an injected ``TileKit/Markdown/Rendering`` and tile
    /// blocks through a ``TileKit/Tile/Registry``, joining the HTML and gathering
    /// each tile's page-local CSS and JavaScript into the artifact's assets. It
    /// renders the body fragment only; wrapping that fragment in a page template
    /// with cross-page context is the site generator's job, not the output seam's.
    struct HTMLRenderer: Rendering {
        /// The output format id this renderer produces.
        public static let formatID = "html"

        public var formatID: String {
            Self.formatID
        }

        private let markdownRenderer: any TileKit.Markdown.Rendering
        private let tileRegistry: TileKit.Tile.Registry

        public init(
            markdownRenderer: any TileKit.Markdown.Rendering,
            tileRegistry: TileKit.Tile.Registry,
        ) {
            self.markdownRenderer = markdownRenderer
            self.tileRegistry = tileRegistry
        }

        public func render(
            _ document: Document,
        ) throws -> Artifact {
            var html: [String] = []
            var css: [String] = []
            var javascript: [String] = []

            for block in document.blocks {
                switch block {
                case let .markdown(markdown):
                    html.append(markdownRenderer.renderHTML(markdown))
                case let .tile(tile):
                    let rendered = try tileRegistry.render(tile)
                    html.append(rendered.html)
                    Self.appendNonEmpty(rendered.css, to: &css)
                    Self.appendNonEmpty(rendered.javascript, to: &javascript)
                }
            }

            return Artifact(
                contents: html.joined(separator: "\n"),
                fileExtension: "html",
                assets: .init(
                    css: css.joined(separator: "\n"),
                    javascript: javascript.joined(separator: "\n"),
                ),
            )
        }

        private static func appendNonEmpty(
            _ value: String,
            to values: inout [String],
        ) {
            guard !value.isEmpty else {
                return
            }

            values.append(value)
        }
    }
}
