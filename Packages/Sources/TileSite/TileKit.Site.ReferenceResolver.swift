import TileCore

extension TileKit.Site {
    /// Resolves a Markdown reference (`page:`, `post:`, `tag:`, `social:`, `link:`)
    /// to a real URL and a display name, against registries the engine already owns.
    ///
    /// Built once per content build from the full page set, the configured posts
    /// source directory, the site's tags, the configured social links, and the
    /// configured outbound link shims. `resolve` returns nil for a key with no
    /// matching target so the caller can report it as a broken reference.
    struct ReferenceResolver {
        let pageURLBySlug: [String: String]
        let titleBySlug: [String: String]
        let postURLBySourceSlug: [String: String]
        let postTitleBySourceSlug: [String: String]
        let tagURLBySlug: [String: String]
        let tagLabelBySlug: [String: String]
        let socialURLByKey: [String: String]
        let socialLabelByKey: [String: String]
        let shimURLByKey: [String: String]
        let postsDirectory: String

        /// The resolved URL and display name for a reference, or nil when the key
        /// names no known target. Each scheme dispatches to its own resolver to keep
        /// this method simple.
        func resolve(
            scheme: String,
            key: String,
        ) -> (url: String, displayName: String)? {
            switch scheme {
            case "page": resolvePage(key)
            case "post": resolvePost(key)
            case "tag": resolveTag(key)
            case "social": resolveSocial(key)
            case "link": resolveLink(key)
            default: nil
            }
        }

        private func resolvePage(
            _ key: String,
        ) -> (url: String, displayName: String)? {
            guard let url = pageURLBySlug[key] else { return nil }
            return (url, titleBySlug[key] ?? key)
        }

        private func resolvePost(
            _ key: String,
        ) -> (url: String, displayName: String)? {
            let slug = postsDirectory + "/" + key
            guard let url = postURLBySourceSlug[slug] else { return nil }
            return (url, postTitleBySourceSlug[slug] ?? key)
        }

        private func resolveTag(
            _ key: String,
        ) -> (url: String, displayName: String)? {
            let slug = TileKit.Site.Tags.slug(for: key)
            guard let url = tagURLBySlug[slug] else { return nil }
            return (url, tagLabelBySlug[slug] ?? key)
        }

        private func resolveSocial(
            _ key: String,
        ) -> (url: String, displayName: String)? {
            let lowered = key.lowercased()
            guard let url = socialURLByKey[lowered] else { return nil }
            return (url, socialLabelByKey[lowered] ?? key)
        }

        private func resolveLink(
            _ key: String,
        ) -> (url: String, displayName: String)? {
            guard let url = shimURLByKey[key] else { return nil }
            return (url, key)
        }
    }
}
