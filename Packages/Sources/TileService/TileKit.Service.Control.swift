import TileCore

public extension TileKit.Service {
    /// Preferred control for a generated service field.
    enum Control: String, Codable, Equatable, Sendable {
        case text
        case multilineText = "multiline-text"
        case number
        case checkbox
        case select
        case radio
        case segmented
        case hidden
    }
}
