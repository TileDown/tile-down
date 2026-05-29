public extension TileKit.Site {
    struct Generator {
        private let fileSystem: any FileSystem
        private let markdownParser: any TileKit.Source.MarkdownParsing
        private let markdownRenderer: any TileKit.Markdown.Rendering
        private let templateRenderer: any TileKit.Template.Rendering
        private let contentDiscovery: TileKit.Source.IndexContentDiscovery

        public init(
            fileSystem: any FileSystem,
            markdownParser: any TileKit.Source.MarkdownParsing,
            markdownRenderer: any TileKit.Markdown.Rendering,
            templateRenderer: any TileKit.Template.Rendering,
            contentDiscovery: TileKit.Source.IndexContentDiscovery = .init(),
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
            let source = try fileSystem.readTextFile(at: request.sourcePath)
            let document = try markdownParser.parse(source)
            let bodyHTML = markdownRenderer.renderHTML(document.body)

            var context = document.frontMatter
            for (key, value) in document.frontMatter {
                context["page.\(key)"] = value
            }
            context["contents"] = bodyHTML
            context["page.contents.html"] = bodyHTML

            let template = try fileSystem.readTextFile(at: request.templatePath)
            let output = try templateRenderer.render(
                template: template,
                context: context,
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

            var outputPaths: [String] = []
            for location in locations {
                let result = try build(
                    .init(
                        sourcePath: join(
                            request.contentRootPath,
                            location.sourceRelativePath,
                        ),
                        templatePath: request.templatePath,
                        outputPath: outputPath(
                            outputRootPath: request.outputRootPath,
                            slug: location.slug,
                        ),
                    ),
                )
                outputPaths.append(result.outputPath)
            }

            return .init(outputPaths: outputPaths)
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
    }
}
