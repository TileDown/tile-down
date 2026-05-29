public extension TileKit.Site {
    struct ContentBuildRequest: Equatable, Sendable {
        public var contentRootPath: String
        public var templatePath: String
        public var outputRootPath: String

        public init(
            contentRootPath: String,
            templatePath: String,
            outputRootPath: String,
        ) {
            self.contentRootPath = contentRootPath
            self.templatePath = templatePath
            self.outputRootPath = outputRootPath
        }
    }
}
