import TileCore
import TileTemplate

extension TileKit.Site.Generator {
    /// Page image metadata for built-in layouts and custom templates. `image` is
    /// the light/default source; `hero` is a migration-friendly fallback for the
    /// same concept. `imageDark` is optional and switches with the same dark-mode
    /// selectors as the built-in themes.
    func heroImageContext(
        _ page: TileKit.Site.Page,
        baseURL: String = "",
    ) -> TileKit.Template.Context? {
        guard let source = heroImageSource(page) else {
            return nil
        }

        let title = page.document.frontMatter["title"] ?? ""
        let darkSource = page.document.frontMatter["imageDark"]
            .flatMap { $0.isEmpty ? nil : $0 }
        let resolvedSource = baseURLPrefixedRootRelativeURL(source, baseURL: baseURL)
        let resolvedDarkSource = darkSource.map { source in
            baseURLPrefixedRootRelativeURL(source, baseURL: baseURL)
        }
        return [
            "src": .string(resolvedSource),
            "darkSrc": .string(resolvedDarkSource ?? ""),
            "alt": .string(title),
            "hasDark": .string(resolvedDarkSource == nil ? "" : "true"),
            "heroHTML": .string(imageHTML(
                source: resolvedSource,
                darkSource: resolvedDarkSource,
                alt: title,
                className: "td-hero",
            )),
            "thumbnailHTML": .string(imageHTML(
                source: resolvedSource,
                darkSource: resolvedDarkSource,
                alt: title,
                className: "td-post-thumb-image",
            )),
        ]
    }

    func heroImageSource(
        _ page: TileKit.Site.Page,
    ) -> String? {
        if let image = nonEmptyFrontMatterValue("image", in: page) {
            return image
        }
        return nonEmptyFrontMatterValue("hero", in: page)
    }

    private func nonEmptyFrontMatterValue(
        _ key: String,
        in page: TileKit.Site.Page,
    ) -> String? {
        page.document.frontMatter[key].flatMap { value in
            value.isEmpty ? nil : value
        }
    }

    private func imageHTML(
        source: String,
        darkSource: String?,
        alt: String,
        className: String,
    ) -> String {
        let escapedSource = TileKit.HTML.escapeAttribute(source)
        let escapedAlt = TileKit.HTML.escapeAttribute(alt)
        guard let darkSource else {
            return #"<img class="\#(className)" src="\#(escapedSource)" alt="\#(escapedAlt)">"#
        }

        let escapedDarkSource = TileKit.HTML.escapeAttribute(darkSource)
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
}
