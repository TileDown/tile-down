import Testing
import TileCore
@testable import TileTile

@Suite("Tile renderer registry")
struct TileRegistryTests {
    @Test("renders registered tile types")
    func rendersRegisteredTileTypes() throws {
        let registry = TileKit.Tile.Registry(
            renderers: [
                "promo": StubRenderer(
                    rendered: .init(
                        html: "<aside>Promo</aside>",
                        css: ".promo {}",
                        javascript: "console.log('promo');",
                    ),
                ),
            ],
        )

        let rendered = try registry.render(
            .init(
                typeID: "promo",
                properties: [],
            ),
        )

        #expect(rendered.html == "<aside>Promo</aside>")
        #expect(rendered.css == ".promo {}")
        #expect(rendered.javascript == "console.log('promo');")
    }

    @Test("renders unsupported tiles as escaped diagnostics")
    func rendersUnsupportedTilesAsEscapedDiagnostics() throws {
        let rendered = try TileKit.Tile.Registry().render(
            .init(
                typeID: #"unknown"<script>"#,
                properties: [],
            ),
        )

        #expect(rendered.html.contains("Unsupported tile: unknown&quot;&lt;script&gt;"))
        #expect(rendered.html.contains(#"data-td-unsupported-tile="unknown&quot;&lt;script&gt;""#))
    }

    private struct StubRenderer: TileKit.Tile.Rendering {
        var rendered: TileKit.Tile.Rendered

        func render(
            _: TileKit.Tile.Instance,
        ) -> TileKit.Tile.Rendered {
            rendered
        }
    }
}
