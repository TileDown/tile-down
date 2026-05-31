import TileCore
import TileSource

extension TileKit.Site.Generator {
    /// Synthesizes listing pages for static tag filters.
    /// Single-tag pages keep the existing `tags/<slug>/` URL. Two-tag AND
    /// filters are generated for every pair so readers can combine any two tags,
    /// including pairs with no matching posts. Larger filters are generated up
    /// to the configured depth when the selected tags co-occur on at least one
    /// post.
    /// A tag page has no source file: it carries `postList` so the layout renders
    /// the post-listing card UI, and filter markers that the context uses to list
    /// only posts carrying every selected tag. Returned in slug order for a
    /// deterministic build.
    func tagPages(
        among posts: some Sequence<TileKit.Site.Page>,
        outputRootPath: String,
    ) -> [TileKit.Site.Page] {
        tagSelections(among: posts).map { selection in
            let filterSlugs = selection.map(\.slug)
            let slug = TileKit.Site.Tags.pageSlug(forFilterSlugs: filterSlugs)
            var frontMatter = [
                "title": tagTitle(selection),
                "postList": "true",
                "tagFilters": filterSlugs.joined(separator: ","),
            ]
            if selection.count == 1 {
                frontMatter["tag"] = selection[0].slug
            }
            return .init(
                sourcePath: "",
                outputPath: join(outputRootPath, slug + "/index.html"),
                slug: slug,
                document: .init(
                    frontMatter: frontMatter,
                    body: "",
                ),
                html: "",
            )
        }
    }

    private func tagSelections(
        among posts: some Sequence<TileKit.Site.Page>,
    ) -> [[TileKit.Site.TagSummary]] {
        let posts = Array(posts)
        let tags = TileKit.Site.Tags.allTags(among: posts)
        let summariesBySlug = Dictionary(uniqueKeysWithValues: tags.map { ($0.slug, $0) })
        let slugs = tags.map(\.slug)
        var selections = Set<[String]>()

        for slug in slugs {
            selections.insert([slug])
        }

        for firstIndex in slugs.indices {
            for secondIndex in slugs.indices.dropFirst(firstIndex + 1) {
                selections.insert([slugs[firstIndex], slugs[secondIndex]])
            }
        }

        for post in posts {
            addCooccurringSelections(
                TileKit.Site.Tags.normalizedSlugs(TileKit.Site.Tags.tagSlugs(of: post)),
                maximumDepth: TileKit.Site.Tags.maximumGeneratedFilterDepth,
                to: &selections,
            )
        }

        return selections.compactMap { selection in
            let summaries = selection.compactMap { summariesBySlug[$0] }
            return summaries.count == selection.count ? summaries : nil
        }
        .sorted { first, second in
            let firstPath = first.map(\.slug).joined(separator: "/")
            let secondPath = second.map(\.slug).joined(separator: "/")
            return firstPath < secondPath
        }
    }

    private func addCooccurringSelections(
        _ slugs: [String],
        maximumDepth: Int,
        to selections: inout Set<[String]>,
    ) {
        guard slugs.count > 2, maximumDepth > 2 else {
            return
        }
        var selected: [String] = []

        func walk(index: Int) {
            guard index < slugs.count else {
                if selected.count > 2, selected.count <= maximumDepth {
                    selections.insert(selected)
                }
                return
            }

            walk(index: index + 1)

            selected.append(slugs[index])
            if selected.count <= maximumDepth {
                walk(index: index + 1)
            }
            selected.removeLast()
        }

        walk(index: 0)
    }

    private func tagTitle(
        _ selection: [TileKit.Site.TagSummary],
    ) -> String {
        selection.map(\.label).joined(separator: " AND ")
    }
}
