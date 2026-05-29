import TileCore

public extension TileKit.Content {
    enum ComparisonOperator: String, Equatable, Sendable {
        case equals
        case notEquals
        case lessThan
        case lessThanOrEqual
        case greaterThan
        case greaterThanOrEqual
        case like
        case caseInsensitiveLike
        case contains
        case containedIn
        case matchesAny
    }
}
