import TileCore

extension TileKit.Site.Generator {
    struct RenderedPagePlan {
        var page: TileKit.Site.Page
        var pages: [TileKit.Site.Page]
        var template: String
        var configuration: TileKit.Site.Configuration
        var sitePaths: TileKit.Site.GeneratedSitePaths
        var outputRootPath: String
    }

    func writeRenderedPages(
        pages: [TileKit.Site.Page],
        template: String,
        configuration: TileKit.Site.Configuration,
        sitePaths: TileKit.Site.GeneratedSitePaths,
        outputRootPath: String,
    ) throws -> [String] {
        try pages.flatMap { page in
            try writeRenderedPage(
                .init(
                    page: page,
                    pages: pages,
                    template: template,
                    configuration: configuration,
                    sitePaths: sitePaths,
                    outputRootPath: outputRootPath,
                ),
            )
        }
    }

    func writeRenderedPage(
        _ plan: RenderedPagePlan,
    ) throws -> [String] {
        // Render the PDF first so the HTML's "Download PDF" link is offered only
        // when a PDF was actually written (a renderer failure leaves no link).
        let pdfOutputPath = try writeArticlePDF(
            page: plan.page,
            configuration: plan.configuration,
            outputRootPath: plan.outputRootPath,
        )
        let output = try render(
            page: plan.page,
            pages: plan.pages,
            template: plan.template,
            configuration: plan.configuration,
            sitePaths: plan.sitePaths,
            pdfWritten: pdfOutputPath != nil,
        )
        let finalOutput = plan.page.slug == Self.notFoundSlug
            ? injectNotFoundRedirectScript(
                into: output,
                redirects: plan.configuration.notFoundRedirects,
            )
            : output
        try fileSystem.writeTextFile(finalOutput, at: plan.page.outputPath)
        return [pdfOutputPath, plan.page.outputPath].compactMap(\.self)
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
