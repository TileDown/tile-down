import Foundation
import TileCore

public extension TileKit.Tile {
    /// Renders unsupported tiles as deterministic diagnostics.
    struct UnknownRenderer: Rendering {
        public init() {}

        public func render(
            _ tile: Instance,
        ) -> Rendered {
            .init(
                html: """
                <div class="td-unsupported-tile" data-td-unsupported-tile="\(Self.escapeAttribute(tile.typeID))">
                Unsupported tile: \(Self.escapeHTML(tile.typeID))
                </div>
                """,
            )
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

        private static func escapeAttribute(
            _ value: String,
        ) -> String {
            escapeHTML(value)
        }
    }
}
