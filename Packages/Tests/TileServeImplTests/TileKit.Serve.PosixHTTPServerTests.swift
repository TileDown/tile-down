import Foundation
import Testing
import TileCore
import TileServe
import TileServeImpl

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("POSIX HTTP server")
struct PosixHTTPServerTests {
    @Test("serves static files over HTTP")
    func servesStaticFilesOverHTTP() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let assets = fixture.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assets,
            withIntermediateDirectories: true,
        )
        try write("Home", to: fixture.appendingPathComponent("index.html"))
        try write("<svg></svg>", to: assets.appendingPathComponent("logo.svg"))

        let server = TileKit.Serve.PosixHTTPServer()
        let running = try server.start(
            configuration: .init(rootPath: fixture.path, port: 0),
            responder: .init(rootPath: fixture.path, fileManager: .default),
        )
        defer { running.stop() }

        let home = try await fetch(running.url)
        #expect(home.status == 200)
        #expect(home.body == "Home")

        let assetURL = running.url.appendingPathComponent("assets/logo.svg")
        let asset = try await fetch(assetURL)
        #expect(asset.status == 200)
        #expect(asset.contentType == "image/svg+xml")

        let missing = try await fetch(running.url.appendingPathComponent("missing"))
        #expect(missing.status == 404)
    }

    @Test("rejects invalid ports before opening a socket")
    func rejectsInvalidPortsBeforeOpeningSocket() throws {
        let server = TileKit.Serve.PosixHTTPServer()

        #expect(throws: TileKit.Serve.ServerError.invalidPort(-1)) {
            try server.start(
                configuration: .init(rootPath: "/", port: -1),
                responder: .init(rootPath: "/", fileManager: .default),
            )
        }
    }

    private func fetch(
        _ url: URL,
    ) async throws -> FetchResult {
        var lastError: Error?
        for _ in 0 ..< 30 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let httpResponse = try #require(response as? HTTPURLResponse)
                return .init(
                    status: httpResponse.statusCode,
                    contentType: httpResponse.value(forHTTPHeaderField: "Content-Type"),
                    body: String(data: data, encoding: .utf8) ?? "",
                )
            } catch {
                lastError = error
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        throw try #require(lastError)
    }

    private struct FetchResult: Equatable {
        var status: Int
        var contentType: String?
        var body: String
    }

    private func makeFixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "tiledown-serve-impl-tests-\(UUID().uuidString)",
                isDirectory: true,
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true,
        )
        return root
    }

    private func write(
        _ text: String,
        to url: URL,
    ) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
