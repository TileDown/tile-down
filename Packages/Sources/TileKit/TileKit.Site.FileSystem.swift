public extension TileKit.Site {
    protocol FileSystem {
        func readTextFile(
            at path: String,
        ) throws -> String

        func writeTextFile(
            _ contents: String,
            at path: String,
        ) throws
    }
}
