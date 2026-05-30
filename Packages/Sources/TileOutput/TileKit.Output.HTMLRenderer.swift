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
    ///
    /// Tile CSS is deduplicated (identical fragments are emitted once per page) and
    /// wrapped in a `theme` cascade layer, with the canonical layer order
    /// `reset, theme, tile-override` declared up front. Every tile rule therefore
    /// sits inside a layer, so unlayered styles cannot silently outrank the theme.
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
                    Self.appendUnique(rendered.css, to: &css)
                    Self.appendNonEmpty(rendered.javascript, to: &javascript)
                }
            }

            return Artifact(
                contents: html.joined(separator: "\n"),
                fileExtension: "html",
                assets: .init(
                    css: Self.layeredCSS(css),
                    javascript: javascript.joined(separator: "\n"),
                ),
            )
        }

        /// Wraps the deduplicated tile CSS in the `theme` cascade layer and declares
        /// the canonical layer order. Returns an empty string when there is no CSS,
        /// so a page without styled tiles emits no stray layer statement.
        private static func layeredCSS(
            _ fragments: [String],
        ) -> String {
            guard !fragments.isEmpty else {
                return ""
            }

            let body = fragments.joined(separator: "\n")
            return """
            @layer reset, theme, tile-override;
            @layer theme {
            \(body)
            }
            """
        }

        private static func appendUnique(
            _ value: String,
            to values: inout [String],
        ) {
            guard !value.isEmpty, !values.contains(value) else {
                return
            }

            values.append(value)
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
