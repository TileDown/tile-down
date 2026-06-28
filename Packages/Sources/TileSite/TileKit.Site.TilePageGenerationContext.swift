import TileCore
import TileTile

public extension TileKit.Site {
    /// Inputs passed to a tile page generator for one source tile.
    struct TilePageGenerationContext: Sendable {
        public var tile: TileKit.Tile.Instance
        public var sourcePage: TileKit.Site.Page
        public var outputRootPath: String

        public init(
            tile: TileKit.Tile.Instance,
            sourcePage: TileKit.Site.Page,
            outputRootPath: String,
        ) {
            self.tile = tile
            self.sourcePage = sourcePage
            self.outputRootPath = outputRootPath
        }
    }
}
