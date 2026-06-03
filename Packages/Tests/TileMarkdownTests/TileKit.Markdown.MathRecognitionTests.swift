import Testing
import TileCore
@testable import TileMarkdown

@Suite("Display math recognition")
struct MathRecognitionTests {
    /// Records what the renderer was asked to typeset and echoes the request so a
    /// test can assert the delimiters were stripped and `display` was set.
    private struct SpyMath: TileKit.MathRendering {
        func rendered(
            tex: String,
            display: Bool,
        ) -> TileKit.FencedBlock? {
            .init(html: "<math data-display=\"\(display)\">\(tex)</math>", css: ".m{}")
        }
    }

    private func renderer() -> TileKit.Markdown.CommonMarkRenderer {
        .init(mathRenderer: SpyMath())
    }

    @Test("a paragraph that is one $$...$$ block becomes display math, delimiters stripped")
    func displayBlock() {
        #expect(
            renderer().renderHTML("$$E = mc^2$$") ==
                #"<math data-display="true">E = mc^2</math>"#,
        )
    }

    @Test("display math is not wrapped in a paragraph")
    func notWrappedInParagraph() {
        let html = renderer().renderHTML("$$a + b$$")
        #expect(!html.contains("<p>"))
    }

    @Test("a multi-line $$ block is recognized, inner trimmed")
    func multilineBlock() {
        #expect(
            renderer().renderHTML(
                """
                $$
                \\sum_i x_i
                $$
                """,
            ) == #"<math data-display="true">\sum_i x_i</math>"#,
        )
    }

    @Test("prose containing single dollars is not math")
    func currencyIsNotMath() {
        #expect(
            renderer().renderHTML("It costs $5 and $10.") ==
                "<p>It costs $5 and $10.</p>",
        )
    }

    @Test("two display blocks in one paragraph are not a single block")
    func twoBlocksInOneParagraphFallBack() {
        let html = renderer().renderHTML("$$a$$ and $$b$$")
        #expect(html == "<p>$$a$$ and $$b$$</p>")
    }

    @Test("inline $...$ is left as prose in this layer")
    func inlineIsNotDisplay() {
        #expect(
            renderer().renderHTML("Euler wrote $e^{i\\pi}+1=0$ here.") ==
                #"<p>Euler wrote $e^{i\pi}+1=0$ here.</p>"#,
        )
    }

    @Test("empty delimiters are not math")
    func emptyDelimiters() {
        #expect(renderer().renderHTML("$$$$") == "<p>$$$$</p>")
    }

    @Test("the math renderer's CSS is collected once into the body")
    func cssCollected() {
        let body = renderer().renderBody(
            """
            $$x$$

            $$y$$
            """,
        )
        #expect(body.css == [".m{}"])
    }

    @Test("with no math renderer, $$ blocks fall back to escaped source")
    func noRendererFallsBack() {
        let plain = TileKit.Markdown.CommonMarkRenderer()
        #expect(plain.renderHTML("$$x$$") == "<p>$$x$$</p>")
    }
}

@Suite("Placeholder math renderer")
struct PlaceholderMathRendererTests {
    private let renderer = TileKit.Markdown.PlaceholderMathRenderer()

    @Test("display math renders a block container with escaped source")
    func display() {
        let block = renderer.rendered(tex: "a < b & c", display: true)
        #expect(block?.html.contains(#"class="td-math td-math-display""#) == true)
        #expect(block?.html.contains("a &lt; b &amp; c") == true)
        #expect(block?.css.contains(".td-math-display") == true)
    }

    @Test("inline math renders an inline container")
    func inline() {
        let block = renderer.rendered(tex: "x^2", display: false)
        #expect(block?.html.contains(#"class="td-math td-math-inline""#) == true)
    }

    @Test("blank source typesets nothing")
    func blank() {
        #expect(renderer.rendered(tex: "   ", display: true) == nil)
    }
}
