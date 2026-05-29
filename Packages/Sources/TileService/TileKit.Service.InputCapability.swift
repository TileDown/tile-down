import TileCore

public extension TileKit.Service {
    /// A supported manifest input primitive.
    enum InputCapability: String, CaseIterable, Codable, Equatable, Sendable {
        case text
        case multilineText = "multiline-text"
        case integer
        case double
        case decimal
        case boolean
        case date
        case image
        case video
        case color
        case url
        case select
        case credentialReference = "credential-reference"
    }
}
