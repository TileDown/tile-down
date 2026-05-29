import Testing
import TileCore
@testable import TileMarkdown

@Suite("CommonMark formatter")
struct CommonMarkFormatterTests {
    private let formatter = TileKit.Markdown.CommonMarkFormatter()

    @Test("normalizes prose to one canonical style")
    func normalizes() {
        #expect(formatter.canonicalize("Title\n=====") == "# Title")
        #expect(formatter.canonicalize("* a\n* b") == "- a\n- b")
        #expect(formatter.canonicalize("***") == "-----")
        #expect(formatter.canonicalize("_x_") == "*x*")
    }

    @Test("the canonical form is a fixed point")
    func idempotent() {
        let samples = [
            "Title\n=====",
            "* a\n* b",
            "3. a\n4. b",
            "# H\n\ntext with `code`",
            "> a quote",
        ]
        for sample in samples {
            let once = formatter.canonicalize(sample)
            #expect(formatter.canonicalize(once) == once)
        }
    }

    @Test("normalizes ordered-list start to 1 (documented profile property)")
    func normalizesOrderedListStart() {
        #expect(formatter.canonicalize("3. a\n4. b") == "1. a\n1. b")
    }
}
