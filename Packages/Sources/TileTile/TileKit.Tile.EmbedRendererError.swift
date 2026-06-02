import TileCore

public extension TileKit.Tile {
    /// Validation failures for the built-in `embed` tile.
    enum EmbedRendererError: Error, Equatable, CustomStringConvertible, Sendable {
        case invalidTileType(actual: String)
        case missingProperty(String)
        case unsupportedScheme(String)
        case unsupportedProvider(String)
        case invalidAspectRatio(String)

        public var description: String {
            switch self {
            case let .invalidTileType(actual):
                "Tile type \(actual) is not embed."
            case let .missingProperty(name):
                "Add the \(name) property to the embed tile."
            case let .unsupportedScheme(scheme):
                "Embed URLs must use https, not \(scheme)."
            case let .unsupportedProvider(url):
                "Embed URL is not an allowed provider or video file: \(url)."
            case let .invalidAspectRatio(value):
                "Embed aspectRatio must be two positive integers separated by /, not \(value)."
            }
        }
    }
}
