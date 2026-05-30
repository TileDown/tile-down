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
            let title = Self.string(tile.property(named: "title")) ?? "Note"
            let body = Self.string(tile.property(named: "body")) ?? ""

            return .init(
                html: """
                <div class="td-callout">
                <p class="td-callout-title">\(Self.escapeHTML(title))</p>
                <p class="td-callout-body">\(Self.escapeHTML(body))</p>
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

        private static func string(
            _ value: Value?,
        ) -> String? {
            guard case let .string(string) = value else {
                return nil
            }
            return string
        }

        private static func escapeHTML(
            _ value: String,
        ) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
    }
}
