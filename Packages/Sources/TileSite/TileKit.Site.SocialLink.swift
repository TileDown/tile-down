import TileCore

public extension TileKit.Site {
    /// A footer social link exposed to built-in layouts and custom templates.
    struct SocialLink: Equatable, Sendable {
        public var label: String
        public var url: String
        /// Optional relationship attribute for identity links such as Mastodon
        /// verification. Empty by default, so existing links render unchanged.
        public var rel: String

        public init(
            label: String,
            url: String,
            rel: String = "",
        ) {
            self.label = label
            self.url = url
            self.rel = rel
        }
    }
}
