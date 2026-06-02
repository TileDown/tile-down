import Foundation

extension ChartSVGRenderer {
    func cartesian(
        _ data: ChartData,
        marks: String,
    ) -> String {
        let range = valueRange(data)
        let plot = ChartPlot(
            labels: data.labels.count,
            plotWidth: width - left - right,
            plotHeight: Double(data.height) - top - bottom,
            range: range,
        )
        let zeroY = yPosition(0, range: range, plotHeight: plot.plotHeight)
        let labelNodes = data.labels.enumerated().map { index, label in
            let labelX = left + (Double(index) + 0.5) * plot.plotWidth / Double(data.labels.count)
            return text(label, xPosition: labelX, yPosition: Double(data.height) - 22, anchor: "middle")
        }.joined(separator: "\n")

        let horizontalAxis = line(
            className: "td-chart-axis",
            startX: left,
            startY: zeroY,
            endX: width - right,
            endY: zeroY,
        )
        let verticalAxis = line(
            className: "td-chart-axis",
            startX: left,
            startY: top,
            endX: left,
            endY: Double(data.height) - bottom,
        )

        return """
        \(svgStart(height: data.height, ariaLabel: ariaLabel(data)))
        <desc>\(escapeHTML(description(data)))</desc>
        \(gridLines(range: range, plotHeight: plot.plotHeight))
        \(horizontalAxis)
        \(verticalAxis)
        \(marks)
        \(labelNodes)
        \(axisCaptions(data))
        \(legend(data))
        </svg>
        """
    }

    /// The optional x-axis and y-axis captions, when supplied (the Markdown
    /// ` ```chart ` fence sets them; the property-authored chart tile does not).
    /// The y caption is rotated up the left margin; the x caption sits centered
    /// below the plot.
    func axisCaptions(
        _ data: ChartData,
    ) -> String {
        var nodes: [String] = []
        let plotWidth = width - left - right
        if let xLabel = data.xLabel, !xLabel.isEmpty {
            nodes.append(text(
                xLabel,
                xPosition: left + plotWidth / 2,
                yPosition: Double(data.height) - 2,
                anchor: "middle",
            ))
        }
        if let yLabel = data.yLabel, !yLabel.isEmpty {
            let midY = top + (Double(data.height) - top - bottom) / 2
            nodes.append("""
            <text
              class="td-chart-label"
              x="16"
              y="\(format(midY))"
              text-anchor="middle"
              transform="rotate(-90 16 \(format(midY)))"
            >\(escapeHTML(yLabel))</text>
            """)
        }
        return nodes.joined(separator: "\n")
    }

    func bars(
        _ data: ChartData,
        range: ClosedRange<Double>,
    ) -> String {
        let plotHeight = Double(data.height) - top - bottom
        let plotWidth = width - left - right
        let groupWidth = plotWidth / Double(data.labels.count)
        let barWidth = min(34, max(3, (groupWidth * 0.72) / Double(data.series.count)))
        let zeroY = yPosition(0, range: range, plotHeight: plotHeight)

        return data.series.enumerated().flatMap { seriesIndex, series in
            series.values.enumerated().map { valueIndex, value in
                let groupX = left + Double(valueIndex) * groupWidth
                let offset = (groupWidth - barWidth * Double(data.series.count)) / 2
                let barX = groupX + offset + Double(seriesIndex) * barWidth
                let valueY = yPosition(value, range: range, plotHeight: plotHeight)
                return bar(
                    seriesIndex: seriesIndex,
                    xPosition: barX,
                    yPosition: min(valueY, zeroY),
                    width: barWidth - 2,
                    height: abs(zeroY - valueY),
                    title: tooltipText(data, seriesIndex: seriesIndex, index: valueIndex, value: value),
                )
            }
        }.joined(separator: "\n")
    }

    func lines(
        _ data: ChartData,
        range: ClosedRange<Double>,
        pointsOnly: Bool,
    ) -> String {
        let plot = ChartPlot(
            labels: data.labels.count,
            plotWidth: width - left - right,
            plotHeight: Double(data.height) - top - bottom,
            range: range,
        )
        return data.series.enumerated().map { seriesIndex, series in
            let points = series.values.enumerated().map { index, value in
                point(index: index, value: value, plot: plot)
            }
            let circles = series.values.enumerated().map { index, value in
                pointCircle(
                    seriesIndex: seriesIndex,
                    point: points[index],
                    title: tooltipText(data, seriesIndex: seriesIndex, index: index, value: value),
                )
            }.joined(separator: "\n")
            guard !pointsOnly else {
                return circles
            }
            let path = points.map { "\(format($0.xPosition)),\(format($0.yPosition))" }
                .joined(separator: " ")
            return """
            <polyline class="td-chart-line td-chart-series-\(seriesIndex % 6)" points="\(path)"></polyline>
            \(circles)
            """
        }.joined(separator: "\n")
    }

    func gridLines(
        range: ClosedRange<Double>,
        plotHeight: Double,
    ) -> String {
        let values = [range.lowerBound, (range.lowerBound + range.upperBound) / 2, range.upperBound]
        return values.map { value in
            let valueY = yPosition(value, range: range, plotHeight: plotHeight)
            let gridLine = line(
                className: "td-chart-grid",
                startX: left,
                startY: valueY,
                endX: width - right,
                endY: valueY,
            )
            let valueLabel = text(
                formatValue(value),
                xPosition: left - 10,
                yPosition: valueY + 4,
                anchor: "end",
                className: "td-chart-value",
            )
            return """
            \(gridLine)
            \(valueLabel)
            """
        }.joined(separator: "\n")
    }

    func yPosition(
        _ value: Double,
        range: ClosedRange<Double>,
        plotHeight: Double,
    ) -> Double {
        top + (range.upperBound - value) / (range.upperBound - range.lowerBound) * plotHeight
    }

    func valueRange(
        _ data: ChartData,
    ) -> ClosedRange<Double> {
        let values = data.series.flatMap(\.values)
        let lower = min(0, values.min() ?? 0)
        var upper = max(0, values.max() ?? 1)
        if lower == upper {
            upper += 1
        }
        return lower ... upper
    }

    private func bar(
        seriesIndex: Int,
        xPosition: Double,
        yPosition: Double,
        width: Double,
        height: Double,
        title: String = "",
    ) -> String {
        """
        <rect
          class="td-chart-bar td-chart-series-\(seriesIndex % 6)"
          x="\(format(xPosition))"
          y="\(format(yPosition))"
          width="\(format(width))"
          height="\(format(height))"
          rx="4"
        >\(markTitle(title))</rect>
        """
    }

    func pointCircle(
        seriesIndex: Int,
        point: ChartPoint,
        title: String = "",
    ) -> String {
        """
        <circle
          class="td-chart-point td-chart-series-\(seriesIndex % 6)"
          cx="\(format(point.xPosition))"
          cy="\(format(point.yPosition))"
          r="4"
        >\(markTitle(title))</circle>
        """
    }

    private func point(
        index: Int,
        value: Double,
        plot: ChartPlot,
    ) -> ChartPoint {
        let xPosition = left + (Double(index) + 0.5) * plot.plotWidth / Double(plot.labels)
        let yPosition = yPosition(value, range: plot.range, plotHeight: plot.plotHeight)
        return .init(xPosition: xPosition, yPosition: yPosition)
    }
}

private struct ChartPlot {
    var labels: Int
    var plotWidth: Double
    var plotHeight: Double
    var range: ClosedRange<Double>
}
