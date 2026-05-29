import TileCore

public extension TileKit.Source {
    protocol MarkdownParsing {
        func parse(
            _ source: String,
        ) throws -> Document
    }
}
