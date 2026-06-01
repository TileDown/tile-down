import TileCore

extension TileKit.Site.Generator {
    /// Writes the site map for published, crawler-facing pages. Draft and
    /// redirect content stays out of the sitemap even when it exists in source.
    func writeSitemap(
        pages: [TileKit.Site.Page],
        request: TileKit.Site.ContentBuildRequest,
        outputPaths: inout [String],
    ) throws {
        let sitemapPages = pages.filter { page in
            !sitemapExcluded(page)
        }
        let outputPath = join(request.outputRootPath, "sitemap.xml")
        try fileSystem.writeTextFile(
            TileKit.Site.SitemapRenderer().render(
                baseURL: request.configuration.baseURL,
                pages: sitemapPages,
            ),
            at: outputPath,
        )
        outputPaths.append(outputPath)
    }

    private func sitemapExcluded(
        _ page: TileKit.Site.Page,
    ) -> Bool {
        isDraft(page) || page.document.frontMatter["type"]?.lowercased() == "redirect"
    }
}
