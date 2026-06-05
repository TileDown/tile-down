import Foundation
import MarkdownPDF
import TileCore

public extension TileKit {
    /// PDF rendering: turns a page's Markdown source into a typeset PDF document,
    /// built on the shared MarkdownPDF engine (which uses the same MathTypeset
    /// layout the site's SVG math uses). The renderer conforms to
    /// ``TileKit/PDFRendering`` and is wired by the composition root, so the site
    /// layer never imports a PDF backend.
    enum PDF {}
}

public extension TileKit.PDF {
    /// A ``TileKit/PDFRendering`` backed by MarkdownPDF. It typesets the page's
    /// Markdown body (math enabled, fonts embedded) into a self-contained PDF, so a
    /// reader downloads the same content the page shows, from the same source.
    struct Renderer: TileKit.PDFRendering {
        public init() {}

        public func renderPDF(markdown: String) -> [UInt8]? {
            renderPDF(markdown: markdown, assetsBaseURL: nil)
        }

        public func renderPDF(markdown: String, assetsBaseURL: URL?) -> [UInt8]? {
            guard let data = try? MarkdownPDFRenderer(
                options: PDFOptions(mathTypesetting: .enabled),
            ).render(markdown: TileKit.PDF.markdownForPDF(markdown), assetsBaseURL: assetsBaseURL) else {
                return nil
            }
            return [UInt8](data)
        }
    }
}
