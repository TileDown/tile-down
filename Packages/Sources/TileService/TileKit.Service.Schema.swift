import TileCore

public extension TileKit.Service {
    /// JSON-schema subset used by generated service tile contracts.
    struct Schema: Codable, Equatable, Sendable {
        public var type: SchemaType
        public var format: String?
        public var semanticType: SemanticType?
        public var pattern: String?
        public var enumValues: [String]
        public var minimum: Double?
        public var exclusiveMinimum: Double?
        public var maximum: Double?
        public var exclusiveMaximum: Double?
        public var properties: [String: Schema]
        public var required: [String]

        public init(
            type: SchemaType,
            format: String? = nil,
            semanticType: SemanticType? = nil,
            pattern: String? = nil,
            enumValues: [String] = [],
            minimum: Double? = nil,
            exclusiveMinimum: Double? = nil,
            maximum: Double? = nil,
            exclusiveMaximum: Double? = nil,
            properties: [String: Schema] = [:],
            required: [String] = [],
        ) {
            self.type = type
            self.format = format
            self.semanticType = semanticType
            self.pattern = pattern
            self.enumValues = enumValues
            self.minimum = minimum
            self.exclusiveMinimum = exclusiveMinimum
            self.maximum = maximum
            self.exclusiveMaximum = exclusiveMaximum
            self.properties = properties
            self.required = required
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceSchemaCodingKeys.self)

            type = try container.decode(SchemaType.self, forKey: .type)
            format = try container.decodeIfPresent(String.self, forKey: .format)
            semanticType = try container.decodeIfPresent(
                SemanticType.self,
                forKey: .semanticType,
            )
            pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
            enumValues = try container.decodeIfPresent(
                [String].self,
                forKey: .enumValues,
            ) ?? []
            minimum = try container.decodeIfPresent(Double.self, forKey: .minimum)
            exclusiveMinimum = try container.decodeIfPresent(
                Double.self,
                forKey: .exclusiveMinimum,
            )
            maximum = try container.decodeIfPresent(Double.self, forKey: .maximum)
            exclusiveMaximum = try container.decodeIfPresent(
                Double.self,
                forKey: .exclusiveMaximum,
            )
            properties = try container.decodeIfPresent(
                [String: Schema].self,
                forKey: .properties,
            ) ?? [:]
            required = try container.decodeIfPresent([String].self, forKey: .required) ?? []
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: TileKitServiceSchemaCodingKeys.self)

            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(format, forKey: .format)
            try container.encodeIfPresent(semanticType, forKey: .semanticType)
            try container.encodeIfPresent(pattern, forKey: .pattern)
            try container.encode(enumValues, forKey: .enumValues)
            try container.encodeIfPresent(minimum, forKey: .minimum)
            try container.encodeIfPresent(exclusiveMinimum, forKey: .exclusiveMinimum)
            try container.encodeIfPresent(maximum, forKey: .maximum)
            try container.encodeIfPresent(exclusiveMaximum, forKey: .exclusiveMaximum)
            try container.encode(properties, forKey: .properties)
            try container.encode(required, forKey: .required)
        }
    }
}

private enum TileKitServiceSchemaCodingKeys: String, CodingKey {
    case type
    case format
    case semanticType = "x-tiledownType"
    case pattern
    case enumValues = "enum"
    case minimum
    case exclusiveMinimum
    case maximum
    case exclusiveMaximum
    case properties
    case required
}
