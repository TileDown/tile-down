import TileCore

public extension TileKit.Tile {
    /// Errors produced while parsing Tiledown tile directive blocks.
    enum DirectiveParserError: Error, Equatable, Sendable {
        case invalidHeader(line: Int, text: String)
        case invalidPropertyLine(line: Int, text: String)
        case missingClosingFence(line: Int)
    }
}
