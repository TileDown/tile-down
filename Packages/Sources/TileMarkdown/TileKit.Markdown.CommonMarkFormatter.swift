import Markdown
import TileCore

public extension TileKit.Markdown {
    /// Canonicalizes Markdown prose using swift-markdown's `MarkupFormatter`.
    ///
    /// Parses the prose and re-emits it in one normalized form: ATX headings,
    /// `-` unordered-list and thematic-break markers, fenced code, `*` emphasis.
    /// The output is a fixed point (formatting it again yields the same string).
    ///
    /// Known normalization: custom ordered-list start indices are not preserved
    /// (swift-markdown #76), so `3.`/`4.` canonicalize to `1.`/`1.`. This is an
    /// accepted property of the normalized profile, documented in
    /// `docs/markdown-profile.md`.
    struct CommonMarkFormatter: Formatting {
        public init() {}

        public func canonicalize(
            _ markdown: String,
        ) -> String {
            Document(parsing: markdown).format()
        }
    }
}
