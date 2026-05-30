import Testing
import TileCore
import TileMarkdown
@testable import TileOutput
import TileTile

@Suite("Output HTML renderer")
struct TileOutputHTMLRendererTests {
    /// A markdown renderer that wraps text so block boundaries are observable.
    private struct StubMarkdown: TileKit.Markdown.Rendering {
        func renderHTML(
            _ markdown: String,
        ) -> String {
            "<p>\(markdown)</p>"
        }
    }

    /// A tile renderer that emits HTML plus page-local assets.
    private struct AssetTile: TileKit.Tile.Rendering {
        func render(
            _ tile: TileKit.Tile.Instance,
        ) -> TileKit.Tile.Rendered {
            .init(
                html: "<div>\(tile.typeID)</div>",
                css: ".x {}",
                javascript: "go()",
            )
        }
    }

    /// A second styled tile with distinct CSS, to prove dedup keys on content.
    private struct OtherTile: TileKit.Tile.Rendering {
        func render(
            _ tile: TileKit.Tile.Instance,
        ) -> TileKit.Tile.Rendered {
            .init(html: "<b>\(tile.typeID)</b>", css: ".y {}")
        }
    }

    /// A tile that rejects the theme and emits into the tile-override layer.
    private struct OverrideTile: TileKit.Tile.Rendering {
        func render(
            _ tile: TileKit.Tile.Instance,
        ) -> TileKit.Tile.Rendered {
            .init(html: "<i>\(tile.typeID)</i>", css: ".z {}", cssPosture: .overriding)
        }
    }

    /// A tile renderer with no assets, to exercise the empty-skip path.
    private struct PlainTile: TileKit.Tile.Rendering {
        func render(
            _ tile: TileKit.Tile.Instance,
        ) -> TileKit.Tile.Rendered {
            .init(html: "<span>\(tile.typeID)</span>")
        }
    }

    private func renderer(
        tileRegistry: TileKit.Tile.Registry = .init(),
    ) -> TileKit.Output.HTMLRenderer {
        .init(
            markdownRenderer: StubMarkdown(),
            tileRegistry: tileRegistry,
        )
    }

    @Test("the format id and file extension are html")
    func format() throws {
        #expect(renderer().formatID == "html")
        #expect(TileKit.Output.HTMLRenderer.formatID == "html")

        let artifact = try renderer().render(.init(blocks: [.markdown("x")]))
        #expect(artifact.fileExtension == "html")
    }

    @Test("renders markdown and tile blocks as HTML in source order")
    func sourceOrder() throws {
        let registry = TileKit.Tile.Registry(renderers: ["box": AssetTile()])
        let document = TileKit.Output.Document(
            blocks: [
                .markdown("Intro"),
                .tile(.init(typeID: "box", properties: [])),
                .markdown("Outro"),
            ],
        )

        let artifact = try renderer(tileRegistry: registry).render(document)
        #expect(artifact.contents == "<p>Intro</p>\n<div>box</div>\n<p>Outro</p>")
    }

    @Test("collects each tile's css and javascript into the artifact assets")
    func collectsAssets() throws {
        let registry = TileKit.Tile.Registry(renderers: ["box": AssetTile()])
        let document = TileKit.Output.Document(
            blocks: [
                .tile(.init(typeID: "box", properties: [])),
                .tile(.init(typeID: "box", properties: [])),
            ],
        )

        let artifact = try renderer(tileRegistry: registry).render(document)
        // The two tiles' identical CSS is deduplicated to one rule inside the theme
        // layer; JavaScript is not deduplicated (it can be per instance).
        #expect(artifact.assets.css == "@layer reset, theme, tile-override;\n@layer theme {\n.x {}\n}")
        #expect(artifact.assets.javascript == "go()\ngo()")
    }

    @Test("keeps distinct tile css while collapsing duplicates")
    func dedupKeepsDistinctCSS() throws {
        let registry = TileKit.Tile.Registry(
            renderers: ["box": AssetTile(), "other": OtherTile()],
        )
        let document = TileKit.Output.Document(
            blocks: [
                .tile(.init(typeID: "box", properties: [])),
                .tile(.init(typeID: "other", properties: [])),
                .tile(.init(typeID: "box", properties: [])),
            ],
        )

        let artifact = try renderer(tileRegistry: registry).render(document)
        // ".x {}" appears once (deduped), ".y {}" kept, both inside the theme layer.
        #expect(artifact.assets.css == "@layer reset, theme, tile-override;\n@layer theme {\n.x {}\n.y {}\n}")
    }

    @Test("an overriding tile's css lands in the tile-override layer")
    func overridePosture() throws {
        let registry = TileKit.Tile.Registry(renderers: ["custom": OverrideTile()])
        let document = TileKit.Output.Document(
            blocks: [.tile(.init(typeID: "custom", properties: []))],
        )

        let artifact = try renderer(tileRegistry: registry).render(document)
        #expect(artifact.assets.css == "@layer reset, theme, tile-override;\n@layer tile-override {\n.z {}\n}")
    }

    @Test("themed and overriding css go to their own layers in order")
    func themedAndOverrideLayers() throws {
        let registry = TileKit.Tile.Registry(
            renderers: ["box": AssetTile(), "custom": OverrideTile()],
        )
        let document = TileKit.Output.Document(
            blocks: [
                .tile(.init(typeID: "box", properties: [])),
                .tile(.init(typeID: "custom", properties: [])),
            ],
        )

        let artifact = try renderer(tileRegistry: registry).render(document)
        #expect(
            artifact.assets.css == """
            @layer reset, theme, tile-override;
            @layer theme {
            .x {}
            }
            @layer tile-override {
            .z {}
            }
            """,
        )
    }

    @Test("skips empty assets so blank fragments are not joined in")
    func skipsEmptyAssets() throws {
        let registry = TileKit.Tile.Registry(renderers: ["plain": PlainTile()])
        let document = TileKit.Output.Document(
            blocks: [.tile(.init(typeID: "plain", properties: []))],
        )

        let artifact = try renderer(tileRegistry: registry).render(document)
        #expect(artifact.contents == "<span>plain</span>")
        #expect(artifact.assets == .init())
    }

    @Test("an empty document renders empty contents and assets")
    func emptyDocument() throws {
        let artifact = try renderer().render(.init(blocks: []))
        #expect(artifact.contents.isEmpty)
        #expect(artifact.assets == .init())
    }

    @Test("an unregistered tile type renders through the registry's unknown fallback")
    func unknownTile() throws {
        // An empty registry falls back to the default unknown renderer.
        let document = TileKit.Output.Document(
            blocks: [.tile(.init(typeID: "mystery", properties: []))],
        )

        let artifact = try renderer().render(document)
        #expect(artifact.contents.contains("data-td-unsupported-tile=\"mystery\""))
    }

    @Test("renders through the output registry for the html format")
    func throughRegistry() throws {
        let tileRegistry = TileKit.Tile.Registry(renderers: ["box": AssetTile()])
        let registry = TileKit.Output.Registry()
            .registering(renderer(tileRegistry: tileRegistry))

        let artifact = try registry.render(
            .init(blocks: [.tile(.init(typeID: "box", properties: []))]),
            format: TileKit.Output.HTMLRenderer.formatID,
        )
        #expect(artifact.contents == "<div>box</div>")
        #expect(artifact.assets.css == "@layer reset, theme, tile-override;\n@layer theme {\n.x {}\n}")
    }
}
