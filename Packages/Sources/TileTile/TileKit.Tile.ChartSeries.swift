import Foundation

struct ChartSeries: Equatable {
    var name: String
    var values: [Double]

    /// Explicit `(x, y)` coordinates for scatter series authored as point pairs.
    /// `nil` for category-indexed series (bar, line, and the property-authored
    /// chart tile), where `values` are plotted against the chart's labels.
    var points: [ChartPoint]?

    init(
        name: String,
        values: [Double],
        points: [ChartPoint]? = nil,
    ) {
        self.name = name
        self.values = values
        self.points = points
    }
}
