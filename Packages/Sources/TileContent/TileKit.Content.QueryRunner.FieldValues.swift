import TileCore

extension TileKit.Content.QueryRunner {
    func valuesEqual(
        _ left: TileKit.Content.FieldValue,
        _ right: TileKit.Content.FieldValue,
    ) -> Bool {
        switch (left, right) {
        case let (.bool(leftValue), .bool(rightValue)):
            return leftValue == rightValue
        case let (.list(leftItems), .list(rightItems)):
            return leftItems == rightItems
        default:
            guard let comparison = compare(
                left,
                right,
            ) else {
                return false
            }
            return comparison == 0
        }
    }

    func compare(
        _ left: TileKit.Content.FieldValue,
        _ right: TileKit.Content.FieldValue,
    ) -> Int? {
        if let leftNumber = number(left) {
            guard let rightNumber = number(right) else {
                return nil
            }
            return compare(
                leftNumber,
                rightNumber,
            )
        }

        return compareStrings(
            left,
            right,
        )
    }

    func compareStrings(
        _ left: TileKit.Content.FieldValue,
        _ right: TileKit.Content.FieldValue,
    ) -> Int? {
        guard
            case let .string(leftString) = left,
            case let .string(rightString) = right
        else {
            return nil
        }

        return compare(
            leftString,
            rightString,
        )
    }

    func compare(
        _ left: Double,
        _ right: Double,
    ) -> Int {
        if left < right {
            return -1
        }
        if left > right {
            return 1
        }
        return 0
    }

    func compare(
        _ left: String,
        _ right: String,
    ) -> Int {
        if left < right {
            return -1
        }
        if left > right {
            return 1
        }
        return 0
    }

    func number(
        _ value: TileKit.Content.FieldValue,
    ) -> Double? {
        switch value {
        case let .int(value):
            Double(value)
        case let .double(value):
            value
        case .bool, .string, .list:
            nil
        }
    }

    func containsString(
        _ fieldValue: TileKit.Content.FieldValue,
        _ value: TileKit.Content.FieldValue,
    ) -> Bool {
        guard
            case let .string(fieldString) = fieldValue,
            case let .string(valueString) = value
        else {
            return false
        }
        return fieldString.contains(valueString)
    }

    func lowercased(
        _ value: TileKit.Content.FieldValue,
    ) -> TileKit.Content.FieldValue {
        guard case let .string(value) = value else {
            return value
        }
        return .string(value.lowercased())
    }

    func contains(
        _ fieldValue: TileKit.Content.FieldValue,
        _ value: TileKit.Content.FieldValue,
    ) -> Bool {
        guard case let .list(items) = fieldValue else {
            return containsString(
                fieldValue,
                value,
            )
        }
        return items.contains {
            valuesEqual(
                $0,
                value,
            )
        }
    }

    func matchesAny(
        _ fieldValue: TileKit.Content.FieldValue,
        _ value: TileKit.Content.FieldValue,
    ) -> Bool {
        guard
            case let .list(leftItems) = fieldValue,
            case let .list(rightItems) = value
        else {
            return false
        }

        return leftItems.contains { leftItem in
            rightItems.contains { rightItem in
                valuesEqual(
                    leftItem,
                    rightItem,
                )
            }
        }
    }
}
