import TileCore

public extension TileKit.Serve {
    /// Errors thrown by the local preview server.
    enum ServerError: Error, Equatable, Sendable, CustomStringConvertible {
        case invalidRequestTarget(String)
        case invalidServerURL(host: String, port: Int)
        case invalidPort(Int)
        case unsupportedHost(String)
        case socketFailed
        case bindFailed(host: String, port: Int)
        case listenFailed

        public var description: String {
            switch self {
            case let .invalidRequestTarget(target):
                "Invalid request target `\(target)`."
            case let .invalidServerURL(host, port):
                "Could not construct preview server URL for \(host):\(port)."
            case let .invalidPort(port):
                "Invalid preview server port `\(port)`. Use a value from 0 to 65535."
            case let .unsupportedHost(host):
                "Unsupported serve host `\(host)`. Use 127.0.0.1 for this slice."
            case .socketFailed:
                "Could not create the preview server socket."
            case let .bindFailed(host, port):
                "Could not bind preview server to \(host):\(port)."
            case .listenFailed:
                "Could not listen on the preview server socket."
            }
        }
    }
}
