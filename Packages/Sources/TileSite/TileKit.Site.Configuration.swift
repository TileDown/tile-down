import TileCore

public extension TileKit.Site {
    /// Site-wide configuration shared by every page in a build.
    ///
    /// The site-scoped counterpart to per-page front matter: values that belong to
    /// the whole site, not one page. Exposed to templates under `site`.
    struct Configuration: Equatable, Sendable {
        /// The site title, exposed to templates as `site.title`.
        public var title: String
        /// The site base URL, exposed to templates as `site.baseURL` and used for
        /// absolute links and shared asset paths.
        public var baseURL: String
        /// The site theme, composed into the shared stylesheet. Defaults to
        /// `.standard`; pass `nil` for an unstyled site where tiles still style
        /// themselves.
        public var theme: Theme?
        /// Footer social links, exposed to templates as `site.socialLinks`.
        public var socialLinks: [SocialLink]
        /// RSS feed settings. When present, content builds emit a feed.
        public var feed: Feed?
        /// How the site offers dark and light appearance. Defaults to `.toggle`.
        public var appearance: Appearance

        public init(
            title: String = "",
            baseURL: String = "",
            theme: Theme? = .standard,
            socialLinks: [SocialLink] = [],
            feed: Feed? = nil,
            appearance: Appearance = .toggle,
        ) {
            self.title = title
            self.baseURL = baseURL
            self.theme = theme
            self.socialLinks = socialLinks
            self.feed = feed
            self.appearance = appearance
        }
    }
}
