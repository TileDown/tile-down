import TileCore

public extension TileKit.Site {
    /// The Markdown reference schemes the engine resolves to real URLs at build
    /// time, e.g. `[text](page:slug)`, `[text](post:key)`, `[text](tag:name)`,
    /// `[text](social:key)`, `[text](link:key)`.
    ///
    /// The composition root passes these to the Markdown renderer as pass-through
    /// schemes so a reference survives rendering (it is not a dangerous scheme, but
    /// it is not a normal one either) and can then be resolved to a real URL.
    enum Reference {
        /// The schemes resolved against registries the engine owns: a page slug, a
        /// post key relative to the posts directory, a tag name, a configured social
        /// link key, and a configured outbound link key (an `/out/<key>/` shim).
        public static let schemes: Set<String> = ["page", "post", "tag", "social", "link"]
    }
}
