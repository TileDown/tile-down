public extension TileKit.Site {
    struct BuildResult: Equatable, Sendable {
        public var outputPath: String

        public init(
            outputPath: String,
        ) {
            self.outputPath = outputPath
        }
    }
}
