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
            var themed: [String] = []
            var overriding: [String] = []
            var javascript: [String] = []

            for block in document.blocks {
                switch block {
                case let .markdown(markdown):
                    let body = markdownRenderer.renderBody(markdown)
                    html.append(body.html)
                    for stylesheet in body.css {
                        Self.appendUnique(stylesheet, to: &themed)
                    }
                    for script in body.javascript {
                        Self.appendUnique(script, to: &javascript)
                    }
                case let .tile(tile):
                    let rendered = try tileRegistry.render(tile)
                    html.append(rendered.html)
                    switch rendered.cssPosture {
                    case .themed:
                        Self.appendUnique(rendered.css, to: &themed)
                    case .overriding:
                        Self.appendUnique(rendered.css, to: &overriding)
                    }
                    // Dedup identical JS, mirroring CSS: a tile type's runtime is
                    // emitted once per page, so a script that binds every instance
                    // by a shared selector does not double-bind when a tile repeats.
                    Self.appendUnique(rendered.javascript, to: &javascript)
                }
            }

            return Artifact(
                contents: html.joined(separator: "\n"),
                fileExtension: "html",
                assets: .init(
                    stylesheet: .init(themed: themed, overriding: overriding),
                    javascript: javascript.joined(separator: "\n"),
                ),
            )
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
    }
}
