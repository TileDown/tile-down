import Foundation

extension ChartSVGRenderer {
    func legend(
        _ data: ChartData,
    ) -> String {
        guard data.showsLegend else {
            return ""
        }
        return legend(labels: data.series.map(\.name), height: data.height)
    }

    func legend(
        labels: [String],
        height: Int,
    ) -> String {
        let placements = legendPlacements(labels)
        let rows = (placements.map(\.row).max() ?? 0) + 1
        let baseY = Double(height) - 12
        return placements.enumerated().map { index, placement in
            // Rows stack upward from the baseline so the last row sits at baseY.
            let yPosition = baseY - Double(rows - 1 - placement.row) * Self.legendLineHeight
            let labelNode = text(
                placement.label,
                xPosition: placement.xPosition + 18,
                yPosition: yPosition,
                anchor: "start",
                className: "td-chart-legend-text",
            )
            return """
            <rect
              class="td-chart-series-\(index % 6)"
              x="\(format(placement.xPosition))"
              y="\(format(yPosition - 10))"
              width="12"
              height="12"
              rx="3"
              fill="currentColor"
            ></rect>
            \(labelNode)
            """
        }.joined(separator: "\n")
    }

    static let legendLineHeight = 22.0

    /// The y-positions and total SVG height for the stack below a cartesian or
    /// scatter plot: an axis-labels row, then the legend rows, then an optional
    /// x-axis caption, each a full line apart so they never collide. The canvas
    /// grows to contain the lowest band instead of cramming them into the margin.
    struct BottomStack {
        var axisY: Double
        var legendBaseY: Double
        var captionY: Double
        var height: Int
    }

    func bottomStack(
        _ data: ChartData,
        legendLabels: [String],
    ) -> BottomStack {
        let line = Self.legendLineHeight
        let plotBottom = Double(data.height) - bottom
        let axisY = plotBottom + line
        let legendRows = data.showsLegend && !legendLabels.isEmpty ? legendRowCount(legendLabels) : 0
        let legendBaseY = legendRows > 0 ? axisY + line + Double(legendRows - 1) * line : axisY
        let belowLegend = legendRows > 0 ? legendBaseY : axisY
        let hasCaption = data.xLabel?.isEmpty == false
        let captionY = belowLegend + line
        let lowest = hasCaption ? captionY : belowLegend
        return BottomStack(axisY: axisY, legendBaseY: legendBaseY, captionY: captionY, height: Int(lowest + 14))
    }

    /// Packs legend entries left to right by measured label width, wrapping to a
    /// new row when the next entry would overflow the plot width. Fixes the
    /// overlap that fixed-width columns caused for long series or slice names.
    struct LegendPlacement {
        var label: String
        var xPosition: Double
        var row: Int
    }

    func legendPlacements(
        _ labels: [String],
    ) -> [LegendPlacement] {
        let maxX = width - right
        var placements: [LegendPlacement] = []
        var xCursor = left
        var row = 0
        for label in labels {
            // 18: swatch width plus gap before the label. 18: trailing gap.
            let itemWidth = 18 + estimatedTextWidth(label, fontSize: 13) + 18
            if xCursor > left, xCursor + itemWidth > maxX {
                row += 1
                xCursor = left
            }
            placements.append(LegendPlacement(label: label, xPosition: xCursor, row: row))
            xCursor += itemWidth
        }
        return placements
    }

    /// The number of rows the wrapped legend occupies, so the renderer can grow
    /// the canvas to fit instead of clipping or overlapping the plot.
    func legendRowCount(
        _ labels: [String],
    ) -> Int {
        (legendPlacements(labels).map(\.row).max() ?? 0) + 1
    }

    /// Estimates the rendered width of a text run without a font metrics table,
    /// using per-character advance classes generous enough to prevent overlap.
    /// Good enough for legend packing and axis-room decisions in static SVG.
    func estimatedTextWidth(
        _ text: String,
        fontSize: Double,
    ) -> Double {
        var advance = 0.0
        for character in text {
            switch character {
            case "i", "j", "l", "I", "t", "f", "r", ".", ",", ":", ";", "'", "|", "!", "(", ")", "[", "]", " ":
                advance += 0.32
            case "m", "M", "W", "w", "@", "%":
                advance += 0.92
            case "A" ... "Z":
                advance += 0.68
            default:
                advance += 0.55
            }
        }
        return advance * fontSize
    }

    func svgStart(
        height: Int,
        ariaLabel: String,
    ) -> String {
        """
        <svg
          class="td-chart-svg"
          viewBox="0 0 \(format(width)) \(height)"
          role="img"
          aria-label="\(ariaLabel)"
        >
        """
    }

    func line(
        className: String,
        startX: Double,
        startY: Double,
        endX: Double,
        endY: Double,
    ) -> String {
        """
        <line
          class="\(className)"
          x1="\(format(startX))"
          y1="\(format(startY))"
          x2="\(format(endX))"
          y2="\(format(endY))"
        ></line>
        """
    }

    func text(
        _ value: String,
        xPosition: Double,
        yPosition: Double,
        anchor: String,
        className: String = "td-chart-label",
    ) -> String {
        """
        <text
          class="\(className)"
          x="\(format(xPosition))"
          y="\(format(yPosition))"
          text-anchor="\(anchor)"
        >\(escapeHTML(value))</text>
        """
    }

    func formatValue(
        _ value: Double,
    ) -> String {
        format(value)
    }

    func format(
        _ value: Double,
    ) -> String {
        let formatted = String(format: "%.2f", value)
        return formatted
            .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
    }

    /// A native SVG `<title>` child, shown as a browser tooltip on hover. Empty
    /// for unlabelled marks. This is the zero-JavaScript hover affordance.
    func markTitle(
        _ text: String,
    ) -> String {
        text.isEmpty ? "" : "<title>\(escapeHTML(text))</title>"
    }

    /// The hover tooltip text for a cartesian mark: `label: value`, prefixed with
    /// the series name when more than one series shares the plot.
    func tooltipText(
        _ data: ChartData,
        seriesIndex: Int,
        index: Int,
        value: Double,
    ) -> String {
        let label = data.labels.indices.contains(index) ? data.labels[index] : ""
        let head = label.isEmpty ? formatValue(value) : "\(label): \(formatValue(value))"
        guard data.series.count > 1, data.series.indices.contains(seriesIndex) else {
            return head
        }
        return "\(data.series[seriesIndex].name), \(head)"
    }

    func escapeHTML(
        _ value: String,
    ) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    func escapeAttribute(
        _ value: String,
    ) -> String {
        escapeHTML(value)
    }
}
