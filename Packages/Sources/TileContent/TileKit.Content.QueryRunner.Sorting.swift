import TileCore

extension TileKit.Content.QueryRunner {
    func sorted(
        _ records: [TileKit.Content.Record],
        order: [TileKit.Content.SortOrder],
    ) -> [TileKit.Content.Record] {
        guard !order.isEmpty else {
            return records
        }

        return records.enumerated().sorted { left, right in
            if let result = orderedBefore(
                left.element,
                right.element,
                order: order,
            ) {
                return result
            }
            return left.offset < right.offset
        }
        .map(\.element)
    }

    func orderedBefore(
        _ left: TileKit.Content.Record,
        _ right: TileKit.Content.Record,
        order: [TileKit.Content.SortOrder],
    ) -> Bool? {
        for item in order {
            let leftValue = left.field(item.key)
            let rightValue = right.field(item.key)

            switch (leftValue, rightValue) {
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            case let (.some(leftValue), .some(rightValue)):
                guard let comparison = compare(
                    leftValue,
                    rightValue,
                ) else {
                    continue
                }
                if comparison != 0 {
                    return item.direction == .ascending
                        ? comparison < 0
                        : comparison > 0
                }
            case (nil, nil):
                continue
            }
        }
        return nil
    }
}
