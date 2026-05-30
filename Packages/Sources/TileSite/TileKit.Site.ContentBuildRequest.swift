import TileCore

public extension TileKit.Site {
    struct ContentBuildRequest: Equatable, Sendable {
        public var contentRootPath: String
        public var template: TemplateSource
        public var outputRootPath: String
        public var configuration: Configuration

        public init(
            contentRootPath: String,
            template: TemplateSource,
            outputRootPath: String,
            configuration: Configuration = .init(),
        ) {
            self.contentRootPath = contentRootPath
            self.template = template
            self.outputRootPath = outputRootPath
            self.configuration = configuration
        }
    }
}
