import TileCore

public extension TileKit.Tile {
    /// Parses Tiledown Markdown into typed tile and Markdown blocks.
    protocol Parsing: Sendable {
        func parseBlocks(
            _ source: String,
        ) throws -> [Block]
    }
}
