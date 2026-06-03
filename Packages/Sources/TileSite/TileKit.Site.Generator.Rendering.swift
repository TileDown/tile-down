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
        // Render the PDF first so the HTML's "Download PDF" link is offered only
        // when a PDF was actually written (a renderer failure leaves no link).
        let pdfWritten = try writeArticlePDF(page: page, configuration: configuration)
        let output = try render(
            page: page,
            pages: pages,
            template: template,
            configuration: configuration,
            sitePaths: sitePaths,
            pdfWritten: pdfWritten,
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
        pdfWritten: Bool = false,
    ) throws -> String {
        try templateRenderer.render(
            template: template,
            context: context(
                page: page,
                pages: pages,
                configuration: configuration,
                sitePaths: sitePaths,
                pdfWritten: pdfWritten,
            ),
        )
    }
}
