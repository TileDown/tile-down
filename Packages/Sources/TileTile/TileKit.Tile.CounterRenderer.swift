import TileCore

public extension TileKit.Tile {
    /// A `local`-mode demo tile: a button that counts clicks in the browser. It
    /// shows a tile that emits browser JavaScript and keeps state client-side,
    /// with no network. Reads a `label` string property. The runtime is scoped
    /// to the tile element, so multiple counters on a page are independent.
    struct CounterRenderer: Rendering {
        public static let typeID = "counter"

        public init() {}

        public func render(
            _ tile: Instance,
        ) -> Rendered {
            let label = Self.string(tile.property(named: "label")) ?? "Clicks"

            return .init(
                html: """
                <div class="td-counter" data-td-counter>
                <button class="td-counter-button" type="button">\(Self.escapeHTML(label))</button>
                <span class="td-counter-value" data-td-counter-value>0</span>
                </div>
                """,
                css: """
                .td-counter { display: inline-flex; align-items: center; gap: 0.75rem; margin-block: 1.5rem; }
                .td-counter-button {
                  cursor: pointer;
                  border: 1px solid var(--td-border);
                  border-radius: var(--td-radius);
                  background: var(--td-accent);
                  color: #fff;
                  padding: 0.5rem 1rem;
                  font: inherit;
                }
                .td-counter-value { font-variant-numeric: tabular-nums; font-weight: 700; color: var(--td-ink); }
                """,
                javascript: """
                document.querySelectorAll('[data-td-counter]').forEach(function (root) {
                  var button = root.querySelector('.td-counter-button');
                  var value = root.querySelector('[data-td-counter-value]');
                  var count = 0;
                  button.addEventListener('click', function () {
                    count += 1;
                    value.textContent = String(count);
                  });
                });
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
