import Testing
import TileCore
@testable import TileMarkdown

@Suite("CommonMark renderer")
struct CommonMarkRendererTests {
    private let renderer = TileKit.Markdown.CommonMarkRenderer()

    @Test("renders headings and paragraphs, blocks joined by newline")
    func headingsAndParagraphs() {
        #expect(
            renderer.renderHTML(
                """
                # Title

                First paragraph.
                """,
            ) == "<h1>Title</h1>\n<p>First paragraph.</p>",
        )
    }

    @Test("renders unordered lists tight")
    func unorderedList() {
        #expect(
            renderer.renderHTML(
                """
                - one
                - two
                """,
            ) == "<ul><li>one</li><li>two</li></ul>",
        )
    }

    @Test("renders emphasis, strong, and inline code")
    func inlineFormatting() {
        #expect(
            renderer.renderHTML("*a* **b** `c`") ==
                "<p><em>a</em> <strong>b</strong> <code>c</code></p>",
        )
    }

    @Test("renders links")
    func links() {
        #expect(
            renderer.renderHTML("[text](https://example.com)") ==
                #"<p><a href="https://example.com">text</a></p>"#,
        )
    }

    @Test("renders fenced code blocks with a language class")
    func fencedCode() {
        #expect(
            renderer.renderHTML(
                """
                ```swift
                let x = 1
                ```
                """,
            ) == #"<pre><code class="language-swift">let x = 1</code></pre>"#,
        )
    }

    @Test("escapes text special characters")
    func escapesText() {
        #expect(
            renderer.renderHTML("5 < 6 & 7") == "<p>5 &lt; 6 &amp; 7</p>",
        )
    }

    @Test("escapes raw HTML instead of passing it through")
    func escapesRawHTML() {
        let html = renderer.renderHTML("<script>alert('x')</script>")
        #expect(!html.contains("<script>"))
        #expect(html.contains("&lt;script&gt;"))
    }
}
