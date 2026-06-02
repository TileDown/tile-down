import TileCore

extension TileKit.Site.Generator {
    func writeRenderedPages(
        pages: [TileKit.Site.Page],
        template: String,
        configuration: TileKit.Site.Configuration,
        sitePaths: TileKit.Site.GeneratedSitePaths,
    ) throws -> [String] {
        try pages.map { page in
            try writeRenderedPage(
                page: page,
                pages: pages,
                template: template,
                configuration: configuration,
                sitePaths: sitePaths,
            )
        }
    }

    func writeRenderedPage(
        page: TileKit.Site.Page,
        pages: [TileKit.Site.Page],
        template: String,
        configuration: TileKit.Site.Configuration,
        sitePaths: TileKit.Site.GeneratedSitePaths,
    ) throws -> String {
        let output = try render(
            page: page,
            pages: pages,
            template: template,
            configuration: configuration,
            sitePaths: sitePaths,
        )
        let finalOutput = page.slug == Self.notFoundSlug
            ? injectNotFoundRedirectScript(
                into: output,
                redirects: configuration.notFoundRedirects,
            )
            : output
        try fileSystem.writeTextFile(finalOutput, at: page.outputPath)
        return page.outputPath
    }

    func render(
        page: TileKit.Site.Page,
        pages: [TileKit.Site.Page],
        template: String,
        configuration: TileKit.Site.Configuration,
        sitePaths: TileKit.Site.GeneratedSitePaths,
    ) throws -> String {
        try templateRenderer.render(
            template: template,
            context: context(
                page: page,
                pages: pages,
                configuration: configuration,
                sitePaths: sitePaths,
            ),
        )
    }
}
