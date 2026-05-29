import TileCore
import TileMarkdown
import TileTile

public extension TileKit.Site {
    /// Serializes a parsed Tiledown document back to canonical Tiledown Markdown.
    ///
    /// The `put` side of the round-trip for the whole document: prose blocks are
    /// canonicalized through an injected ``TileKit/Markdown/Formatting`` and tile
    /// blocks through ``TileKit/Tile/DirectiveSerializer``, joined in source order.
    /// The canonical output is a fixed point, so re-serializing it does not change
    /// it. Byte identity with the original is not a goal; the canonical form is the
    /// normalized profile.
    struct DocumentSerializer {
        private let markdownFormatter: any TileKit.Markdown.Formatting
        private let tileSerializer: TileKit.Tile.DirectiveSerializer

        public init(
            markdownFormatter: any TileKit.Markdown.Formatting,
            tileSerializer: TileKit.Tile.DirectiveSerializer = .init(),
        ) {
            self.markdownFormatter = markdownFormatter
            self.tileSerializer = tileSerializer
        }

        public func serialize(
            _ blocks: [TileKit.Tile.Block],
        ) -> String {
            blocks
                .map(serialize)
                .joined(separator: "\n")
        }

        private func serialize(
            _ block: TileKit.Tile.Block,
        ) -> String {
            switch block {
            case let .markdown(text):
                markdownFormatter.canonicalize(text)
            case let .tile(instance):
                tileSerializer.serialize(instance)
            }
        }
    }
}
