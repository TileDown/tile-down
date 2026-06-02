import TileCore

public extension TileKit.Tile {
    /// Validation failures for the built-in `chart` tile.
    enum ChartRendererError: Error, Equatable, CustomStringConvertible, Sendable {
        case invalidTileType(actual: String)
        case missingProperty(String)
        case unsupportedType(String)
        case missingSeries
        case emptySeriesName(String)
        case invalidNumber(property: String, value: String)
        case mismatchedSeriesLength(series: String, expected: Int, actual: Int)
        case unsupportedSeriesCount(type: String, expected: String, actual: Int)
        case invalidPieValue(series: String, value: Double)
        case zeroTotal(type: String)
        case invalidHeight(String)
        case invalidBoolean(property: String, value: String)

        public var description: String {
            switch self {
            case let .invalidTileType(actual):
                "Tile type \(actual) is not chart."
            case let .missingProperty(name):
                "Add the \(name) property to the chart tile."
            case let .unsupportedType(value):
                "Chart type \(value) is not supported."
            case .missingSeries:
                "Add at least one series.<name> property to the chart tile."
            case let .emptySeriesName(key):
                "Chart series key \(key) must include a non-empty name after series."
            case let .invalidNumber(property, value):
                "Chart property \(property) contains a non-numeric value: \(value)."
            case let .mismatchedSeriesLength(series, expected, actual):
                "Chart series \(series) has \(actual) values, but labels has \(expected)."
            case let .unsupportedSeriesCount(type, expected, actual):
                "Chart type \(type) expects \(expected) series, but found \(actual)."
            case let .invalidPieValue(series, value):
                "Pie and doughnut charts require positive values; \(series) contains \(value)."
            case let .zeroTotal(type):
                "Chart type \(type) needs values whose total is greater than zero."
            case let .invalidHeight(value):
                "Chart height must be an integer from 240 through 720, not \(value)."
            case let .invalidBoolean(property, value):
                "Chart property \(property) must be true or false, not \(value)."
            }
        }
    }
}
