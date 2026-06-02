import Testing
import TileCore
import TileMarkdown
@testable import TileOutput
import TileTile

/// End-to-end coverage of Markdown fenced capability blocks (charts, mermaid
/// diagrams) flowing through the Markdown renderer's `FencedBlockRendering` seam
/// into the assembled page and its collected assets.
@Suite("Output fenced capability blocks")
struct TileOutputFencedBlockTests {
    private func renderer(
        _ fenced: any TileKit.FencedBlockRendering,
    ) -> TileKit.Output.HTMLRenderer {
        .init(
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(fencedRenderer: fenced),
            tileRegistry: .init(),
        )
    }

    @Test("renders a chart fence to SVG and collects its stylesheet")
    func chartFenceRendersToSVG() throws {
        let document = TileKit.Output.Document(blocks: [
            .markdown(
                """
                Before the chart.

                ```chart
                type: bar
                title: Release metrics
                categories: Jan, Feb
                series: Downloads = 3, 5
                ```

                After the chart.
                """,
            ),
        ])

        let artifact = try renderer(TileKit.Tile.ChartFenceRenderer()).render(document)
        #expect(artifact.contents.contains("td-chart-svg"))
        #expect(artifact.contents.contains("Release metrics"))
        #expect(artifact.contents.contains("<p>Before the chart.</p>"))
        #expect(!artifact.contents.contains("language-chart"))
        #expect(artifact.assets.css.contains(".td-chart-frame"))
    }

    @Test("an unparseable chart fence falls back to an escaped code block")
    func chartFenceFallsBack() throws {
        let document = TileKit.Output.Document(blocks: [
            .markdown(
                """
                ```chart
                type: bar
                ```
                """,
            ),
        ])

        let artifact = try renderer(TileKit.Tile.ChartFenceRenderer()).render(document)
        #expect(artifact.contents.contains("language-chart"))
        #expect(!artifact.contents.contains("td-chart-svg"))
    }

    @Test("a mermaid graph fence renders the runtime and collects its script")
    func mermaidFenceCollectsScript() throws {
        let document = TileKit.Output.Document(blocks: [
            .markdown(
                """
                ```mermaid
                graph TD
                  A[Start] --> B[End]
                ```
                """,
            ),
        ])

        let artifact = try renderer(TileKit.Tile.MermaidFenceRenderer()).render(document)
        #expect(artifact.contents.contains("td-mermaid-source"))
        #expect(!artifact.contents.contains("language-mermaid"))
        #expect(artifact.assets.javascript.contains("mermaid"))
    }

    @Test("a composite renderer dispatches chart and mermaid fences together")
    func compositeDispatchesBoth() throws {
        let composite = TileKit.CompositeFencedBlockRenderer([
            TileKit.Tile.ChartFenceRenderer(),
            TileKit.Tile.MermaidFenceRenderer(),
        ])
        let document = TileKit.Output.Document(blocks: [
            .markdown(
                """
                ```chart
                type: pie
                slice: A = 3
                slice: B = 1
                ```

                ```mermaid
                graph TD
                  A[X] --> B[Y]
                ```
                """,
            ),
        ])

        let artifact = try renderer(composite).render(document)
        #expect(artifact.contents.contains("td-chart-svg"))
        #expect(artifact.contents.contains("td-mermaid-source"))
        #expect(artifact.assets.javascript.contains("mermaid"))
    }
}
