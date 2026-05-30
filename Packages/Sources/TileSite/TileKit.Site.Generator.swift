import TileCore
import TileOutput
import TileSource
import TileTemplate
import TileTile

public extension TileKit.Site {
    struct Generator {
        private let fileSystem: any FileSystem
        private let markdownParser: any TileKit.Source.MarkdownParsing
        private let tileParser: any TileKit.Tile.Parsing
        private let htmlRenderer: any TileKit.Output.Rendering
        private let templateRenderer: any TileKit.Template.Rendering
        private let contentDiscovery: any TileKit.Source.ContentDiscovering

        public init(
            fileSystem: any FileSystem,
            markdownParser: any TileKit.Source.MarkdownParsing,
            tileParser: any TileKit.Tile.Parsing,
            htmlRenderer: any TileKit.Output.Rendering,
            templateRenderer: any TileKit.Template.Rendering,
            contentDiscovery: any TileKit.Source.ContentDiscovering,
        ) {
            self.fileSystem = fileSystem
            self.markdownParser = markdownParser
            self.tileParser = tileParser
            self.htmlRenderer = htmlRenderer
            self.templateRenderer = templateRenderer
            self.contentDiscovery = contentDiscovery
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
                stylesheetPath: "",
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
            let relativePaths = try fileSystem.listFilesRecursively(
                at: request.contentRootPath,
            )
            let locations = contentDiscovery.discover(
                relativePaths: relativePaths,
            )
            let pages = try locations.map { location in
                try loadPage(
                    sourcePath: join(
                        request.contentRootPath,
                        location.sourceRelativePath,
                    ),
                    outputPath: outputPath(
                        outputRootPath: request.outputRootPath,
                        slug: location.slug,
                    ),
                    slug: location.slug,
                )
            }
            let template = try template(from: request.template)

            var outputPaths: [String] = []
            let stylesheetPath = try writeSharedStylesheet(
                pages: pages,
                outputRootPath: request.outputRootPath,
                configuration: request.configuration,
                outputPaths: &outputPaths,
            )

            for page in pages {
                let output = try render(
                    page: page,
                    pages: pages,
                    template: template,
                    configuration: request.configuration,
                    stylesheetPath: stylesheetPath,
                )
                try fileSystem.writeTextFile(
                    output,
                    at: page.outputPath,
                )
                outputPaths.append(page.outputPath)
            }

            return .init(outputPaths: outputPaths)
        }

        private static let sharedStylesheetFileName = "styles.css"

        private func template(
            from source: TemplateSource,
        ) throws -> String {
            switch source {
            case let .file(path):
                try fileSystem.readTextFile(at: path)
            case let .layout(layout):
                layout.template
            }
        }

        /// Merges every page's CSS into one site stylesheet, writes it to the output
        /// root, records it in `outputPaths`, and returns the URL to link it from
        /// each page. Returns "" and writes nothing when no page has any CSS, so a
        /// site without styled tiles emits no stray stylesheet.
        private func writeSharedStylesheet(
            pages: [Page],
            outputRootPath: String,
            configuration: Configuration,
            outputPaths: inout [String],
        ) throws -> String {
            let tiles = pages.reduce(TileKit.Output.Stylesheet()) { result, page in
                result.merging(page.stylesheet)
            }
            let css = Self.composeStylesheet(
                theme: configuration.theme,
                tiles: tiles,
            )
            guard !css.isEmpty else {
                return ""
            }

            let outputPath = join(outputRootPath, Self.sharedStylesheetFileName)
            try fileSystem.writeTextFile(
                css,
                at: outputPath,
            )
            outputPaths.append(outputPath)
            return stylesheetURL(
                baseURL: configuration.baseURL,
                fileName: Self.sharedStylesheetFileName,
            )
        }

        /// Composes the shared stylesheet from the theme and the merged tile CSS.
        /// With no theme this is exactly the tile stylesheet; with a theme it adds
        /// the theme properties (unlayered) and the theme's reset and base styles
        /// into the `reset` and `theme` cascade layers, beside the tiles.
        private static func composeStylesheet(
            theme: Theme?,
            tiles: TileKit.Output.Stylesheet,
        ) -> String {
            guard let theme else {
                return tiles.text()
            }

            var result = theme.tokens
            result += "\n@layer reset, theme, tile-override;"
            if !theme.reset.isEmpty {
                result += "\n@layer reset {\n\(theme.reset)\n}"
            }
            let themeLayer = ([theme.base] + tiles.themed)
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            if !themeLayer.isEmpty {
                result += "\n@layer theme {\n\(themeLayer)\n}"
            }
            if !tiles.overriding.isEmpty {
                result += "\n@layer tile-override {\n\(tiles.overriding.joined(separator: "\n"))\n}"
            }
            return result
        }

        private func stylesheetURL(
            baseURL: String,
            fileName: String,
        ) -> String {
            guard !baseURL.isEmpty else {
                return "/" + fileName
            }
            return baseURL.hasSuffix("/") ? baseURL + fileName : baseURL + "/" + fileName
        }

        private func loadPage(
            sourcePath: String,
            outputPath: String,
            slug: String,
        ) throws -> Page {
            let source = try fileSystem.readTextFile(at: sourcePath)
            let document = try markdownParser.parse(source)
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
                slug: slug,
                document: document,
                html: artifact.contents,
                stylesheet: artifact.assets.stylesheet,
                javascript: artifact.assets.javascript,
            )
        }

        private func render(
            page: Page,
            pages: [Page],
            template: String,
            configuration: Configuration,
            stylesheetPath: String,
        ) throws -> String {
            try templateRenderer.render(
                template: template,
                context: context(
                    page: page,
                    pages: pages,
                    configuration: configuration,
                    stylesheetPath: stylesheetPath,
                ),
            )
        }

        private func context(
            page: Page,
            pages: [Page],
            configuration: Configuration,
            stylesheetPath: String,
        ) -> TileKit.Template.Context {
            var result = stringValues(page.document.frontMatter)
            result["site"] = siteValue(
                configuration,
                stylesheetPath: stylesheetPath,
                sections: sections(pages),
                title: siteTitle(
                    configuration: configuration,
                    pages: pages,
                ),
            )
            result["page"] = pageValue(page)
            result["pages"] = .list(pages.map(pageContext))
            result["contents"] = .string(page.html)
            result["assets"] = assetsValue(page)
            return result
        }

        private func join(
            _ parent: String,
            _ child: String,
        ) -> String {
            guard !parent.isEmpty else {
                return child
            }

            if parent.hasSuffix("/") {
                return parent + child
            }

            return parent + "/" + child
        }

        private func outputPath(
            outputRootPath: String,
            slug: String,
        ) -> String {
            let path = slug.isEmpty ? "index.html" : slug + "/index.html"
            return join(outputRootPath, path)
        }

        private func url(
            for slug: String,
        ) -> String {
            slug.isEmpty ? "/" : "/" + slug + "/"
        }
    }
}

// MARK: - Template context

private extension TileKit.Site.Generator {
    func siteValue(
        _ configuration: TileKit.Site.Configuration,
        stylesheetPath: String,
        sections: [TileKit.Site.Page],
        title: String,
    ) -> TileKit.Template.Value {
        .object(
            [
                "title": .string(title),
                "baseURL": .string(configuration.baseURL),
                "stylesheetPath": .string(stylesheetPath),
                "sections": .list(sections.map(pageContext)),
            ],
        )
    }

    func siteTitle(
        configuration: TileKit.Site.Configuration,
        pages: [TileKit.Site.Page],
    ) -> String {
        if !configuration.title.isEmpty {
            return configuration.title
        }
        return pages.first { $0.slug.isEmpty }?
            .document
            .frontMatter["title"] ?? ""
    }

    /// The site's top-level sections for navigation: the depth-1 pages (each
    /// section's `index.md` landing page), ordered by a front-matter `weight`
    /// (pages without a weight sort last, then alphabetically by title or slug).
    /// The root page (empty slug, the home page) is not a section.
    func sections(
        _ pages: [TileKit.Site.Page],
    ) -> [TileKit.Site.Page] {
        pages
            .filter { !$0.slug.isEmpty && !$0.slug.contains("/") }
            .sorted { first, second in
                let firstWeight = weight(first)
                let secondWeight = weight(second)
                if firstWeight != secondWeight {
                    return firstWeight < secondWeight
                }
                let firstKey = sortKey(first)
                let secondKey = sortKey(second)
                if firstKey != secondKey {
                    return firstKey < secondKey
                }
                // Slugs are unique, so this makes the order fully deterministic.
                return first.slug < second.slug
            }
    }

    func weight(
        _ page: TileKit.Site.Page,
    ) -> Int {
        page.document.frontMatter["weight"].flatMap(Int.init) ?? Int.max
    }

    func sortKey(
        _ page: TileKit.Site.Page,
    ) -> String {
        page.document.frontMatter["title"] ?? page.slug
    }

    func pageValue(
        _ page: TileKit.Site.Page,
    ) -> TileKit.Template.Value {
        .object(pageContext(page))
    }

    func pageContext(
        _ page: TileKit.Site.Page,
    ) -> TileKit.Template.Context {
        var context = stringValues(page.document.frontMatter)
        context["slug"] = .string(page.slug)
        context["url"] = .string(url(for: page.slug))
        context["contents"] = .object(
            [
                "html": .string(page.html),
            ],
        )
        context["assets"] = assetsValue(page)
        return context
    }

    func assetsValue(
        _ page: TileKit.Site.Page,
    ) -> TileKit.Template.Value {
        .object(
            [
                "css": .string(page.stylesheet.text()),
                "javascript": .string(page.javascript),
            ],
        )
    }

    func stringValues(
        _ values: [String: String],
    ) -> TileKit.Template.Context {
        values.reduce(into: [:]) { result, item in
            result[item.key] = .string(item.value)
        }
    }
}
