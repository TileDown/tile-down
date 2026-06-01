import TileCore
import TileTemplate

extension TileKit.Site.Generator {
    /// Page image metadata for built-in layouts and custom templates. `image` is
    /// the light/default source; `imageDark` is optional and switches with the
    /// same dark-mode selectors as the built-in themes.
    func heroImageContext(
        _ page: TileKit.Site.Page,
        baseURL: String = "",
    ) -> TileKit.Template.Context? {
        guard
            let rawSource = page.document.frontMatter["image"],
            !rawSource.isEmpty
        else {
            return nil
        }

        let source = assetURL(rawSource, baseURL: baseURL)
        let title = page.document.frontMatter["title"] ?? ""
        let darkSource = page.document.frontMatter["imageDark"]
            .flatMap { $0.isEmpty ? nil : $0 }
            .map { assetURL($0, baseURL: baseURL) }
        return [
            "src": .string(source),
            "darkSrc": .string(darkSource ?? ""),
            "alt": .string(title),
            "hasDark": .string(darkSource == nil ? "" : "true"),
            "heroHTML": .string(imageHTML(
                source: source,
                darkSource: darkSource,
                alt: title,
                className: "td-hero",
            )),
            "thumbnailHTML": .string(imageHTML(
                source: source,
                darkSource: darkSource,
                alt: title,
                className: "td-post-thumb-image",
            )),
        ]
    }

    private func imageHTML(
        source: String,
        darkSource: String?,
        alt: String,
        className: String,
    ) -> String {
        let escapedSource = escapeHTMLAttribute(source)
        let escapedAlt = escapeHTMLAttribute(alt)
        guard let darkSource else {
            return #"<img class="\#(className)" src="\#(escapedSource)" alt="\#(escapedAlt)">"#
        }

        let escapedDarkSource = escapeHTMLAttribute(darkSource)
        let accessibility = if escapedAlt.isEmpty {
            #" aria-hidden="true""#
        } else {
            #" role="img" aria-label="\#(escapedAlt)""#
        }
        return [
            #"<span class="td-theme-image \#(className)"\#(accessibility)>"#,
            #"<img class="td-theme-image-light" src="\#(escapedSource)" alt="" aria-hidden="true">"#,
            #"<img class="td-theme-image-dark" src="\#(escapedDarkSource)" alt="" aria-hidden="true">"#,
            "</span>",
        ].joined()
    }

    private func assetURL(
        _ source: String,
        baseURL: String,
    ) -> String {
        guard !baseURL.isEmpty, source.hasPrefix("/"), !isExternalAssetURL(source) else {
            return source
        }
        let path = String(source.dropFirst())
        return baseURL.hasSuffix("/") ? baseURL + path : baseURL + "/" + path
    }

    private func isExternalAssetURL(
        _ source: String,
    ) -> Bool {
        let lowercased = source.lowercased()
        return lowercased.hasPrefix("http://")
            || lowercased.hasPrefix("https://")
            || lowercased.hasPrefix("data:")
            || lowercased.hasPrefix("//")
    }

    private func escapeHTMLAttribute(
        _ value: String,
    ) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
