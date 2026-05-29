import Testing
@testable import TileKit

@Suite("Basic HTML renderer")
struct BasicHTMLRendererTests {
    @Test("renders headings and paragraphs")
    func rendersHeadingsAndParagraphs() {
        let renderer = TileKit.Markdown.BasicHTMLRenderer()

        let html = renderer.renderHTML(
            """
            # Title

            First paragraph
            continues here.
            """,
        )

        #expect(
            html == """
            <h1>Title</h1>
            <p>First paragraph continues here.</p>
            """,
        )
    }

    @Test("escapes text")
    func escapesText() {
        let renderer = TileKit.Markdown.BasicHTMLRenderer()

        #expect(
            renderer.renderHTML("<script>alert('x')</script>") ==
                "<p>&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;</p>",
        )
    }
}
