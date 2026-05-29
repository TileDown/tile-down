public extension TileKit.Content {
    struct Query: Equatable, Sendable {
        public var contentType: String?
        public var filter: Condition?
        public var order: [SortOrder]
        public var limit: Int?
        public var offset: Int?

        public init(
            contentType: String? = nil,
            filter: Condition? = nil,
            order: [SortOrder] = [],
            limit: Int? = nil,
            offset: Int? = nil,
        ) {
            self.contentType = contentType
            self.filter = filter
            self.order = order
            self.limit = limit
            self.offset = offset
        }
    }
}
