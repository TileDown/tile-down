import TileCore

public extension TileKit.Service {
    /// A callable service operation that can back a generated tile.
    struct Operation: Codable, Equatable, Sendable {
        public var id: String
        public var modes: [Mode]
        public var transport: Transport
        public var inputSchema: Schema
        public var inputUI: [String: FieldUI]
        public var outputSchema: Schema
        public var outputUI: [String: FieldUI]
        public var auth: OperationAuth?
        public var errors: ErrorResponse?
        public var cache: CachePolicy?

        public init(
            id: String,
            modes: [Mode],
            transport: Transport,
            inputSchema: Schema,
            inputUI: [String: FieldUI] = [:],
            outputSchema: Schema,
            outputUI: [String: FieldUI] = [:],
            auth: OperationAuth? = nil,
            errors: ErrorResponse? = nil,
            cache: CachePolicy? = nil,
        ) {
            self.id = id
            self.modes = modes
            self.transport = transport
            self.inputSchema = inputSchema
            self.inputUI = inputUI
            self.outputSchema = outputSchema
            self.outputUI = outputUI
            self.auth = auth
            self.errors = errors
            self.cache = cache
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceOperationCodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            modes = try container.decode([Mode].self, forKey: .modes)
            transport = try container.decode(Transport.self, forKey: .transport)
            inputSchema = try container.decode(Schema.self, forKey: .inputSchema)
            inputUI = try container.decodeIfPresent(
                [String: FieldUI].self,
                forKey: .inputUI,
            ) ?? [:]
            outputSchema = try container.decode(Schema.self, forKey: .outputSchema)
            outputUI = try container.decodeIfPresent(
                [String: FieldUI].self,
                forKey: .outputUI,
            ) ?? [:]
            auth = try container.decodeIfPresent(OperationAuth.self, forKey: .auth)
            errors = try container.decodeIfPresent(ErrorResponse.self, forKey: .errors)
            cache = try container.decodeIfPresent(CachePolicy.self, forKey: .cache)
        }
    }
}

private enum TileKitServiceOperationCodingKeys: String, CodingKey {
    case id
    case modes
    case transport
    case inputSchema
    case inputUI = "inputUi"
    case outputSchema
    case outputUI = "outputUi"
    case auth
    case errors
    case cache
}
