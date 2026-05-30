import TileCore
import TileTemplate

extension TileKit.Site.Generator {
    func context(
        page: TileKit.Site.Page,
        pages: [TileKit.Site.Page],
        configuration: TileKit.Site.Configuration,
        sitePaths: TileKit.Site.GeneratedSitePaths,
    ) -> TileKit.Template.Context {
        var result = stringValues(page.document.frontMatter)
        result["site"] = siteValue(
            configuration,
            sitePaths: sitePaths,
            sections: sections(pages),
            title: siteTitle(
                configuration: configuration,
                pages: pages,
            ),
        )
        result["page"] = pageValue(
            page,
            baseURL: configuration.baseURL,
        )
        result["pages"] = .list(
            pages.map { page in
                pageContext(
                    page,
                    baseURL: configuration.baseURL,
                )
            },
        )
        result["contents"] = .string(page.html)
        result["assets"] = assetsValue(page)
        return result
    }

    func siteValue(
        _ configuration: TileKit.Site.Configuration,
        sitePaths: TileKit.Site.GeneratedSitePaths,
        sections: [TileKit.Site.Page],
        title: String,
    ) -> TileKit.Template.Value {
        .object(
            [
                "title": .string(title),
                "baseURL": .string(configuration.baseURL),
                "homeURL": .string(url(for: "", baseURL: configuration.baseURL)),
                "stylesheetPath": .string(sitePaths.stylesheetPath),
                "feedPath": .string(sitePaths.feedPath),
                "socialLinks": .list(configuration.socialLinks.map(socialLinkContext)),
                "sections": .list(
                    sections.map { section in
                        pageContext(
                            section,
                            baseURL: configuration.baseURL,
                        )
                    },
                ),
            ],
        )
    }

    func siteTitle(
        configuration: TileKit.Site.Configuration,
        pages: [TileKit.Site.Page],
    ) -> String {
        if !configuration.title.isEmpty {
            return configuration.title
        }
        return pages.first { $0.slug.isEmpty }?
            .document
            .frontMatter["title"] ?? ""
    }

    /// The site's top-level sections for navigation: the depth-1 pages (each
    /// section's `index.md` landing page), ordered by a front-matter `weight`
    /// (pages without a weight sort last, then alphabetically by title or slug).
    /// The root page (empty slug, the home page) is not a section.
    func sections(
        _ pages: [TileKit.Site.Page],
    ) -> [TileKit.Site.Page] {
        pages
            .filter { !$0.slug.isEmpty && !$0.slug.contains("/") }
            .sorted { first, second in
                let firstWeight = weight(first)
                let secondWeight = weight(second)
                if firstWeight != secondWeight {
                    return firstWeight < secondWeight
                }
                let firstKey = sortKey(first)
                let secondKey = sortKey(second)
                if firstKey != secondKey {
                    return firstKey < secondKey
                }
                // Slugs are unique, so this makes the order fully deterministic.
                return first.slug < second.slug
            }
    }

    func weight(
        _ page: TileKit.Site.Page,
    ) -> Int {
        page.document.frontMatter["weight"].flatMap(Int.init) ?? Int.max
    }

    func sortKey(
        _ page: TileKit.Site.Page,
    ) -> String {
        page.document.frontMatter["title"] ?? page.slug
    }

    func pageValue(
        _ page: TileKit.Site.Page,
        baseURL: String = "",
    ) -> TileKit.Template.Value {
        .object(
            pageContext(
                page,
                baseURL: baseURL,
            ),
        )
    }

    func pageContext(
        _ page: TileKit.Site.Page,
        baseURL: String = "",
    ) -> TileKit.Template.Context {
        var context = stringValues(page.document.frontMatter)
        context["slug"] = .string(page.slug)
        context["url"] = .string(
            url(
                for: page.slug,
                baseURL: baseURL,
            ),
        )
        context["contents"] = .object(
            [
                "html": .string(page.html),
            ],
        )
        context["assets"] = assetsValue(page)
        return context
    }

    func assetsValue(
        _ page: TileKit.Site.Page,
    ) -> TileKit.Template.Value {
        .object(
            [
                "css": .string(page.stylesheet.text()),
                "javascript": .string(page.javascript),
            ],
        )
    }

    func socialLinkContext(
        _ link: TileKit.Site.SocialLink,
    ) -> TileKit.Template.Context {
        [
            "label": .string(link.label),
            "url": .string(link.url),
        ]
    }

    func stringValues(
        _ values: [String: String],
    ) -> TileKit.Template.Context {
        values.reduce(into: [:]) { result, item in
            result[item.key] = .string(item.value)
        }
    }

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
}
