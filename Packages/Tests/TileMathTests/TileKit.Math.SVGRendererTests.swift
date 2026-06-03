import Testing
import TileCore
@testable import TileMath

@Suite("SVG math renderer")
struct SVGRendererTests {
    private let renderer = TileKit.Math.SVGRenderer()

    private func html(_ tex: String, display: Bool = true) -> String {
        renderer.rendered(tex: tex, display: display)?.html ?? ""
    }

    @Test("a glyph renders as an svg with a path and a viewBox")
    func singleGlyph() {
        let out = html("x")
        #expect(out.contains("<svg "))
        #expect(out.contains("viewBox="))
        #expect(out.contains("<path d=\"M"))
        #expect(out.contains("fill=\"currentColor\""))
        #expect(out.contains("em")) // dimensions are in em
    }

    @Test("a fraction draws the bar as a rect")
    func fractionBar() {
        #expect(html(#"\frac{a}{b}"#).contains("<rect "))
    }

    @Test("display math is a block, inline math a span shifted by its depth")
    func wrappers() {
        #expect(html("x", display: true).hasPrefix("<div class=\"td-math td-math-display\""))
        let inline = html("x", display: false)
        #expect(inline.hasPrefix("<span class=\"td-math td-math-inline\""))
        #expect(inline.contains("vertical-align:-"))
    }

    @Test("the accessible MathML companion is present and hidden")
    func accessibleCompanion() {
        let out = html(#"\sqrt{2}"#)
        #expect(out.contains("class=\"td-math-a11y\""))
        #expect(out.contains("<msqrt>"))
        #expect(out.contains("aria-hidden=\"true\"")) // the svg is hidden from SR; MathML is read
    }

    @Test("a radical draws its sign as scaling stroke lines")
    func radicalStrokes() {
        // MathTypeset 0.4.0 emits the radical sign as `.line` strokes that scale
        // with the radicand; the emitter renders them as <line stroke=...>.
        let out = html(#"\sqrt{x^2 + y^2}"#)
        #expect(out.contains("<line "))
        #expect(out.contains("stroke=\"currentColor\""))
    }

    @Test("unparsable input yields nil so it falls back to source")
    func malformedIsNil() {
        #expect(renderer.rendered(tex: #"\frac{a"#, display: true) == nil)
    }
}
