import TileCore

public extension TileKit.Site {
    /// A Markdown reference (`scheme:key`) that named a target the site does not
    /// contain, with the source file it appeared in. Collected during a build so
    /// every broken reference is reported together.
    struct UnresolvedReference: Equatable, Sendable {
        public let scheme: String
        public let key: String
        public let sourcePath: String

        public init(
            scheme: String,
            key: String,
            sourcePath: String,
        ) {
            self.scheme = scheme
            self.key = key
            self.sourcePath = sourcePath
        }
    }
}
