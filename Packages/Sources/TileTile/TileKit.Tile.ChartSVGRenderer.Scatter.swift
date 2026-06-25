import Foundation

extension ChartSVGRenderer {
    /// True when a chart's series carry explicit numeric `(x, y)` points (the
    /// Markdown ` ```chart ` fence's scatter pairs or a line chart's numeric
    /// `x:` axis), so it can be drawn on a real numeric x-axis. Property-authored
    /// chart tiles carry only value series and report `false`.
    func hasNumericPoints(
        _ data: ChartData,
    ) -> Bool {
        data.series.contains { ($0.points?.isEmpty == false) }
    }

    /// Renders a scatter chart. With explicit numeric points it plots them on a
    /// numeric x-axis; without them it falls back to the category-indexed point
    /// path used by the property-authored chart tile.
    func scatter(
        _ data: ChartData,
    ) -> String {
        guard hasNumericPoints(data) else {
            return cartesian(data, marks: lines(data, range: valueRange(data), pointsOnly: true))
        }
        return pointPlot(data, connect: false)
    }

    /// Plots series of numeric `(x, y)` points on a shared numeric x-axis and the
    /// usual value y-axis. `connect` draws a polyline through each series' points
    /// in source order (the line chart authored with a numeric `x:` axis); without
    /// it only the point markers are drawn (scatter). Both position points by
    /// their x value rather than by index, matching the PDF renderer.
    func pointPlot(
        _ data: ChartData,
        connect: Bool,
    ) -> String {
        let plotWidth = width - left - right
        let plotHeight = Double(data.height) - top - bottom
        let xRange = pointRange(data.series.flatMap { $0.points ?? [] }.map(\.xPosition))
        let yRange = valueRange(data)
        let zeroY = yPosition(0, range: yRange, plotHeight: plotHeight)
        let stack = bottomStack(data, legendLabels: data.series.map(\.name))
        let legendNodes = data.showsLegend
            ? legend(labels: data.series.map(\.name), height: Int(stack.legendBaseY + 12))
            : ""

        return """
        \(svgStart(height: stack.height, ariaLabel: ariaLabel(data)))
        <desc>\(escapeHTML(description(data)))</desc>
        \(gridLines(range: yRange, plotHeight: plotHeight))
        \(line(className: "td-chart-axis", startX: left, startY: zeroY, endX: width - right, endY: zeroY))
        \(line(className: "td-chart-axis", startX: left, startY: top, endX: left, endY: Double(data.height) - bottom))
        \(numericXAxis(xRange: xRange, plotWidth: plotWidth, axisY: stack.axisY))
        \(pointMarks(data, xRange: xRange, yRange: yRange, plotWidth: plotWidth, plotHeight: plotHeight, connect: connect))
        \(axisCaptions(data, captionY: stack.captionY))
        \(legendNodes)
        </svg>
        """
    }

    private func pointMarks(
        _ data: ChartData,
        xRange: ClosedRange<Double>,
        yRange: ClosedRange<Double>,
        plotWidth: Double,
        plotHeight: Double,
        connect: Bool,
    ) -> String {
        data.series.enumerated().map { seriesIndex, series in
            let sourcePoints = series.points ?? []
            let placed = sourcePoints.map { point in
                ChartPoint(
                    xPosition: left + normalized(point.xPosition, in: xRange) * plotWidth,
                    yPosition: yPosition(point.yPosition, range: yRange, plotHeight: plotHeight),
                )
            }
            let circles = zip(sourcePoints, placed).map { source, placedPoint in
                pointCircle(
                    seriesIndex: seriesIndex,
                    point: placedPoint,
                    title: "\(series.name): (\(format(source.xPosition)), \(format(source.yPosition)))",
                )
            }.joined(separator: "\n")
            guard connect, placed.count > 1 else {
                return circles
            }
            let path = placed.map { "\(format($0.xPosition)),\(format($0.yPosition))" }
                .joined(separator: " ")
            return """
            <polyline class="td-chart-line td-chart-series-\(seriesIndex % 6)" points="\(path)"></polyline>
            \(circles)
            """
        }.joined(separator: "\n")
    }

    /// Three numeric ticks (low, mid, high) placed by value along the x-axis,
    /// shared by scatter and the numeric-x line chart.
    func numericXAxis(
        xRange: ClosedRange<Double>,
        plotWidth: Double,
        axisY: Double,
    ) -> String {
        let ticks = [xRange.lowerBound, (xRange.lowerBound + xRange.upperBound) / 2, xRange.upperBound]
        return ticks.map { value in
            let xPosition = left + normalized(value, in: xRange) * plotWidth
            return text(formatValue(value), xPosition: xPosition, yPosition: axisY, anchor: "middle")
        }.joined(separator: "\n")
    }

    /// A non-degenerate range over the point x-values, widening a single value so
    /// scaling never divides by zero.
    func pointRange(
        _ values: [Double],
    ) -> ClosedRange<Double> {
        let lower = values.min() ?? 0
        var upper = values.max() ?? 1
        if lower == upper {
            upper += 1
        }
        return lower ... upper
    }

    func normalized(
        _ value: Double,
        in range: ClosedRange<Double>,
    ) -> Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}
