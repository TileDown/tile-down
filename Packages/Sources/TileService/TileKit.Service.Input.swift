import TileCore

public extension TileKit.Service {
    /// An input field declared by a provider integration manifest.
    struct Input: Codable, Equatable, Sendable {
        public var type: InputCapability
        public var required: Bool
        public var defaultValue: String?
        public var allowedValues: [String]

        public init(
            type: InputCapability,
            required: Bool,
            defaultValue: String? = nil,
            allowedValues: [String] = [],
        ) {
            self.type = type
            self.required = required
            self.defaultValue = defaultValue
            self.allowedValues = allowedValues
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceInputCodingKeys.self)

            type = try container.decode(InputCapability.self, forKey: .type)
            required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
            defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
            allowedValues = try container.decodeIfPresent(
                [String].self,
                forKey: .allowedValues,
            ) ?? []
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: TileKitServiceInputCodingKeys.self)

            try container.encode(type, forKey: .type)
            try container.encode(required, forKey: .required)
            try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
            try container.encode(allowedValues, forKey: .allowedValues)
        }
    }
}

private enum TileKitServiceInputCodingKeys: String, CodingKey {
    case type
    case required
    case defaultValue = "default"
    case allowedValues
}
