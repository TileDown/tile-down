public extension TileKit.Source {
    struct ContentLocation: Equatable, Sendable {
        public var sourceRelativePath: String
        public var slug: String

        public init(
            sourceRelativePath: String,
            slug: String,
        ) {
            self.sourceRelativePath = sourceRelativePath
            self.slug = slug
        }
    }
}
