import Foundation
import TileCore
import TileTemplate

extension TileKit.Site.Generator {
    /// SEO and social metadata for the built-in layouts. Only absolute URLs are
    /// exposed for canonical/social surfaces because crawlers and social preview
    /// fetchers do not resolve generated sites the same way a browser resolves
    /// body links.
    func metadataContext(
        _ page: TileKit.Site.Page,
        baseURL: String,
        siteTitle: String,
        postsDirectory: String,
    ) -> TileKit.Template.Context {
        let title = page.document.frontMatter["title"] ?? page.slug
        let description = page.document.frontMatter["description"] ?? ""
        let pageURL = canonicalURL(page, baseURL: baseURL)
        let imageURL = metadataImageURL(page, pageURL: pageURL, baseURL: baseURL)
        let isArticle = pageIsPost(page, postsDirectory: postsDirectory)

        return [
            "title": .string(title),
            "description": .string(description),
            "canonicalURL": .string(pageURL),
            "openGraphType": .string(isArticle ? "article" : "website"),
            "siteTitle": .string(siteTitle),
            "imageURL": .string(imageURL),
            "twitterCard": .string(imageURL.isEmpty ? "summary" : "summary_large_image"),
            "articlePublishedTime": .string(
                isArticle ? publishedTime(page.document.frontMatter["date"]) : "",
            ),
        ]
    }

    private func canonicalURL(
        _ page: TileKit.Site.Page,
        baseURL: String,
    ) -> String {
        guard !baseURL.isEmpty else {
            return ""
        }
        return url(for: page.slug, baseURL: baseURL)
    }

    private func metadataImageURL(
        _ page: TileKit.Site.Page,
        pageURL: String,
        baseURL: String,
    ) -> String {
        guard
            let source = page.document.frontMatter["image"],
            !source.isEmpty
        else {
            return ""
        }
        return metadataAbsoluteURL(source, pageURL: pageURL, baseURL: baseURL)
    }

    private func metadataAbsoluteURL(
        _ source: String,
        pageURL: String,
        baseURL: String,
    ) -> String {
        if let scheme = URLComponents(string: source)?.scheme?.lowercased() {
            return scheme == "http" || scheme == "https" ? source : ""
        }

        guard
            !source.hasPrefix("//"),
            !source.hasPrefix("#"),
            !source.hasPrefix("?"),
            !baseURL.isEmpty
        else {
            return ""
        }

        if source.hasPrefix("/") {
            return baseURLPrefixedPath(source, baseURL: baseURL)
        }

        guard
            !pageURL.isEmpty,
            let base = URL(string: pageURL),
            let resolved = URL(string: source, relativeTo: base)?.absoluteURL,
            let components = URLComponents(url: resolved, resolvingAgainstBaseURL: false),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return ""
        }

        return resolved.absoluteString
    }

    private func baseURLPrefixedPath(
        _ path: String,
        baseURL: String,
    ) -> String {
        if path == "/" {
            return baseURL.hasSuffix("/") ? baseURL : baseURL + "/"
        }

        let relativePath = String(path.dropFirst())
        return baseURL.hasSuffix("/") ? baseURL + relativePath : baseURL + "/" + relativePath
    }

    private func publishedTime(
        _ value: String?,
    ) -> String {
        guard let value,
              TileKit.Site.PostSelection.parsedDate(value) != nil
        else {
            return ""
        }
        return value + "T00:00:00Z"
    }
}
