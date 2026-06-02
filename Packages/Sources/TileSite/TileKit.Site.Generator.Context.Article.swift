import Foundation
import TileCore
import TileTemplate

extension TileKit.Site.Generator {
    /// The rendered HTML for the recent-posts placement marker (`:::recent:::` on
    /// its own line), as CommonMark renders it: a paragraph of that literal text.
    private static let recentMarkerHTML = "<p>:::recent:::</p>"

    /// Splits a page's rendered HTML at the recent-posts marker so a layout can
    /// render the recent block in its place. Returns the body before the marker
    /// and the body after it. With no marker the whole body is the head.
    func recentSplit(
        _ html: String,
    ) -> (head: String, tail: String) {
        guard let range = html.range(of: Self.recentMarkerHTML) else {
            return (html, "")
        }
        let head = String(html[..<range.lowerBound])
        let tail = String(html[range.upperBound...])
        return (head, tail)
    }

    func pageIsPost(
        _ page: TileKit.Site.Page,
        postsDirectory: String,
    ) -> Bool {
        TileKit.Site.ContentType.isPost(
            page,
            postsDirectory: postsDirectory,
        )
    }

    func articleContext(
        _ page: TileKit.Site.Page,
        sitePosts: [TileKit.Site.Page],
        baseURL: String,
        shareLinksEnabled: Bool,
    ) -> TileKit.Template.Context {
        var context: TileKit.Template.Context = [
            "kicker": .string(articleKicker(page)),
            "date": .string(TileKit.Site.PostSelection.displayDate(page.document.frontMatter["date"])),
            "title": .string(page.document.frontMatter["title"] ?? page.slug),
            "description": .string(page.document.frontMatter["description"] ?? ""),
            "url": .string(url(for: page.slug, baseURL: baseURL)),
        ]
        if let heroImage = heroImageContext(page) {
            context["heroImage"] = .object(heroImage)
        }

        let split = recentSplit(page.html)
        context["contents"] = .object(
            [
                "htmlHead": .string(stripLeadingHeading(split.head)),
                "htmlTail": .string(split.tail),
            ],
        )

        let relatedPosts = sitePosts
            .filter { $0.slug != page.slug }
            .prefix(3)
        context["relatedPosts"] = .list(pageContexts(relatedPosts, baseURL: baseURL))
        context["hasRelatedPosts"] = .string(relatedPosts.isEmpty ? "" : "true")
        addShareLinks(to: &context, for: page, baseURL: baseURL, enabled: shareLinksEnabled)
        return context
    }

    private func addShareLinks(
        to context: inout TileKit.Template.Context,
        for page: TileKit.Site.Page,
        baseURL: String,
        enabled: Bool,
    ) {
        guard enabled else { return }
        let shareLinks = articleShareLinks(page, baseURL: baseURL)
        context["shareLinks"] = .list(shareLinks)
        context["hasShareLinks"] = .string(shareLinks.isEmpty ? "" : "true")
    }

    private func articleShareLinks(
        _ page: TileKit.Site.Page,
        baseURL: String,
    ) -> [TileKit.Template.Context] {
        let pageURL = url(for: page.slug, baseURL: baseURL)
        let title = page.document.frontMatter["title"] ?? page.slug
        let encodedURL = shareEncoded(pageURL)
        let encodedTitle = shareEncoded(title)
        return [
            shareLink(
                "X",
                url: "https://twitter.com/intent/tweet?url=\(encodedURL)&text=\(encodedTitle)",
            ),
            shareLink(
                "LinkedIn",
                url: "https://www.linkedin.com/sharing/share-offsite/?url=\(encodedURL)",
            ),
            shareLink(
                "Facebook",
                url: "https://www.facebook.com/sharer/sharer.php?u=\(encodedURL)",
            ),
            shareLink(
                "Email",
                url: "mailto:?subject=\(encodedTitle)&body=\(encodedURL)",
            ),
        ]
    }

    private func shareLink(
        _ label: String,
        url: String,
    ) -> TileKit.Template.Context {
        [
            "label": .string(label),
            "url": .string(url),
        ]
    }

    private func shareEncoded(
        _ value: String,
    ) -> String {
        value.addingPercentEncoding(withAllowedCharacters: Self.shareQueryAllowed) ?? ""
    }

    private static let shareQueryAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=/?")
        return allowed
    }()

    private func articleKicker(
        _ page: TileKit.Site.Page,
    ) -> String {
        if let kicker = page.document.frontMatter["kicker"], !kicker.isEmpty {
            return kicker
        }
        return TileKit.Site.ContentType.articleKicker(for: page)
    }

    private func stripLeadingHeading(
        _ html: String,
    ) -> String {
        guard let headingStart = html.range(of: "<h1") else {
            return html
        }
        let beforeHeading = html[..<headingStart.lowerBound]
        guard beforeHeading.allSatisfy(\.isWhitespace) else {
            return html
        }
        guard let headingEnd = html[headingStart.lowerBound...].range(of: "</h1>") else {
            return html
        }
        var remainder = String(html[headingEnd.upperBound...])
        while remainder.first?.isNewline == true {
            remainder.removeFirst()
        }
        return String(beforeHeading) + remainder
    }
}
