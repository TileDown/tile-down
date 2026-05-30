import TileCore

public extension TileKit.Output {
    /// Page-local runtime assets an output renderer collects alongside its
    /// contents.
    ///
    /// CSS and browser JavaScript that a rendered document needs. A renderer with
    /// no runtime assets (such as the JSON renderer) leaves these empty.
    struct Assets: Equatable, Sendable {
        /// The page's CSS, organized by cascade layer so it can be merged across
        /// pages into a shared site stylesheet.
        public var stylesheet: Stylesheet
        public var javascript: String

        public init(
            stylesheet: Stylesheet = .init(),
            javascript: String = "",
        ) {
            self.stylesheet = stylesheet
            self.javascript = javascript
        }

        /// The page's CSS rendered to canonical layered text, for inlining when the
        /// page is not linking a shared stylesheet.
        public var css: String {
            stylesheet.text()
        }
    }
}
