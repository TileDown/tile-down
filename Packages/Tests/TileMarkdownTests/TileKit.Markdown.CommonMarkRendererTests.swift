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

    @Test("escapes the code fence info string in the class attribute")
    func escapesCodeFenceInfoString() {
        let html = renderer.renderHTML(
            """
            ```<script>
            x
            ```
            """,
        )
        #expect(!html.contains("<script>"))
        #expect(html.contains(#"class="language-&lt;script&gt;""#))
    }

    @Test("drops javascript: links, keeping the text inert")
    func dropsJavaScriptLink() {
        let html = renderer.renderHTML("[click](javascript:alert(1))")
        #expect(!html.contains("javascript:"))
        #expect(!html.contains("<a "))
        #expect(html == "<p>click</p>")
    }

    @Test("keeps safe and relative link schemes")
    func keepsSafeLinks() {
        #expect(
            renderer.renderHTML("[a](mailto:x@y.com)") ==
                #"<p><a href="mailto:x@y.com">a</a></p>"#,
        )
        #expect(
            renderer.renderHTML("[a](/local/path)") ==
                #"<p><a href="/local/path">a</a></p>"#,
        )
    }

    @Test("drops javascript: image sources, keeping alt text inert")
    func dropsJavaScriptImage() {
        let html = renderer.renderHTML("![alt text](javascript:void(0))")
        #expect(!html.contains("javascript:"))
        #expect(!html.contains("<img"))
        #expect(html.contains("alt text"))
    }

    @Test("renders the image title attribute")
    func rendersImageTitle() {
        #expect(
            renderer.renderHTML(#"![a](x.png "cap")"#) ==
                #"<p><img src="x.png" alt="a" title="cap"></p>"#,
        )
    }

    @Test("emits the ordered list start attribute when not 1")
    func orderedListStart() {
        #expect(
            renderer.renderHTML(
                """
                3. a
                4. b
                """,
            ) == #"<ol start="3"><li>a</li><li>b</li></ol>"#,
        )
    }

    @Test("wraps paragraphs in loose lists separated by blank lines")
    func looseListBlankLines() {
        #expect(
            renderer.renderHTML(
                """
                - a

                - b
                """,
            ) == "<ul><li><p>a</p></li><li><p>b</p></li></ul>",
        )
    }

    @Test("wraps and separates multi-block list items")
    func looseListMultiBlock() {
        #expect(
            renderer.renderHTML(
                """
                - a

                  b
                """,
            ) == "<ul><li><p>a</p>\n<p>b</p></li></ul>",
        )
    }
}
