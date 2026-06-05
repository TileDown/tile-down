import Foundation
import Testing
import TileCore
import TilePDF
@testable import TileSite
import TileSiteImpl

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

    private func articlePDFAssetFileSystem() -> MemoryFileSystem {
        MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/blog/cube/index.md": """
                ---
                title: Cube Post
                date: 2026-06-01
                image: /images/hero.jpg
                ---
                # Article Body

                ![Body](/images/body.jpg)

                ![Spaced](/images/body%20shot.jpg)
                """,
                "content/public/images/body.jpg": "BODY",
                "content/public/images/body shot.jpg": "SPACE",
                "content/public/images/hero.jpg": "HERO",
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

    @Test("articlePDF renders body and copies local images into a PDF asset root")
    func articlePDFPreparesBodyAndImageAssets() throws {
        let fileSystem = articlePDFAssetFileSystem()
        let renderer = RecordingPDFRenderer()
        _ = try articlePDFGenerator(fileSystem: fileSystem, pdfRenderer: renderer)
            .buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: .init(
                        postsDirectory: "blog",
                        articlePDF: true,
                        staticPassthroughs: [
                            .init(sourcePath: "public/images", outputPath: "images"),
                        ],
                    ),
                ),
            )

        let call = try #require(renderer.calls.first)
        let assetRoot = try #require(call.assetsBaseURL?.path)
        #expect(call.markdown.contains("# Cube Post"))
        #expect(call.markdown.contains("![Cube Post](images/hero.jpg)"))
        #expect(call.markdown.contains("![Body](images/body.jpg)"))
        #expect(call.markdown.contains("![Spaced](images/body_shot-"))
        #expect(call.markdown.contains(".jpg)"))
        #expect(!call.markdown.contains("title: Cube Post"))
        #expect(fileSystem.files[assetRoot + "/images/hero.jpg"] == "HERO")
        #expect(fileSystem.files[assetRoot + "/images/body.jpg"] == "BODY")
        let spacedAsset = fileSystem.files.keys.first { path in
            path.hasPrefix(assetRoot + "/images/body_shot-")
                && path.hasSuffix(".jpg")
        }
        #expect(spacedAsset != nil)
        #expect(spacedAsset.map { fileSystem.files[$0] } == "SPACE")
    }

    @Test("articlePDF end to end embeds local hero and body images")
    func articlePDFEndToEndEmbedsLocalImages() throws {
        let fixture = try LocalArticlePDFFixture()
        defer { fixture.remove() }
        try fixture.writeContent()

        _ = try articlePDFGenerator(
            fileSystem: TileKit.Site.LocalFileSystem(fileManager: .default),
            pdfRenderer: TileKit.PDF.Renderer(),
        ).buildContent(
            .init(
                contentRootPath: fixture.content.path,
                template: .layout(.topNav),
                outputRootPath: fixture.output.path,
                configuration: .init(postsDirectory: "blog", articlePDF: true),
            ),
        )

        let pdf = try Data(contentsOf: fixture.output.appendingPathComponent("cube.pdf"))
        let bytes = [UInt8](pdf)
        #expect(pdfTokenCount("/Subtype /Image", in: bytes) == 2)
        #expect(pdfTokenCount("/DCTDecode", in: bytes) == 2)
        #expect(!containsPDFToken("[Image:", in: bytes))
        #expect(!containsPDFToken("title: Cube Post", in: bytes))
    }

    @Test("articlePDF end to end embeds percent-encoded local image paths")
    func articlePDFEndToEndEmbedsPercentEncodedLocalImagePaths() throws {
        let fixture = try LocalArticlePDFFixture()
        defer { fixture.remove() }
        try fixture.writeContent(
            heroImage: "/images/hero%20shot.jpg",
            bodyImage: "/images/body%20shot.jpg",
        )

        _ = try articlePDFGenerator(
            fileSystem: TileKit.Site.LocalFileSystem(fileManager: .default),
            pdfRenderer: TileKit.PDF.Renderer(),
        ).buildContent(
            .init(
                contentRootPath: fixture.content.path,
                template: .layout(.topNav),
                outputRootPath: fixture.output.path,
                configuration: .init(postsDirectory: "blog", articlePDF: true),
            ),
        )

        let pdf = try Data(contentsOf: fixture.output.appendingPathComponent("cube.pdf"))
        let bytes = [UInt8](pdf)
        #expect(pdfTokenCount("/Subtype /Image", in: bytes) == 2)
        #expect(pdfTokenCount("/DCTDecode", in: bytes) == 2)
        #expect(!containsPDFToken("[Image:", in: bytes))
    }

    #if canImport(CoreGraphics) && canImport(ImageIO)
        @Test("articlePDF converts unsupported local images before rendering")
        func articlePDFConvertsUnsupportedLocalImagesBeforeRendering() throws {
            let fixture = try LocalArticlePDFFixture()
            defer { fixture.remove() }
            try fixture.writeContent(
                heroImage: "/images/hero.png",
                heroImageData: rgbaPNGForPDFTest(),
                bodyImage: "/images/body.gif",
                bodyImageData: minimalGIFForPDFTest(),
            )
            let inspection = PDFAssetInspection()
            let renderer = InspectingPDFRenderer { markdown, assetsBaseURL in
                inspection.didInspect = true
                #expect(markdown.contains("![Cube Post](images/hero.png.jpg)"))
                #expect(markdown.contains("![](images/body.gif.jpg)"))
                guard let assetsBaseURL else {
                    #expect(Bool(false), "expected an asset root")
                    return
                }

                let hero = assetsBaseURL.appendingPathComponent("images/hero.png.jpg")
                let body = assetsBaseURL.appendingPathComponent("images/body.gif.jpg")
                #expect(jpegExists(at: hero))
                #expect(jpegExists(at: body))
            }

            _ = try articlePDFGenerator(
                fileSystem: TileKit.Site.LocalFileSystem(fileManager: .default),
                pdfRenderer: renderer,
            ).buildContent(
                .init(
                    contentRootPath: fixture.content.path,
                    template: .layout(.topNav),
                    outputRootPath: fixture.output.path,
                    configuration: .init(postsDirectory: "blog", articlePDF: true),
                ),
            )

            #expect(inspection.didInspect)
        }

        @Test("articlePDF end to end embeds converted local images")
        func articlePDFEndToEndEmbedsConvertedLocalImages() throws {
            let fixture = try LocalArticlePDFFixture()
            defer { fixture.remove() }
            try fixture.writeContent(
                heroImage: "/images/hero.png",
                heroImageData: rgbaPNGForPDFTest(),
                bodyImage: "/images/body.gif",
                bodyImageData: minimalGIFForPDFTest(),
            )

            _ = try articlePDFGenerator(
                fileSystem: TileKit.Site.LocalFileSystem(fileManager: .default),
                pdfRenderer: TileKit.PDF.Renderer(),
            ).buildContent(
                .init(
                    contentRootPath: fixture.content.path,
                    template: .layout(.topNav),
                    outputRootPath: fixture.output.path,
                    configuration: .init(postsDirectory: "blog", articlePDF: true),
                ),
            )

            let pdf = try Data(contentsOf: fixture.output.appendingPathComponent("cube.pdf"))
            let bytes = [UInt8](pdf)
            #expect(pdfTokenCount("/Subtype /Image", in: bytes) == 2)
            #expect(pdfTokenCount("/DCTDecode", in: bytes) == 2)
            #expect(!containsPDFToken("[Image:", in: bytes))
        }
    #endif

    @Test("articlePDF does not crash when an image is missing")
    func articlePDFMissingImageDoesNotCrash() throws {
        let fixture = try LocalArticlePDFFixture()
        defer { fixture.remove() }
        try fixture.writeContent(bodyImage: "/images/missing.jpg", writeBodyImage: false)

        _ = try articlePDFGenerator(
            fileSystem: TileKit.Site.LocalFileSystem(fileManager: .default),
            pdfRenderer: TileKit.PDF.Renderer(),
        ).buildContent(
            .init(
                contentRootPath: fixture.content.path,
                template: .layout(.topNav),
                outputRootPath: fixture.output.path,
                configuration: .init(postsDirectory: "blog", articlePDF: true),
            ),
        )

        let pdf = try Data(contentsOf: fixture.output.appendingPathComponent("cube.pdf"))
        #expect(containsPDFToken("[Image:", in: [UInt8](pdf)))
    }

    private func articlePDFGenerator(
        fileSystem: any TileKit.Site.FileSystem,
        pdfRenderer: any TileKit.PDFRendering,
    ) -> TileKit.Site.Generator {
        TileKit.Site.Generator(
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
    }
}
