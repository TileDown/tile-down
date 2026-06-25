import Foundation
import TileCore

/// Parses a Markdown ` ```chart ` fenced block into ``ChartData``.
///
/// The authoring syntax matches the sibling MarkdownPDF project so a document
/// moves between the two engines: `key: value` lines with `type`/`kind`,
/// `title`, `x-label`/`y-label`, `categories`, numeric `x`, repeatable
/// `series`/`points` (`Name = values`, or `Name = (x, y), ...` for scatter), and
/// `slice` (`Label = value`) entries. Blank lines and `#` comment lines are
/// ignored. Keys are case-insensitive. Lexing helpers live in the companion
/// `ChartFence.Lexing` file.
enum ChartFence {
    /// The fenced-code info string this parser claims.
    static let infoLanguage = "chart"

    static let maximumCategories = 12
    static let maximumPieSlices = 8
    static let maximumPointsPerSeries = 12
    static let maximumSeriesCount = 4

    static func parse(
        _ source: String,
    ) throws -> ChartData {
        let fields = try collectFields(source)
        guard let kind = fields.kind else {
            throw fenceError("chart type is required")
        }

        switch kind {
        case .pie, .doughnut:
            return try pieChart(fields, kind: kind)
        case .bar, .line:
            return try valueSeriesChart(fields, kind: kind)
        case .scatter:
            return try scatterChart(fields)
        }
    }

    private static func collectFields(
        _ source: String,
    ) throws -> Fields {
        var fields = Fields()
        for line in contentLines(source) {
            guard let split = splitKeyValue(line.text) else {
                throw fenceError(line, "expected `key: value`")
            }
            try apply(key: canonicalKey(split.key), value: split.value, line: line, to: &fields)
        }
        return fields
    }

    /// Collapses key spellings to a canonical form so the dispatch is one
    /// pattern per field: `kind` -> `type`, `category` -> `categories`,
    /// `points` -> `series`, and dashes/spaces removed (`x-label` -> `xlabel`).
    private static func canonicalKey(
        _ key: String,
    ) -> String {
        let normalized = key.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        return ["kind": "type", "category": "categories", "points": "series"][normalized] ?? normalized
    }

    private static func apply(
        key: String,
        value: String,
        line: SourceLine,
        to fields: inout Fields,
    ) throws {
        switch key {
        case "type":
            fields.kind = try parseKind(value, line: line)
        case "title":
            fields.title = sanitizedLabel(value)
        case "xlabel":
            fields.xLabel = sanitizedLabel(value)
        case "ylabel":
            fields.yLabel = sanitizedLabel(value)
        case "categories":
            fields.categories = splitList(value).map(sanitizedLabel)
        case "x":
            fields.xValues = try requireNumbers(value, line: line)
        case "series":
            try fields.series.append(parseSeriesInput(value, line: line))
        case "slice":
            try fields.slices.append(parseSliceInput(value, line: line))
        default:
            throw fenceError(line, "unknown chart key `\(key)`")
        }
    }

    private static func requireNumbers(
        _ value: String,
        line: SourceLine,
    ) throws -> [Double] {
        guard let values = parseNumberList(value) else {
            throw fenceError(line, "x values must be numbers")
        }
        return values
    }

    // MARK: - Chart builders

    private static func pieChart(
        _ fields: Fields,
        kind: ChartKind,
    ) throws -> ChartData {
        let resolved = try pieSlices(fields)
        guard resolved.count <= maximumPieSlices else {
            throw fenceError("too many pie slices (maximum \(maximumPieSlices))")
        }
        for slice in resolved where slice.label.isEmpty {
            throw fenceError(line: slice.line, "pie slice labels must not be empty")
        }
        for slice in resolved where slice.value <= 0 {
            throw TileKit.Tile.ChartRendererError.invalidPieValue(series: slice.label, value: slice.value)
        }
        guard resolved.reduce(0, { $0 + $1.value }) > 0 else {
            throw TileKit.Tile.ChartRendererError.zeroTotal(type: kind.rawValue)
        }

        return ChartData(
            kind: kind,
            title: fields.title,
            labels: resolved.map(\.label),
            series: [ChartSeries(name: "Slices", values: resolved.map(\.value))],
        )
    }

    private static func pieSlices(
        _ fields: Fields,
    ) throws -> [SliceInput] {
        if !fields.slices.isEmpty {
            return fields.slices
        }
        guard fields.series.count == 1 else {
            throw fenceError("pie charts need `slice:` entries or one value series")
        }
        let input = fields.series[0]
        guard !fields.categories.isEmpty else {
            throw fenceError(line: input.line, "pie value series require categories")
        }
        guard let values = parseNumberList(input.payload), values.count == fields.categories.count else {
            throw fenceError(line: input.line, "pie values must match the category count")
        }
        return zip(fields.categories, values).map { SliceInput(line: input.line, label: $0.0, value: $0.1) }
    }

    private static func valueSeriesChart(
        _ fields: Fields,
        kind: ChartKind,
    ) throws -> ChartData {
        guard !fields.series.isEmpty else {
            throw TileKit.Tile.ChartRendererError.missingSeries
        }
        guard fields.series.count <= maximumSeriesCount else {
            throw fenceError("too many series (maximum \(maximumSeriesCount))")
        }
        if kind == .bar, fields.xValues != nil {
            throw fenceError("bar charts do not support numeric x values")
        }
        if kind == .line, !fields.categories.isEmpty, fields.xValues != nil {
            throw fenceError("line charts cannot combine categories and numeric x values")
        }

        let series = try resolveValueSeries(fields)
        let count = series.first?.values.count ?? 0
        let labels = try resolveLabels(fields, count: count)
        return ChartData(
            kind: kind,
            title: fields.title,
            labels: labels,
            series: series,
            xLabel: fields.xLabel,
            yLabel: fields.yLabel,
        )
    }

    private static func resolveValueSeries(
        _ fields: Fields,
    ) throws -> [ChartSeries] {
        var resolved: [ChartSeries] = []
        var expectedCount: Int?
        for input in fields.series {
            guard let values = parseNumberList(input.payload), !values.isEmpty else {
                throw fenceError(line: input.line, "series values must be numbers")
            }
            if let expectedCount, values.count != expectedCount {
                throw fenceError(line: input.line, "every series must have the same value count")
            }
            expectedCount = values.count
            guard values.count <= maximumPointsPerSeries else {
                throw fenceError(line: input.line, "too many points (maximum \(maximumPointsPerSeries))")
            }
            if let xValues = fields.xValues {
                guard xValues.count == values.count else {
                    throw fenceError(line: input.line, "x values must match the series value count")
                }
                let points = zip(xValues, values).map { ChartPoint(xPosition: $0.0, yPosition: $0.1) }
                resolved.append(ChartSeries(name: input.name, values: values, points: points))
            } else {
                resolved.append(ChartSeries(name: input.name, values: values))
            }
        }
        return resolved
    }

    private static func resolveLabels(
        _ fields: Fields,
        count: Int,
    ) throws -> [String] {
        // A numeric `x:` axis (line charts only; bar rejects it earlier) carries
        // no category labels: the renderer positions points by their x value and
        // derives the axis ticks from the value range, like a scatter chart.
        if fields.xValues != nil {
            return []
        }
        if fields.categories.isEmpty {
            return (1 ... max(1, count)).map(String.init)
        }
        guard fields.categories.count == count else {
            throw fenceError("category count must match the series value count")
        }
        guard fields.categories.count <= maximumCategories else {
            throw fenceError("too many categories (maximum \(maximumCategories))")
        }
        return fields.categories
    }

    private static func scatterChart(
        _ fields: Fields,
    ) throws -> ChartData {
        guard !fields.series.isEmpty else {
            throw fenceError("scatter charts need at least one point series")
        }
        guard fields.categories.isEmpty, fields.xValues == nil else {
            throw fenceError("scatter charts use `(x, y)` pairs, not categories or x values")
        }
        guard fields.series.count <= maximumSeriesCount else {
            throw fenceError("too many series (maximum \(maximumSeriesCount))")
        }

        var resolved: [ChartSeries] = []
        for input in fields.series {
            guard let points = parsePointList(input.payload), !points.isEmpty else {
                throw fenceError(line: input.line, "scatter series must use `(x, y)` pairs")
            }
            guard points.count <= maximumPointsPerSeries else {
                throw fenceError(line: input.line, "too many points (maximum \(maximumPointsPerSeries))")
            }
            resolved.append(ChartSeries(name: input.name, values: points.map(\.yPosition), points: points))
        }

        return ChartData(
            kind: .scatter,
            title: fields.title,
            labels: [],
            series: resolved,
            xLabel: fields.xLabel,
            yLabel: fields.yLabel,
        )
    }

    // MARK: - Errors

    static func fenceError(
        _ message: String,
    ) -> TileKit.Tile.ChartRendererError {
        .fenceSyntax(line: nil, message: message)
    }

    static func fenceError(
        _ line: SourceLine,
        _ message: String,
    ) -> TileKit.Tile.ChartRendererError {
        .fenceSyntax(line: line.number, message: message)
    }

    static func fenceError(
        line: Int,
        _ message: String,
    ) -> TileKit.Tile.ChartRendererError {
        .fenceSyntax(line: line, message: message)
    }
}
