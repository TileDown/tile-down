import Testing
import TileCore
import TileMarkdown
import TileSite
import TileTile

@Suite("Document serializer")
struct DocumentSerializerTests {
    private let parser = TileKit.Tile.DirectiveParser()
    private let serializer = TileKit.Site.DocumentSerializer(
        markdownFormatter: TileKit.Markdown.CommonMarkFormatter(),
    )
    private let renderer = TileKit.Markdown.CommonMarkRenderer()

    private static let document = """
    Title
    =====

    * one
    * two

    :::tile poll
    id: favorite
    mode: local
    :::

    Some _emphasis_ here.
    """

    @Test("canonicalizes both prose and tiles to one form")
    func canonicalizes() throws {
        let output = try serializer.serialize(parser.parseBlocks(Self.document))
        #expect(output.contains("# Title"))
        #expect(output.contains("- one\n- two"))
        #expect(output.contains(":::tile poll"))
        #expect(output.contains("Some *emphasis* here."))
        #expect(!output.contains("====="))
    }

    @Test("the canonical document is a fixed point (PutPut)")
    func fixedPoint() throws {
        let once = try serializer.serialize(parser.parseBlocks(Self.document))
        let twice = try serializer.serialize(parser.parseBlocks(once))
        #expect(twice == once)
    }

    @Test("once canonical, the tile tree round-trips (PutGet)")
    func putGet() throws {
        let canonical = try serializer.serialize(parser.parseBlocks(Self.document))
        let first = try parser.parseBlocks(canonical)
        let second = try parser.parseBlocks(serializer.serialize(first))
        #expect(second == first)
    }

    @Test("canonicalizing prose preserves its rendered meaning")
    func semanticPreservation() {
        let prose = "Title\n=====\n\n* one\n* two\n\nSome _emphasis_."
        let canonical = TileKit.Markdown.CommonMarkFormatter().canonicalize(prose)
        #expect(renderer.renderHTML(prose) == renderer.renderHTML(canonical))
    }
}
