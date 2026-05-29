import Foundation

public extension TileKit.Site {
    struct LocalFileSystem: FileSystem {
        private let fileManager: FileManager

        public init(
            fileManager: FileManager,
        ) {
            self.fileManager = fileManager
        }

        public func readTextFile(
            at path: String,
        ) throws -> String {
            try String(
                contentsOf: URL(fileURLWithPath: path),
                encoding: .utf8,
            )
        }

        public func writeTextFile(
            _ contents: String,
            at path: String,
        ) throws {
            let outputURL = URL(fileURLWithPath: path)
            try fileManager.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            try contents.write(
                to: outputURL,
                atomically: true,
                encoding: .utf8,
            )
        }
    }
}
