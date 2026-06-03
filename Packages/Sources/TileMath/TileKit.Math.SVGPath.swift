import TileCore

extension TileKit.Math {
    /// Encodes a glyph outline as an SVG `path` `d` string. The outline is in font
    /// units, y-up; this scales it and flips into the SVG's y-down space, placing
    /// the glyph at `originX` (its left pen position, in points) on the baseline
    /// `baselineY` (the SVG y of the formula baseline, in points).
    enum SVGPath {
        static func data(
            for outline: TileKit.Math.GlyphOutline,
            scale: Double,
            originX: Double,
            baselineY: Double,
        ) -> String {
            func mapped(_ point: TileKit.Math.Point) -> String {
                let svgX = originX + point.xPosition * scale
                let svgY = baselineY - point.yPosition * scale
                return "\(number(svgX)) \(number(svgY))"
            }
            var data = ""
            for element in outline.elements {
                switch element {
                case let .move(point):
                    data += "M\(mapped(point))"
                case let .line(point):
                    data += "L\(mapped(point))"
                case let .curve(control1, control2, end):
                    data += "C\(mapped(control1)) \(mapped(control2)) \(mapped(end))"
                case .close:
                    data += "Z"
                }
            }
            return data
        }

        /// Formats a coordinate compactly: rounded to two decimals, trailing zeros
        /// and a trailing point trimmed, locale-independent.
        static func number(
            _ value: Double,
        ) -> String {
            let rounded = (value * 100).rounded() / 100
            if rounded == rounded.rounded() {
                return String(Int(rounded))
            }
            var text = String(format: "%.2f", locale: nil, rounded)
            while text.hasSuffix("0") {
                text.removeLast()
            }
            if text.hasSuffix(".") {
                text.removeLast()
            }
            return text
        }
    }
}
