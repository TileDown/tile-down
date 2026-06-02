import Foundation
import Testing
import TileCore
import TileServe

@Suite("Static file responder")
struct StaticFileResponderTests {
    @Test("serves directory index files")
    func servesDirectoryIndexFiles() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        try write("Hello", to: fixture.appendingPathComponent("index.html"))

        let response = try responder(root: fixture).response(
            for: .init(method: "GET", target: "/"),
        )

        #expect(response.statusCode == 200)
        #expect(String(data: response.body, encoding: .utf8) == "Hello")
        #expect(header("Content-Type", in: response) == "text/html; charset=utf-8")
    }

    @Test("serves assets with their content type")
    func servesAssetsWithContentType() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let assets = fixture.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assets,
            withIntermediateDirectories: true,
        )
        try write("<svg></svg>", to: assets.appendingPathComponent("logo.svg"))

        let response = try responder(root: fixture).response(
            for: .init(method: "GET", target: "/assets/logo.svg"),
        )

        #expect(response.statusCode == 200)
        #expect(header("Content-Type", in: response) == "image/svg+xml")
    }

    @Test("missing paths return not found")
    func missingPathsReturnNotFound() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }

        let response = try responder(root: fixture).response(
            for: .init(method: "GET", target: "/missing/"),
        )

        #expect(response.statusCode == 404)
        #expect(String(data: response.body, encoding: .utf8) == "Not Found\n")
    }

    @Test("path traversal cannot escape the root")
    func pathTraversalCannotEscapeRoot() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let sibling = fixture
            .deletingLastPathComponent()
            .appendingPathComponent("secret.txt")
        try write("secret", to: sibling)

        let response = try responder(root: fixture).response(
            for: .init(method: "GET", target: "/../secret.txt"),
        )

        #expect(response.statusCode == 404)
    }

    @Test("symlinks cannot escape the root")
    func symlinksCannotEscapeRoot() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let outside = fixture
            .deletingLastPathComponent()
            .appendingPathComponent("outside-\(UUID().uuidString).html")
        try write("secret", to: outside)
        defer { try? FileManager.default.removeItem(at: outside) }
        try FileManager.default.createSymbolicLink(
            at: fixture.appendingPathComponent("outside.html"),
            withDestinationURL: outside,
        )

        let response = try responder(root: fixture).response(
            for: .init(method: "GET", target: "/outside.html"),
        )

        #expect(response.statusCode == 404)
    }

    @Test("head responses keep content length and omit the body")
    func headResponsesKeepContentLengthAndOmitBody() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        try write("Hello", to: fixture.appendingPathComponent("index.html"))

        let response = try responder(root: fixture).response(
            for: .init(method: "HEAD", target: "/"),
        )

        #expect(response.statusCode == 200)
        #expect(header("Content-Length", in: response) == "5")
        #expect(response.body.isEmpty)
    }

    @Test("head misses keep content length and omit the body")
    func headMissesKeepContentLengthAndOmitBody() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }

        let response = try responder(root: fixture).response(
            for: .init(method: "HEAD", target: "/missing/"),
        )

        #expect(response.statusCode == 404)
        #expect(header("Content-Length", in: response) == "10")
        #expect(response.body.isEmpty)
    }

    private func responder(
        root: URL,
    ) -> TileKit.Serve.StaticFileResponder {
        .init(rootPath: root.path, fileManager: .default)
    }

    private func header(
        _ name: String,
        in response: TileKit.Serve.Response,
    ) -> String? {
        response.headers
            .first { $0.name.lowercased() == name.lowercased() }?
            .value
    }

    private func makeFixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "tiledown-serve-tests-\(UUID().uuidString)",
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
