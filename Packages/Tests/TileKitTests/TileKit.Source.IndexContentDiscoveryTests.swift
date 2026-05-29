import Testing
@testable import TileKit

@Suite("Index content discovery")
struct IndexContentDiscoveryTests {
    @Test("discovers index markdown files as content locations")
    func discoversIndexMarkdownFiles() {
        let discovery = TileKit.Source.IndexContentDiscovery()

        let locations = discovery.discover(
            relativePaths: [
                "index.md",
                "blog/index.md",
                "blog/draft.md",
                "notes/index.markdown",
                "assets/image.png",
            ],
        )

        #expect(
            locations == [
                .init(sourceRelativePath: "index.md", slug: ""),
                .init(sourceRelativePath: "blog/index.md", slug: "blog"),
                .init(sourceRelativePath: "notes/index.markdown", slug: "notes"),
            ],
        )
    }
}
