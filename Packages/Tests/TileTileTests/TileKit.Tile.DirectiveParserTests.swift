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

    @Test("parses multiline string properties")
    func parsesMultilineStringProperties() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            :::tile mermaid
            title: Release flow
            definition: |
              graph TD
                A[Start] --> B{OK?}
                B -->|yes| C[Ship]
            :::
            """,
        )

        guard case let .tile(tile) = blocks.first else {
            Issue.record("Expected a tile block")
            return
        }

        #expect(tile.typeID == "mermaid")
        #expect(tile.property(named: "title") == .string("Release flow"))
        #expect(
            tile.property(named: "definition") == .string(
                """
                graph TD
                  A[Start] --> B{OK?}
                  B -->|yes| C[Ship]
                """,
            ),
        )
    }

    @Test("parses exact mermaid shorthand as a definition property")
    func parsesMermaidShorthand() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            :::mermaid
            graph TD
              A[Start] --> B{OK?}
              B -->|no| A
            :::
            """,
        )

        guard case let .tile(tile) = blocks.first else {
            Issue.record("Expected a tile block")
            return
        }

        #expect(tile.typeID == "mermaid")
        #expect(
            tile.property(named: "definition") == .string(
                """
                graph TD
                  A[Start] --> B{OK?}
                  B -->|no| A
                """,
            ),
        )
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

    @Test("treats a tile fence inside a code block as Markdown content")
    func ignoresTileFenceInsideCodeBlock() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            Example:

            ```
            :::tile fake
            content
            :::
            ```

            After.
            """,
        )

        #expect(!blocks.contains { if case .tile = $0 { true } else { false } })
        let markdown = blocks
            .compactMap { if case let .markdown(text) = $0 { text } else { nil } }
            .joined(separator: "\n")
        #expect(markdown.contains(":::tile fake"))
    }

    @Test("tilde code fences also shield tile fences")
    func ignoresTileFenceInsideTildeFence() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            ~~~
            :::tile fake
            ~~~
            """,
        )

        #expect(blocks.count == 1)
        #expect(!blocks.contains { if case .tile = $0 { true } else { false } })
    }

    @Test("a line with backticks in its info is not a fence opener")
    func inlineCodeIsNotAFenceOpener() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            ```inline``` text

            :::tile real
            id: x
            :::
            """,
        )

        // The leading-backtick line is an inline code span, not a code fence, so
        // the real tile that follows must still be parsed.
        #expect(blocks.contains { if case .tile = $0 { true } else { false } })
    }

    @Test("still parses a real tile after a code block")
    func parsesTileAfterCodeBlock() throws {
        let parser = TileKit.Tile.DirectiveParser()

        let blocks = try parser.parseBlocks(
            """
            ```
            code
            ```

            :::tile poll
            id: x
            :::
            """,
        )

        #expect(blocks.contains { if case .tile = $0 { true } else { false } })
    }

    @Test("plain unindented body lines remain invalid in canonical tile directives")
    func plainBodyLinesRemainInvalid() {
        let parser = TileKit.Tile.DirectiveParser()

        #expect(throws: TileKit.Tile.DirectiveParserError.invalidPropertyLine(line: 2, text: "graph TD")) {
            try parser.parseBlocks(
                """
                :::tile mermaid
                graph TD
                :::
                """,
            )
        }
    }
}
