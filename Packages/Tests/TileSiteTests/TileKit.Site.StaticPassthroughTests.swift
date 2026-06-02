import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site static passthrough")
struct SiteStaticPassthroughTests {
    @Test("preserves root files and public directories")
    func preservesRootFilesAndPublicDirectories() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /images/hero.svg
                ---
                # Home
                """,
                "content/deployment/CNAME": "example.com\n",
                "content/deployment/robots.txt": "User-agent: *\nAllow: /\n",
                "content/private/downloads/resume.pdf": "PDF-BYTES",
                "content/public/images/hero.svg": "<svg/>",
                "content/public/images/icons/icon.png": "PNG-BYTES",
            ],
        )

        let result = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    baseURL: "https://example.com",
                    staticPassthroughs: [
                        .init(sourcePath: "deployment/CNAME", outputPath: "CNAME"),
                        .init(sourcePath: "deployment/robots.txt", outputPath: "robots.txt"),
                        .init(sourcePath: "private/downloads/resume.pdf", outputPath: "resume.pdf"),
                        .init(sourcePath: "public/images", outputPath: "images"),
                    ],
                ),
            ),
        )

        #expect(fileSystem.files["dist/CNAME"] == "example.com\n")
        #expect(fileSystem.files["dist/robots.txt"]?.contains("Allow: /") == true)
        #expect(fileSystem.files["dist/resume.pdf"] == "PDF-BYTES")
        #expect(fileSystem.files["dist/images/hero.svg"] == "<svg/>")
        #expect(fileSystem.files["dist/images/icons/icon.png"] == "PNG-BYTES")
        #expect(result.outputPaths.contains("dist/CNAME"))
        #expect(result.outputPaths.contains("dist/images/icons/icon.png"))

        // Configured source trees are private inputs, not mirrored public output.
        #expect(fileSystem.files["dist/deployment/CNAME"] == nil)
        #expect(fileSystem.files["dist/deployment/robots.txt"] == nil)
        #expect(fileSystem.files["dist/public/images/hero.svg"] == nil)
        #expect(fileSystem.files["dist/private/downloads/resume.pdf"] == nil)

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"src="https://example.com/images/hero.svg""#))
    }

    @Test("copies explicitly configured hidden deployment paths")
    func copiesExplicitHiddenDeploymentPaths() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/deployment/.nojekyll": "",
                "content/public/.well-known/security.txt": "Contact: mailto:security@example.com\n",
            ],
        )

        let result = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    staticPassthroughs: [
                        .init(sourcePath: "deployment/.nojekyll", outputPath: ".nojekyll"),
                        .init(sourcePath: "public/.well-known", outputPath: ".well-known"),
                    ],
                ),
            ),
        )

        #expect(fileSystem.files["dist/.nojekyll"] == "")
        #expect(fileSystem.files["dist/.well-known/security.txt"]?.contains("security@example.com") == true)
        #expect(fileSystem.files["dist/public/.well-known/security.txt"] == nil)
        #expect(result.outputPaths.contains("dist/.nojekyll"))
        #expect(result.outputPaths.contains("dist/.well-known/security.txt"))
    }

    @Test("rejects missing sources")
    func rejectsMissingSources() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
            ],
        )
        #expect(throws: TileKit.Site.ConfigurationFileError.missingStaticPath("missing/CNAME")) {
            _ = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: .init(
                        staticPassthroughs: [
                            .init(sourcePath: "missing/CNAME", outputPath: "CNAME"),
                        ],
                    ),
                ),
            )
        }
    }

    @Test("rejects generated output collisions")
    func rejectsOutputCollisions() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/public/home.html": "HAND-WRITTEN",
            ],
        )
        #expect(throws: TileKit.Site.ConfigurationFileError.duplicateOutputPath("index.html")) {
            _ = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: .init(
                        staticPassthroughs: [
                            .init(sourcePath: "public/home.html", outputPath: "index.html"),
                        ],
                    ),
                ),
            )
        }
    }

    @Test("validates direct API paths")
    func validatesDirectAPIPaths() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
            ],
        )
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath("../secret")) {
            _ = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: .init(
                        staticPassthroughs: [
                            .init(sourcePath: "../secret", outputPath: "secret.txt"),
                        ],
                    ),
                ),
            )
        }
    }

    @Test("validates direct API output paths")
    func validatesDirectAPIOutputPaths() {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/public/images/hero.svg": "<svg/>",
            ],
        )
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath("images?preview")) {
            _ = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: .init(
                        staticPassthroughs: [
                            .init(sourcePath: "public/images", outputPath: "images?preview"),
                        ],
                    ),
                ),
            )
        }
    }

    @Test("validates mapped directory output paths", arguments: [
        "hero?preview.svg",
        "hero#preview.svg",
        "hero%2Fpreview.svg",
        #"hero\preview.svg"#,
    ])
    func validatesMappedDirectoryOutputPaths(fileName: String) {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/public/images/\(fileName)": "<svg/>",
            ],
        )
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath("images/\(fileName)")) {
            _ = try makeStaticPassthroughGenerator(fileSystem: fileSystem).buildContent(
                .init(
                    contentRootPath: "content",
                    template: .layout(.topNav),
                    outputRootPath: "dist",
                    configuration: .init(
                        staticPassthroughs: [
                            .init(sourcePath: "public/images", outputPath: "images"),
                        ],
                    ),
                ),
            )
        }
    }
}

private func makeStaticPassthroughGenerator(
    fileSystem: any TileKit.Site.FileSystem,
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
    )
}
