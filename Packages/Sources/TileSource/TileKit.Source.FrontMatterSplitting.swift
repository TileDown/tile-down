import TileCore

public extension TileKit.Source {
    /// Separates a source document's raw front matter from its body.
    ///
    /// A narrower seam than ``TileKit/Source/MarkdownParsing``: a formatter needs
    /// only the raw split (front matter preserved verbatim, body to canonicalize),
    /// not the decoded front matter values. Kept separate so a consumer depends on
    /// exactly the capability it uses.
    protocol FrontMatterSplitting {
        func split(
            _ source: String,
        ) throws -> Split
    }
}
