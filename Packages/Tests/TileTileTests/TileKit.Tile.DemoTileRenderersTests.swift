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

    @Test("embed renders a responsive YouTube iframe through youtube-nocookie")
    func embedRendersYouTube() throws {
        let rendered = try TileKit.Tile.EmbedRenderer().render(
            .init(
                typeID: "embed",
                properties: [
                    .init(key: "url", value: .string("https://www.youtube.com/watch?v=dQw4w9WgXcQ")),
                    .init(key: "title", value: .string(#"Demo "video""#)),
                    .init(key: "aspectRatio", value: .string("4/3")),
                ],
            ),
        )

        #expect(rendered.html.contains(#"src="https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ""#))
        #expect(rendered.html.contains(#"title="Demo &quot;video&quot;""#))
        #expect(rendered.html.contains("--td-embed-aspect-ratio: 4 / 3"))
        #expect(rendered.html.contains("loading=\"lazy\""))
        #expect(rendered.css.contains(".td-embed-frame"))
        #expect(rendered.javascript.isEmpty)
    }

    @Test("embed renders Vimeo and direct HTTPS videos")
    func embedRendersVimeoAndVideo() throws {
        let vimeo = try TileKit.Tile.EmbedRenderer().render(
            .init(
                typeID: "embed",
                properties: [
                    .init(key: "url", value: .string("https://vimeo.com/123456")),
                ],
            ),
        )
        #expect(vimeo.html.contains(#"src="https://player.vimeo.com/video/123456""#))

        let video = try TileKit.Tile.EmbedRenderer().render(
            .init(
                typeID: "embed",
                properties: [
                    .init(key: "url", value: .string("https://media.example.com/demo.mp4")),
                ],
            ),
        )
        #expect(video.html.contains("<video class=\"td-embed-video\" controls preload=\"none\""))
        #expect(video.html.contains(#"type="video/mp4""#))
    }

    @Test("embed rejects unsafe or unsupported inputs")
    func embedRejectsUnsafeInputs() {
        #expect(throws: TileKit.Tile.EmbedRendererError.missingProperty("url")) {
            try TileKit.Tile.EmbedRenderer().render(.init(typeID: "embed", properties: []))
        }

        #expect(throws: TileKit.Tile.EmbedRendererError.unsupportedScheme("javascript")) {
            try TileKit.Tile.EmbedRenderer().render(
                .init(
                    typeID: "embed",
                    properties: [
                        .init(key: "url", value: .string("javascript:alert(1)")),
                    ],
                ),
            )
        }

        #expect(throws: TileKit.Tile.EmbedRendererError.unsupportedProvider("https://example.com/widget")) {
            try TileKit.Tile.EmbedRenderer().render(
                .init(
                    typeID: "embed",
                    properties: [
                        .init(key: "url", value: .string("https://example.com/widget")),
                    ],
                ),
            )
        }

        let credentialURL = "https://user:secret@example.com/video.mp4"
        #expect(throws: TileKit.Tile.EmbedRendererError.unsupportedProvider(credentialURL)) {
            try TileKit.Tile.EmbedRenderer().render(
                .init(
                    typeID: "embed",
                    properties: [
                        .init(key: "url", value: .string(credentialURL)),
                    ],
                ),
            )
        }

        #expect(throws: TileKit.Tile.EmbedRendererError.invalidAspectRatio("16:9")) {
            try TileKit.Tile.EmbedRenderer().render(
                .init(
                    typeID: "embed",
                    properties: [
                        .init(key: "url", value: .string("https://vimeo.com/123456")),
                        .init(key: "aspectRatio", value: .string("16:9")),
                    ],
                ),
            )
        }
    }

    @Test("mermaid renders escaped source and emits the browser runtime")
    func mermaidRenders() throws {
        let rendered = try TileKit.Tile.MermaidRenderer().render(
            .init(
                typeID: "mermaid",
                properties: [
                    .init(
                        key: "definition",
                        value: .string(
                            """
                            graph TD
                              A[Start] --> B{OK?}
                              B -->|yes| C[<script>]
                            """,
                        ),
                    ),
                    .init(key: "title", value: .string("Release flow")),
                ],
            ),
        )

        #expect(rendered.html.contains(#"<figure class="td-mermaid" data-td-mermaid>"#))
        #expect(rendered.html.contains("A[Start] --&gt; B{OK?}"))
        #expect(rendered.html.contains("C[&lt;script&gt;]"))
        #expect(rendered.html.contains(#"<figcaption class="td-mermaid-caption">Release flow</figcaption>"#))
        #expect(rendered.css.contains(".td-mermaid-source"))
        #expect(rendered.javascript.contains("mermaid@10.9.3"))
        #expect(rendered.javascript.contains("securityLevel: 'strict'"))
        #expect(rendered.javascript.contains("MutationObserver"))
        #expect(rendered.javascript.contains("data-td-mermaid-error"))
    }

    @Test("mermaid rejects missing definitions and wrong tile types")
    func mermaidRejectsInvalidInputs() {
        #expect(throws: TileKit.Tile.MermaidRendererError.missingProperty("definition")) {
            try TileKit.Tile.MermaidRenderer().render(
                .init(typeID: "mermaid", properties: []),
            )
        }

        #expect(throws: TileKit.Tile.MermaidRendererError.invalidTileType(actual: "chart")) {
            try TileKit.Tile.MermaidRenderer().render(
                .init(
                    typeID: "chart",
                    properties: [
                        .init(key: "definition", value: .string("graph TD\nA --> B")),
                    ],
                ),
            )
        }
    }
}
