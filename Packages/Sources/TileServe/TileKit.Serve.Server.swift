import Foundation
import TileCore

public extension TileKit.Serve {
    /// Starts a local preview server and returns a handle that can stop or wait
    /// for that server.
    protocol Server {
        func start(
            configuration: Configuration,
            responder: StaticFileResponder,
        ) throws -> any RunningServer
    }

    /// A running preview server instance.
    protocol RunningServer {
        var url: URL { get }

        func stop()
        func wait()
    }
}
