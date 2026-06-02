import TileCore

extension TileKit.Site.ConfigurationFile {
    static func applyFeedSetting(
        _ item: (key: String, value: String),
        feed: inout TileKit.Site.Feed?,
        feedEnabled: inout Bool?,
    ) throws -> Bool {
        switch item.key {
        case "rss":
            feedEnabled = try boolean(item.value)
        case "rssPath":
            feed = updatingFeed(feed, path: item.value)
        case "rssTitle":
            feed = updatingFeed(feed, title: item.value)
        case "rssDescription":
            feed = updatingFeed(feed, description: item.value)
        default:
            return false
        }
        return true
    }

    static func resolvedFeed(
        _ feed: TileKit.Site.Feed?,
        feedEnabled: Bool?,
    ) -> TileKit.Site.Feed? {
        switch feedEnabled {
        case .some(true):
            feed ?? .init()
        case .some(false):
            nil
        case nil:
            feed
        }
    }

    private static func updatingFeed(
        _ existing: TileKit.Site.Feed?,
        path: String? = nil,
        title: String? = nil,
        description: String? = nil,
    ) -> TileKit.Site.Feed {
        var result = existing ?? .init()
        if let path {
            result.path = path
        }
        if let title {
            result.title = title
        }
        if let description {
            result.description = description
        }
        return result
    }
}
