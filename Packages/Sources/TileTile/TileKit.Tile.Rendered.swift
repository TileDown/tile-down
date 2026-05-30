import TileCore

public extension TileKit.Tile {
    /// Static output emitted by a tile renderer.
    struct Rendered: Equatable, Sendable {
        public var html: String
        public var css: String
        /// Which cascade layer the tile's CSS belongs to. Defaults to `themed`.
        public var cssPosture: StylePosture
        public var javascript: String

        public init(
            html: String,
            css: String = "",
            cssPosture: StylePosture = .themed,
            javascript: String = "",
        ) {
            self.html = html
            self.css = css
            self.cssPosture = cssPosture
            self.javascript = javascript
        }
    }
}
