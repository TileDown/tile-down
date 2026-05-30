import TileCore

public extension TileKit.Site {
    /// A footer social link exposed to built-in layouts and custom templates.
    struct SocialLink: Equatable, Sendable {
        public var label: String
        public var url: String

        public init(
            label: String,
            url: String,
        ) {
            self.label = label
            self.url = url
        }
    }
}
