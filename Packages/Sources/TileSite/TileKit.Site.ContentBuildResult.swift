import TileCore

public extension TileKit.Site {
    struct ContentBuildResult: Equatable, Sendable {
        public var outputPaths: [String]

        public init(
            outputPaths: [String],
        ) {
            self.outputPaths = outputPaths
        }
    }
}
