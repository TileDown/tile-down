import TileCore

extension TileKit.Site.Generator {
    struct FinalOutputPlan {
        var pages: [TileKit.Site.Page]
        var notFoundPage: TileKit.Site.Page
        var redirectPages: [TileKit.Site.Page]
        var template: String
        var request: TileKit.Site.ContentBuildRequest
        var sitePaths: TileKit.Site.GeneratedSitePaths
        var initialOutputPaths: [String]
        var notFoundAssetDirectory: String?
    }

    func writeFinalOutputs(
        _ plan: FinalOutputPlan,
    ) throws -> [String] {
        var outputPaths = plan.initialOutputPaths
        outputPaths += try writeRenderedPages(
            pages: plan.pages,
            template: plan.template,
            configuration: plan.request.configuration,
            sitePaths: plan.sitePaths,
        )
        try outputPaths.append(
            writeRenderedPage(
                page: plan.notFoundPage,
                pages: plan.pages,
                template: plan.template,
                configuration: plan.request.configuration,
                sitePaths: plan.sitePaths,
            ),
        )
        outputPaths += try contentRedirects(
            plan.redirectPages,
            outputRootPath: plan.request.outputRootPath,
            generated: Set(outputPaths),
        )
        outputPaths += try outboundShims(
            request: plan.request,
            generated: Set(outputPaths),
        )
        var generatedPaths = Set(outputPaths)
        try copyStaticPassthroughs(
            request: plan.request,
            generated: &generatedPaths,
            outputPaths: &outputPaths,
        )
        try copyAssets(
            request: plan.request,
            generated: generatedPaths,
            notFoundAssetDirectory: plan.notFoundAssetDirectory,
            outputPaths: &outputPaths,
        )
        return outputPaths
    }
}
