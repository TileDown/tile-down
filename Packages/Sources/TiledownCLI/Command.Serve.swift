import Foundation
import TileKit

extension Command {
    func serve() throws {
        let options = try parseServeOptions()
        let outputPath = options.outputRootPath ?? defaultServeOutputPath(
            contentRootPath: options.contentRootPath,
        )
        try buildContentSite(
            contentRootPath: options.contentRootPath,
            outputRootPath: outputPath,
            includeDrafts: options.includeDrafts,
        )

        let responder = TileKit.Serve.StaticFileResponder(
            rootPath: outputPath,
            fileManager: .default,
        )
        let running = try TileKit.Serve.PosixHTTPServer().start(
            configuration: .init(
                rootPath: outputPath,
                host: "127.0.0.1",
                port: options.port,
            ),
            responder: responder,
        )
        print("Serving \(running.url.absoluteString) from \(outputPath)")
        running.wait()
    }

    private func parseServeOptions() throws -> ServeOptions {
        var includeDrafts = false
        var outputRootPath: String?
        var port = 8000
        var positional: [String] = []

        var index = 1
        while index < arguments.count {
            switch arguments[index] {
            case "--drafts":
                includeDrafts = true
                index += 1
            case "--output":
                guard index + 1 < arguments.count else {
                    throw CommandError.invalidArguments
                }
                outputRootPath = arguments[index + 1]
                index += 2
            case "--port":
                guard
                    index + 1 < arguments.count,
                    let parsedPort = Int(arguments[index + 1]),
                    (0 ... 65535).contains(parsedPort)
                else {
                    throw CommandError.invalidArguments
                }
                port = parsedPort
                index += 2
            case let value where value.hasPrefix("--"):
                throw CommandError.invalidArguments
            case let value:
                positional.append(value)
                index += 1
            }
        }

        guard positional.count == 1 else {
            throw CommandError.invalidArguments
        }
        return .init(
            contentRootPath: positional[0],
            outputRootPath: outputRootPath,
            port: port,
            includeDrafts: includeDrafts,
        )
    }

    private func defaultServeOutputPath(
        contentRootPath: String,
    ) -> String {
        let currentDirectory = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true,
        )
        let contentURL = URL(
            fileURLWithPath: contentRootPath,
            relativeTo: currentDirectory,
        ).standardizedFileURL
        return contentURL
            .deletingLastPathComponent()
            .appendingPathComponent(".tiledown", isDirectory: true)
            .appendingPathComponent("serve", isDirectory: true)
            .path
    }
}

private struct ServeOptions {
    var contentRootPath: String
    var outputRootPath: String?
    var port: Int
    var includeDrafts: Bool
}
