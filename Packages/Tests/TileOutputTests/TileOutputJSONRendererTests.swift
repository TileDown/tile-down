import Foundation
import Testing
import TileCore
@testable import TileOutput
import TileTile

@Suite("Output JSON renderer")
struct TileOutputJSONRendererTests {
    private let renderer = TileKit.Output.JSONRenderer()

    /// A document exercising prose, ordered properties, both value kinds, an
    /// unknown tile type, and nested children.
    private func sampleDocument(
        frontMatter: [String: String] = ["title": "Hello", "date": "2026-05-30"],
    ) -> TileKit.Output.Document {
        .init(
            frontMatter: frontMatter,
            blocks: [
                .markdown("# Hello\n\nBody."),
                .tile(
                    .init(
                        typeID: "poll",
                        properties: [
                            .init(key: "question", value: .string("Best?")),
                            .init(key: "options", value: .list(["A", "B"])),
                        ],
                        children: [
                            .tile(
                                .init(
                                    typeID: "mystery",
                                    properties: [
                                        .init(key: "shape", value: .string("triangle")),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ],
            slug: "posts/hello",
        )
    }

    private func decode(
        _ artifact: TileKit.Output.Artifact,
    ) throws -> DecodedDocument {
        try JSONDecoder().decode(
            DecodedDocument.self,
            from: Data(artifact.contents.utf8),
        )
    }

    @Test("the artifact is named with a json file extension")
    func fileExtension() throws {
        let artifact = try renderer.render(sampleDocument())
        #expect(artifact.fileExtension == "json")
        #expect(renderer.formatID == "json")
    }

    @Test("output is valid json with a trailing newline")
    func trailingNewline() throws {
        let artifact = try renderer.render(sampleDocument())
        #expect(artifact.contents.hasSuffix("}\n"))
        // Decoding proves the body is valid JSON.
        _ = try decode(artifact)
    }

    @Test("the self-describing header carries the product version and schema format")
    func header() throws {
        let decoded = try decode(renderer.render(sampleDocument()))
        #expect(decoded.tiledown.version == TileKit.Product.version)
        #expect(decoded.tiledown.format == TileKit.Output.JSONRenderer.schemaFormat)
        #expect(decoded.slug == "posts/hello")
    }

    @Test("output is deterministic across repeated renders")
    func deterministicAcrossRenders() throws {
        let document = sampleDocument()
        let first = try renderer.render(document)
        let second = try renderer.render(document)
        #expect(first == second)
    }

    @Test("output is independent of front matter insertion order")
    func deterministicFrontMatterOrder() throws {
        var forward: [String: String] = [:]
        for key in ["alpha", "beta", "gamma", "delta", "epsilon"] {
            forward[key] = key.uppercased()
        }
        var reversed: [String: String] = [:]
        for key in ["epsilon", "delta", "gamma", "beta", "alpha"] {
            reversed[key] = key.uppercased()
        }

        let forwardOutput = try renderer.render(sampleDocument(frontMatter: forward))
        let reversedOutput = try renderer.render(sampleDocument(frontMatter: reversed))
        #expect(forwardOutput == reversedOutput)
    }

    @Test("blocks are projected in source order, prose as a verbatim markdown string")
    func blockOrderAndProse() throws {
        let decoded = try decode(renderer.render(sampleDocument()))
        #expect(decoded.blocks.count == 2)
        #expect(decoded.blocks[0].kind == "markdown")
        #expect(decoded.blocks[0].text == "# Hello\n\nBody.")
        #expect(decoded.blocks[1].kind == "tile")
        #expect(decoded.blocks[1].type == "poll")
    }

    @Test("tile properties preserve source order as an array")
    func propertyOrder() throws {
        let decoded = try decode(renderer.render(sampleDocument()))
        let props = try #require(decoded.blocks[1].props)
        #expect(props.map(\.key) == ["question", "options"])
    }

    @Test("string and list values are tagged by kind")
    func valueKinds() throws {
        let decoded = try decode(renderer.render(sampleDocument()))
        let props = try #require(decoded.blocks[1].props)
        #expect(props[0].value.kind == "string")
        #expect(props[0].value.string == "Best?")
        #expect(props[1].value.kind == "list")
        #expect(props[1].value.list == ["A", "B"])
    }

    @Test("an unknown tile type survives with its type and properties")
    func unknownTileSurvives() throws {
        let decoded = try decode(renderer.render(sampleDocument()))
        let children = try #require(decoded.blocks[1].children)
        let child = try #require(children.first)
        #expect(child.kind == "tile")
        #expect(child.type == "mystery")
        #expect(child.props?.map(\.key) == ["shape"])
        #expect(child.props?.first?.value.string == "triangle")
    }

    @Test("an empty document still emits a well-formed envelope")
    func emptyDocument() throws {
        let decoded = try decode(renderer.render(.init(blocks: [])))
        #expect(decoded.blocks.isEmpty)
        #expect(decoded.frontMatter.isEmpty)
        #expect(decoded.slug.isEmpty)
        #expect(decoded.tiledown.format == TileKit.Output.JSONRenderer.schemaFormat)
    }

    @Test("JSON-significant characters round-trip without corruption")
    func escapesSpecialCharacters() throws {
        let tricky = "quote \" backslash \\ slash / newline \n tab \t unicode é control \u{01} end"
        let document = TileKit.Output.Document(
            frontMatter: ["note": tricky],
            blocks: [
                .markdown("Prose with \" and \\ and / and a newline\nhere."),
                .tile(
                    .init(
                        typeID: "weird \" type",
                        properties: [
                            .init(key: "k \"", value: .string(tricky)),
                            .init(key: "list", value: .list([tricky, "", "plain"])),
                        ],
                    ),
                ),
            ],
            slug: tricky,
        )

        let decoded = try decode(renderer.render(document))
        #expect(decoded.slug == tricky)
        #expect(decoded.frontMatter["note"] == tricky)
        #expect(decoded.blocks[0].text == "Prose with \" and \\ and / and a newline\nhere.")
        #expect(decoded.blocks[1].type == "weird \" type")
        let props = try #require(decoded.blocks[1].props)
        #expect(props[0].key == "k \"")
        #expect(props[0].value.string == tricky)
        #expect(props[1].value.list == [tricky, "", "plain"])
    }

    @Test("a tile with no properties projects an empty props array")
    func tileWithoutProperties() throws {
        let document = TileKit.Output.Document(
            blocks: [.tile(.init(typeID: "bare", properties: []))],
        )
        let decoded = try decode(renderer.render(document))
        let props = try #require(decoded.blocks[0].props)
        #expect(props.isEmpty)
        #expect(decoded.blocks[0].children?.isEmpty == true)
    }
}

// MARK: - Decodable mirrors of the wire schema (test-only)

private struct DecodedDocument: Decodable {
    let tiledown: DecodedHeader
    let slug: String
    let frontMatter: [String: String]
    let blocks: [DecodedBlock]
}

private struct DecodedHeader: Decodable {
    let version: String
    let format: String
}

private struct DecodedBlock: Decodable {
    let kind: String
    let text: String?
    let type: String?
    let props: [DecodedProperty]?
    let children: [DecodedBlock]?
}

private struct DecodedProperty: Decodable {
    let key: String
    let value: DecodedValue
}

private struct DecodedValue: Decodable {
    let kind: String
    let string: String?
    let list: [String]?
}
