public extension TileKit.Template {
    indirect enum Value: Equatable, ExpressibleByStringLiteral, Sendable {
        case string(String)
        case object(Context)
        case list([Context])

        public init(
            stringLiteral value: String,
        ) {
            self = .string(value)
        }

        public var stringValue: String? {
            switch self {
            case let .string(value):
                value
            case .object, .list:
                nil
            }
        }
    }
}
