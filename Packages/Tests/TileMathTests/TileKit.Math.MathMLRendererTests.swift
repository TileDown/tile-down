import Testing
import TileCore
@testable import TileMath

@Suite("MathML renderer")
struct MathMLRendererTests {
    private let renderer = TileKit.Math.MathMLRenderer()

    private func html(_ tex: String, display: Bool = true) -> String {
        renderer.rendered(tex: tex, display: display)?.html ?? ""
    }

    @Test("display math is a block math element")
    func displayWrapper() {
        let out = html("x")
        #expect(out.hasPrefix("<math "))
        #expect(out.contains("display=\"block\""))
        #expect(out.contains("class=\"td-math td-math-display\""))
        #expect(out.contains("</math>"))
    }

    @Test("inline math omits the block display attribute")
    func inlineWrapper() {
        let out = html("x", display: false)
        #expect(!out.contains("display=\"block\""))
        #expect(out.contains("td-math-inline"))
    }

    @Test("a superscript becomes msup")
    func superscript() {
        #expect(html("x^2").contains("<msup>"))
    }

    @Test("a subscript becomes msub")
    func subscriptToken() {
        #expect(html("x_i").contains("<msub>"))
    }

    @Test("a fraction becomes mfrac")
    func fraction() {
        #expect(html(#"\frac{a}{b}"#).contains("<mfrac>"))
    }

    @Test("a radical becomes msqrt")
    func radical() {
        #expect(html(#"\sqrt{2}"#).contains("<msqrt>"))
    }

    @Test("a number becomes mn and an identifier becomes mi")
    func tokenClasses() {
        let out = html("2x")
        #expect(out.contains("<mn>2</mn>"))
        #expect(out.contains("<mi>x</mi>"))
    }

    @Test("relational operators are XML-escaped inside mo")
    func escaping() {
        #expect(html("a < b").contains("&lt;"))
    }

    @Test("the renderer ships its page-local CSS")
    func css() {
        #expect(renderer.rendered(tex: "x", display: true)?.css.contains("math.td-math-display") == true)
    }

    @Test("unparsable input yields nil so it falls back to source")
    func malformedIsNil() {
        #expect(renderer.rendered(tex: #"\frac{a"#, display: true) == nil)
    }

    @Test("blank input yields nil")
    func blankIsNil() {
        #expect(renderer.rendered(tex: "   ", display: false) == nil)
    }
}
