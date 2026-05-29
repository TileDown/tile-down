import Testing
@testable import TileKit

@Suite("Front matter parser")
struct FrontMatterParserTests {
    @Test("parses key value front matter")
    func parsesKeyValueFrontMatter() throws {
        let parser = TileKit.Source.FrontMatterParser()

        let document = try parser.parse(
            """
            ---
            title: First Post
            slug: first-post
            ---
            Body text
            """,
        )

        #expect(document.frontMatter["title"] == "First Post")
        #expect(document.frontMatter["slug"] == "first-post")
        #expect(document.body == "Body text")
    }

    @Test("keeps source without front matter as body")
    func keepsBodyWithoutFrontMatter() throws {
        let parser = TileKit.Source.FrontMatterParser()

        let document = try parser.parse("Body text")

        #expect(document.frontMatter.isEmpty)
        #expect(document.body == "Body text")
    }
}
