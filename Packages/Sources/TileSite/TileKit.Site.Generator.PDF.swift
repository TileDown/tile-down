import TileCore

extension TileKit.Site.Generator {
    /// Whether a page should get a downloadable PDF: the site opted in (`articlePDF`),
    /// a PDF renderer is wired at the composition root, the page is an article (a
    /// post), and it has a backing source file. Used both to write the PDF and to
    /// gate the "Download PDF" action, so the link and the file agree.
    func shouldRenderArticlePDF(
        _ page: TileKit.Site.Page,
        configuration: TileKit.Site.Configuration,
    ) -> Bool {
        configuration.articlePDF
            && pdfRenderer != nil
            && !page.rawSource.isEmpty
            && pageIsPost(page, postsDirectory: configuration.postsDirectory)
    }

    /// Renders and writes the per-article PDF beside its HTML when applicable, and
    /// reports whether a PDF was actually written. A render failure omits the PDF
    /// (and returns `false`) rather than failing the build, so the "Download PDF"
    /// link is offered only when the file truly exists.
    func writeArticlePDF(
        page: TileKit.Site.Page,
        configuration: TileKit.Site.Configuration,
    ) throws -> Bool {
        guard shouldRenderArticlePDF(page, configuration: configuration),
              let bytes = pdfRenderer?.renderPDF(markdown: page.rawSource)
        else {
            return false
        }
        try fileSystem.writeBytes(bytes, at: pdfOutputPath(for: page.outputPath))
        return true
    }

    /// The PDF output path for an HTML output path: the same path with a `.pdf`
    /// extension (e.g. `posts/x/index.html` -> `posts/x/index.pdf`).
    func pdfOutputPath(for htmlOutputPath: String) -> String {
        guard htmlOutputPath.hasSuffix(".html") else {
            return htmlOutputPath + ".pdf"
        }
        return String(htmlOutputPath.dropLast(".html".count)) + ".pdf"
    }
}
