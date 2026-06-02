import Foundation
import TileCore
import TileServe

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

public extension TileKit.Serve {
    /// A small local HTTP server used by `tiledown serve`.
    final class PosixHTTPServer: Server {
        public init() {}

        public func start(
            configuration: Configuration,
            responder: StaticFileResponder,
        ) throws -> any RunningServer {
            guard configuration.host == "127.0.0.1" else {
                throw ServerError.unsupportedHost(configuration.host)
            }
            guard (0 ... 65535).contains(configuration.port) else {
                throw ServerError.invalidPort(configuration.port)
            }

            let descriptor = socket(AF_INET, streamSocketType, 0)
            guard descriptor >= 0 else {
                throw ServerError.socketFailed
            }

            do {
                try configure(descriptor)
                try bind(
                    descriptor,
                    host: configuration.host,
                    port: configuration.port,
                )
                guard listen(descriptor, SOMAXCONN) == 0 else {
                    throw ServerError.listenFailed
                }
                let actualPort = try boundPort(descriptor)
                let running = try Running(
                    descriptor: descriptor,
                    host: configuration.host,
                    port: actualPort,
                    responder: responder,
                )
                running.start()
                return running
            } catch {
                closeSocket(descriptor)
                throw error
            }
        }

        private func configure(
            _ descriptor: Int32,
        ) throws {
            var reuse: Int32 = 1
            let result = withUnsafePointer(to: &reuse) {
                setsockopt(
                    descriptor,
                    SOL_SOCKET,
                    SO_REUSEADDR,
                    $0,
                    socklen_t(MemoryLayout<Int32>.size),
                )
            }
            guard result == 0 else {
                throw ServerError.socketFailed
            }
        }

        private func bind(
            _ descriptor: Int32,
            host: String,
            port: Int,
        ) throws {
            var address = sockaddr_in()
            address.sin_family = sa_family_t(AF_INET)
            address.sin_port = in_port_t(port).bigEndian
            address.sin_addr.s_addr = inet_addr(host)

            let result = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    DarwinGlibc.bind(
                        descriptor,
                        $0,
                        socklen_t(MemoryLayout<sockaddr_in>.size),
                    )
                }
            }
            guard result == 0 else {
                throw ServerError.bindFailed(host: host, port: port)
            }
        }

        private func boundPort(
            _ descriptor: Int32,
        ) throws -> Int {
            var address = sockaddr_in()
            var length = socklen_t(MemoryLayout<sockaddr_in>.size)
            let result = withUnsafeMutablePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    getsockname(descriptor, $0, &length)
                }
            }
            guard result == 0 else {
                throw ServerError.socketFailed
            }
            return Int(in_port_t(bigEndian: address.sin_port))
        }
    }
}

/// The server handle is passed to one background Thread closure. Its mutable
/// lifecycle flags are used by the owning caller, while accepted clients are
/// handled serially on that thread.
private final class Running: TileKit.Serve.RunningServer, @unchecked Sendable {
    private let descriptor: Int32
    private let responder: TileKit.Serve.StaticFileResponder
    private var thread: Thread?
    private var didStop = false

    let url: URL

    init(
        descriptor: Int32,
        host: String,
        port: Int,
        responder: TileKit.Serve.StaticFileResponder,
    ) throws {
        self.descriptor = descriptor
        self.responder = responder
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        components.path = "/"
        guard let url = components.url else {
            throw TileKit.Serve.ServerError.invalidServerURL(
                host: host,
                port: port,
            )
        }
        self.url = url
    }

    func start() {
        let thread = Thread { [weak self] in
            self?.acceptLoop()
        }
        thread.name = "tiledown-serve"
        self.thread = thread
        thread.start()
    }

    func stop() {
        guard !didStop else {
            return
        }
        didStop = true
        thread?.cancel()
        shutdownSocket(descriptor)
        closeSocket(descriptor)
    }

    func wait() {
        guard let thread else {
            return
        }
        while !thread.isFinished {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func acceptLoop() {
        while !Thread.current.isCancelled {
            let client = accept(descriptor, nil, nil)
            guard client >= 0 else {
                break
            }
            handle(client)
            closeSocket(client)
        }
    }

    private func handle(
        _ client: Int32,
    ) {
        do {
            let request = try readRequest(from: client)
            let response = try responder.response(for: request)
            try write(response, to: client)
        } catch {
            let response = TileKit.Serve.Response(
                statusCode: 400,
                reasonPhrase: "Bad Request",
                headers: [
                    .init(name: "Content-Type", value: "text/plain; charset=utf-8"),
                ],
                body: Data("Bad Request\n".utf8),
            )
            try? write(response, to: client)
        }
    }

    private func readRequest(
        from client: Int32,
    ) throws -> TileKit.Serve.Request {
        let data = try readRequestHead(from: client)
        guard
            let text = String(data: data, encoding: .utf8),
            let requestLine = text.split(separator: "\r\n").first
        else {
            throw TileKit.Serve.ServerError.invalidRequestTarget("")
        }
        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else {
            throw TileKit.Serve.ServerError.invalidRequestTarget(String(requestLine))
        }
        return .init(
            method: String(parts[0]),
            target: String(parts[1]),
        )
    }

    private func readRequestHead(
        from client: Int32,
    ) throws -> Data {
        let maximumRequestHeadBytes = 16384
        let lineEnd = Data("\r\n".utf8)
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)

        while data.count < maximumRequestHeadBytes {
            let remaining = maximumRequestHeadBytes - data.count
            let count = recv(client, &buffer, min(buffer.count, remaining), 0)
            guard count > 0 else {
                throw TileKit.Serve.ServerError.invalidRequestTarget("")
            }
            data.append(contentsOf: buffer.prefix(Int(count)))
            if let range = data.range(of: lineEnd) {
                return Data(data[..<range.upperBound])
            }
        }

        throw TileKit.Serve.ServerError.invalidRequestTarget("")
    }

    private func write(
        _ response: TileKit.Serve.Response,
        to client: Int32,
    ) throws {
        var headers = response.headers
        headers.append(.init(name: "Connection", value: "close"))
        if !headers.contains(where: { $0.name.lowercased() == "content-length" }) {
            headers.append(.init(name: "Content-Length", value: "\(response.body.count)"))
        }

        var head = "HTTP/1.1 \(response.statusCode) \(response.reasonPhrase)\r\n"
        for header in headers {
            head += "\(header.name): \(header.value)\r\n"
        }
        head += "\r\n"

        try write(Data(head.utf8), to: client)
        if !response.body.isEmpty {
            try write(response.body, to: client)
        }
    }

    private func write(
        _ data: Data,
        to client: Int32,
    ) throws {
        try data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else {
                return
            }
            var sent = 0
            while sent < data.count {
                let result = send(
                    client,
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

private enum DarwinGlibc {
    static var streamSocketType: Int32 {
        #if canImport(Darwin)
            Int32(SOCK_STREAM)
        #elseif canImport(Glibc)
            Int32(SOCK_STREAM.rawValue)
        #endif
    }

    static func bind(
        _ descriptor: Int32,
        _ address: UnsafePointer<sockaddr>,
        _ length: socklen_t,
    ) -> Int32 {
        #if canImport(Darwin)
            Darwin.bind(descriptor, address, length)
        #elseif canImport(Glibc)
            Glibc.bind(descriptor, address, length)
        #endif
    }
}

private var streamSocketType: Int32 {
    DarwinGlibc.streamSocketType
}

private func closeSocket(
    _ descriptor: Int32,
) {
    #if canImport(Darwin)
        _ = Darwin.close(descriptor)
    #elseif canImport(Glibc)
        _ = Glibc.close(descriptor)
    #endif
}

private func shutdownSocket(
    _ descriptor: Int32,
) {
    #if canImport(Darwin)
        _ = Darwin.shutdown(descriptor, SHUT_RDWR)
    #elseif canImport(Glibc)
        _ = Glibc.shutdown(descriptor, Int32(SHUT_RDWR))
    #endif
}
