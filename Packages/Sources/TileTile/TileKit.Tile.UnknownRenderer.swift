import TileCore

public extension TileKit.Tile {
    /// Renders unsupported tiles as deterministic diagnostics.
    struct UnknownRenderer: Rendering {
        public init() {}

        public func render(
            _ tile: Instance,
        ) -> Rendered {
            let escapedAttribute = TileKit.HTML.escapeAttribute(tile.typeID)
            let escapedText = TileKit.HTML.escape(tile.typeID)
            return .init(
                html: """
                <div class="td-unsupported-tile" data-td-unsupported-tile="\(escapedAttribute)">
                Unsupported tile: \(escapedText)
                </div>
                """,
            )
        }
    }
}
