import TileCore

public extension TileKit.Source {
    struct Document: Equatable, Sendable {
        public var frontMatter: [String: String]
        public var body: String

        public init(
            frontMatter: [String: String],
            body: String,
        ) {
            self.frontMatter = frontMatter
            self.body = body
        }
    }
}
