import Foundation
import TileCore
import TileSite

public extension TileKit.Site {
    struct LocalFileSystem: FileSystem {
        private let fileManager: FileManager

        public init(
            fileManager: FileManager,
        ) {
            self.fileManager = fileManager
        }

        public func listFilesRecursively(
            at path: String,
        ) throws -> [String] {
            try listFilesRecursively(at: path, includingHidden: false)
        }

        public func listFilesRecursively(
            at path: String,
            includingHidden: Bool,
        ) throws -> [String] {
            let rootURL = URL(fileURLWithPath: path)
                .standardizedFileURL
            var options: FileManager.DirectoryEnumerationOptions = []
            if !includingHidden {
                options.insert(.skipsHiddenFiles)
            }
            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: options,
            ) else {
                return []
            }

            var files: [String] = []
            for case let fileURL as URL in enumerator {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true else {
                    continue
                }
                files.append(relativePath(for: fileURL, rootURL: rootURL))
            }

            return files.sorted()
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

        public func copyFile(
            from sourcePath: String,
            to destinationPath: String,
        ) throws {
            let destinationURL = URL(fileURLWithPath: destinationPath)
            try fileManager.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            if fileManager.fileExists(atPath: destinationPath) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(
                at: URL(fileURLWithPath: sourcePath),
                to: destinationURL,
            )
        }

        private func relativePath(
            for fileURL: URL,
            rootURL: URL,
        ) -> String {
            let rootPath = rootURL.pathComponents
            let filePath = fileURL.standardizedFileURL.pathComponents
            let relativeComponents = filePath.dropFirst(rootPath.count)
            return relativeComponents.joined(separator: "/")
        }
    }
}
