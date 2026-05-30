import Testing
import TileCore
@testable import TileTile

@Suite("Demo tile renderers")
struct DemoTileRenderersTests {
    @Test("callout renders title and body with themed CSS and no JavaScript")
    func calloutRenders() {
        let rendered = TileKit.Tile.CalloutRenderer().render(
            .init(
                typeID: "callout",
                properties: [
                    .init(key: "title", value: .string("Tip")),
                    .init(key: "body", value: .string("Typed tiles <3")),
                ],
            ),
        )

        #expect(rendered.html.contains(#"<p class="td-callout-title">Tip</p>"#))
        // Body text is HTML-escaped.
        #expect(rendered.html.contains("Typed tiles &lt;3"))
        #expect(rendered.css.contains(".td-callout"))
        #expect(rendered.javascript.isEmpty)
        #expect(rendered.cssPosture == .themed)
    }

    @Test("callout falls back to defaults when properties are missing")
    func calloutDefaults() {
        let rendered = TileKit.Tile.CalloutRenderer().render(
            .init(typeID: "callout", properties: []),
        )
        #expect(rendered.html.contains("Note"))
    }

    @Test("counter renders a button with a label and emits local JavaScript")
    func counterRenders() {
        let rendered = TileKit.Tile.CounterRenderer().render(
            .init(
                typeID: "counter",
                properties: [
                    .init(key: "label", value: .string("Tap me")),
                ],
            ),
        )

        #expect(rendered.html.contains("Tap me"))
        #expect(rendered.html.contains("data-td-counter"))
        #expect(rendered.css.contains(".td-counter"))
        // The tile emits a browser runtime scoped to its element.
        #expect(rendered.javascript.contains("addEventListener"))
        #expect(rendered.javascript.contains("[data-td-counter]"))
    }
}
