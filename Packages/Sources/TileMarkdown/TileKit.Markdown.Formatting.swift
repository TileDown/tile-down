import TileCore

public extension TileKit.Markdown {
    /// Canonicalizes a Markdown prose string to one normalized form.
    ///
    /// The prose half of the `put` side of the round-trip, paired with the tile
    /// serializer. A seam so the site serializer is not bound to one Markdown
    /// engine.
    protocol Formatting {
        func canonicalize(
            _ markdown: String,
        ) -> String
    }
}
