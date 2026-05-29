import Testing
import TileCore
@testable import TileTile

@Suite("Tile directive parser")
struct TileDirectiveParserTests {
    @Test("parses Markdown and tile directive blocks")
    func parsesMarkdownAndTileBlocks() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            # Intro

            :::tile poll
            id: favorite-editor
            mode: local
            question: What editor do you use?
            options:
              - Xcode
              - VS Code
              - Other
            :::

            After text
            """,
        )

        #expect(blocks.count == 3)
        #expect(blocks[0] == .markdown("# Intro\n"))
        #expect(blocks[2] == .markdown("\nAfter text"))

        guard case let .tile(tile) = blocks[1] else {
            Issue.record("Expected a tile block")
            return
        }

        #expect(tile.typeID == "poll")
        #expect(tile.property(named: "id") == .string("favorite-editor"))
        #expect(tile.property(named: "mode") == .string("local"))
        #expect(tile.property(named: "question") == .string("What editor do you use?"))
        #expect(tile.property(named: "options") == .list(["Xcode", "VS Code", "Other"]))
    }

    @Test("keeps property order")
    func keepsPropertyOrder() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            :::tile youtube-video
            id: swift-talk
            mode: static
            videoId: dQw4w9WgXcQ
            privacyEnhanced: true
            :::
            """,
        )

        guard case let .tile(tile) = blocks.first else {
            Issue.record("Expected a tile block")
            return
        }

        #expect(tile.properties.map(\.key) == ["id", "mode", "videoId", "privacyEnhanced"])
    }

    @Test("throws on missing closing fence")
    func throwsOnMissingClosingFence() {
        let parser = TileKit.Tile.DirectiveParser()

        #expect(throws: TileKit.Tile.DirectiveParserError.missingClosingFence(line: 1)) {
            try parser.parseBlocks(
                """
                :::tile poll
                id: favorite-editor
                """,
            )
        }
    }
}
