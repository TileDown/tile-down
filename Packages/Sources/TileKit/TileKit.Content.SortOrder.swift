public extension TileKit.Content {
    struct SortOrder: Equatable, Sendable {
        public var key: String
        public var direction: SortDirection

        public init(
            key: String,
            direction: SortDirection = .ascending,
        ) {
            self.key = key
            self.direction = direction
        }
    }
}
