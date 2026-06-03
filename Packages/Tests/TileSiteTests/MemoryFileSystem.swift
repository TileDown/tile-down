import TileCore
import TileSite

/// In-memory file system for site generator tests.
final class MemoryFileSystem: TileKit.Site.FileSystem {
    enum Error: Swift.Error {
        case missingFile(String)
    }

    var files: [String: String]
    private(set) var binaryFiles: [String: [UInt8]] = [:]
    private(set) var listedPaths: [String] = []

    init(
        files: [String: String],
    ) {
        self.files = files
    }

    func listFilesRecursively(
        at path: String,
    ) throws -> [String] {
        try listFilesRecursively(at: path, includingHidden: false)
    }

    func listFilesRecursively(
        at path: String,
        includingHidden: Bool,
    ) throws -> [String] {
        listedPaths.append(path)
        let prefix = path.hasSuffix("/") ? path : path + "/"
        return files.keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .filter { !$0.isEmpty }
            .filter { includingHidden || !hasHiddenComponent($0) }
            .sorted()
    }

    func readTextFile(
        at path: String,
    ) throws -> String {
        guard let file = files[path] else {
            throw Error.missingFile(path)
        }
        return file
    }

    func writeTextFile(
        _ contents: String,
        at path: String,
    ) throws {
        files[path] = contents
    }

    func writeBytes(
        _ bytes: [UInt8],
        at path: String,
    ) throws {
        binaryFiles[path] = bytes
    }

    func copyFile(
        from sourcePath: String,
        to destinationPath: String,
    ) throws {
        guard let file = files[sourcePath] else {
            throw Error.missingFile(sourcePath)
        }
        files[destinationPath] = file
    }

    private func hasHiddenComponent(
        _ path: String,
    ) -> Bool {
        path.split(separator: "/").contains { component in
            component.hasPrefix(".")
        }
    }
}
