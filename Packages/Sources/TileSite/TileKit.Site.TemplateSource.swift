import TileCore

public extension TileKit.Site {
    /// The source of the page template used for a site build.
    ///
    /// A template can be supplied by the author as a file, or selected from the
    /// built-in layout set. The built-in path keeps a site build usable without a
    /// hand-written template, while the file path remains the custom-template
    /// override.
    enum TemplateSource: Equatable, Sendable {
        /// Read a custom Mustache template from the given path.
        case file(path: String)
        /// Use the built-in template for the selected layout.
        case layout(Layout)
    }
}
