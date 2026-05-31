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
        let posts = TileKit.Site.PostCollection(
            among: pages,
            postsDirectory: configuration.postsDirectory,
        )
        result["site"] = siteValue(
            configuration,
            sitePaths: sitePaths,
            posts: posts,
            pages: pages,
            currentSlug: page.slug,
        )
        result["page"] = pageValue(
            page,
            baseURL: configuration.baseURL,
            posts: pagePosts(for: page, among: posts),
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
        posts: TileKit.Site.PostCollection,
        pages: [TileKit.Site.Page],
        currentSlug: String,
    ) -> TileKit.Template.Value {
        let baseURL = configuration.baseURL
        let latest = posts.prefix(max(0, configuration.latestPostCount))
        let title = siteTitle(configuration: configuration, pages: pages)
        return .object(
            [
                "title": .string(title),
                "baseURL": .string(baseURL),
                "homeURL": .string(url(for: "", baseURL: baseURL)),
                "stylesheetPath": .string(sitePaths.stylesheetPath),
                "feedPath": .string(sitePaths.feedPath),
                // Forced light/dark sets data-theme on <html>; empty for toggle/auto.
                "appearanceForced": .string(forcedAppearance(configuration.appearance)),
                // Non-empty only in toggle mode, gating the button and its script.
                "appearanceToggle": .string(configuration.appearance == .toggle ? "true" : ""),
                "socialLinks": .list(configuration.socialLinks.map(socialLinkContext)),
                "sections": .list(sectionContexts(sections(pages), baseURL: baseURL, currentSlug: currentSlug)),
                "posts": .list(pageContexts(posts, baseURL: baseURL)),
                "tags": .list(tagContexts(posts: posts, baseURL: baseURL)),
                "latestPosts": .list(pageContexts(latest, baseURL: baseURL)),
            ],
        )
    }

    /// Maps pages to their template contexts at a base URL. The shared projection
    /// behind `site.sections`, `site.posts`, and `site.latestPosts`.
    func pageContexts(
        _ pages: some Sequence<TileKit.Site.Page>,
        baseURL: String,
    ) -> [TileKit.Template.Context] {
        pages.map { page in
            pageContext(page, baseURL: baseURL)
        }
    }

    /// Section contexts for the navigation, each carrying `isCurrent` so the
    /// template can mark the active item. A section is current when the page being
    /// rendered is that section's landing page or any page beneath it.
    func sectionContexts(
        _ sections: some Sequence<TileKit.Site.Page>,
        baseURL: String,
        currentSlug: String,
    ) -> [TileKit.Template.Context] {
        sections.map { section in
            var context = pageContext(section, baseURL: baseURL)
            let isCurrent = currentSlug == section.slug
                || currentSlug.hasPrefix(section.slug + "/")
            context["isCurrent"] = .string(isCurrent ? "true" : "")
            return context
        }
    }

    /// The site-wide tag contexts for `site.tags`: every distinct tag with its
    /// name, URL, and post count, ordered by slug.
    func tagContexts(
        posts: some Sequence<TileKit.Site.Page>,
        baseURL: String,
    ) -> [TileKit.Template.Context] {
        TileKit.Site.Tags.allTags(among: posts).map { tag in
            [
                "name": .string(tag.label),
                "url": .string(url(for: "tags/" + tag.slug, baseURL: baseURL)),
                "count": .string(String(tag.count)),
            ]
        }
    }

    /// The literal appearance to pin on `<html data-theme>` for forced modes
    /// (`light`/`dark`), or "" for `toggle`/`auto` where the document is not
    /// pinned (the script or the OS decides).
    func forcedAppearance(
        _ appearance: TileKit.Site.Appearance,
    ) -> String {
        switch appearance {
        case .light:
            "light"
        case .dark:
            "dark"
        case .toggle, .auto:
            ""
        }
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
        posts: [TileKit.Site.Page] = [],
    ) -> TileKit.Template.Value {
        var context = pageContext(
            page,
            baseURL: baseURL,
        )
        context["posts"] = .list(
            posts.map { post in
                pageContext(
                    post,
                    baseURL: baseURL,
                )
            },
        )
        return .object(context)
    }

    /// The posts a page lists. A tag page (carrying a `tag` marker) lists only
    /// the posts with that tag; every other page is given all posts and the
    /// template decides whether to show them (via `postList`).
    func pagePosts(
        for page: TileKit.Site.Page,
        among posts: some Sequence<TileKit.Site.Page>,
    ) -> [TileKit.Site.Page] {
        guard let tag = page.document.frontMatter["tag"], !tag.isEmpty else {
            return Array(posts)
        }
        return posts.filter { post in
            TileKit.Site.Tags.tags(of: post).contains { candidate in
                TileKit.Site.Tags.slug(for: candidate) == tag
            }
        }
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
        let tags = TileKit.Site.Tags.tags(of: page)
        context["tags"] = .list(
            tags.map { tag in
                [
                    "name": .string(tag),
                    "url": .string(url(for: "tags/" + TileKit.Site.Tags.slug(for: tag), baseURL: baseURL)),
                ]
            },
        )
        // Non-empty only when the page has tags, gating the chip block in templates.
        context["hasTags"] = .string(tags.isEmpty ? "" : "true")
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
