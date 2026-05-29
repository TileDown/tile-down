import TileCore

public extension TileKit.Content {
    indirect enum Condition: Equatable, Sendable {
        case field(String, ComparisonOperator, FieldValue)
        case all([Condition])
        case any([Condition])
    }
}
