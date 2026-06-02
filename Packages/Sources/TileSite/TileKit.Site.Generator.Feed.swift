import TileCore

extension TileKit.Site.Generator {
    func writeFeed(
        pages: [TileKit.Site.Page],
        outputRootPath: String,
        configuration: TileKit.Site.Configuration,
        outputPaths: inout [String],
    ) throws -> String {
        guard let feed = configuration.feed else {
            return ""
        }

        let feedFilePath = try outputFilePath(feed.path)
        let outputPath = join(outputRootPath, feedFilePath)
        try fileSystem.writeTextFile(
            TileKit.Site.FeedRenderer().render(
                feed: feed,
                siteTitle: siteTitle(
                    configuration: configuration,
                    pages: pages,
                ),
                baseURL: configuration.baseURL,
                pages: pages,
                postsDirectory: configuration.postsDirectory,
            ),
            at: outputPath,
        )
        outputPaths.append(outputPath)
        return stylesheetURL(
            baseURL: configuration.baseURL,
            fileName: feedFilePath,
        )
    }

    private func outputFilePath(
        _ path: String,
    ) throws -> String {
        var result = path
        while result.hasPrefix("/") {
            result.removeFirst()
        }
        guard !result.isEmpty else {
            return "feed.xml"
        }

        let components = result.split(separator: "/", omittingEmptySubsequences: false)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw TileKit.Site.ConfigurationFileError.invalidPath(path)
        }
        return result
    }
}
