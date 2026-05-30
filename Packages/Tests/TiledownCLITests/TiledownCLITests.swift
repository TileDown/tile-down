import Foundation
import Testing

@Suite("tiledown CLI")
struct TiledownCLITests {
    @Test("build-site without a template writes a styled top-nav site")
    func buildSiteWithBuiltInLayoutAndTheme() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }

        let result = try runTiledown(
            arguments: ["build-site", fixture.content.path, fixture.output.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        try assertBuiltInSiteOutput(at: fixture.output)
    }

    private func makeContentFixture() throws -> ContentFixture {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent(
                "tiledown-cli-tests-\(UUID().uuidString)",
                isDirectory: true,
            )
        let content = root.appendingPathComponent("content", isDirectory: true)
        let blog = content.appendingPathComponent("blog", isDirectory: true)
        let output = root.appendingPathComponent("dist", isDirectory: true)

        try fileManager.createDirectory(
            at: blog,
            withIntermediateDirectories: true,
        )
        try writeHomePage(to: content)
        try writeBlogPage(to: blog)

        return .init(root: root, content: content, output: output)
    }

    private func writeHomePage(
        to content: URL,
    ) throws {
        try """
        ---
        title: Home
        ---
        # Home
        """.write(
            to: content.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )
    }

    private func writeBlogPage(
        to blog: URL,
    ) throws {
        try """
        ---
        title: Blog
        weight: 1
        ---
        # Blog
        """.write(
            to: blog.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )
    }

    private func assertBuiltInSiteOutput(
        at output: URL,
    ) throws {
        let home = try String(
            contentsOf: output.appendingPathComponent("index.html"),
            encoding: .utf8,
        )
        let css = try String(
            contentsOf: output.appendingPathComponent("styles.css"),
            encoding: .utf8,
        )
        #expect(home.contains(#"<a class="td-brand" href="/">Home</a>"#))
        #expect(home.contains(#"<link rel="stylesheet" href="/styles.css">"#))
        #expect(home.contains(#"<a class="td-nav-link" href="/blog/">Blog</a>"#))
        #expect(css.contains("--td-bg: #ffffff;"))
        #expect(css.contains("@layer reset, theme, tile-override;"))
        #expect(css.contains(".td-header {"))
    }

    private func runTiledown(
        arguments: [String],
    ) throws -> ProcessResult {
        let process = Process()
        process.executableURL = try tiledownExecutable()
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return .init(
            status: process.terminationStatus,
            stdout: String(
                data: stdout.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8,
            ) ?? "",
            stderr: String(
                data: stderr.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8,
            ) ?? "",
        )
    }

    private func tiledownExecutable() throws -> URL {
        let fileManager = FileManager.default
        var directories = ancestorDirectories(
            from: URL(fileURLWithPath: CommandLine.arguments[0])
                .resolvingSymlinksInPath()
                .deletingLastPathComponent(),
        )
        directories += ancestorDirectories(
            from: URL(fileURLWithPath: fileManager.currentDirectoryPath),
        )

        for directory in directories {
            let candidate = directory.appendingPathComponent("tiledown")
            if fileManager.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        let buildDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appendingPathComponent(".build", isDirectory: true)
        if let enumerator = fileManager.enumerator(
            at: buildDirectory,
            includingPropertiesForKeys: nil,
        ) {
            for case let candidate as URL in enumerator {
                guard candidate.lastPathComponent == "tiledown" else {
                    continue
                }
                if fileManager.isExecutableFile(atPath: candidate.path) {
                    return candidate
                }
            }
        }

        throw CLIError.missingExecutable
    }

    private func ancestorDirectories(
        from url: URL,
    ) -> [URL] {
        var result: [URL] = []
        var directory = url
        for _ in 0 ..< 12 {
            result.append(directory)
            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else {
                break
            }
            directory = parent
        }
        return result
    }
}

private struct ContentFixture: Equatable {
    var root: URL
    var content: URL
    var output: URL
}

private struct ProcessResult: Equatable {
    var status: Int32
    var stdout: String
    var stderr: String
}

private enum CLIError: Error {
    case missingExecutable
}
