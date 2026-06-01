import Foundation
import TileCore

public extension TileKit.Site {
    /// The definition of a valid post `date`, shared by `PostCollection` (which
    /// selects and orders the posts) and the RSS feed's `pubDate`, so they always
    /// agree on what counts as a dated post.
    enum PostSelection {
        /// Parses a post `date` value as `yyyy-MM-dd`, or `nil` when it is absent
        /// or malformed.
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

        /// Formats a `yyyy-MM-dd` post date for article chrome. Returns the
        /// original value when parsing fails so custom templates never lose data.
        static func displayDate(
            _ value: String?,
        ) -> String {
            guard
                let value,
                let date = parsedDate(value)
            else {
                return value ?? ""
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}
