import Foundation

extension ChartSVGRenderer {
    /// Renders a scatter chart. When the series carry explicit `(x, y)` points
    /// (the Markdown ` ```chart ` fence) it plots them on a numeric x-axis; when
    /// they do not (the property-authored chart tile, which has only value
    /// series) it falls back to the category-indexed point path.
    func scatter(
        _ data: ChartData,
    ) -> String {
        guard data.series.contains(where: { $0.points?.isEmpty == false }) else {
            return cartesian(data, marks: lines(data, range: valueRange(data), pointsOnly: true))
        }

        let plotWidth = width - left - right
        let plotHeight = Double(data.height) - top - bottom
        let xRange = pointRange(data.series.flatMap { $0.points ?? [] }.map(\.xPosition))
        let yRange = valueRange(data)
        let zeroY = yPosition(0, range: yRange, plotHeight: plotHeight)

        return """
        \(svgStart(height: data.height, ariaLabel: ariaLabel(data)))
        <desc>\(escapeHTML(description(data)))</desc>
        \(gridLines(range: yRange, plotHeight: plotHeight))
        \(line(className: "td-chart-axis", startX: left, startY: zeroY, endX: width - right, endY: zeroY))
        \(line(className: "td-chart-axis", startX: left, startY: top, endX: left, endY: Double(data.height) - bottom))
        \(scatterXAxis(xRange: xRange, plotWidth: plotWidth, height: data.height))
        \(scatterMarks(data, xRange: xRange, yRange: yRange, plotWidth: plotWidth, plotHeight: plotHeight))
        \(axisCaptions(data))
        \(legend(data))
        </svg>
        """
    }

    private func scatterMarks(
        _ data: ChartData,
        xRange: ClosedRange<Double>,
        yRange: ClosedRange<Double>,
        plotWidth: Double,
        plotHeight: Double,
    ) -> String {
        data.series.enumerated().map { seriesIndex, series in
            (series.points ?? []).map { point in
                let placed = ChartPoint(
                    xPosition: left + normalized(point.xPosition, in: xRange) * plotWidth,
                    yPosition: yPosition(point.yPosition, range: yRange, plotHeight: plotHeight),
                )
                return pointCircle(seriesIndex: seriesIndex, point: placed)
            }.joined(separator: "\n")
        }.joined(separator: "\n")
    }

    private func scatterXAxis(
        xRange: ClosedRange<Double>,
        plotWidth: Double,
        height: Int,
    ) -> String {
        let ticks = [xRange.lowerBound, (xRange.lowerBound + xRange.upperBound) / 2, xRange.upperBound]
        return ticks.map { value in
            let xPosition = left + normalized(value, in: xRange) * plotWidth
            return text(formatValue(value), xPosition: xPosition, yPosition: Double(height) - 22, anchor: "middle")
        }.joined(separator: "\n")
    }

    /// A non-degenerate range over the point x-values, widening a single value so
    /// scaling never divides by zero.
    private func pointRange(
        _ values: [Double],
    ) -> ClosedRange<Double> {
        let lower = values.min() ?? 0
        var upper = values.max() ?? 1
        if lower == upper {
            upper += 1
        }
        return lower ... upper
    }

    private func normalized(
        _ value: Double,
        in range: ClosedRange<Double>,
    ) -> Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}
