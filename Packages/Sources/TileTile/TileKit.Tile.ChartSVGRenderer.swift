import Foundation

struct ChartSVGRenderer {
    let width = 720.0
    let left = 58.0
    let right = 24.0
    let top = 24.0
    let bottom = 58.0

    func render(
        _ data: ChartData,
    ) -> String {
        let svg = switch data.kind {
        case .bar:
            cartesian(data, marks: bars(data, range: valueRange(data)))
        case .line:
            cartesian(data, marks: lines(data, range: valueRange(data), pointsOnly: false))
        case .scatter:
            cartesian(data, marks: lines(data, range: valueRange(data), pointsOnly: true))
        case .pie:
            radial(data, holeRatio: 0)
        case .doughnut:
            radial(data, holeRatio: 0.52)
        }

        let caption = data.title.map {
            "\n<figcaption class=\"td-chart-caption\">\(escapeHTML($0))</figcaption>"
        } ?? ""
        return """
        <figure class="td-chart td-chart-\(data.kind.rawValue)">\(caption)
        <div class="td-chart-frame">
        \(svg)
        </div>
        </figure>
        """
    }

    func ariaLabel(
        _ data: ChartData,
    ) -> String {
        escapeAttribute(data.title ?? "\(data.kind.rawValue.capitalized) chart")
    }

    func description(
        _ data: ChartData,
    ) -> String {
        "\(data.kind.rawValue) chart with \(data.labels.count) labels and \(data.series.count) series"
    }
}
