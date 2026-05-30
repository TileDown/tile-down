import TileCore

public extension TileKit.Site {
    /// Site-wide feed settings.
    struct Feed: Equatable, Sendable {
        /// The feed file path relative to the output root.
        public var path: String
        /// The feed title. Falls back to the site title when empty.
        public var title: String
        /// The feed description.
        public var description: String

        public init(
            path: String = "feed.xml",
            title: String = "",
            description: String = "",
        ) {
            self.path = path
            self.title = title
            self.description = description
        }
    }
}
