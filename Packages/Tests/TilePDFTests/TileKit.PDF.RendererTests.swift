import Testing
import TileCore
@testable import TilePDF

@Suite("PDF renderer")
struct PDFRendererTests {
    @Test("renders Markdown source to a PDF document")
    func rendersPDF() throws {
        let bytes = TileKit.PDF.Renderer().renderPDF(
            markdown: """
            # Title

            A paragraph with inline math $a + b$ and a display block.

            $$
            \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}
            $$
            """,
        )
        let pdf = try #require(bytes, "expected PDF bytes")
        #expect(pdf.count > 100)
        // The PDF magic header: "%PDF-".
        #expect(pdf.prefix(5).elementsEqual([0x25, 0x50, 0x44, 0x46, 0x2D]))
    }
}
