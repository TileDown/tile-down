import TileCore

extension TileKit.Site.Generator {
    struct SourcePages {
        var contentPages: [TileKit.Site.Page]
        var redirectPages: [TileKit.Site.Page]
        var notFoundPage: TileKit.Site.Page
        var notFoundAssetDirectory: String?

        var hasAuthoredTagLandingPage: Bool {
            (contentPages + redirectPages).contains { $0.slug == "tags" }
        }
    }
}
