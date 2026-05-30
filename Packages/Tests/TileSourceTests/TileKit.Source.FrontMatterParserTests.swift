import Testing
import TileCore
@testable import TileSource

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

    @Test("parse throws on front matter with no closing separator")
    func parseThrowsOnMissingClosingSeparator() {
        let parser = TileKit.Source.FrontMatterParser()

        #expect(throws: TileKit.Source.FrontMatterParserError.missingClosingSeparator) {
            try parser.parse(
                """
                ---
                title: Unterminated
                Body text
                """,
            )
        }
    }

    @Test("split returns the raw front matter block with its fences and the body")
    func splitReturnsRawFrontMatterAndBody() throws {
        let parser = TileKit.Source.FrontMatterParser()

        let parts = try parser.split(
            """
            ---
            title:   Spaced Out
            ---
            # Body

            More.
            """,
        )

        // The front matter is preserved verbatim, fences and all, including the
        // irregular spacing that parse would normalize away.
        #expect(parts.frontMatter == "---\ntitle:   Spaced Out\n---")
        #expect(parts.body == "# Body\n\nMore.")
    }

    @Test("split keeps source without front matter as body verbatim")
    func splitKeepsBodyWithoutFrontMatter() throws {
        let parser = TileKit.Source.FrontMatterParser()

        let parts = try parser.split("# Just body\n\nText.")

        #expect(parts.frontMatter == nil)
        #expect(parts.body == "# Just body\n\nText.")
    }

    @Test("split closes at the first fence, leaving a later --- in the body")
    func splitKeepsBodyThematicBreak() throws {
        let parser = TileKit.Source.FrontMatterParser()

        let parts = try parser.split("---\ntitle: X\n---\nIntro\n\n---\n\nAfter break")

        #expect(parts.frontMatter == "---\ntitle: X\n---")
        #expect(parts.body == "Intro\n\n---\n\nAfter break")
    }

    @Test("split throws on front matter with no closing separator")
    func splitThrowsOnMissingClosingSeparator() {
        let parser = TileKit.Source.FrontMatterParser()

        #expect(throws: TileKit.Source.FrontMatterParserError.missingClosingSeparator) {
            try parser.split(
                """
                ---
                title: Unterminated
                Body text
                """,
            )
        }
    }
}
