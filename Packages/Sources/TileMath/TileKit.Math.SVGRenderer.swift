import MathTypeset
import TileCore

public extension TileKit.Math {
    /// A ``TileKit/MathRendering`` that typesets TeX into self-contained SVG using
    /// the shared `MathTypeset` layout and glyph outlines extracted from the
    /// vendored font. Glyphs are drawn as `<path>` and rules as `<rect>` at the
    /// engine's exact coordinates, so the result renders identically in every
    /// browser with no shipped font or runtime script. Fill is `currentColor`, so
    /// the math follows the surrounding text color in light and dark themes. A
    /// visually hidden MathML companion carries the accessible, copyable form.
    struct SVGRenderer: TileKit.MathRendering {
        /// The point size the layout runs at. Output dimensions are expressed in
        /// `em` relative to this, so the math scales with the surrounding text.
        static let baseSize = 10.0

        /// A font supplied by the caller (for hosts without bundle resources, such
        /// as WebAssembly). When `nil` the bundled Latin Modern Math font is used.
        private let injectedFont: TileKit.Math.Font?

        public init() {
            injectedFont = nil
        }

        init(font: TileKit.Math.Font) {
            injectedFont = font
        }

        public func rendered(
            tex: String,
            display: Bool,
        ) -> TileKit.FencedBlock? {
            let trimmed = tex.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let font = injectedFont ?? TileKit.Math.Font.latinModern,
                  let parsed = try? MathParser().parse(trimmed),
                  let box = laidOut(parsed.root, font: font, display: display)
            else {
                return nil
            }
            let svg = svg(for: box, font: font)
            let mathML = MathMLWriter().mathML(parsed.root)
            let tag = display ? "div" : "span"
            let kind = display ? "td-math-display" : "td-math-inline"
            let html = "<\(tag) class=\"td-math \(kind)\">\(svg)"
                + "<math class=\"td-math-a11y\" xmlns=\"http://www.w3.org/1998/Math/MathML\">\(mathML)</math>"
                + "</\(tag)>"
            return .init(html: html, css: Self.css)
        }

        private func laidOut(
            _ node: MathNode,
            font: TileKit.Math.Font,
            display: Bool,
        ) -> MathBox? {
            let layout = MathLayout(
                font: .regular,
                color: .black,
                measureText: { run in font.advance(of: run.text, size: run.size) },
                metrics: font.metrics,
            )
            return try? layout.layout(node, size: Self.baseSize, displayStyle: display)
        }

        /// The `<svg>` element for a laid-out box. The viewBox is in points with
        /// the baseline at `box.height` from the top; width/height are in `em` so
        /// the formula scales with font size, and inline math is shifted down by
        /// its depth so its baseline sits on the text baseline.
        private func svg(
            for box: MathBox,
            font: TileKit.Math.Font,
        ) -> String {
            let total = box.height + box.depth
            let body = box.elements.map { element in
                self.element(element, baselineY: box.height, font: font)
            }.joined()
            let widthEm = SVGPath.number(box.width / Self.baseSize)
            let heightEm = SVGPath.number(total / Self.baseSize)
            let depthEm = SVGPath.number(box.depth / Self.baseSize)
            let viewBox = "0 0 \(SVGPath.number(box.width)) \(SVGPath.number(total))"
            return "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"\(viewBox)\""
                + " fill=\"currentColor\" aria-hidden=\"true\""
                + " style=\"width:\(widthEm)em;height:\(heightEm)em;vertical-align:-\(depthEm)em\">"
                + body + "</svg>"
        }

        private func element(
            _ element: MathLayoutElement,
            baselineY: Double,
            font: TileKit.Math.Font,
        ) -> String {
            switch element {
            case let .text(run, posX, posY):
                glyphs(run: run, originX: posX, baseline: baselineY - posY, font: font)
            case let .rule(posX, posY, width, height, _):
                "<rect x=\"\(SVGPath.number(posX))\" y=\"\(SVGPath.number(baselineY - posY - height))\""
                    + " width=\"\(SVGPath.number(width))\" height=\"\(SVGPath.number(height))\"/>"
            case let .line(startX, startY, endX, endY, thickness, _):
                // A diagonal stroke (the scaling radical sign). Flip y the same way.
                "<line x1=\"\(SVGPath.number(startX))\" y1=\"\(SVGPath.number(baselineY - startY))\""
                    + " x2=\"\(SVGPath.number(endX))\" y2=\"\(SVGPath.number(baselineY - endY))\""
                    + " stroke=\"currentColor\" stroke-width=\"\(SVGPath.number(thickness))\""
                    + " stroke-linejoin=\"miter\" stroke-linecap=\"butt\"/>"
            }
        }

        /// The `<path>` elements for one positioned text run, laying its glyphs out
        /// left to right by their advances (the same measurement the layout used).
        private func glyphs(
            run: MathRun,
            originX: Double,
            baseline: Double,
            font: TileKit.Math.Font,
        ) -> String {
            let scale = run.size / font.unitsPerEm
            var penX = originX
            var paths = ""
            for scalar in run.text.unicodeScalars {
                guard let glyph = font.glyphID(for: scalar) else { continue }
                if let outline = try? font.outline(glyphID: glyph), !outline.elements.isEmpty {
                    let data = SVGPath.data(for: outline, scale: scale, originX: penX, baselineY: baseline)
                    paths += "<path d=\"\(data)\"/>"
                }
                penX += Double((try? font.advanceWidth(glyphID: glyph)) ?? 0) * scale
            }
            return paths
        }

        static let css = """
        .td-math-svg, .td-math svg { display: inline-block; }
        /* Display math is sized in em, so it would otherwise render at body-text
           scale and read as tiny. Enlarge it for a proper display presence; inline
           math keeps its 1em so it sits on the text baseline. */
        .td-math-display { display: block; text-align: center; margin: 1.4rem 0; overflow-x: auto; font-size: 1.6em; }
        .td-math-display svg { vertical-align: middle; }
        .td-math-a11y {
            position: absolute; width: 1px; height: 1px;
            overflow: hidden; clip: rect(0 0 0 0); clip-path: inset(50%);
        }
        """
    }
}
