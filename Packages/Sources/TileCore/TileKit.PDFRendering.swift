import Foundation

public extension TileKit {
    /// A protocol seam for rendering a page's Markdown source into a PDF document,
    /// so the engine can emit a downloadable PDF beside an article without importing
    /// a PDF engine into the site layer.
    ///
    /// The site generator consumes this seam and the composition root supplies the
    /// concrete renderer (backed by MarkdownPDF), so the engine core never links a
    /// PDF backend. When no renderer is wired, no PDFs are produced. The renderer
    /// returns the PDF bytes, or `nil` for source it cannot render, so a failure
    /// simply omits the download rather than failing the build.
    protocol PDFRendering: Sendable {
        func renderPDF(markdown: String) -> [UInt8]?
        func renderPDF(markdown: String, assetsBaseURL: URL?) -> [UInt8]?
    }
}

public extension TileKit.PDFRendering {
    func renderPDF(markdown: String, assetsBaseURL _: URL?) -> [UInt8]? {
        renderPDF(markdown: markdown)
    }
}
