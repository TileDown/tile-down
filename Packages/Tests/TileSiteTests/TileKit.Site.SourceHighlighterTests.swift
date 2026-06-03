import Testing
import TileCore
@testable import TileSite

@Suite("Source highlighter")
struct SourceHighlighterTests {
    private func html(_ source: String) -> String {
        TileKit.Site.SourceHighlighter.html(for: source)
    }

    @Test("front matter delimiters and keys are tokenized")
    func frontMatter() {
        let out = html("---\ntitle: Hello\n---\n")
        #expect(out.contains(#"<span class="tok-fm-delim">---</span>"#))
        #expect(out.contains(#"<span class="tok-fm-key">title</span>"#))
        #expect(out.contains(#"<span class="tok-fm-value"> Hello</span>"#))
    }

    @Test("an ATX heading is tokenized as a heading")
    func heading() {
        #expect(html("# Title").contains(#"<span class="tok-heading"># Title</span>"#))
    }

    @Test("inline code, strong, emphasis, link, and math are tokenized")
    func inlineConstructs() {
        #expect(html("a `code` b").contains(#"<span class="tok-code">`code`</span>"#))
        #expect(html("a **bold** b").contains(#"<span class="tok-strong">**bold**</span>"#))
        #expect(html("a *em* b").contains(#"<span class="tok-em">*em*</span>"#))
        #expect(html("see [t](u)").contains(#"<span class="tok-link">[t](u)</span>"#))
        #expect(html("x $y$ z").contains(#"<span class="tok-math">$y$</span>"#))
    }

    @Test("a fenced block tokenizes the fence, language, and body")
    func fence() {
        let out = html("```swift\nlet x = 1\n```")
        #expect(out.contains(#"<span class="tok-fence">```</span>"#))
        #expect(out.contains(#"<span class="tok-fence-lang">swift</span>"#))
        #expect(out.contains(#"<span class="tok-fence-body">let x = 1</span>"#))
    }

    @Test("list and quote markers are tokenized")
    func markers() {
        #expect(html("- item").contains(#"<span class="tok-list">- </span>"#))
        #expect(html("1. item").contains(#"<span class="tok-list">1. </span>"#))
        #expect(html("> quote").contains(#"<span class="tok-quote">&gt;</span>"#))
    }

    @Test("all text is HTML-escaped so the source cannot inject markup")
    func escaping() {
        let out = html("a <script>alert(1)</script> b")
        #expect(!out.contains("<script>"))
        #expect(out.contains("&lt;script&gt;"))
    }

    @Test("lines are preserved and rejoined with newlines")
    func lineCount() {
        let out = html("one\ntwo\nthree")
        #expect(out.split(separator: "\n", omittingEmptySubsequences: false).count == 3)
    }
}
