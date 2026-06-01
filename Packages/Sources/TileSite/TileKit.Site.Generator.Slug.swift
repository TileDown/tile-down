import TileCore

extension TileKit.Site.Generator {
    /// The slug a content page publishes under. A non-empty `slug` front-matter
    /// value overrides the folder-derived slug; surrounding slashes are trimmed so
    /// `slug: /custom/` and `slug: custom` resolve to the same path. Interior
    /// empty segments, `.`, `..`, URL syntax delimiters, and control characters
    /// are rejected because this value becomes both an output path and a browser
    /// URL. An unset, empty, or slash-only value keeps the folder slug.
    func effectiveSlug(
        folderSlug: String,
        frontMatter: [String: String],
    ) throws -> String {
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
        guard !slug.isEmpty else {
            return folderSlug
        }
        let result = String(slug)
        let components = result.split(separator: "/", omittingEmptySubsequences: false)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
              !containsURLSyntaxCharacters(result)
        else {
            throw TileKit.Site.ConfigurationFileError.invalidPath(override)
        }
        return result
    }

    private func containsURLSyntaxCharacters(
        _ slug: String,
    ) -> Bool {
        slug.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x00 ... 0x1F, 0x7F:
                true
            case 0x23, 0x25, 0x3F, 0x5C:
                true
            default:
                false
            }
        }
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
