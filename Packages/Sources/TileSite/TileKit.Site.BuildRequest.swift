import TileCore

public extension TileKit.Site {
    struct BuildRequest: Equatable, Sendable {
        public var sourcePath: String
        public var templatePath: String
        public var outputPath: String
        public var configuration: Configuration

        public init(
            sourcePath: String,
            templatePath: String,
            outputPath: String,
            configuration: Configuration = .init(),
        ) {
            self.sourcePath = sourcePath
            self.templatePath = templatePath
            self.outputPath = outputPath
            self.configuration = configuration
        }
    }
}
