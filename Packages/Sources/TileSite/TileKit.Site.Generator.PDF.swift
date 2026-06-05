import Foundation
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

    /// Renders and writes the per-article PDF when applicable, and returns its
    /// generated output path. A render failure omits the PDF
    /// (and returns `nil`) rather than failing the build, so the "Download PDF"
    /// link is offered only when the file truly exists.
    func writeArticlePDF(
        page: TileKit.Site.Page,
        configuration: TileKit.Site.Configuration,
        outputRootPath: String,
        contentRootPath: String,
    ) throws -> String? {
        guard shouldRenderArticlePDF(page, configuration: configuration),
              let pdfRenderer
        else {
            return nil
        }
        let assetRoot = temporaryPDFAssetRoot()
        defer { removeTemporaryPDFAssetRoot(assetRoot) }

        let markdown = preparedArticlePDFMarkdown(
            for: page,
            configuration: configuration,
            contentRootPath: contentRootPath,
            assetRoot: assetRoot,
        )
        guard let bytes = pdfRenderer.renderPDF(
            markdown: markdown,
            assetsBaseURL: assetRoot,
        ) else {
            return nil
        }
        let outputPath = pdfOutputPath(
            for: page,
            postsDirectory: configuration.postsDirectory,
            outputRootPath: outputRootPath,
        )
        try fileSystem.writeBytes(
            bytes,
            at: outputPath,
        )
        return outputPath
    }

    /// The Markdown source sent to the PDF renderer. It deliberately uses the
    /// parsed article body rather than raw source, so YAML front matter does not
    /// appear as prose in the PDF. The article title and hero image live in front
    /// matter for HTML layouts, so they are reintroduced here as Markdown.
    func articlePDFMarkdown(
        for page: TileKit.Site.Page,
    ) -> String {
        var sections: [String] = []
        let body = page.document.body.trimmingCharacters(in: .whitespacesAndNewlines)

        if let title = articlePDFTitle(for: page), !bodyStartsWithTitle(body, title: title) {
            sections.append("# \(title)")
        }

        if let heroImage = heroImageSource(page), !page.document.body.contains(heroImage) {
            let alt = articlePDFTitle(for: page) ?? ""
            sections.append("![\(alt)](\(heroImage))")
        }

        if !body.isEmpty {
            sections.append(body)
        }
        return sections.joined(separator: "\n\n")
    }

    /// The PDF output path for an article: a root-level PDF named after the
    /// article slug, with the configured posts directory stripped first
    /// (e.g. `posts/x` or `blog/x` -> `<outputRootPath>/x.pdf`).
    func pdfOutputPath(
        for page: TileKit.Site.Page,
        postsDirectory: String,
        outputRootPath: String,
    ) -> String {
        join(
            outputRootPath,
            articlePDFFileName(for: page, postsDirectory: postsDirectory),
        )
    }

    /// The public PDF URL for an article, with `baseURL` applied in the same way
    /// as other generated root-relative URLs.
    func pdfURL(
        for page: TileKit.Site.Page,
        postsDirectory: String,
        baseURL: String,
    ) -> String {
        baseURLPrefixedRootRelativeURL(
            "/" + articlePDFFileName(for: page, postsDirectory: postsDirectory),
            baseURL: baseURL,
        )
    }

    private func articlePDFFileName(
        for page: TileKit.Site.Page,
        postsDirectory: String,
    ) -> String {
        let relativeSlug = articleRelativeSlug(
            page.slug,
            postsDirectory: postsDirectory,
        )
        let fileSlug = relativeSlug
            .split(separator: "/")
            .joined(separator: "-")
        return (fileSlug.isEmpty ? "article" : fileSlug) + ".pdf"
    }

    private func articleRelativeSlug(
        _ slug: String,
        postsDirectory: String,
    ) -> String {
        let normalizedSlug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPostsDirectory = postsDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !normalizedPostsDirectory.isEmpty else {
            return normalizedSlug
        }
        if normalizedSlug == normalizedPostsDirectory {
            return normalizedSlug
        }
        let prefix = normalizedPostsDirectory + "/"
        if normalizedSlug.hasPrefix(prefix) {
            return String(normalizedSlug.dropFirst(prefix.count))
        }
        return normalizedSlug
    }

    private func articlePDFTitle(
        for page: TileKit.Site.Page,
    ) -> String? {
        let title = page.document.frontMatter["title"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title?.isEmpty == false ? title : nil
    }

    private func bodyStartsWithTitle(
        _ body: String,
        title: String,
    ) -> Bool {
        guard let firstLine = body.components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
            let heading = headingText(firstLine)
        else {
            return false
        }
        return normalizedHeading(heading) == normalizedHeading(title)
    }

    private func headingText(
        _ line: String,
    ) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let hashes = trimmed.prefix { $0 == "#" }
        guard !hashes.isEmpty, hashes.count <= 6 else {
            return nil
        }
        let afterHashes = trimmed.dropFirst(hashes.count)
        guard afterHashes.first == " " else {
            return nil
        }
        return afterHashes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedHeading(
        _ value: String,
    ) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
