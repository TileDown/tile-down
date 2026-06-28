import Testing
import TileCore
@testable import TileTile

@Suite("Buttondown renderer")
struct ButtondownRendererTests {
    @Test("renders a subscribe form with tags and metadata")
    func rendersSubscribeFormWithTagsAndMetadata() throws {
        let rendered = try TileKit.Tile.ButtondownRenderer().render(
            .init(
                typeID: "buttondown",
                properties: [
                    .init(key: "username", value: .string("mihaela")),
                    .init(key: "title", value: .string("Apple Frameworks")),
                    .init(key: "body", value: .string("Clean-room notes <daily>")),
                    .init(key: "emailLabel", value: .string("Work email")),
                    .init(key: "placeholder", value: .string("you@example.com")),
                    .init(key: "buttonLabel", value: .string("Join")),
                    .init(key: "note", value: .string("No spam.")),
                    .init(key: "tags", value: .list(["swift", "frameworks"])),
                    .init(key: "metadata.source", value: .string("tiledown")),
                ],
            ),
        )

        #expect(
            rendered.html.contains(
                #"action="https://buttondown.com/api/emails/embed-subscribe/mihaela""#,
            ),
        )
        #expect(rendered.html.contains(#"<input type="hidden" name="embed" value="1">"#))
        #expect(rendered.html.contains(#"<input type="hidden" name="tag" value="swift">"#))
        #expect(rendered.html.contains(#"<input type="hidden" name="tag" value="frameworks">"#))
        #expect(rendered.html.contains(#"<input type="hidden" name="metadata__source" value="tiledown">"#))
        #expect(rendered.html.contains("Clean-room notes &lt;daily&gt;"))
        #expect(rendered.html.contains(#"placeholder="you@example.com""#))
        #expect(rendered.html.contains(#"<button class="td-buttondown-submit" type="submit">Join</button>"#))
        #expect(rendered.html.contains("Powered by Buttondown."))
        #expect(rendered.css.contains(".td-buttondown"))
        #expect(rendered.javascript.isEmpty)
    }

    @Test("hides attribution when poweredBy is false")
    func hidesAttributionWhenDisabled() throws {
        let rendered = try TileKit.Tile.ButtondownRenderer().render(
            .init(
                typeID: "buttondown",
                properties: [
                    .init(key: "username", value: .string("mihaela")),
                    .init(key: "poweredBy", value: .string("false")),
                ],
            ),
        )

        #expect(!rendered.html.contains("Powered by Buttondown."))
    }

    @Test("rejects missing usernames")
    func rejectsMissingUsernames() {
        #expect(throws: TileKit.Tile.ButtondownRendererError.missingProperty("username")) {
            try TileKit.Tile.ButtondownRenderer().render(
                .init(typeID: "buttondown", properties: []),
            )
        }
    }

    @Test("rejects invalid usernames")
    func rejectsInvalidUsernames() {
        #expect(throws: TileKit.Tile.ButtondownRendererError.invalidUsername("bad/name")) {
            try TileKit.Tile.ButtondownRenderer().render(
                .init(
                    typeID: "buttondown",
                    properties: [
                        .init(key: "username", value: .string("bad/name")),
                    ],
                ),
            )
        }
    }

    @Test("rejects invalid metadata keys")
    func rejectsInvalidMetadataKeys() {
        #expect(throws: TileKit.Tile.ButtondownRendererError.invalidMetadataKey("")) {
            try TileKit.Tile.ButtondownRenderer().render(
                .init(
                    typeID: "buttondown",
                    properties: [
                        .init(key: "username", value: .string("mihaela")),
                        .init(key: "metadata.", value: .string("x")),
                    ],
                ),
            )
        }
    }

    @Test("rejects invalid poweredBy boolean values")
    func rejectsInvalidPoweredByBooleanValues() {
        #expect(
            throws: TileKit.Tile.ButtondownRendererError.invalidBoolean(
                property: "poweredBy",
                value: "flase",
            ),
        ) {
            try TileKit.Tile.ButtondownRenderer().render(
                .init(
                    typeID: "buttondown",
                    properties: [
                        .init(key: "username", value: .string("mihaela")),
                        .init(key: "poweredBy", value: .string("flase")),
                    ],
                ),
            )
        }
    }

    @Test("rejects list poweredBy boolean values")
    func rejectsListPoweredByBooleanValues() {
        #expect(
            throws: TileKit.Tile.ButtondownRendererError.invalidBoolean(
                property: "poweredBy",
                value: "list",
            ),
        ) {
            try TileKit.Tile.ButtondownRenderer().render(
                .init(
                    typeID: "buttondown",
                    properties: [
                        .init(key: "username", value: .string("mihaela")),
                        .init(key: "poweredBy", value: .list(["false"])),
                    ],
                ),
            )
        }
    }
}
