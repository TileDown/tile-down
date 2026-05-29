public extension TileKit.Content {
    struct Record: Equatable, Sendable {
        public var id: String
        public var contentType: String
        public var fields: [String: FieldValue]

        public init(
            id: String,
            contentType: String,
            fields: [String: FieldValue],
        ) {
            self.id = id
            self.contentType = contentType
            self.fields = fields
        }

        public func field(
            _ key: String,
        ) -> FieldValue? {
            switch key {
            case "id":
                .string(id)
            case "type":
                .string(contentType)
            default:
                fields[key]
            }
        }
    }
}
