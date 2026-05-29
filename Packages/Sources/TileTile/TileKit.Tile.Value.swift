import TileCore

public extension TileKit.Tile {
    /// A property value parsed from a tile directive.
    enum Value: Equatable, Sendable {
        case string(String)
        case list([String])
    }
}
