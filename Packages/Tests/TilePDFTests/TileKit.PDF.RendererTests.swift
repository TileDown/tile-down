import Foundation
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

    @Test("embeds local JPEG image assets through MarkdownPDF")
    func embedsLocalJPEGImageAssets() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TilePDFTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageDirectory = directory.appendingPathComponent("images", isDirectory: true)
        try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        try minimalJPEG().write(to: imageDirectory.appendingPathComponent("pixel.jpg"))

        let bytes = try #require(TileKit.PDF.Renderer().renderPDF(
            markdown: "![](/images/pixel.jpg)",
            assetsBaseURL: directory,
        ))

        #expect(containsPDFToken("[Image:", in: bytes))
        #expect(!containsPDFToken("/Subtype /Image", in: bytes))

        let rewrittenBytes = try #require(TileKit.PDF.Renderer().renderPDF(
            markdown: "![](images/pixel.jpg)",
            assetsBaseURL: directory,
        ))
        #expect(containsPDFToken("/Subtype /Image", in: rewrittenBytes))
        #expect(containsPDFToken("/DCTDecode", in: rewrittenBytes))
        #expect(!containsPDFToken("[Image:", in: rewrittenBytes))
    }

    private func minimalJPEG() -> Data {
        Data([
            0xFF, 0xD8,
            0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
            0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01,
            0x00, 0x00,
            0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00,
            0x01, 0x03, 0x01, 0x11, 0x00, 0x02, 0x11, 0x00,
            0x03, 0x11, 0x00,
            0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02,
            0x11, 0x03, 0x11, 0x00, 0x3F, 0x00,
            0x00,
            0xFF, 0xD9,
        ])
    }
}

private func containsPDFToken(
    _ token: String,
    in bytes: [UInt8],
) -> Bool {
    let needle = Array(token.utf8)
    guard !needle.isEmpty, bytes.count >= needle.count else {
        return false
    }
    return bytes.indices.dropLast(needle.count - 1).contains { index in
        Array(bytes[index ..< index + needle.count]) == needle
    }
}
