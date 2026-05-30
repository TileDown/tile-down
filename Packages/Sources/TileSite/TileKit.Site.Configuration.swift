import TileCore

public extension TileKit.Site {
    /// Site-wide configuration shared by every page in a build.
    ///
    /// The site-scoped counterpart to per-page front matter: values that belong to
    /// the whole site, not one page. Exposed to templates under `site`. Carried as
    /// direct values for now; loading it from a config file is a later concern.
    struct Configuration: Equatable, Sendable {
        /// The site title, exposed to templates as `site.title`.
        public var title: String
        /// The site base URL, exposed to templates as `site.baseURL` and used for
        /// absolute links and shared asset paths.
        public var baseURL: String
        /// The site theme, composed into the shared stylesheet. `nil` means no theme
        /// (tiles still style themselves; the site is otherwise unstyled).
        public var theme: Theme?

        public init(
            title: String = "",
            baseURL: String = "",
            theme: Theme? = nil,
        ) {
            self.title = title
            self.baseURL = baseURL
            self.theme = theme
        }
    }
}
