import Markdown
import TileCore

public extension TileKit.Markdown {
    /// Renders a CommonMark document to HTML using swift-markdown.
    ///
    /// Parses Markdown into swift-markdown's typed tree and walks it to emit HTML.
    /// Text is escaped by default (Tiledown's security posture); raw HTML is not
    /// passed through. This is the prose half of Tiledown Markdown; tile directives
    /// are extracted before rendering, so the input here never contains them.
    struct CommonMarkRenderer: Rendering {
        public init() {}

        public func renderHTML(
            _ markdown: String,
        ) -> String {
            var visitor = HTMLVisitor()
            return visitor.visitDocument(Document(parsing: markdown))
        }
    }
}

private extension Markup {
    /// Whether this node sits inside a list item, so paragraphs render tight.
    var isInsideList: Bool {
        self is ListItemContainer || parent?.isInsideList == true
    }
}

/// Walks a swift-markdown tree and emits escaped HTML for the supported subset.
private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(
        _ markup: any Markup,
    ) -> String {
        render(markup.children)
    }

    mutating func visitDocument(
        _ document: Document,
    ) -> String {
        render(document.children, separator: "\n")
    }

    mutating func visitHeading(
        _ heading: Heading,
    ) -> String {
        "<h\(heading.level)>\(render(heading.children))</h\(heading.level)>"
    }

    mutating func visitParagraph(
        _ paragraph: Paragraph,
    ) -> String {
        let inner = render(paragraph.children)
        return paragraph.isInsideList ? inner : "<p>\(inner)</p>"
    }

    mutating func visitText(
        _ text: Text,
    ) -> String {
        escape(text.string)
    }

    mutating func visitEmphasis(
        _ emphasis: Emphasis,
    ) -> String {
        "<em>\(render(emphasis.children))</em>"
    }

    mutating func visitStrong(
        _ strong: Strong,
    ) -> String {
        "<strong>\(render(strong.children))</strong>"
    }

    mutating func visitInlineCode(
        _ inlineCode: InlineCode,
    ) -> String {
        "<code>\(escape(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(
        _ codeBlock: CodeBlock,
    ) -> String {
        let languageClass = codeBlock.language.map { " class=\"language-\($0)\"" } ?? ""
        var code = codeBlock.code
        while code.hasSuffix("\n") {
            code.removeLast()
        }
        return "<pre><code\(languageClass)>\(escape(code))</code></pre>"
    }

    mutating func visitLink(
        _ link: Link,
    ) -> String {
        let href = escapeAttribute(link.destination ?? "")
        return "<a href=\"\(href)\">\(render(link.children))</a>"
    }

    mutating func visitImage(
        _ image: Image,
    ) -> String {
        let source = escapeAttribute(image.source ?? "")
        let alt = escapeAttribute(image.plainText)
        return "<img src=\"\(source)\" alt=\"\(alt)\">"
    }

    mutating func visitUnorderedList(
        _ list: UnorderedList,
    ) -> String {
        "<ul>\(render(list.children))</ul>"
    }

    mutating func visitOrderedList(
        _ list: OrderedList,
    ) -> String {
        "<ol>\(render(list.children))</ol>"
    }

    mutating func visitListItem(
        _ listItem: ListItem,
    ) -> String {
        "<li>\(render(listItem.children))</li>"
    }

    mutating func visitBlockQuote(
        _ blockQuote: BlockQuote,
    ) -> String {
        "<blockquote>\(render(blockQuote.children, separator: "\n"))</blockquote>"
    }

    mutating func visitThematicBreak(
        _: ThematicBreak,
    ) -> String {
        "<hr>"
    }

    mutating func visitLineBreak(
        _: LineBreak,
    ) -> String {
        "<br>"
    }

    mutating func visitSoftBreak(
        _: SoftBreak,
    ) -> String {
        "\n"
    }

    mutating func visitHTMLBlock(
        _ html: HTMLBlock,
    ) -> String {
        // Raw HTML is escaped, not passed through: escape by default, no
        // author or remote HTML executes in generated output.
        escape(html.rawHTML)
    }

    mutating func visitInlineHTML(
        _ inlineHTML: InlineHTML,
    ) -> String {
        escape(inlineHTML.rawHTML)
    }

    private mutating func render(
        _ children: MarkupChildren,
        separator: String = "",
    ) -> String {
        var parts: [String] = []
        for child in children {
            parts.append(visit(child))
        }
        return parts.joined(separator: separator)
    }

    private func escape(
        _ value: String,
    ) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(
        _ value: String,
    ) -> String {
        escape(value)
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
