import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site theme tag bar")
struct SiteThemeTagBarTests {
    @Test("the built-in sticky tag bar bounds its height so it cannot eclipse the page")
    func stickyTagBarHeightIsBounded() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\ntagBar: true\n---\n# Posts",
                "content/posts/alpha/index.md": "---\ntitle: Alpha\ndate: 2026-05-28\ntags: swift, ios\n---\n# Alpha",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        // The tag bar shows every site tag, so with many tags it wraps tall; being
        // sticky with a background it would float over and hide the content behind
        // it. Its height is bounded with an internal scroll so it stays a compact
        // filter that can never eclipse the page.
        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains(".td-tagbar { position: sticky;"))
        #expect(css.contains("max-height: clamp(6rem, 28vh, 14rem); overflow-y: auto;"))
    }

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
