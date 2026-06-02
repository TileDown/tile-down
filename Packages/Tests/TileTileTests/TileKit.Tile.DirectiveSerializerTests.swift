import Testing
import TileCore
@testable import TileTile

@Suite("Tile directive serializer")
struct TileDirectiveSerializerTests {
    private let parser = TileKit.Tile.DirectiveParser()
    private let serializer = TileKit.Tile.DirectiveSerializer()

    /// Sample Tiledown Markdown documents exercised by the round-trip laws.
    private static let documents: [String] = [
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
        """
        :::tile youtube-video
        id: swift-talk
        mode: static
        videoId: dQw4w9WgXcQ
        :::
        :::tile service-form
        id: price-calculator
        service: calculator
        operation: positive-decimal-calculation
        mode: proxy
        :::
        """,
        """
        :::tile mermaid
        title: Release flow
        definition: |
          graph TD
            A[Start] --> B{OK?}
            B -->|yes| C[Ship]
        :::
        """,
    ]

    // PutGet: parsing the serialized form of a parsed tree yields the same tree.
    // This is the research's semantic round-trip invariant: parse -> serialize ->
    // parse, AST1 == AST2. Byte identity is explicitly not the goal.
    @Test("PutGet: a parsed tree survives serialize then re-parse")
    func putGet() throws {
        for markdown in Self.documents {
            let tree = try parser.parseBlocks(markdown)
            let reparsed = try parser.parseBlocks(serializer.serialize(tree))
            #expect(reparsed == tree)
        }
    }

    // PutPut: the canonical serialization is a fixed point, so repeated edits do
    // not accumulate change. serialize(parse(canonical)) == canonical.
    @Test("PutPut: canonical serialization is a fixed point")
    func putPut() throws {
        for markdown in Self.documents {
            let once = try serializer.serialize(parser.parseBlocks(markdown))
            let twice = try serializer.serialize(parser.parseBlocks(once))
            #expect(twice == once)
        }
    }

    @Test("preserves unknown tile types and unknown properties")
    func preservesUnknown() throws {
        let markdown = """
        :::tile vendor.mystery
        id: m-1
        weirdProp: kept
        emptyProp:
        :::
        """
        let tree = try parser.parseBlocks(markdown)
        let reparsed = try parser.parseBlocks(serializer.serialize(tree))
        #expect(reparsed == tree)

        guard case let .tile(tile) = tree.first else {
            Issue.record("expected a tile block")
            return
        }
        #expect(tile.typeID == "vendor.mystery")
        #expect(tile.property(named: "weirdProp") == .string("kept"))
        #expect(tile.property(named: "emptyProp") == .string(""))
    }

    @Test("emits a tile in one canonical form")
    func canonicalTileOutput() {
        let tile = TileKit.Tile.Instance(
            typeID: "poll",
            properties: [
                .init(key: "id", value: .string("favorite-editor")),
                .init(key: "options", value: .list(["Xcode", "VS Code"])),
            ],
        )

        #expect(
            serializer.serialize([.tile(tile)]) == """
            :::tile poll
            id: favorite-editor
            options:
            - Xcode
            - VS Code
            :::
            """,
        )
    }

    @Test("emits multiline string properties as literal blocks")
    func multilineStringOutput() {
        let tile = TileKit.Tile.Instance(
            typeID: "mermaid",
            properties: [
                .init(
                    key: "definition",
                    value: .string(
                        """
                        graph TD
                          A[Start] --> B{OK?}
                          B -->|yes| C[Ship]
                        """,
                    ),
                ),
            ],
        )

        #expect(
            serializer.serialize([.tile(tile)]) == """
            :::tile mermaid
            definition: |
              graph TD
                A[Start] --> B{OK?}
                B -->|yes| C[Ship]
            :::
            """,
        )
    }
}
