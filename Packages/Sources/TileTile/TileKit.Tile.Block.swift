import TileCore

public extension TileKit.Tile {
    /// A parsed block in a Tiledown Markdown document.
    indirect enum Block: Equatable, Sendable {
        case markdown(String)
        case tile(Instance)
    }
}
