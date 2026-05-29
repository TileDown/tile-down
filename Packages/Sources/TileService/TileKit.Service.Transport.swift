import TileCore

public extension TileKit.Service {
    /// HTTP transport shape for a service operation.
    struct Transport: Codable, Equatable, Sendable {
        public var method: HTTPMethod
        public var path: String
        public var requestContentType: String
        public var responseContentType: String
        public var timeoutMilliseconds: Int?

        public init(
            method: HTTPMethod,
            path: String,
            requestContentType: String = "application/json",
            responseContentType: String = "application/json",
            timeoutMilliseconds: Int? = nil,
        ) {
            self.method = method
            self.path = path
            self.requestContentType = requestContentType
            self.responseContentType = responseContentType
            self.timeoutMilliseconds = timeoutMilliseconds
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceTransportCodingKeys.self)

            method = try container.decode(HTTPMethod.self, forKey: .method)
            path = try container.decode(String.self, forKey: .path)
            requestContentType = try container.decodeIfPresent(
                String.self,
                forKey: .requestContentType,
            ) ?? "application/json"
            responseContentType = try container.decodeIfPresent(
                String.self,
                forKey: .responseContentType,
            ) ?? "application/json"
            timeoutMilliseconds = try container.decodeIfPresent(
                Int.self,
                forKey: .timeoutMilliseconds,
            )
        }
    }
}

private enum TileKitServiceTransportCodingKeys: String, CodingKey {
    case method
    case path
    case requestContentType
    case responseContentType
    case timeoutMilliseconds
}
