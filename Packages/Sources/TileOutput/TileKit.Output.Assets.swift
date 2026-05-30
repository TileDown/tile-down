import TileCore

public extension TileKit.Output {
    /// Page-local runtime assets an output renderer collects alongside its
    /// contents.
    ///
    /// CSS and browser JavaScript that a rendered document needs. A renderer with
    /// no runtime assets (such as the JSON renderer) leaves these empty.
    struct Assets: Equatable, Sendable {
        public var css: String
        public var javascript: String

        public init(
            css: String = "",
            javascript: String = "",
        ) {
            self.css = css
            self.javascript = javascript
        }
    }
}
