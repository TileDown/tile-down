import MathTypeset
import TileCore

public extension TileKit.Math {
    /// A ``TileKit/MathRendering`` that parses TeX with the shared `MathTypeset`
    /// engine and emits MathML Core, which modern browsers render natively (no
    /// bundled font, no runtime script). It returns `nil` for input the parser
    /// rejects, so a malformed formula degrades to its escaped source rather than
    /// disappearing.
    ///
    /// This is the semantic layer of math support. The forthcoming SVG renderer
    /// uses the engine's positioned `MathBox` for pixel-consistent visuals and
    /// keeps this MathML as the accessible, visually hidden companion.
    struct MathMLRenderer: TileKit.MathRendering {
        public init() {}

        public func rendered(
            tex: String,
            display: Bool,
        ) -> TileKit.FencedBlock? {
            let trimmed = tex.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let parsed = try? MathParser().parse(trimmed)
            else {
                return nil
            }
            let body = MathMLWriter().mathML(parsed.root)
            let displayAttr = display ? " display=\"block\"" : ""
            let kind = display ? "td-math-display" : "td-math-inline"
            let html = "<math xmlns=\"http://www.w3.org/1998/Math/MathML\""
                + "\(displayAttr) class=\"td-math \(kind)\">\(body)</math>"
            return .init(html: html, css: Self.css)
        }

        /// Page-local styling. Display math is centered and scrolls horizontally
        /// when it overflows a narrow column; inline math stays on the baseline.
        static let css = """
        math.td-math { font-size: 1.05em; }
        math.td-math-display { display: block; margin: 1.1rem 0; text-align: center; overflow-x: auto; }
        math.td-math-inline { display: inline-block; }
        """
    }
}
