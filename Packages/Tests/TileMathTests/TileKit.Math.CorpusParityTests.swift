import Foundation
import Testing
import TileCore
import TileMarkdown
@testable import TileMath

/// Renders MarkdownPDF's own `math-formulas.md` witness corpus through Tiledown's
/// pipeline, so the two projects are held to the same TeX-math syntax. The fixture
/// is a verbatim copy of MarkdownPDF's witness; if a construct works there it must
/// at least parse and emit (or degrade) here without throwing.
@Suite("Math corpus parity (MarkdownPDF witness)")
struct CorpusParityTests {
    private func corpus() throws -> String {
        let url = try #require(Bundle.module.url(forResource: "math-formulas", withExtension: "md"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func render(_ markdown: String) -> String {
        TileKit.Markdown.CommonMarkRenderer(mathRenderer: TileKit.Math.MathMLRenderer())
            .renderHTML(markdown)
    }

    @Test("the whole corpus renders without throwing")
    func rendersWithoutThrowing() throws {
        let html = try render(corpus())
        #expect(!html.isEmpty)
    }

    @Test("display blocks become MathML elements")
    func displayBlocksBecomeMath() throws {
        let html = try render(corpus())
        // The corpus has 30+ display blocks; most are supported and become <math>.
        let mathElements = html.components(separatedBy: "<math ").count - 1
        #expect(mathElements >= 25)
    }

    @Test("the quadratic formula emits a fraction over a radical")
    func quadraticFormula() {
        let html = render("$$\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$")
        #expect(html.contains("<mfrac>"))
        #expect(html.contains("<msqrt>"))
    }

    @Test("a matrix environment emits an mtable")
    func matrixEnvironment() {
        let html = render("$$\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}$$")
        #expect(html.contains("<mtable"))
    }

    @Test("an unsupported construct does not crash the render")
    func unsupportedDegradesGracefully() {
        // MarkdownPDF renders these as visible source; Tiledown must not throw.
        let html = render("$$\\textcolor{red}{c}\\boxed{x}$$")
        #expect(!html.isEmpty)
    }
}
