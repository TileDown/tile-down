public extension TileKit.Site {
    struct Generator {
        private let fileSystem: any FileSystem
        private let markdownParser: any TileKit.Source.MarkdownParsing
        private let markdownRenderer: any TileKit.Markdown.Rendering
        private let templateRenderer: any TileKit.Template.Rendering

        public init(
            fileSystem: any FileSystem,
            markdownParser: any TileKit.Source.MarkdownParsing,
            markdownRenderer: any TileKit.Markdown.Rendering,
            templateRenderer: any TileKit.Template.Rendering,
        ) {
            self.fileSystem = fileSystem
            self.markdownParser = markdownParser
            self.markdownRenderer = markdownRenderer
            self.templateRenderer = templateRenderer
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
    }
}
