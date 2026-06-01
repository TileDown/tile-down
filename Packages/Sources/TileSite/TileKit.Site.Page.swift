import TileCore
import TileOutput
import TileSource

public extension TileKit.Site {
    /// A built page: its source and output paths, folder-derived source slug,
    /// canonical output slug, parsed document, rendered HTML, and per-page assets.
    ///
    /// A page's identity is its slug, which the generator guarantees is unique per
    /// build (see `assertUniqueSlugs`). `Equatable`, `Hashable`, and `Comparable`
    /// are all keyed on the slug so they agree: two pages are equal iff they share
    /// a slug, hash by that slug, and order alphabetically by it. This lets a page
    /// sit in a `Set`, be a dictionary key, and sort without a custom comparator.
    struct Page: Hashable, Comparable, Sendable {
        public var sourcePath: String
        public var outputPath: String
        public var sourceSlug: String
        public var slug: String
        public var document: TileKit.Source.Document
        public var html: String
        /// The page's CSS by cascade layer, mergeable into a shared site stylesheet.
        public var stylesheet: TileKit.Output.Stylesheet
        public var javascript: String

        public init(
            sourcePath: String,
            outputPath: String,
            sourceSlug: String? = nil,
            slug: String,
            document: TileKit.Source.Document,
            html: String,
            stylesheet: TileKit.Output.Stylesheet = .init(),
            javascript: String = "",
        ) {
            self.sourcePath = sourcePath
            self.outputPath = outputPath
            self.sourceSlug = sourceSlug ?? slug
            self.slug = slug
            self.document = document
            self.html = html
            self.stylesheet = stylesheet
            self.javascript = javascript
        }

        public static func == (lhs: Page, rhs: Page) -> Bool {
            lhs.slug == rhs.slug
        }

        public static func < (lhs: Page, rhs: Page) -> Bool {
            lhs.slug < rhs.slug
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(slug)
        }
    }
}
