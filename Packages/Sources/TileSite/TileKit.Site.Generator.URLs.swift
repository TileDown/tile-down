import TileCore

extension TileKit.Site.Generator {
    func url(
        for slug: String,
        baseURL: String = "",
    ) -> String {
        let path = slug.isEmpty ? "/" : "/" + slug + "/"
        guard !baseURL.isEmpty else {
            return path
        }
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.hasSuffix("/") ? baseURL + relativePath : baseURL + "/" + relativePath
    }

    /// Applies `baseURL` to a generated root-relative URL while leaving external,
    /// protocol-relative, fragment, query, and authored relative URLs unchanged.
    func baseURLPrefixedRootRelativeURL(
        _ value: String,
        baseURL: String,
    ) -> String {
        guard
            !baseURL.isEmpty,
            value.hasPrefix("/"),
            !value.hasPrefix("//")
        else {
            return value
        }

        if value == "/" {
            return baseURL.hasSuffix("/") ? baseURL : baseURL + "/"
        }

        let relativePath = String(value.dropFirst())
        return baseURL.hasSuffix("/") ? baseURL + relativePath : baseURL + "/" + relativePath
    }

    /// Rewrites generated `href` and `src` attributes whose values are
    /// root-relative, so Markdown-authored root paths behave the same as the
    /// engine-owned links under subpath deployments.
    func rewriteRootRelativeURLs(
        in html: String,
        baseURL: String,
    ) -> String {
        guard !baseURL.isEmpty else {
            return html
        }

        guard let regex = try? Regex(#"(<(?:a|img)\b[^>]*?\s)(href|src)="(/[^"]*)""#) else {
            return html
        }
        let matches = html.matches(of: regex)
        guard !matches.isEmpty else {
            return html
        }

        var result = ""
        var index = html.startIndex
        for match in matches {
            result += html[index ..< match.range.lowerBound]
            let prefix = String(match.output[1].substring ?? "")
            let name = String(match.output[2].substring ?? "")
            let value = String(match.output[3].substring ?? "")
            let rewritten = baseURLPrefixedRootRelativeAttributeValue(
                value,
                baseURL: baseURL,
            )
            result += #"\#(prefix)\#(name)="\#(rewritten)""#
            index = match.range.upperBound
        }
        result += html[index...]
        return result
    }

    /// Rewrites an already escaped root-relative attribute value by prefixing an
    /// escaped configured base URL. The attribute value came from generated HTML,
    /// so escaping the whole result would double-escape path/query characters.
    private func baseURLPrefixedRootRelativeAttributeValue(
        _ value: String,
        baseURL: String,
    ) -> String {
        guard
            !baseURL.isEmpty,
            value.hasPrefix("/"),
            !value.hasPrefix("//")
        else {
            return value
        }

        let escapedBaseURL = TileKit.HTML.escapeAttribute(baseURL)
        if value == "/" {
            return baseURL.hasSuffix("/") ? escapedBaseURL : escapedBaseURL + "/"
        }

        let relativePath = String(value.dropFirst())
        return baseURL.hasSuffix("/") ? escapedBaseURL + relativePath : escapedBaseURL + "/" + relativePath
    }
}
