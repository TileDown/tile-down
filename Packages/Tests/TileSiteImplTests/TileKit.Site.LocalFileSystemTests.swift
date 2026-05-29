import Foundation
import Testing
import TileCore
import TileSite
@testable import TileSiteImpl

@Suite("Local file system")
struct LocalFileSystemTests {
    @Test("writes reads and lists text files")
    func writesReadsAndListsTextFiles() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tiledown-\(UUID().uuidString)")
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let fileSystem = TileKit.Site.LocalFileSystem(
            fileManager: .default,
        )
        let filePath = rootURL
            .appendingPathComponent("content/index.md")
            .path

        try fileSystem.writeTextFile(
            "# Home",
            at: filePath,
        )

        #expect(try fileSystem.readTextFile(at: filePath) == "# Home")
        #expect(try fileSystem.listFilesRecursively(at: rootURL.path) == ["content/index.md"])
    }
}
