import TileCore

public extension TileKit.Service {
    /// A supported validation primitive for manifest inputs.
    enum ValidationCapability: String, CaseIterable, Codable, Equatable, Sendable {
        case required
        case optional
        case defaultValue = "default-value"
        case allowedValues = "allowed-values"
        case minLength = "min-length"
        case maxLength = "max-length"
        case regex
        case minimum
        case maximum
    }
}
