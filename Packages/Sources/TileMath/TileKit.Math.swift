import MathTypeset
import TileCore

public extension TileKit {
    /// Math typesetting: renders TeX recognized from Markdown into SVG plus hidden
    /// MathML, built on the shared `MathTypeset` engine. The renderer conforms to
    /// ``TileKit/MathRendering`` and is wired by the composition root, so the
    /// Markdown layer stays free of the engine.
    enum Math {}
}
