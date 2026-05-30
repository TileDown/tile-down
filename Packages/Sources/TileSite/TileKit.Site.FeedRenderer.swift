import Foundation
import TileCore

public extension TileKit.Site {
    /// Renders the site's RSS feed from dated pages under `posts/`.
    struct FeedRenderer: Sendable {
        public init() {}

        public func render(
            feed: Feed,
            siteTitle: String,
            baseURL: String,
            pages: [Page],
        ) -> String {
            let title = feed.title.isEmpty ? siteTitle : feed.title
            let items = postPages(pages)
                .map { page in
                    feedItemXML(
                        page: page,
                        baseURL: baseURL,
                    )
                }
                .joined(separator: "\n")

            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
            <channel>
            <title>\(xmlEscaped(title))</title>
            <link>\(xmlEscaped(absoluteURL(baseURL: baseURL, path: "/")))</link>
            <description>\(xmlEscaped(feed.description))</description>
            \(items)
            </channel>
            </rss>

            """
        }

        private func feedItemXML(
            page: Page,
            baseURL: String,
        ) -> String {
            let title = page.document.frontMatter["title"] ?? page.slug
            let path = url(for: page.slug)
            let absolutePath = absoluteURL(
                baseURL: baseURL,
                path: path,
            )
            let description = page.document.frontMatter["description"] ?? title
            let pubDate = page.document.frontMatter["date"].flatMap(rssDate)
            let pubDateXML = pubDate.map { "<pubDate>\(xmlEscaped($0))</pubDate>\n" } ?? ""

            return """
            <item>
            <title>\(xmlEscaped(title))</title>
            <link>\(xmlEscaped(absolutePath))</link>
            <guid>\(xmlEscaped(absolutePath))</guid>
            \(pubDateXML)<description>\(xmlEscaped(description))</description>
            <content:encoded>\(cdata(page.html))</content:encoded>
            </item>
            """
        }

        private func postPages(
            _ pages: [Page],
        ) -> [Page] {
            pages
                .filter { page in
                    page.slug.hasPrefix("posts/")
                        && page.document.frontMatter["date"].flatMap(rssDate) != nil
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

        private func url(
            for slug: String,
        ) -> String {
            slug.isEmpty ? "/" : "/" + slug + "/"
        }

        private func absoluteURL(
            baseURL: String,
            path: String,
        ) -> String {
            guard !baseURL.isEmpty else {
                return path
            }

            let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            return baseURL.hasSuffix("/") ? baseURL + normalizedPath : baseURL + "/" + normalizedPath
        }

        private func rssDate(
            _ value: String,
        ) -> String? {
            let input = DateFormatter()
            input.locale = Locale(identifier: "en_US_POSIX")
            input.timeZone = TimeZone(secondsFromGMT: 0)
            input.dateFormat = "yyyy-MM-dd"

            guard let date = input.date(from: value) else {
                return nil
            }

            let output = DateFormatter()
            output.locale = Locale(identifier: "en_US_POSIX")
            output.timeZone = TimeZone(secondsFromGMT: 0)
            output.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            return output.string(from: date)
        }

        /// Wraps content in a CDATA section so HTML passes through verbatim. Any
        /// embedded `]]>` is split across two sections, the standard way to keep
        /// a literal terminator from closing the block early.
        private func cdata(
            _ content: String,
        ) -> String {
            let safe = Self.xmlLegal(content)
                .replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>")
            return "<![CDATA[\(safe)]]>"
        }

        private func xmlEscaped(
            _ value: String,
        ) -> String {
            Self.xmlLegal(value)
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&apos;")
        }

        /// Drops characters that are illegal in XML 1.0 regardless of escaping or
        /// CDATA wrapping: the C0 control range except tab, newline, and carriage
        /// return. One such byte (a stray form feed or NUL pasted into a post)
        /// would otherwise make the whole feed not-well-formed.
        private static func xmlLegal(
            _ value: String,
        ) -> String {
            String(value.unicodeScalars.filter { scalar in
                switch scalar.value {
                case 0x9, 0xA, 0xD:
                    true
                case 0x0 ... 0x1F:
                    false
                default:
                    true
                }
            })
        }
    }
}
