public extension TileKit.Content {
    indirect enum FieldValue: Equatable, Sendable {
        case bool(Bool)
        case int(Int)
        case double(Double)
        case string(String)
        case list([FieldValue])
    }
}

extension TileKit.Content.FieldValue: ExpressibleByBooleanLiteral {
    public init(
        booleanLiteral value: Bool,
    ) {
        self = .bool(value)
    }
}

extension TileKit.Content.FieldValue: ExpressibleByIntegerLiteral {
    public init(
        integerLiteral value: Int,
    ) {
        self = .int(value)
    }
}

extension TileKit.Content.FieldValue: ExpressibleByFloatLiteral {
    public init(
        floatLiteral value: Double,
    ) {
        self = .double(value)
    }
}

extension TileKit.Content.FieldValue: ExpressibleByStringLiteral {
    public init(
        stringLiteral value: String,
    ) {
        self = .string(value)
    }
}

extension TileKit.Content.FieldValue: ExpressibleByArrayLiteral {
    public init(
        arrayLiteral elements: TileKit.Content.FieldValue...,
    ) {
        self = .list(elements)
    }
}
