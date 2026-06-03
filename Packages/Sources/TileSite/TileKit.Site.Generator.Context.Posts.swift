import TileCore

extension TileKit.Site.Generator {
    /// The posts a page lists. A tag page (carrying tag filter markers) lists only
    /// the posts with every selected tag; every other page is given all posts and
    /// the template decides whether to show them (via `postList`).
    func pagePosts(
        for page: TileKit.Site.Page,
        among posts: some Sequence<TileKit.Site.Page>,
    ) -> [TileKit.Site.Page] {
        let selectedSlugs = TileKit.Site.Tags.filterSlugs(of: page)
        guard !selectedSlugs.isEmpty else {
            return Array(posts)
        }
        let requiredSlugs = Set(selectedSlugs)
        return posts.filter { post in
            requiredSlugs.isSubset(of: Set(TileKit.Site.Tags.tagSlugs(of: post)))
        }
    }
}
