import TileCore

extension TileKit.Site.Generator {
    /// The slug a content page publishes under. A non-empty `slug` front-matter
    /// value overrides the folder-derived slug; surrounding slashes are trimmed so
    /// `slug: /custom/` and `slug: custom` resolve to the same path. An unset,
    /// empty, or slash-only value keeps the folder slug.
    func effectiveSlug(
        folderSlug: String,
        frontMatter: [String: String],
    ) -> String {
        guard let override = frontMatter["slug"], !override.isEmpty else {
            return folderSlug
        }
        var slug = override[...]
        while slug.hasPrefix("/") {
            slug = slug.dropFirst()
        }
        while slug.hasSuffix("/") {
            slug = slug.dropLast()
        }
        return slug.isEmpty ? folderSlug : String(slug)
    }

    /// Ensures no two pages resolve to the same slug. Two pages sharing a slug
    /// would write the same output file and silently clobber one another, so a
    /// collision is a typed build error naming the slug.
    func assertUniqueSlugs(
        _ pages: [TileKit.Site.Page],
    ) throws {
        var seen: Set<String> = []
        for page in pages where !seen.insert(page.slug).inserted {
            throw TileKit.Site.ConfigurationFileError.duplicateSlug(page.slug)
        }
    }
}
