import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site asset copy")
struct SiteAssetCopyTests {
    @Test("copies non-markdown assets verbatim and skips markdown sources")
    func copiesAssetsAndSkipsMarkdown() throws {
        let template = "{{{ contents }}}"
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home
                """,
                "content/assets/images/hero.png": "PNG-BYTES",
                "content/posts/post/index.md": """
                ---
                title: Post
                ---
                # Post
                """,
                "content/posts/post/cover.jpg": "JPG-BYTES",
                "content/posts/post/draft.md": "# Draft",
                "templates/page.html": template,
            ],
        )

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // Assets are copied byte-for-byte to the mirrored output path.
        #expect(fileSystem.files["dist/assets/images/hero.png"] == "PNG-BYTES")
        #expect(fileSystem.files["dist/posts/post/cover.jpg"] == "JPG-BYTES")
        #expect(result.outputPaths.contains("dist/assets/images/hero.png"))
        #expect(result.outputPaths.contains("dist/posts/post/cover.jpg"))

        // Markdown is source, never copied: neither the page index nor a
        // non-index draft lands as a raw file in the output.
        #expect(fileSystem.files["dist/index.md"] == nil)
        #expect(fileSystem.files["dist/posts/post/index.md"] == nil)
        #expect(fileSystem.files["dist/posts/post/draft.md"] == nil)
    }

    @Test("does not copy build inputs or clobber generated output")
    func skipsConfigMetadataAndCollisions() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home
                """,
                // Build input the CLI reads; must not be published.
                "content/tiledown.yml": "title: Demo",
                // OS metadata; must not be published.
                "content/.DS_Store": "junk",
                // A content file whose path collides with a generated output.
                // It must not overwrite the generated page.
                "content/index.html": "HAND-WRITTEN",
                "templates/page.html": "GENERATED {{{ contents }}}",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // The generated page survives; the colliding content file did not win.
        #expect(fileSystem.files["dist/index.html"]?.contains("GENERATED") == true)
        #expect(fileSystem.files["dist/index.html"] != "HAND-WRITTEN")
        // Build inputs are not published.
        #expect(fileSystem.files["dist/tiledown.yml"] == nil)
        #expect(fileSystem.files["dist/.DS_Store"] == nil)
    }

    @Test("runs the injected image checker over image assets")
    func runsImageChecker() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home
                """,
                "content/assets/logo.svg": "<svg/>",
                "content/assets/photo.jpeg": "JPEG-BYTES",
                "content/assets/data.json": "{}",
                "templates/page.html": "{{{ contents }}}",
            ],
        )
        let checker = RecordingImageChecker()

        _ = try makeGenerator(
            fileSystem: fileSystem,
            imageChecker: checker,
        ).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // Only image extensions reach the checker; the JSON asset does not.
        #expect(checker.checkedPaths == ["assets/logo.svg", "assets/photo.jpeg"])
    }

    @Test("a throwing image checker fails the build")
    func throwingImageCheckerFailsBuild() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/assets/bad.png": "x",
                "templates/page.html": "{{{ contents }}}",
            ],
        )

        #expect(throws: RejectingImageChecker.Rejected.self) {
            _ = try makeGenerator(
                fileSystem: fileSystem,
                imageChecker: RejectingImageChecker(),
            ).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .file(path: "templates/page.html"),
                    outputRootPath: "dist",
                    configuration: .init(theme: nil),
                ),
            )
        }
    }

    private func makeGenerator(
        fileSystem: any TileKit.Site.FileSystem,
        imageChecker: any TileKit.Site.ImageChecking = TileKit.Site.PassthroughImageChecker(),
    ) -> TileKit.Site.Generator {
        let registry = TileKit.Tile.Registry()
        let htmlRenderer = TileKit.Output.HTMLRenderer(
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
            tileRegistry: registry,
        )
        return TileKit.Site.Generator(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: htmlRenderer,
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
            imageChecker: imageChecker,
        )
    }
}

/// Records which image paths the generator passed to the checker.
private final class RecordingImageChecker: TileKit.Site.ImageChecking, @unchecked Sendable {
    private(set) var checkedPaths: [String] = []

    func check(
        imagePaths: [String],
    ) throws {
        checkedPaths = imagePaths
    }
}

/// Rejects any build that has images, to prove the pass can stop a build.
private struct RejectingImageChecker: TileKit.Site.ImageChecking {
    struct Rejected: Error {}

    func check(
        imagePaths: [String],
    ) throws {
        if !imagePaths.isEmpty {
            throw Rejected()
        }
    }
}
