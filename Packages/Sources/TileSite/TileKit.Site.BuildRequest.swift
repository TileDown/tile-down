import TileCore

public extension TileKit.Site {
    struct BuildRequest: Equatable, Sendable {
        public var sourcePath: String
        public var templatePath: String
        public var outputPath: String

        public init(
            sourcePath: String,
            templatePath: String,
            outputPath: String,
        ) {
            self.sourcePath = sourcePath
            self.templatePath = templatePath
            self.outputPath = outputPath
        }
    }
}
