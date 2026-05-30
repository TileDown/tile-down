import Testing
import TileCore
import TileMarkdown
@testable import TileSite
import TileSource
import TileTile

@Suite("Document formatter")
struct DocumentFormatterTests {
    private let formatter = TileKit.Site.DocumentFormatter(
        frontMatterSplitter: TileKit.Source.FrontMatterParser(),
        tileParser: TileKit.Tile.DirectiveParser(),
        serializer: TileKit.Site.DocumentSerializer(
            markdownFormatter: TileKit.Markdown.CommonMarkFormatter(),
        ),
    )

    /// Documents exercised by the fixed-point law.
    private static let documents: [String] = [
        """
        ---
        title: Hello
        ---
        # Heading

        Prose.

        :::tile poll
        question: Best?
        options:
          - A
          - B
        :::
        """,
        "# Just a body\n\nNo front matter here.",
        """
        ---
        a: 1
        ---
        :::tile youtube-video
        videoId: abc
        :::
        """,
        // Front matter only, no body: exercises the empty-body recompose path.
        "---\nonly: frontmatter\n---",
    ]

    @Test("canonicalizes the body while preserving the front matter verbatim")
    func canonicalizesBodyKeepsFrontMatter() throws {
        let source = """
        ---
        title:   Irregular Spacing
        ---

        #    Messy Heading
        """

        let output = try formatter.format(source)

        // Exact output: front matter carried byte for byte (the triple space
        // survives), the body canonicalized (heading marker normalized, the blank
        // line after the front matter folded), and the boundary intact.
        #expect(output == "---\ntitle:   Irregular Spacing\n---\n# Messy Heading")
    }

    @Test("the canonical form is a fixed point")
    func fixedPoint() throws {
        for document in Self.documents {
            let once = try formatter.format(document)
            let twice = try formatter.format(once)
            #expect(once == twice, "format is not idempotent for: \(document)")
        }
    }

    @Test("isCanonical is false for messy input and true for its canonical form")
    func isCanonical() throws {
        for document in Self.documents {
            let canonical = try formatter.format(document)
            #expect(try formatter.isCanonical(canonical))
        }

        let messy = "#    Spaced heading\n\n\n\nExtra blank lines."
        #expect(try !formatter.isCanonical(messy))
        #expect(try formatter.isCanonical(formatter.format(messy)))
    }

    @Test("formats a document with no front matter")
    func noFrontMatter() throws {
        let output = try formatter.format("#   Title\n\nBody.")
        #expect(output == "# Title\n\nBody.")
    }

    @Test("normalizes CRLF line endings and stays idempotent")
    func normalizesCRLF() throws {
        let crlf = "#   Title\r\n\r\nBody."
        let once = try formatter.format(crlf)

        #expect(!once.contains("\r"))
        // The CRLF source is not canonical; its LF-normalized form is.
        #expect(try !formatter.isCanonical(crlf))
        #expect(try formatter.isCanonical(once))
    }

    @Test("propagates malformed front matter as an error")
    func malformedFrontMatter() {
        #expect(throws: TileKit.Source.FrontMatterParserError.missingClosingSeparator) {
            try formatter.format(
                """
                ---
                title: Unterminated
                # Body
                """,
            )
        }
    }
}
