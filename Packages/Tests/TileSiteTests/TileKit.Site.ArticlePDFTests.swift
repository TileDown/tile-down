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

    @discardableResult
    private func buildArticlePDFFixture(
        fileSystem: MemoryFileSystem,
        pdfRenderer: (any TileKit.PDFRendering)?,
        articlePDF: Bool,
    ) throws -> TileKit.Site.ContentBuildResult {
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
        return try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(articlePDF: articlePDF),
            ),
        )
    }

    @Test("articlePDF writes a root-level slug PDF for each article and links it")
    func articlePDFWritesAndLinks() throws {
        let fileSystem = articlePDFFileSystem()
        let result = try buildArticlePDFFixture(
            fileSystem: fileSystem,
            pdfRenderer: StubPDFRenderer(),
            articlePDF: true,
        )

        // The post gets a root-level slug PDF written from its source, and the
        // article links it.
        #expect(fileSystem.binaryFiles["dist/first.pdf"] == Array("%PDF-1.4 stub".utf8))
        #expect(result.outputPaths.contains("dist/first.pdf"))
        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        #expect(post.contains(#"<a href="/first.pdf" download>Download PDF</a>"#))

        // A non-article page (the home page) gets neither.
        #expect(fileSystem.binaryFiles["dist/index.pdf"] == nil)
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(!home.contains("Download PDF"))
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

    @Test("articlePDF strips configured posts directory from PDF file name")
    func articlePDFUsesArticleSlugWithoutPostsDirectory() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/blog/core-animation-3d-cube/index.md": """
                ---
                title: Cube
                date: 2026-06-01
                ---
                # Cube
                """,
            ],
        )
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
            pdfRenderer: StubPDFRenderer(),
        )
        let result = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(postsDirectory: "blog", articlePDF: true),
            ),
        )

        #expect(fileSystem.binaryFiles["dist/core-animation-3d-cube.pdf"] == Array("%PDF-1.4 stub".utf8))
        #expect(result.outputPaths.contains("dist/core-animation-3d-cube.pdf"))
        let post = try #require(fileSystem.files["dist/blog/core-animation-3d-cube/index.html"])
        #expect(post.contains(#"<a href="/core-animation-3d-cube.pdf" download>Download PDF</a>"#))
    }
}
