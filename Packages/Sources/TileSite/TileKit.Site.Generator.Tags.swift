import TileCore
import TileSource

extension TileKit.Site.Generator {
    /// Synthesizes one listing page per distinct tag found on `posts`, each at
    /// `tags/<slug>/`. A tag page has no source file: it carries `postList` so the
    /// layout renders the post-listing card UI, and a `tag` marker that the
    /// context uses to list only the posts carrying that tag. Returned in slug
    /// order for a deterministic build.
    func tagPages(
        among posts: some Sequence<TileKit.Site.Page>,
        outputRootPath: String,
    ) -> [TileKit.Site.Page] {
        TileKit.Site.Tags.allTags(among: posts).map { tag in
            let slug = "tags/" + tag.slug
            return .init(
                sourcePath: "",
                outputPath: join(outputRootPath, slug + "/index.html"),
                slug: slug,
                document: .init(
                    frontMatter: [
                        "title": tag.label,
                        "postList": "true",
                        "tag": tag.slug,
                    ],
                    body: "",
                ),
                html: "",
            )
        }
    }
}
