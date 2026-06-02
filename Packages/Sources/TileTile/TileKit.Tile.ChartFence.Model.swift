import Foundation

/// The intermediate values ``ChartFence`` accumulates while lexing a fence,
/// before a chart kind turns them into a typed ``ChartData``.
extension ChartFence {
    struct SourceLine {
        var number: Int
        var text: String
    }

    struct SeriesInput {
        var line: Int
        var name: String
        var payload: String
    }

    struct SliceInput {
        var line: Int
        var label: String
        var value: Double
    }

    /// The accumulated `key: value` fields of a chart fence.
    struct Fields {
        var kind: ChartKind?
        var title: String?
        var xLabel: String?
        var yLabel: String?
        var categories: [String] = []
        var xValues: [Double]?
        var series: [SeriesInput] = []
        var slices: [SliceInput] = []
    }
}
