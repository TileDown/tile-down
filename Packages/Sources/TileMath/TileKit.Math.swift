import MathTypeset
import TileCore

public extension TileKit {
    /// Math typesetting: renders TeX recognized from Markdown into SVG plus hidden
    /// MathML, built on the shared `MathTypeset` engine. The renderer conforms to
    /// ``TileKit/MathRendering`` and is wired by the composition root, so the
    /// Markdown layer stays free of the engine.
    enum Math {}
}

public extension TileKit.Math {
    /// Renders TeX to the renderer's markup (a themed SVG plus a hidden MathML
    /// companion) using a caller-supplied font, for hosts without bundle resources
    /// such as WebAssembly. Returns `nil` if the font or the formula cannot be
    /// parsed. `display` selects display versus inline style.
    static func svgMarkup(
        forTeX tex: String,
        display: Bool,
        fontBytes: [UInt8],
    ) -> String? {
        guard let font = try? Font(bytes: fontBytes) else {
            return nil
        }
        return SVGRenderer(font: font).rendered(tex: tex, display: display)?.html
    }
}
