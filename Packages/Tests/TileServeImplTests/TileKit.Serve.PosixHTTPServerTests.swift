import Foundation
import Testing
import TileCore
import TileServe
import TileServeImpl

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

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

    @Test("accepts request lines split across TCP packets")
    func acceptsRequestLinesSplitAcrossTCPPackets() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        try write("Home", to: fixture.appendingPathComponent("index.html"))

        let server = TileKit.Serve.PosixHTTPServer()
        let running = try server.start(
            configuration: .init(rootPath: fixture.path, port: 0),
            responder: .init(rootPath: fixture.path, fileManager: .default),
        )
        defer { running.stop() }

        let port = try #require(running.url.port)
        let response = try rawHTTPResponse(
            port: port,
            chunks: [
                "GE",
                "T / HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n",
            ],
        )

        #expect(response.contains("HTTP/1.1 200 OK"))
        #expect(response.hasSuffix("Home"))
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

    private func rawHTTPResponse(
        port: Int,
        chunks: [String],
    ) throws -> String {
        let descriptor = socket(AF_INET, testStreamSocketType, 0)
        guard descriptor >= 0 else {
            throw TileKit.Serve.ServerError.socketFailed
        }
        defer { testCloseSocket(descriptor) }
        try configureReceiveTimeout(for: descriptor)

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        address.sin_addr.s_addr = inet_addr("127.0.0.1")

        let connectResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                testConnect(
                    descriptor,
                    $0,
                    socklen_t(MemoryLayout<sockaddr_in>.size),
                )
            }
        }
        guard connectResult == 0 else {
            throw TileKit.Serve.ServerError.socketFailed
        }

        for chunk in chunks {
            try sendAll(Data(chunk.utf8), to: descriptor)
            Thread.sleep(forTimeInterval: 0.05)
        }

        var received = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = recv(descriptor, &buffer, buffer.count, 0)
            guard count > 0 else {
                break
            }
            received.append(contentsOf: buffer.prefix(Int(count)))
        }

        return String(data: received, encoding: .utf8) ?? ""
    }

    private func configureReceiveTimeout(
        for descriptor: Int32,
    ) throws {
        var timeout = timeval(tv_sec: 2, tv_usec: 0)
        let result = withUnsafePointer(to: &timeout) {
            setsockopt(
                descriptor,
                SOL_SOCKET,
                SO_RCVTIMEO,
                $0,
                socklen_t(MemoryLayout<timeval>.size),
            )
        }
        guard result == 0 else {
            throw TileKit.Serve.ServerError.socketFailed
        }
    }

    private func sendAll(
        _ data: Data,
        to descriptor: Int32,
    ) throws {
        try data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else {
                return
            }
            var sent = 0
            while sent < data.count {
                let result = send(
                    descriptor,
                    baseAddress.advanced(by: sent),
                    data.count - sent,
                    0,
                )
                guard result > 0 else {
                    throw TileKit.Serve.ServerError.socketFailed
                }
                sent += result
            }
        }
    }
}

private var testStreamSocketType: Int32 {
    #if canImport(Darwin)
        Int32(SOCK_STREAM)
    #elseif canImport(Glibc)
        Int32(SOCK_STREAM.rawValue)
    #endif
}

private func testConnect(
    _ descriptor: Int32,
    _ address: UnsafePointer<sockaddr>,
    _ length: socklen_t,
) -> Int32 {
    #if canImport(Darwin)
        Darwin.connect(descriptor, address, length)
    #elseif canImport(Glibc)
        Glibc.connect(descriptor, address, length)
    #endif
}

private func testCloseSocket(
    _ descriptor: Int32,
) {
    #if canImport(Darwin)
        _ = Darwin.close(descriptor)
    #elseif canImport(Glibc)
        _ = Glibc.close(descriptor)
    #endif
}
