import TileCore

public extension TileKit.Tile {
    /// Where a tile's CSS sits in the cascade-layer order.
    ///
    /// A tile is theme-governed by default; it may reject the site theme and impose
    /// its own look. The output renderer places `themed` CSS in the `theme` layer
    /// and `overriding` CSS in the later `tile-override` layer, which wins over the
    /// theme regardless of selector specificity. An overriding tile must use normal
    /// declarations, not `!important`, since `!important` inverts layer order.
    enum StylePosture: Equatable, Sendable {
        /// Follows the site theme. The default.
        case themed
        /// Rejects the theme and supplies its own look, winning over it.
        case overriding
    }
}
