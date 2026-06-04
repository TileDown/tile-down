import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Tags navigation")
struct SiteTagsNavigationTests {
    @Test("generated tags landing is not added to site navigation")
    func generatedTagsLandingDoesNotAppearInNavigation() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\ntagBar: true\n---\n# Posts",
                "content/posts/alpha/index.md": "---\ntitle: Alpha\ndate: 2026-05-28\ntags: swift\n---\n# Alpha",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<nav class="td-nav"><a class="td-nav-link" href="/posts/">Posts</a></nav>"#))
        #expect(!home.contains(#"href="/tags/">All articles</a>"#))

        let tags = try #require(fileSystem.files["dist/tags/index.html"])
        #expect(tags.contains(#"<h1 class="td-tagbar-title">All articles</h1>"#))
        #expect(tags.contains(#"href="/tags/swift/">swift</a>"#))
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
