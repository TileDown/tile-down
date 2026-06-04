import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Tags landing")
struct SiteTagsLandingTests {
    @Test("the generated tags landing page clears filters to every post")
    func generatedTagsLandingListsEveryPost() throws {
        let fileSystem = MemoryFileSystem(files: fixtureFiles())

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let all = try #require(fileSystem.files["dist/tags/index.html"])
        let beta = try #require(all.range(of: "<li>Beta</li>")?.lowerBound)
        let gamma = try #require(all.range(of: "<li>Gamma</li>")?.lowerBound)
        let alpha = try #require(all.range(of: "<li>Alpha</li>")?.lowerBound)
        #expect(beta < gamma)
        #expect(gamma < alpha)
    }

    @Test("an authored tags landing page is not overwritten")
    func authoredTagsLandingPageWins() throws {
        var files = fixtureFiles()
        files["content/tags/index.md"] = "---\ntitle: Tags\n---\nBrowse tags."
        let fileSystem = MemoryFileSystem(files: files)

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let tags = try #require(fileSystem.files["dist/tags/index.html"])
        #expect(tags.contains("<title>Tags</title>"))
        #expect(!tags.contains("<li>Beta</li>"))
    }

    private func fixtureFiles() -> [String: String] {
        [
            "content/index.md": "---\ntitle: Home\n---\n# Home",
            "content/posts/index.md": "---\ntitle: Posts\n---\n# Posts",
            "content/posts/alpha/index.md": "---\ntitle: Alpha\ndate: 2026-05-28\ntags: swift, ios\n---\n# Alpha",
            "content/posts/beta/index.md": "---\ntitle: Beta\ndate: 2026-05-30\ntags: swift\n---\n# Beta",
            "content/posts/gamma/index.md": "---\ntitle: Gamma\ndate: 2026-05-29\n---\n# Gamma",
            "templates/page.html": tagListingTemplate(),
        ]
    }

    private func tagListingTemplate() -> String {
        [
            "<title>{{ page.title }}</title>",
            "{{#page.postList}}{{#page.posts}}<li>{{ title }}</li>{{/page.posts}}{{/page.postList}}",
        ].joined()
    }

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(
                    passthroughSchemes: TileKit.Site.Reference.schemes,
                ),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
