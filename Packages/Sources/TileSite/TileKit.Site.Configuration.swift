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
        /// The content directory whose dated pages count as posts for the listing
        /// (`site.posts`) and the RSS feed. A slug-style path with no surrounding
        /// slashes (e.g. `posts`, `blog`, `writing/notes`). Defaults to `posts`.
        public var postsDirectory: String
        /// How many of the newest posts `site.latestPosts` exposes (for a home-page
        /// "recent posts" block). Defaults to 3; a value <= 0 yields no latest posts.
        public var latestPostCount: Int
        /// An optional label for the posts section, overriding the posts landing
        /// page's own title in navigation and its heading (e.g. `Writings`). Empty
        /// means use the page's own title.
        public var postsLabel: String
        /// A multiplier on the base font size, applied to the root element so the
        /// whole type scale grows or shrinks together. `1` is the theme default;
        /// `1.1` is 10% larger. Values <= 0 are rejected at parse time.
        public var fontScale: Double
        /// Named outbound external links, keyed by name. `[text](link:key)` resolves
        /// to a generated `/out/<key>/` redirect page that forwards here, so an
        /// external URL lives in one place and the public link stays stable.
        public var outboundLinks: [String: String]
        /// An opt-in analytics snippet injected into every page's `<head>`, verbatim
        /// (e.g. a provider's script tag). Empty by default, so a build emits no
        /// analytics. Author-supplied and third-party, like client-side tile JS.
        public var analyticsHead: String
        /// An opt-in analytics snippet injected at the end of every page's `<body>`,
        /// verbatim. Empty by default. For providers whose snippet belongs before
        /// `</body>` rather than in the head.
        public var analyticsBodyEnd: String
        /// Whether built-in article pages include static social share links.
        /// Disabled by default so a site only emits third-party share URLs when it
        /// opts in.
        public var shareLinks: Bool
        /// Static files or directories to copy from the content tree to explicit
        /// output paths, e.g. root deployment files or migrated public assets.
        public var staticPassthroughs: [StaticPassthrough]

        public init(
            title: String = "",
            baseURL: String = "",
            theme: Theme? = .standard,
            socialLinks: [SocialLink] = [],
            feed: Feed? = nil,
            appearance: Appearance = .toggle,
            postsDirectory: String = "posts",
            latestPostCount: Int = 3,
            postsLabel: String = "",
            fontScale: Double = 1,
            outboundLinks: [String: String] = [:],
            analyticsHead: String = "",
            analyticsBodyEnd: String = "",
            shareLinks: Bool = false,
            staticPassthroughs: [StaticPassthrough] = [],
        ) {
            self.title = title
            self.baseURL = baseURL
            self.theme = theme
            self.socialLinks = socialLinks
            self.feed = feed
            self.appearance = appearance
            self.postsDirectory = postsDirectory
            self.latestPostCount = latestPostCount
            self.postsLabel = postsLabel
            self.fontScale = fontScale
            self.outboundLinks = outboundLinks
            self.analyticsHead = analyticsHead
            self.analyticsBodyEnd = analyticsBodyEnd
            self.shareLinks = shareLinks
            self.staticPassthroughs = staticPassthroughs
        }
    }
}
