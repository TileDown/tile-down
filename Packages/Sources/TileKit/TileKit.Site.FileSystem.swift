public extension TileKit.Site {
    protocol FileSystem {
        func listFilesRecursively(
            at path: String,
        ) throws -> [String]

        func readTextFile(
            at path: String,
        ) throws -> String

        func writeTextFile(
            _ contents: String,
            at path: String,
        ) throws
    }
}
