import TileCore

public extension TileKit.Site {
    /// Produces additional static pages from a rendered tile.
    ///
    /// Site generation keeps tile-specific output behind this injected seam so the
    /// generic generator does not infer side effects from tile type ids alone.
    protocol TilePageGenerating: Sendable {
        func pages(
            for context: TilePageGenerationContext,
        ) throws -> [Page]
    }
}
