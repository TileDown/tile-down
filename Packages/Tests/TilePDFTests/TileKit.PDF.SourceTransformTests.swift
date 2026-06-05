import Testing
import TileCore
@testable import TilePDF

@Suite("PDF source transform")
struct SourceTransformTests {
    @Test("a chart directive becomes a chart fence in the engine's vocabulary")
    func chartDirectiveToFence() {
        let out = TileKit.PDF.markdownForPDF("""
        # Title

        :::chart
        type: bar
        title: Devs
        labels: A, B, C
        series.Happy: 1, 2, 3
        :::

        After.
        """)
        #expect(out.contains("```chart"))
        #expect(!out.contains(":::"))
        #expect(out.contains("categories: A, B, C"))
        #expect(out.contains("series: Happy = 1, 2, 3"))
        // pass-through lines and surrounding prose are preserved
        #expect(out.contains("type: bar"))
        #expect(out.contains("# Title"))
        #expect(out.contains("After."))
    }

    @Test("ordinary Markdown is left unchanged")
    func leavesProseAlone() {
        let source = "# H\n\nA paragraph with a ```chart fence already.\n"
        #expect(TileKit.PDF.markdownForPDF(source) == source)
    }

    @Test("image-only lines become standalone paragraphs")
    func separatesImageOnlyLines() {
        let out = TileKit.PDF.markdownForPDF("""
        Prose before image.
        ![](/images/cube.png)
        Prose after image.
        """)

        #expect(out.contains("Prose before image.\n\n![](/images/cube.png)\n\nProse after image."))
    }

    @Test("image-looking code fence lines are not separated")
    func leavesImageLinesInsideCodeFences() {
        let source = """
        ```markdown
        Prose before image.
        ![](/images/cube.png)
        ```
        """

        #expect(TileKit.PDF.markdownForPDF(source) == source)
    }
}
