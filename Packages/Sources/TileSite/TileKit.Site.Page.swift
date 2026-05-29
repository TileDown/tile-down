import TileCore
import TileSource

public extension TileKit.Site {
    struct Page: Equatable, Sendable {
        public var sourcePath: String
        public var outputPath: String
        public var slug: String
        public var document: TileKit.Source.Document
        public var html: String

        public init(
            sourcePath: String,
            outputPath: String,
            slug: String,
            document: TileKit.Source.Document,
            html: String,
        ) {
            self.sourcePath = sourcePath
            self.outputPath = outputPath
            self.slug = slug
            self.document = document
            self.html = html
        }
    }
}
