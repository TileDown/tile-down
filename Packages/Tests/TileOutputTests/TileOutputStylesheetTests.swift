import Testing
import TileCore
@testable import TileOutput

@Suite("Output stylesheet")
struct TileOutputStylesheetTests {
    @Test("merging unions fragments per layer and deduplicates")
    func merge() {
        let first = TileKit.Output.Stylesheet(themed: [".x {}"], overriding: [".z {}"])
        let second = TileKit.Output.Stylesheet(themed: [".x {}", ".y {}"], overriding: [".z {}"])

        let merged = first.merging(second)
        #expect(merged.themed == [".x {}", ".y {}"])
        #expect(merged.overriding == [".z {}"])
    }

    @Test("text renders the layered css, empty when there are no fragments")
    func text() {
        #expect(TileKit.Output.Stylesheet().text().isEmpty)
        #expect(TileKit.Output.Stylesheet().isEmpty)
        #expect(
            TileKit.Output.Stylesheet(themed: [".x {}"]).text()
                == "@layer reset, theme, tile-override;\n@layer theme {\n.x {}\n}",
        )
        #expect(
            TileKit.Output.Stylesheet(overriding: [".z {}"]).text()
                == "@layer reset, theme, tile-override;\n@layer tile-override {\n.z {}\n}",
        )
    }
}
