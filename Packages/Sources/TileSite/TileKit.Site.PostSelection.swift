import Foundation
import TileCore

public extension TileKit.Site {
    /// The single source of truth for which pages count as posts and in what
    /// order, shared by the on-page listing (`site.posts`) and the RSS feed so
    /// the two never diverge.
    ///
    /// A post is a page under the posts directory whose `date` front matter
    /// parses as `yyyy-MM-dd`. A page with an absent or malformed date is not a
    /// post and so appears in neither the listing nor the feed.
    enum PostSelection {
        /// The posts among `pages`, newest first, ties broken by slug. The
        /// section landing page (the bare directory slug) is excluded because it
        /// has no `date`.
        static func posts(
            in pages: [Page],
            postsDirectory: String,
        ) -> [Page] {
            pages
                .filter { page in
                    page.slug.hasPrefix(postsDirectory + "/")
                        && parsedDate(page.document.frontMatter["date"]) != nil
                }
                .sorted { first, second in
                    let firstDate = first.document.frontMatter["date"] ?? ""
                    let secondDate = second.document.frontMatter["date"] ?? ""
                    if firstDate != secondDate {
                        return firstDate > secondDate
                    }
                    return first.slug < second.slug
                }
        }

        /// Parses a post `date` value as `yyyy-MM-dd`, or `nil` when it is absent
        /// or malformed. The one definition of a valid post date, so the listing,
        /// the feed's selection, and the feed's `pubDate` all agree on it.
        static func parsedDate(
            _ value: String?,
        ) -> Date? {
            guard let value else {
                return nil
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: value)
        }
    }
}
