import TileCore

public extension TileKit.Service {
    /// A supported manifest output primitive.
    enum OutputCapability: String, CaseIterable, Codable, Equatable, Sendable {
        case html
        case markdown
        case imagePlaceholder = "image-placeholder"
        case videoPlaceholder = "video-placeholder"
        case iframe
        case form
        case cssAsset = "css-asset"
        case javascriptAsset = "javascript-asset"
        case externalEmbed = "external-embed"
    }
}
