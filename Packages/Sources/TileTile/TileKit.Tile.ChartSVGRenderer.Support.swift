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
        let baseY = Double(height) - 12
        return labels.enumerated().map { index, label in
            let xPosition = left + Double(index % 4) * 150
            let yPosition = baseY - Double(index / 4) * 22
            let labelNode = text(
                label,
                xPosition: xPosition + 18,
                yPosition: yPosition,
                anchor: "start",
                className: "td-chart-legend-text",
            )
            return """
            <rect
              class="td-chart-series-\(index % 6)"
              x="\(format(xPosition))"
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
