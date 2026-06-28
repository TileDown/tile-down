import TileCore

extension TileKit.Site {
    struct GeneratedSitePaths: Equatable {
        var stylesheetPath: String
        var feedPath: String
        /// The rendered site-wide newsletter form HTML, or "" when no newsletter is
        /// configured. Carried here so it reaches every page's template context.
        var newsletterHTML: String

        init(
            stylesheetPath: String = "",
            feedPath: String = "",
            newsletterHTML: String = "",
        ) {
            self.stylesheetPath = stylesheetPath
            self.feedPath = feedPath
            self.newsletterHTML = newsletterHTML
        }
    }
}
