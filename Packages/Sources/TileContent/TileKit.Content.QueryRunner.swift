import TileCore

public extension TileKit.Content {
    struct QueryRunner: Sendable {
        public init() {}

        public func run(
            _ query: Query,
            records: [Record],
        ) -> [Record] {
            var result = records.filter { record in
                matchesContentType(
                    query.contentType,
                    record: record,
                ) && evaluate(
                    query.filter,
                    record: record,
                )
            }

            result = sorted(
                result,
                order: query.order,
            )

            if let offset = query.offset {
                result = Array(result.dropFirst(max(offset, 0)))
            }

            if let limit = query.limit {
                result = Array(result.prefix(max(limit, 0)))
            }

            return result
        }
    }
}
