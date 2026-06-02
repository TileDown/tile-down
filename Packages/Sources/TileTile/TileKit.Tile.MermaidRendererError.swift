import TileCore

public extension TileKit.Tile {
    /// Validation failures for the built-in `mermaid` tile.
    enum MermaidRendererError: Error, Equatable, CustomStringConvertible, Sendable {
        case invalidTileType(actual: String)
        case missingProperty(String)

        public var description: String {
            switch self {
            case let .invalidTileType(actual):
                "Tile type \(actual) is not mermaid."
            case let .missingProperty(name):
                "Add the \(name) property to the mermaid tile."
            }
        }
    }
}
