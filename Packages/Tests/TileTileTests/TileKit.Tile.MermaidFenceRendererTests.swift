import Testing
import TileCore
@testable import TileTile

@Suite("Mermaid fence renderer")
struct MermaidFenceRendererTests {
    @Test("a graph diagram renders the client mermaid runtime container")
    func graphRendersRuntime() {
        let block = TileKit.Tile.MermaidFenceRenderer().rendered(
            language: "mermaid",
            source: "graph TD\n  A[Start] --> B[End]",
        )

        #expect(block?.html.contains("td-mermaid-source") == true)
        #expect(block?.html.contains(#"class="mermaid"#) == true)
        #expect(block?.html.contains("A[Start]") == true)
        #expect(block?.javascript.contains("mermaid") == true)
    }

    @Test("a pie diagram renders a static SVG chart with no runtime")
    func pieRendersStaticChart() {
        let block = TileKit.Tile.MermaidFenceRenderer().rendered(
            language: "mermaid",
            source: "pie title Results\n  \"Pass\" : 5\n  \"Fail\" : 1",
        )

        #expect(block?.html.contains("td-chart-svg") == true)
        #expect(block?.html.contains("td-chart-pie") == true)
        #expect(block?.html.contains("Results") == true)
        #expect(block?.javascript.isEmpty == true)
    }

    @Test("a non-mermaid language is not claimed")
    func ignoresOtherLanguages() {
        let block = TileKit.Tile.MermaidFenceRenderer().rendered(language: "swift", source: "let x = 1")
        #expect(block == nil)
    }
}
