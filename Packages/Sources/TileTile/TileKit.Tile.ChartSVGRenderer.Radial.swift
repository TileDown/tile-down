import Foundation

extension ChartSVGRenderer {
    func radial(
        _ data: ChartData,
        holeRatio: Double,
    ) -> String {
        let values = data.series[0].values
        let total = values.reduce(0, +)
        let geometry = ChartArcGeometry(
            centerX: width / 2,
            centerY: Double(data.height) / 2 - 8,
            radius: min(width, Double(data.height)) * 0.32,
            innerRadius: min(width, Double(data.height)) * 0.32 * holeRatio,
        )
        var angle = -Double.pi / 2
        let slices = values.enumerated().map { index, value in
            let nextAngle = angle + (value / total) * Double.pi * 2
            defer { angle = nextAngle }
            let label = data.labels.indices.contains(index) ? data.labels[index] : ""
            let percent = formatValue(value / total * 100)
            let title = label.isEmpty
                ? "\(formatValue(value)) (\(percent)%)"
                : "\(label): \(formatValue(value)) (\(percent)%)"
            return slice(
                index: index,
                geometry: geometry,
                start: angle,
                end: nextAngle,
                isFullCircle: values.count == 1,
                title: title,
            )
        }.joined(separator: "\n")
        let legendRows = data.showsLegend ? legendRowCount(data.labels) : 0
        let svgHeight = data.height + max(0, legendRows - 1) * Int(Self.legendLineHeight)
        let legend = data.showsLegend ? legend(labels: data.labels, height: svgHeight) : ""

        return """
        \(svgStart(height: svgHeight, ariaLabel: ariaLabel(data)))
        <desc>\(escapeHTML(description(data)))</desc>
        \(slices)
        \(legend)
        </svg>
        """
    }

    func slice(
        index: Int,
        geometry: ChartArcGeometry,
        start: Double,
        end: Double,
        isFullCircle: Bool,
        title: String = "",
    ) -> String {
        if isFullCircle, geometry.innerRadius == 0 {
            return """
            <circle
              class="td-chart-slice td-chart-series-\(index % 6)"
              cx="\(format(geometry.centerX))"
              cy="\(format(geometry.centerY))"
              r="\(format(geometry.radius))"
            >\(markTitle(title))</circle>
            """
        }
        if isFullCircle {
            return doughnutCircle(index: index, geometry: geometry, title: title)
        }

        let outerStart = polar(geometry.centerX, geometry.centerY, geometry.radius, start)
        let outerEnd = polar(geometry.centerX, geometry.centerY, geometry.radius, end)
        let largeArc = end - start > Double.pi ? 1 : 0
        guard geometry.innerRadius > 0 else {
            let pathData = [
                "M \(format(geometry.centerX)) \(format(geometry.centerY))",
                "L \(format(outerStart.xPosition)) \(format(outerStart.yPosition))",
                "A \(format(geometry.radius)) \(format(geometry.radius)) 0 \(largeArc) 1",
                "\(format(outerEnd.xPosition)) \(format(outerEnd.yPosition))",
                "Z",
            ].joined(separator: " ")
            return path(index: index, data: pathData, title: title)
        }

        let innerStart = polar(geometry.centerX, geometry.centerY, geometry.innerRadius, start)
        let innerEnd = polar(geometry.centerX, geometry.centerY, geometry.innerRadius, end)
        let pathData = [
            "M \(format(outerStart.xPosition)) \(format(outerStart.yPosition))",
            "A \(format(geometry.radius)) \(format(geometry.radius)) 0 \(largeArc) 1",
            "\(format(outerEnd.xPosition)) \(format(outerEnd.yPosition))",
            "L \(format(innerEnd.xPosition)) \(format(innerEnd.yPosition))",
            "A \(format(geometry.innerRadius)) \(format(geometry.innerRadius)) 0 \(largeArc) 0",
            "\(format(innerStart.xPosition)) \(format(innerStart.yPosition))",
            "Z",
        ].joined(separator: " ")
        return path(index: index, data: pathData)
    }

    func polar(
        _ centerX: Double,
        _ centerY: Double,
        _ radius: Double,
        _ angle: Double,
    ) -> ChartPoint {
        .init(
            xPosition: centerX + radius * cos(angle),
            yPosition: centerY + radius * sin(angle),
        )
    }

    private func path(
        index: Int,
        data: String,
        title: String = "",
    ) -> String {
        """
        <path
          class="td-chart-slice td-chart-series-\(index % 6)"
          d="\(data)"
        >\(markTitle(title))</path>
        """
    }

    private func doughnutCircle(
        index: Int,
        geometry: ChartArcGeometry,
        title: String = "",
    ) -> String {
        """
        <circle
          class="td-chart-slice td-chart-series-\(index % 6)"
          cx="\(format(geometry.centerX))"
          cy="\(format(geometry.centerY))"
          r="\(format(geometry.radius))"
        >\(markTitle(title))</circle>
        <circle
          cx="\(format(geometry.centerX))"
          cy="\(format(geometry.centerY))"
          r="\(format(geometry.innerRadius))"
          fill="var(--td-surface)"
        ></circle>
        """
    }
}

struct ChartArcGeometry {
    var centerX: Double
    var centerY: Double
    var radius: Double
    var innerRadius: Double
}
