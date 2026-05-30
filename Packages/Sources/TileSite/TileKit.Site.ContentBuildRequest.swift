import TileCore

public extension TileKit.Site {
    struct ContentBuildRequest: Equatable, Sendable {
        public var contentRootPath: String
        public var templatePath: String
        public var outputRootPath: String
        public var configuration: Configuration

        public init(
            contentRootPath: String,
            templatePath: String,
            outputRootPath: String,
            configuration: Configuration = .init(),
        ) {
            self.contentRootPath = contentRootPath
            self.templatePath = templatePath
            self.outputRootPath = outputRootPath
            self.configuration = configuration
        }
    }
}
