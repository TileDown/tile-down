import TileCore
import TileSource
import TileTile

public extension TileKit.Site {
    /// Rewrites a Tiledown Markdown source document into its canonical form.
    ///
    /// The formatter is the consumer of the serializer's fixed-point law: it splits
    /// the raw front matter off (preserved verbatim, since front matter has no
    /// canonical serializer yet), canonicalizes the body through
    /// ``TileKit/Site/DocumentSerializer``, and recomposes the two. Because the body
    /// serialization is a fixed point and the front matter is carried unchanged, the
    /// whole output is itself a fixed point: ``isCanonical(_:)`` is exactly
    /// `format(x) == x`.
    struct DocumentFormatter {
        private let frontMatterSplitter: any TileKit.Source.FrontMatterSplitting
        private let tileParser: any TileKit.Tile.Parsing
        private let serializer: DocumentSerializer

        public init(
            frontMatterSplitter: any TileKit.Source.FrontMatterSplitting,
            tileParser: any TileKit.Tile.Parsing,
            serializer: DocumentSerializer,
        ) {
            self.frontMatterSplitter = frontMatterSplitter
            self.tileParser = tileParser
            self.serializer = serializer
        }

        /// Returns the canonical form of the source document.
        public func format(
            _ source: String,
        ) throws -> String {
            let parts = try frontMatterSplitter.split(source)
            let blocks = try tileParser.parseBlocks(parts.body)
            let body = serializer.serialize(blocks)

            guard let frontMatter = parts.frontMatter else {
                return body
            }

            return frontMatter + "\n" + body
        }

        /// Whether the source is already in canonical form.
        public func isCanonical(
            _ source: String,
        ) throws -> Bool {
            try format(source) == source
        }
    }
}
