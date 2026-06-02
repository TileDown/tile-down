import TileCore

public extension TileKit.Tile {
    /// A static demo tile: a titled callout box. It shows the simplest tile
    /// shape, typed properties rendered to HTML plus themed CSS, with no browser
    /// runtime. Reads `title` and `body` string properties.
    struct CalloutRenderer: Rendering {
        public static let typeID = "callout"

        public init() {}

        public func render(
            _ tile: Instance,
        ) -> Rendered {
            let title = tile.property(named: "title")?.stringValue ?? "Note"
            let body = tile.property(named: "body")?.stringValue ?? ""

            return .init(
                html: """
                <div class="td-callout">
                <p class="td-callout-title">\(TileKit.HTML.escape(title))</p>
                <p class="td-callout-body">\(TileKit.HTML.escape(body))</p>
                </div>
                """,
                css: """
                .td-callout {
                  border: 1px solid var(--td-border);
                  border-left: 4px solid var(--td-accent);
                  border-radius: var(--td-radius);
                  background: var(--td-surface);
                  padding: 1rem 1.25rem;
                  margin-block: 1.5rem;
                }
                .td-callout-title { margin: 0 0 0.35rem; font-weight: 700; color: var(--td-ink); }
                .td-callout-body { margin: 0; color: var(--td-muted); }
                """,
            )
        }
    }
}
