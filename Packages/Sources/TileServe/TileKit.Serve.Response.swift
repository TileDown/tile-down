import Foundation
import TileCore

public extension TileKit.Serve {
    /// A single HTTP response header.
    struct Header: Equatable, Sendable {
        public var name: String
        public var value: String

        public init(
            name: String,
            value: String,
        ) {
            self.name = name
            self.value = value
        }
    }

    /// An HTTP response produced by a preview-server request handler.
    struct Response: Equatable, Sendable {
        public var statusCode: Int
        public var reasonPhrase: String
        public var headers: [Header]
        public var body: Data

        public init(
            statusCode: Int,
            reasonPhrase: String,
            headers: [Header] = [],
            body: Data = Data(),
        ) {
            self.statusCode = statusCode
            self.reasonPhrase = reasonPhrase
            self.headers = headers
            self.body = body
        }
    }
}
