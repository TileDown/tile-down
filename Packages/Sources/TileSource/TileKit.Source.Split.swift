import TileCore

public extension TileKit.Source {
    /// A source document separated into its raw front matter and its body, with
    /// neither part decoded.
    ///
    /// `frontMatter` is the verbatim front matter block including its `---`
    /// fences, or `nil` when the source has no front matter. `body` is everything
    /// after the closing fence. This is the raw split that `parse` decodes and that
    /// a formatter preserves: the front matter is carried byte for byte because it
    /// has no canonical serializer yet, while the body is the part a canonical
    /// formatter rewrites.
    struct Split: Equatable, Sendable {
        public var frontMatter: String?
        public var body: String

        public init(
            frontMatter: String?,
            body: String,
        ) {
            self.frontMatter = frontMatter
            self.body = body
        }
    }
}
