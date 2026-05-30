import Foundation
import TileCore

public extension TileKit.Site {
    /// A distinct tag across the site: its display label (the first spelling
    /// seen), its URL-safe slug, and how many posts carry it.
    struct TagSummary: Equatable, Sendable {
        public var label: String
        public var slug: String
        public var count: Int
    }

    /// The single source of truth for how a page declares tags and how a tag maps
    /// to its page URL, shared by the per-post `tags`, the site-wide `site.tags`,
    /// and the synthesized per-tag listing pages so they all agree.
    enum Tags {
        /// The tags declared on a page, parsed from a comma-separated `tags`
        /// front-matter value (e.g. `tags: swift, ios`). Each tag is trimmed;
        /// empty tokens are dropped; source order is preserved; tags that
        /// normalize to the same slug are de-duplicated, keeping the first.
        static func tags(
            of page: Page,
        ) -> [String] {
            guard let raw = page.document.frontMatter["tags"] else {
                return []
            }
            var seenSlugs: Set<String> = []
            var result: [String] = []
            for token in raw.split(separator: ",") {
                let tag = token.trimmingCharacters(in: .whitespaces)
                let slug = slug(for: tag)
                guard !slug.isEmpty, seenSlugs.insert(slug).inserted else {
                    continue
                }
                result.append(tag)
            }
            return result
        }

        /// The URL-safe slug for a tag: lowercased, with each run of
        /// non-alphanumeric characters collapsed to a single hyphen and leading
        /// and trailing hyphens removed. `Swift on iOS` becomes `swift-on-ios`.
        /// A tag with no alphanumeric characters has an empty slug and is dropped.
        static func slug(
            for tag: String,
        ) -> String {
            var pieces: [String] = []
            var current = ""
            for character in tag.lowercased() {
                if character.isLetter || character.isNumber {
                    current.append(character)
                } else if !current.isEmpty {
                    pieces.append(current)
                    current = ""
                }
            }
            if !current.isEmpty {
                pieces.append(current)
            }
            return pieces.joined(separator: "-")
        }

        /// Every distinct tag across `posts`, with its slug and post count,
        /// ordered by slug for a deterministic build. The display label is the
        /// first spelling seen for that slug. The basis for both `site.tags` and
        /// the synthesized per-tag listing pages.
        static func allTags(
            among posts: [Page],
        ) -> [TagSummary] {
            var labels: [String: String] = [:]
            var counts: [String: Int] = [:]
            for post in posts {
                for tag in tags(of: post) {
                    let slug = slug(for: tag)
                    if labels[slug] == nil {
                        labels[slug] = tag
                    }
                    counts[slug, default: 0] += 1
                }
            }
            return labels.keys.sorted().compactMap { slug in
                guard let label = labels[slug], let count = counts[slug] else {
                    return nil
                }
                return TagSummary(label: label, slug: slug, count: count)
            }
        }
    }
}
