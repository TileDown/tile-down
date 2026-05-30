import TileCore

extension TileKit.Site {
    struct GeneratedSitePaths: Equatable {
        var stylesheetPath: String
        var feedPath: String

        init(
            stylesheetPath: String = "",
            feedPath: String = "",
        ) {
            self.stylesheetPath = stylesheetPath
            self.feedPath = feedPath
        }
    }
}
