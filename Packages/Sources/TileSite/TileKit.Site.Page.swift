import TileCore
import TileOutput
import TileSource

public extension TileKit.Site {
    struct Page: Equatable, Sendable {
        public var sourcePath: String
        public var outputPath: String
        public var slug: String
        public var document: TileKit.Source.Document
        public var html: String
        /// The page's CSS by cascade layer, mergeable into a shared site stylesheet.
        public var stylesheet: TileKit.Output.Stylesheet
        public var javascript: String

        public init(
            sourcePath: String,
            outputPath: String,
            slug: String,
            document: TileKit.Source.Document,
            html: String,
            stylesheet: TileKit.Output.Stylesheet = .init(),
            javascript: String = "",
        ) {
            self.sourcePath = sourcePath
            self.outputPath = outputPath
            self.slug = slug
            self.document = document
            self.html = html
            self.stylesheet = stylesheet
            self.javascript = javascript
        }
    }
}
