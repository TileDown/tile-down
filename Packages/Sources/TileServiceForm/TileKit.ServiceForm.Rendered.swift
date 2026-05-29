import TileCore

public extension TileKit.ServiceForm {
    /// Static output emitted by a generated service form renderer.
    struct Rendered: Equatable, Sendable {
        public var html: String
        public var css: String
        public var javascript: String

        public init(
            html: String,
            css: String,
            javascript: String,
        ) {
            self.html = html
            self.css = css
            self.javascript = javascript
        }
    }
}
