import Foundation
import TileCore

public extension TileKit.Serve {
    /// Runtime configuration for the local preview server.
    struct Configuration: Equatable, Sendable {
        public var rootPath: String
        public var host: String
        public var port: Int

        public init(
            rootPath: String,
            host: String = "127.0.0.1",
            port: Int = 8000,
        ) {
            self.rootPath = rootPath
            self.host = host
            self.port = port
        }
    }
}
