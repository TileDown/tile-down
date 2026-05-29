import TileCore

public extension TileKit {
    /// Namespace for output renderers that project a parsed document into a
    /// serialized output format.
    ///
    /// HTML is the first output (today on the site generator's own path); JSON is
    /// the second, derived from the parsed tile tree. Output renderers are
    /// registered by injected values, never selected by a hard-coded switch in the
    /// core pipeline (DESIGN G7, § 8.3).
    enum Output {}
}
