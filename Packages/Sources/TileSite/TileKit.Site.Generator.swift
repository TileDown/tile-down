import TileCore
import TileMarkdown
import TileSource
import TileTemplate

public extension TileKit.Site {
    struct Generator {
        private let fileSystem: any FileSystem
        private let markdownParser: any TileKit.Source.MarkdownParsing
        private let markdownRenderer: any TileKit.Markdown.Rendering
        private let templateRenderer: any TileKit.Template.Rendering
        private let contentDiscovery: any TileKit.Source.ContentDiscovering

        public init(
            fileSystem: any FileSystem,
            markdownParser: any TileKit.Source.MarkdownParsing,
            markdownRenderer: any TileKit.Markdown.Rendering,
            templateRenderer: any TileKit.Template.Rendering,
            contentDiscovery: any TileKit.Source.ContentDiscovering,
        ) {
            self.fileSystem = fileSystem
            self.markdownParser = markdownParser
            self.markdownRenderer = markdownRenderer
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
            let template = try fileSystem.readTextFile(at: request.templatePath)

            var outputPaths: [String] = []
            for page in pages {
                let output = try render(
                    page: page,
                    pages: pages,
                    template: template,
                )
                try fileSystem.writeTextFile(
                    output,
                    at: page.outputPath,
                )
                outputPaths.append(page.outputPath)
            }

            return .init(outputPaths: outputPaths)
        }

        private func loadPage(
            sourcePath: String,
            outputPath: String,
            slug: String,
        ) throws -> Page {
            let source = try fileSystem.readTextFile(at: sourcePath)
            let document = try markdownParser.parse(source)
            let html = markdownRenderer.renderHTML(document.body)
            return .init(
                sourcePath: sourcePath,
                outputPath: outputPath,
                slug: slug,
                document: document,
                html: html,
            )
        }

        private func render(
            page: Page,
            pages: [Page],
            template: String,
        ) throws -> String {
            try templateRenderer.render(
                template: template,
                context: context(
                    page: page,
                    pages: pages,
                ),
            )
        }

        private func context(
            page: Page,
            pages: [Page],
        ) -> TileKit.Template.Context {
            var result = stringValues(page.document.frontMatter)
            result["page"] = pageValue(page)
            result["pages"] = .list(pages.map(pageContext))
            result["contents"] = .string(page.html)
            return result
        }

        private func pageValue(
            _ page: Page,
        ) -> TileKit.Template.Value {
            .object(pageContext(page))
        }

        private func pageContext(
            _ page: Page,
        ) -> TileKit.Template.Context {
            var context = stringValues(page.document.frontMatter)
            context["slug"] = .string(page.slug)
            context["url"] = .string(url(for: page.slug))
            context["contents"] = .object(
                [
                    "html": .string(page.html),
                ],
            )
            return context
        }

        private func stringValues(
            _ values: [String: String],
        ) -> TileKit.Template.Context {
            values.reduce(into: [:]) { result, item in
                result[item.key] = .string(item.value)
            }
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
