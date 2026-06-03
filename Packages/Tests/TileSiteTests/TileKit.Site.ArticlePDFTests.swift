import Testing
import TileCore
@testable import TileSite

private struct StubPDFRenderer: TileKit.PDFRendering {
    func renderPDF(markdown _: String) -> [UInt8]? {
        Array("%PDF-1.4 stub".utf8)
    }
}

extension SiteGeneratorTests {
    private func articlePDFFileSystem() -> MemoryFileSystem {
        MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/first/index.md": """
                ---
                title: First Post
                date: 2026-06-01
                ---
                # First Post

                Body text.
                """,
            ],
        )
    }

    private func buildArticlePDFFixture(
        fileSystem: MemoryFileSystem,
        pdfRenderer: (any TileKit.PDFRendering)?,
        articlePDF: Bool,
    ) throws {
        let generator = TileKit.Site.Generator(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
            pdfRenderer: pdfRenderer,
        )
        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(articlePDF: articlePDF),
            ),
        )
    }

    @Test("articlePDF writes a PDF beside each article and links it")
    func articlePDFWritesAndLinks() throws {
        let fileSystem = articlePDFFileSystem()
        try buildArticlePDFFixture(fileSystem: fileSystem, pdfRenderer: StubPDFRenderer(), articlePDF: true)

        // The post gets a PDF written from its source, and the article links it.
        #expect(fileSystem.binaryFiles["dist/posts/first/index.pdf"] == Array("%PDF-1.4 stub".utf8))
        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        #expect(post.contains(#"<a href="/posts/first/index.pdf" download>Download PDF</a>"#))

        // A non-article page (the home page) gets neither.
        #expect(fileSystem.binaryFiles["dist/index.pdf"] == nil)
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(!home.contains("index.pdf"))
    }

    @Test("articlePDF disabled writes no PDF and no link, even with a renderer wired")
    func articlePDFDisabledIsInert() throws {
        let fileSystem = articlePDFFileSystem()
        try buildArticlePDFFixture(fileSystem: fileSystem, pdfRenderer: StubPDFRenderer(), articlePDF: false)

        #expect(fileSystem.binaryFiles.isEmpty)
        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        #expect(!post.contains("Download PDF"))
    }

    @Test("articlePDF with no renderer wired writes no PDF and no link")
    func articlePDFWithoutRendererIsInert() throws {
        let fileSystem = articlePDFFileSystem()
        try buildArticlePDFFixture(fileSystem: fileSystem, pdfRenderer: nil, articlePDF: true)

        #expect(fileSystem.binaryFiles.isEmpty)
        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        #expect(!post.contains("Download PDF"))
    }
}
