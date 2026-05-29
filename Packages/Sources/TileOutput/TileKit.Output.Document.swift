import TileCore
import TileTile

public extension TileKit.Output {
    /// The resolved page data an output renderer projects into a serialized form.
    ///
    /// This is the renderer input: the front matter, the parsed tile block tree in
    /// source order, and the page slug. It carries no template or cross-page
    /// context; a renderer that needs those (such as a full HTML page renderer) is
    /// layered on top by the composition root, not by the output seam.
    struct Document: Equatable, Sendable {
        public var frontMatter: [String: String]
        public var blocks: [TileKit.Tile.Block]
        public var slug: String

        public init(
            frontMatter: [String: String] = [:],
            blocks: [TileKit.Tile.Block],
            slug: String = "",
        ) {
            self.frontMatter = frontMatter
            self.blocks = blocks
            self.slug = slug
        }
    }
}
