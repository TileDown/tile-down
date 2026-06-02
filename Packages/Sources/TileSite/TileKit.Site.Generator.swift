import TileCore
import TileOutput
import TileSource
import TileTemplate
import TileTile

public extension TileKit.Site {
    struct Generator {
        // Visible to the same-module asset/image extension in
        // TileKit.Site.Generator.Assets.swift; not part of the public API.
        let fileSystem: any FileSystem
        private let markdownParser: any TileKit.Source.MarkdownParsing
        private let tileParser: any TileKit.Tile.Parsing
        private let htmlRenderer: any TileKit.Output.Rendering
        let templateRenderer: any TileKit.Template.Rendering
        private let contentDiscovery: any TileKit.Source.ContentDiscovering
        let imageChecker: any ImageChecking

        public init(
            fileSystem: any FileSystem,
            markdownParser: any TileKit.Source.MarkdownParsing,
            tileParser: any TileKit.Tile.Parsing,
            htmlRenderer: any TileKit.Output.Rendering,
            templateRenderer: any TileKit.Template.Rendering,
            contentDiscovery: any TileKit.Source.ContentDiscovering,
            imageChecker: any ImageChecking = PassthroughImageChecker(),
        ) {
            self.fileSystem = fileSystem
            self.markdownParser = markdownParser
            self.tileParser = tileParser
            self.htmlRenderer = htmlRenderer
            self.templateRenderer = templateRenderer
            self.contentDiscovery = contentDiscovery
            self.imageChecker = imageChecker
        }

        public func build(
            _ request: BuildRequest,
        ) throws -> BuildResult {
            let page = try loadPage(
                sourcePath: request.sourcePath,
                outputPath: request.outputPath,
                slug: "",
            )
            let template = try fileSystem.readTextFile(at: request.templatePath)
            let output = try render(
                page: page,
                pages: [page],
                template: template,
                configuration: request.configuration,
                sitePaths: .init(),
            )

            try fileSystem.writeTextFile(
                output,
                at: request.outputPath,
            )

            return .init(outputPath: request.outputPath)
        }

        public func buildContent(
            _ request: ContentBuildRequest,
        ) throws -> ContentBuildResult {
            let source = try sourcePages(request)
            let contentPages = source.contentPages
            let redirectPages = source.redirectPages
            let notFoundPage = source.notFoundPage
            let posts = TileKit.Site.PostCollection(
                among: contentPages,
                postsDirectory: request.configuration.postsDirectory,
            )
            let pages = try assembledPages(contentPages, posts: posts, request: request)
            try assertUniqueSlugs(pages)
            let template = try template(from: request.template)

            try runImageCheck(request: request)

            var outputPaths: [String] = []
            let stylesheetPath = try writeSharedStylesheet(
                pages: pages + [notFoundPage],
                outputRootPath: request.outputRootPath,
                configuration: request.configuration,
                outputPaths: &outputPaths,
            )
            let feedPath = try writeFeed(
                pages: pages,
                outputRootPath: request.outputRootPath,
                configuration: request.configuration,
                outputPaths: &outputPaths,
            )
            let sitePaths = TileKit.Site.GeneratedSitePaths(
                stylesheetPath: stylesheetPath,
                feedPath: feedPath,
            )

            outputPaths += try writeRenderedPages(
                pages: pages,
                template: template,
                configuration: request.configuration,
                sitePaths: sitePaths,
            )
            let notFoundOutputPath = try writeRenderedPage(
                page: notFoundPage,
                pages: pages,
                template: template,
                configuration: request.configuration,
                sitePaths: sitePaths,
            )
            outputPaths.append(notFoundOutputPath)
            outputPaths += try contentRedirects(
                redirectPages,
                outputRootPath: request.outputRootPath,
                generated: Set(outputPaths),
            )
            outputPaths += try outboundShims(
                request: request,
                generated: Set(outputPaths),
            )
            try copyAssets(
                request: request,
                generated: Set(outputPaths),
                notFoundAssetDirectory: source.notFoundAssetDirectory,
                outputPaths: &outputPaths,
            )

            return .init(outputPaths: outputPaths)
        }
    }
}

private extension TileKit.Site.Generator {
    static let notFoundSlug = "404"
    static let notFoundFileName = "404.html"

    func loadPages(
        _ request: TileKit.Site.ContentBuildRequest,
    ) throws -> [TileKit.Site.Page] {
        let relativePaths = try fileSystem.listFilesRecursively(
            at: request.contentRootPath,
        )
        let locations = contentDiscovery.discover(
            relativePaths: relativePaths,
        )
        let pages = try locations
            .map { location in
                try loadContentPage(
                    sourcePath: join(
                        request.contentRootPath,
                        location.sourceRelativePath,
                    ),
                    folderSlug: location.slug,
                    outputRootPath: request.outputRootPath,
                )
            }
            // Drafts are excluded from the whole build, no page, no listing, no
            // feed, since every downstream output derives from this array. A
            // preview build (--drafts) keeps them.
            .filter { page in
                request.includeDrafts || !isDraft(page)
            }
        try assertUniqueSlugs(pages)
        return pages
    }

    private func sourcePages(
        _ request: TileKit.Site.ContentBuildRequest,
    ) throws -> SourcePages {
        let loadedPages = try loadPages(request)
        let sourceNotFoundPage = loadedPages.first(where: isNotFoundPage)
        let notFoundPage = try notFoundPage(
            from: sourceNotFoundPage,
            outputRootPath: request.outputRootPath,
        )
        let notFoundAssetDirectory = sourceNotFoundPage.flatMap { page in
            sourceRelativeDirectory(
                sourcePath: page.sourcePath,
                contentRootPath: request.contentRootPath,
            )
        }
        let contentPages = applyingPostsLabel(
            to: loadedPages.filter { page in
                !isNotFoundPage(page) && !isRedirect(page)
            },
            configuration: request.configuration,
        )
        let redirectPages = loadedPages.filter(isRedirect)
        return SourcePages(
            contentPages: contentPages,
            redirectPages: redirectPages,
            notFoundPage: notFoundPage,
            notFoundAssetDirectory: notFoundAssetDirectory,
        )
    }

    /// Applies the configured `postsLabel` to the posts landing page (the page
    /// whose slug is the posts directory), overriding its `title` so navigation
    /// and its heading read the chosen label. An empty label leaves pages as is.
    func applyingPostsLabel(
        to pages: [TileKit.Site.Page],
        configuration: TileKit.Site.Configuration,
    ) -> [TileKit.Site.Page] {
        let label = configuration.postsLabel
        guard !label.isEmpty else {
            return pages
        }
        return pages.map { page in
            guard page.slug == configuration.postsDirectory
                || page.sourceSlug == configuration.postsDirectory
            else {
                return page
            }
            var page = page
            page.document.frontMatter["title"] = label
            return page
        }
    }

    func template(
        from source: TileKit.Site.TemplateSource,
    ) throws -> String {
        switch source {
        case let .file(path):
            try fileSystem.readTextFile(at: path)
        case let .layout(layout):
            layout.template
        }
    }

    private func notFoundPage(
        from sourcePage: TileKit.Site.Page?,
        outputRootPath: String,
    ) throws -> TileKit.Site.Page {
        var page = try sourcePage ?? defaultNotFoundPage(outputRootPath: outputRootPath)
        page.slug = Self.notFoundSlug
        page.outputPath = join(outputRootPath, Self.notFoundFileName)
        return page
    }

    private func defaultNotFoundPage(
        outputRootPath: String,
    ) throws -> TileKit.Site.Page {
        try makePage(
            sourcePath: "",
            outputPath: join(outputRootPath, Self.notFoundFileName),
            slug: Self.notFoundSlug,
            document: .init(
                frontMatter: [
                    "title": "Page not found",
                ],
                body: """
                # Page not found

                The page you requested could not be found.
                """,
            ),
        )
    }

    private func isNotFoundPage(
        _ page: TileKit.Site.Page,
    ) -> Bool {
        page.slug == Self.notFoundSlug
    }

    private func sourceRelativeDirectory(
        sourcePath: String,
        contentRootPath: String,
    ) -> String? {
        let prefix = contentRootPath.hasSuffix("/") ? contentRootPath : contentRootPath + "/"
        guard sourcePath.hasPrefix(prefix) else {
            return nil
        }
        let relativePath = String(sourcePath.dropFirst(prefix.count))
        guard let lastSeparator = relativePath.lastIndex(of: "/") else {
            return ""
        }
        return String(relativePath[..<lastSeparator])
    }

    private func writeFeed(
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

    /// Loads a single page at a fixed slug and output path, for the single-file
    /// `build`. Content builds go through `loadContentPage`, which can override the
    /// slug from front matter.
    private func loadPage(
        sourcePath: String,
        outputPath: String,
        slug: String,
    ) throws -> TileKit.Site.Page {
        let document = try markdownParser.parse(
            fileSystem.readTextFile(at: sourcePath),
        )
        return try makePage(
            sourcePath: sourcePath,
            outputPath: outputPath,
            sourceSlug: slug,
            slug: slug,
            document: document,
        )
    }

    /// Loads a content page, letting a non-empty `slug` front-matter value
    /// override the folder-derived slug and the output path it publishes under.
    private func loadContentPage(
        sourcePath: String,
        folderSlug: String,
        outputRootPath: String,
    ) throws -> TileKit.Site.Page {
        let document = try markdownParser.parse(
            fileSystem.readTextFile(at: sourcePath),
        )
        let slug = try effectiveSlug(
            folderSlug: folderSlug,
            frontMatter: document.frontMatter,
        )
        let resolvedOutputPath = outputPath(
            outputRootPath: outputRootPath,
            slug: slug,
        )
        guard !isRedirect(frontMatter: document.frontMatter) else {
            return .init(
                sourcePath: sourcePath,
                outputPath: resolvedOutputPath,
                sourceSlug: folderSlug,
                slug: slug,
                document: document,
                html: "",
            )
        }
        return try makePage(
            sourcePath: sourcePath,
            outputPath: resolvedOutputPath,
            sourceSlug: folderSlug,
            slug: slug,
            document: document,
        )
    }

    /// Parses tiles and renders a page from an already-parsed document: the shared
    /// tail of `loadPage` and `loadContentPage`.
    private func makePage(
        sourcePath: String,
        outputPath: String,
        sourceSlug: String,
        slug: String,
        document: TileKit.Source.Document,
    ) throws -> TileKit.Site.Page {
        let blocks = try tileParser.parseBlocks(document.body)
        let artifact = try htmlRenderer.render(
            .init(
                frontMatter: document.frontMatter,
                blocks: blocks,
                slug: slug,
            ),
        )
        return .init(
            sourcePath: sourcePath,
            outputPath: outputPath,
            sourceSlug: sourceSlug,
            slug: slug,
            document: document,
            html: artifact.contents,
            stylesheet: artifact.assets.stylesheet,
            javascript: artifact.assets.javascript,
        )
    }

    private func outputPath(
        outputRootPath: String,
        slug: String,
    ) -> String {
        let path = slug.isEmpty ? "index.html" : slug + "/index.html"
        return join(outputRootPath, path)
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
