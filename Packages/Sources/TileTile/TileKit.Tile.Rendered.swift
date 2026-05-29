import TileCore

public extension TileKit.Tile {
    /// Static output emitted by a tile renderer.
    struct Rendered: Equatable, Sendable {
        public var html: String
        public var css: String
        public var javascript: String

        public init(
            html: String,
            css: String = "",
            javascript: String = "",
        ) {
            self.html = html
            self.css = css
            self.javascript = javascript
        }
    }
}
