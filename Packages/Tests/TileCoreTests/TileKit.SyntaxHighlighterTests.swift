import Testing
@testable import TileCore

@Suite("Syntax highlighter")
struct SyntaxHighlighterTests {
    @Test("supports at least fifteen language names")
    func supportedLanguageCount() {
        #expect(TileKit.SyntaxHighlighter.supportedLanguages.count >= 15)
        #expect(TileKit.SyntaxHighlighter.supportedLanguages.contains("swift"))
        #expect(TileKit.SyntaxHighlighter.supportedLanguages.contains("typescript"))
        #expect(TileKit.SyntaxHighlighter.supportedLanguages.contains("python"))
        #expect(TileKit.SyntaxHighlighter.supportedLanguages.contains("html"))
        #expect(TileKit.SyntaxHighlighter.supportedLanguages.contains("sql"))
    }

    @Test("highlights Swift with multiple token classes")
    func swiftTokens() {
        let html = TileKit.SyntaxHighlighter.html(
            for: #"struct Demo { let value: String = "ok" // comment }"#,
            language: "swift",
        )

        #expect(html.contains(#"<span class="tok-keyword">struct</span>"#))
        #expect(html.contains(#"<span class="tok-type">Demo</span>"#))
        #expect(html.contains(#"<span class="tok-type">String</span>"#))
        #expect(html.contains(#"<span class="tok-string">"ok"</span>"#))
        #expect(html.contains(#"<span class="tok-comment">// comment }</span>"#))
    }

    @Test("highlights JSON keys and values")
    func jsonTokens() {
        let html = TileKit.SyntaxHighlighter.html(
            for: #"{"name": "TileDown", "count": 3, "ok": true}"#,
            language: "json",
        )

        #expect(html.contains(#"<span class="tok-property">"name"</span>"#))
        #expect(html.contains(#"<span class="tok-string">"TileDown"</span>"#))
        #expect(html.contains(#"<span class="tok-number">3</span>"#))
        #expect(html.contains(#"<span class="tok-literal">true</span>"#))
    }

    @Test("highlights markup tags and attributes")
    func markupTokens() {
        let html = TileKit.SyntaxHighlighter.html(
            for: #"<a href="/docs">Docs</a>"#,
            language: "html",
        )

        #expect(html.contains(#"<span class="tok-keyword">a</span>"#))
        #expect(html.contains(#"<span class="tok-property">href</span>"#))
        #expect(html.contains(#"<span class="tok-string">"/docs"</span>"#))
    }

    @Test("escapes source before emitting highlighted HTML")
    func escapesSource() {
        let html = TileKit.SyntaxHighlighter.html(
            for: #"<script>alert("x")</script>"#,
            language: "swift",
        )

        #expect(!html.contains("<script>"))
        #expect(html.contains("&lt;"))
        #expect(html.contains("script"))
    }

    @Test("unknown languages still get safe generic highlighting")
    func unknownLanguage() {
        let html = TileKit.SyntaxHighlighter.html(
            for: #"const value = "safe""#,
            language: "made-up",
        )

        #expect(html.contains(#"<span class="tok-keyword">const</span>"#))
        #expect(html.contains(#"<span class="tok-string">"safe"</span>"#))
    }
}
