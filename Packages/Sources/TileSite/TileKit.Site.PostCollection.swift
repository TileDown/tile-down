import TileCore

public extension TileKit.Site {
    /// The site's posts as a Swift collection: every post page whose `date`
    /// parses as `yyyy-MM-dd`, newest first (ties broken by canonical slug).
    ///
    /// Conforming to `RandomAccessCollection` means the on-page listing, the RSS
    /// feed, per-tag filtering, and the latest-posts block all derive from one
    /// ordered sequence through `prefix`, `filter`, and iteration, instead of
    /// bespoke helpers. The newest-first, date-valid rule lives here, once.
    struct PostCollection: RandomAccessCollection, Sendable {
        private let posts: [Page]

        /// Selects and orders the posts among `pages` a single time. A page with
        /// an absent or malformed `date` is omitted from date-ordered post
        /// collections. `postsDirectory` remains the compatibility fallback for
        /// pages without an explicit `type`, using the source slug so migrated
        /// posts keep legacy URLs without leaving the post collection.
        public init(
            among pages: [Page],
            postsDirectory: String,
        ) {
            posts = pages
                .filter { page in
                    ContentType.isCollectionPost(
                        page,
                        postsDirectory: postsDirectory,
                    )
                }
                .sorted { first, second in
                    let firstDate = first.document.frontMatter["date"] ?? ""
                    let secondDate = second.document.frontMatter["date"] ?? ""
                    if firstDate != secondDate {
                        return firstDate > secondDate
                    }
                    // Ties broken by slug via Page: Comparable.
                    return first < second
                }
        }

        public var startIndex: Int {
            posts.startIndex
        }

        public var endIndex: Int {
            posts.endIndex
        }

        public subscript(position: Int) -> Page {
            posts[position]
        }

        public func index(after index: Int) -> Int {
            posts.index(after: index)
        }

        public func index(before index: Int) -> Int {
            posts.index(before: index)
        }
    }
}
