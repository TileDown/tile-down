import TileCore

public extension TileKit.Site {
    protocol FileSystem {
        /// Lists non-hidden regular files below `path`, returned as slash paths
        /// relative to that root.
        func listFilesRecursively(
            at path: String,
        ) throws -> [String]

        /// Lists regular files below `path`, optionally including hidden files
        /// and hidden directories when a caller explicitly needs deployment
        /// files such as `.nojekyll` or `.well-known/security.txt`.
        func listFilesRecursively(
            at path: String,
            includingHidden: Bool,
        ) throws -> [String]

        func readTextFile(
            at path: String,
        ) throws -> String

        func writeTextFile(
            _ contents: String,
            at path: String,
        ) throws

        /// Copies a file's bytes verbatim, creating any missing parent
        /// directories and overwriting an existing destination. This is the
        /// binary-safe path the text helpers cannot serve, used to copy assets
        /// such as images into the generated site.
        func copyFile(
            from sourcePath: String,
            to destinationPath: String,
        ) throws
    }
}

public extension TileKit.Site.FileSystem {
    func listFilesRecursively(
        at path: String,
        includingHidden _: Bool,
    ) throws -> [String] {
        try listFilesRecursively(at: path)
    }
}
