import Foundation
import TileCore

extension TileKit.Site.Generator {
    /// Merges content pages with the generated tag pages, then resolves every
    /// Markdown reference (`page:`/`post:`/`tag:`/`social:`/`link:`) in their HTML.
    func assembledPages(
        _ contentPages: [TileKit.Site.Page],
        posts: TileKit.Site.PostCollection,
        request: TileKit.Site.ContentBuildRequest,
    ) throws -> [TileKit.Site.Page] {
        let merged = contentPages + tagPages(
            among: posts,
            outputRootPath: request.outputRootPath,
        )
        return try resolveReferences(
            in: merged,
            posts: posts,
            configuration: request.configuration,
        )
    }

    /// Rewrites reference-scheme links in every page to the URLs the engine owns,
    /// failing the build with one aggregated error if any reference is unknown.
    func resolveReferences(
        in pages: [TileKit.Site.Page],
        posts: TileKit.Site.PostCollection,
        configuration: TileKit.Site.Configuration,
    ) throws -> [TileKit.Site.Page] {
        let resolver = referenceResolver(
            pages: pages,
            posts: posts,
            configuration: configuration,
        )
        let schemes = TileKit.Site.Reference.schemes
            .sorted()
            .joined(separator: "|")
        let regex = try Regex("<a href=\"(\(schemes)):([^\"]*)\">(</a>)?")

        var unresolved: [TileKit.Site.UnresolvedReference] = []
        var result: [TileKit.Site.Page] = []
        for page in pages {
            let (html, broken) = rewriteReferences(
                in: page.html,
                sourcePath: page.sourcePath,
                regex: regex,
                resolver: resolver,
            )
            var copy = page
            copy.html = html
            result.append(copy)
            unresolved.append(contentsOf: broken)
        }

        guard unresolved.isEmpty else {
            throw TileKit.Site.ReferenceError.unresolved(unresolved)
        }
        return result
    }

    /// Builds the resolver from the full page set (slug to URL and title), the
    /// configured posts directory, the site's tags, the configured socials, and the
    /// configured outbound link shims (each an `/out/<key>/` URL).
    private func referenceResolver(
        pages: [TileKit.Site.Page],
        posts: TileKit.Site.PostCollection,
        configuration: TileKit.Site.Configuration,
    ) -> TileKit.Site.ReferenceResolver {
        let baseURL = configuration.baseURL
        var pageURL: [String: String] = [:]
        var title: [String: String] = [:]
        for page in pages {
            pageURL[page.slug] = url(for: page.slug, baseURL: baseURL)
            title[page.slug] = page.document.frontMatter["title"] ?? page.slug
        }
        var tagURL: [String: String] = [:]
        var tagLabel: [String: String] = [:]
        for tag in TileKit.Site.Tags.allTags(among: posts) {
            tagURL[tag.slug] = url(for: "tags/" + tag.slug, baseURL: baseURL)
            tagLabel[tag.slug] = tag.label
        }
        var socialURL: [String: String] = [:]
        var socialLabel: [String: String] = [:]
        for link in configuration.socialLinks {
            let key = link.label.lowercased()
            socialURL[key] = link.url
            socialLabel[key] = link.label
        }
        var shimURL: [String: String] = [:]
        for key in configuration.outboundLinks.keys {
            shimURL[key] = url(for: "out/" + key, baseURL: baseURL)
        }
        return .init(
            pageURLBySlug: pageURL,
            titleBySlug: title,
            tagURLBySlug: tagURL,
            tagLabelBySlug: tagLabel,
            socialURLByKey: socialURL,
            socialLabelByKey: socialLabel,
            shimURLByKey: shimURL,
            postsDirectory: configuration.postsDirectory,
        )
    }

    /// Rewrites each reference anchor in one page's HTML, filling empty anchor text
    /// with the target's display name, and returns any references that did not
    /// resolve so the caller can aggregate and report them.
    private func rewriteReferences(
        in html: String,
        sourcePath: String,
        regex: Regex<AnyRegexOutput>,
        resolver: TileKit.Site.ReferenceResolver,
    ) -> (String, [TileKit.Site.UnresolvedReference]) {
        let matches = html.matches(of: regex)
        guard !matches.isEmpty else {
            return (html, [])
        }
        var out = ""
        var index = html.startIndex
        var unresolved: [TileKit.Site.UnresolvedReference] = []
        for match in matches {
            out += html[index ..< match.range.lowerBound]
            let scheme = String(match.output[1].substring ?? "")
            let key = String(match.output[2].substring ?? "")
            let emptyAnchor = match.output[3].substring != nil
            if let resolved = resolver.resolve(scheme: scheme, key: key) {
                out += "<a href=\"\(attributeEscape(resolved.url))\">"
                if emptyAnchor {
                    out += textEscape(resolved.displayName) + "</a>"
                }
            } else {
                unresolved.append(
                    .init(scheme: scheme, key: key, sourcePath: sourcePath),
                )
                out += String(html[match.range])
            }
            index = match.range.upperBound
        }
        out += html[index...]
        return (out, unresolved)
    }

    /// Escapes a value for use inside a double-quoted HTML attribute.
    private func attributeEscape(
        _ value: String,
    ) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
    }

    /// Escapes a value for use as HTML element text.
    private func textEscape(
        _ value: String,
    ) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
