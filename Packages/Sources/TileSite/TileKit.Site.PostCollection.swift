import TileCore

public extension TileKit.Site {
    /// The site's posts as a Swift collection: every page sourced under the posts
    /// directory whose `date` parses as `yyyy-MM-dd`, newest first (ties broken by
    /// canonical slug). The section landing page (the bare directory source slug)
    /// has no `date` and so is not a post.
    ///
    /// Conforming to `RandomAccessCollection` means the on-page listing, the RSS
    /// feed, per-tag filtering, and the latest-posts block all derive from one
    /// ordered sequence through `prefix`, `filter`, and iteration, instead of
    /// bespoke helpers. The newest-first, date-valid rule lives here, once.
    struct PostCollection: RandomAccessCollection, Sendable {
        private let posts: [Page]

        /// Selects and orders the posts among `pages` a single time. A page with
        /// an absent or malformed `date`, or one sourced outside `postsDirectory`,
        /// is not a post and is omitted. The public slug can differ from the source
        /// slug so migrated posts keep legacy URLs without leaving the post
        /// collection.
        public init(
            among pages: [Page],
            postsDirectory: String,
        ) {
            posts = pages
                .filter { page in
                    page.sourceSlug.hasPrefix(postsDirectory + "/")
                        && PostSelection.parsedDate(page.document.frontMatter["date"]) != nil
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
