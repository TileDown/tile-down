import TileCore

extension TileKit.Content.QueryRunner {
    func matchesContentType(
        _ contentType: String?,
        record: TileKit.Content.Record,
    ) -> Bool {
        guard let contentType else {
            return true
        }
        return record.contentType == contentType
    }

    func evaluate(
        _ condition: TileKit.Content.Condition?,
        record: TileKit.Content.Record,
    ) -> Bool {
        guard let condition else {
            return true
        }

        switch condition {
        case let .field(key, operation, value):
            guard let fieldValue = record.field(key) else {
                return false
            }
            return evaluate(
                fieldValue,
                operation: operation,
                value: value,
            )
        case let .all(conditions):
            return conditions.allSatisfy {
                evaluate(
                    $0,
                    record: record,
                )
            }
        case let .any(conditions):
            return conditions.contains {
                evaluate(
                    $0,
                    record: record,
                )
            }
        }
    }

    func evaluate(
        _ fieldValue: TileKit.Content.FieldValue,
        operation: TileKit.Content.ComparisonOperator,
        value: TileKit.Content.FieldValue,
    ) -> Bool {
        switch operation {
        case .equals, .notEquals:
            evaluateEquality(
                fieldValue,
                operation: operation,
                value: value,
            )
        case .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual:
            evaluateOrdering(
                fieldValue,
                operation: operation,
                value: value,
            )
        case .like, .caseInsensitiveLike:
            evaluateString(
                fieldValue,
                operation: operation,
                value: value,
            )
        case .contains, .containedIn, .matchesAny:
            evaluateCollection(
                fieldValue,
                operation: operation,
                value: value,
            )
        }
    }

    func evaluateEquality(
        _ fieldValue: TileKit.Content.FieldValue,
        operation: TileKit.Content.ComparisonOperator,
        value: TileKit.Content.FieldValue,
    ) -> Bool {
        switch operation {
        case .equals:
            valuesEqual(fieldValue, value)
        case .notEquals:
            !valuesEqual(fieldValue, value)
        case .lessThan,
             .lessThanOrEqual,
             .greaterThan,
             .greaterThanOrEqual,
             .like,
             .caseInsensitiveLike,
             .contains,
             .containedIn,
             .matchesAny:
            false
        }
    }

    func evaluateOrdering(
        _ fieldValue: TileKit.Content.FieldValue,
        operation: TileKit.Content.ComparisonOperator,
        value: TileKit.Content.FieldValue,
    ) -> Bool {
        guard let comparison = compare(
            fieldValue,
            value,
        ) else {
            return false
        }

        switch operation {
        case .lessThan:
            return comparison == -1
        case .lessThanOrEqual:
            return comparison <= 0
        case .greaterThan:
            return comparison == 1
        case .greaterThanOrEqual:
            return comparison >= 0
        case .equals,
             .notEquals,
             .like,
             .caseInsensitiveLike,
             .contains,
             .containedIn,
             .matchesAny:
            return false
        }
    }

    func evaluateString(
        _ fieldValue: TileKit.Content.FieldValue,
        operation: TileKit.Content.ComparisonOperator,
        value: TileKit.Content.FieldValue,
    ) -> Bool {
        switch operation {
        case .like:
            containsString(fieldValue, value)
        case .caseInsensitiveLike:
            containsString(
                lowercased(fieldValue),
                lowercased(value),
            )
        case .equals,
             .notEquals,
             .lessThan,
             .lessThanOrEqual,
             .greaterThan,
             .greaterThanOrEqual,
             .contains,
             .containedIn,
             .matchesAny:
            false
        }
    }

    func evaluateCollection(
        _ fieldValue: TileKit.Content.FieldValue,
        operation: TileKit.Content.ComparisonOperator,
        value: TileKit.Content.FieldValue,
    ) -> Bool {
        switch operation {
        case .contains:
            contains(fieldValue, value)
        case .containedIn:
            contains(value, fieldValue)
        case .matchesAny:
            matchesAny(fieldValue, value)
        case .equals,
             .notEquals,
             .lessThan,
             .lessThanOrEqual,
             .greaterThan,
             .greaterThanOrEqual,
             .like,
             .caseInsensitiveLike:
            false
        }
    }
}
