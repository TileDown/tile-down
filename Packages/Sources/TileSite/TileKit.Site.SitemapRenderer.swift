import TileCore

extension TileKit.Site {
    /// Renders `sitemap.xml` for generated site pages.
    struct SitemapRenderer {
        init() {}

        func render(
            baseURL: String,
            pages: [Page],
        ) -> String {
            let entries = pages.sorted()
                .map { page in
                    urlXML(page: page, baseURL: baseURL)
                }
                .joined(separator: "\n")
            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            \(entries)
            </urlset>

            """
        }

        private func urlXML(
            page: Page,
            baseURL: String,
        ) -> String {
            let location = absoluteURL(
                baseURL: baseURL,
                path: url(for: page.slug),
            )
            let lastmod = lastmodXML(page.document.frontMatter["date"])
            return """
            <url>
            <loc>\(xmlEscaped(location))</loc>\(lastmod)
            </url>
            """
        }

        private func lastmodXML(
            _ value: String?,
        ) -> String {
            guard let value, TileKit.Site.PostSelection.parsedDate(value) != nil else {
                return ""
            }
            return "\n<lastmod>\(xmlEscaped(value))</lastmod>"
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

        private func xmlEscaped(
            _ value: String,
        ) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&apos;")
        }
    }
}
