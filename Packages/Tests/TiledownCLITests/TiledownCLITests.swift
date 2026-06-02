import Foundation
import Testing

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("tiledown CLI")
struct TiledownCLITests {}

extension TiledownCLITests {
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

    @Test("a content generator runs against a relative content directory")
    func buildSiteRunsContentGenerator() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeContentGenerator(to: fixture.content)

        // Run with a relative content directory, from the fixture root, so the
        // generator subprocess must resolve its working directory. Without that
        // resolution the generator fails and the build exits non-zero.
        let result = try runTiledown(
            arguments: ["build-site", "content", "dist"],
            currentDirectory: fixture.root,
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        let generated = fixture.output
            .appendingPathComponent("extra/index.html")
        #expect(
            FileManager.default.fileExists(atPath: generated.path),
            "generator did not produce \(generated.path)",
        )
    }

    @Test("build-site reads tiledown.yml for layout theme footer links and RSS")
    func buildSiteWithConfigurationFile() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeConfiguration(to: fixture.content)

        let result = try runTiledown(
            arguments: ["build-site", fixture.content.path, fixture.output.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        let home = try String(
            contentsOf: fixture.output.appendingPathComponent("index.html"),
            encoding: .utf8,
        )
        let css = try String(
            contentsOf: fixture.output.appendingPathComponent("styles.css"),
            encoding: .utf8,
        )
        let feed = try String(
            contentsOf: fixture.output.appendingPathComponent("feed.xml"),
            encoding: .utf8,
        )

        #expect(home.contains(#"<body class="td-layout-sidebar">"#))
        #expect(home.contains(#"<a class="td-brand" href="https://example.com/">Configured Demo</a>"#))
        #expect(home.contains(#"<a href="https://github.com/TileDown/tile-down">GitHub</a>"#))
        #expect(home.contains(#"<a href="https://example.com/feed.xml">RSS</a>"#))
        #expect(css.contains("--td-bg: #f5f5f7;"))
        #expect(feed.contains("<title>Configured Feed</title>"))
    }

    @Test("serve builds a site and serves it over localhost")
    func serveBuildsAndServesSite() async throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }

        let port = Int.random(in: 20000 ... 50000)
        let process = try runTiledownProcess(
            arguments: [
                "serve",
                "--port",
                "\(port)",
                "--output",
                fixture.output.path,
                fixture.content.path,
            ],
        )
        defer {
            if process.isRunning {
                process.terminate()
            }
            process.waitUntilExit()
        }

        let result = try await fetchWithRetry(
            #require(URL(string: "http://127.0.0.1:\(port)/")),
            process: process,
        )

        #expect(result.status == 200)
        #expect(result.body.contains("<h1>Home</h1>"))
        #expect(
            FileManager.default.fileExists(
                atPath: fixture.output.appendingPathComponent("index.html").path,
            ),
        )
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

    private func writeContentGenerator(
        to content: URL,
    ) throws {
        try """
        title: Generator Demo
        generate.extra: bash gen.sh
        """.write(
            to: content.appendingPathComponent("tiledown.yml"),
            atomically: true,
            encoding: .utf8,
        )
        // A generator that writes a new page into the content tree.
        try """
        #!/bin/bash
        mkdir -p extra
        printf -- '---\\ntitle: Extra\\n---\\n# Extra\\n' > extra/index.md
        """.write(
            to: content.appendingPathComponent("gen.sh"),
            atomically: true,
            encoding: .utf8,
        )
    }

    private func writeConfiguration(
        to content: URL,
    ) throws {
        try """
        title: Configured Demo
        baseURL: https://example.com
        layout: left-sidebar
        theme: system
        rss: true
        rssTitle: Configured Feed
        rssDescription: Posts from the configured demo.
        social.github: https://github.com/TileDown/tile-down
        """.write(
            to: content.appendingPathComponent("tiledown.yml"),
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
        currentDirectory: URL? = nil,
    ) throws -> ProcessResult {
        let process = try runTiledownProcess(
            arguments: arguments,
            currentDirectory: currentDirectory,
        )
        let stdout = try #require(process.standardOutput as? Pipe)
        let stderr = try #require(process.standardError as? Pipe)
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

    private func runTiledownProcess(
        arguments: [String],
        currentDirectory: URL? = nil,
    ) throws -> Process {
        let process = Process()
        process.executableURL = try tiledownExecutable()
        process.arguments = arguments
        if let currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }

        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        return process
    }

    private func fetchWithRetry(
        _ url: URL,
        process: Process,
    ) async throws -> HTTPFetchResult {
        var lastError: Error?
        for _ in 0 ..< 50 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let httpResponse = try #require(response as? HTTPURLResponse)
                return .init(
                    status: httpResponse.statusCode,
                    body: String(data: data, encoding: .utf8) ?? "",
                )
            } catch {
                lastError = error
                if !process.isRunning {
                    let stderr = (process.standardError as? Pipe)?
                        .fileHandleForReading
                        .readDataToEndOfFile()
                    let message = stderr
                        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    Issue.record("serve exited early: \(message)")
                    break
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        throw try #require(lastError)
    }

    private struct HTTPFetchResult: Equatable {
        var status: Int
        var body: String
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
