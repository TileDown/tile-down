import Testing
@testable import TileCore

@Suite("HTML escaping")
struct HTMLTests {
    @Test("escapes with the conservative renderer table")
    func escapesWithRendererTable() {
        #expect(TileKit.HTML.escape(#"&<>"'"#) == #"&amp;&lt;&gt;&quot;&#39;"#)
    }

    @Test("escapes text nodes")
    func escapesTextNodes() {
        #expect(TileKit.HTML.escapeText(#"&<>"'"#) == #"&amp;&lt;&gt;"'"#)
    }

    @Test("escapes double-quoted attributes")
    func escapesDoubleQuotedAttributes() {
        #expect(TileKit.HTML.escapeAttribute(#"&<>"'"#) == #"&amp;&lt;&gt;&quot;&#39;"#)
    }
}
