import Foundation
import Markdown
import TileCore

public extension TileKit.Markdown {
    /// Renders a CommonMark document to HTML using swift-markdown.
    ///
    /// Parses Markdown into swift-markdown's typed tree and walks it to emit HTML.
    /// Text and attributes are escaped by default and unsafe URL schemes are
    /// dropped (Tiledown's security posture); raw HTML is not passed through. This
    /// is the prose half of Tiledown Markdown; tile directives are extracted before
    /// rendering, so the input here never contains them.
    struct CommonMarkRenderer: Rendering {
        /// URL schemes, beyond the built-in safe set, that may pass through to
        /// generated `href`/`src` unchanged. The site layer opts in its reference
        /// schemes (`page:`, `post:`, `tag:`, ...) so they survive rendering and can
        /// be resolved to real URLs afterward.
        private let passthroughSchemes: Set<String>

        public init(
            passthroughSchemes: Set<String> = [],
        ) {
            self.passthroughSchemes = passthroughSchemes
        }

        public func renderHTML(
            _ markdown: String,
        ) -> String {
            var visitor = HTMLVisitor(extraSchemes: passthroughSchemes)
            return visitor.visitDocument(Document(parsing: markdown))
        }
    }
}

/// Walks a swift-markdown tree and emits escaped HTML for the supported subset.
private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    /// URL schemes allowed to reach generated `href`/`src`. Everything else is
    /// dropped so `javascript:`, `data:`, and similar cannot execute.
    private static let safeSchemes: Set<String> = ["http", "https", "mailto"]

    /// Extra schemes the composition root allows through unchanged, beyond the
    /// built-in safe set (e.g. the site's `page:`/`post:`/`tag:` references).
    let extraSchemes: Set<String>

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
        // A paragraph that is the direct child of an item in a tight list renders
        // without a wrapping <p>; loose lists and non-list paragraphs keep it.
        return isTightListItemParagraph(paragraph) ? inner : "<p>\(inner)</p>"
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
        let languageClass = codeBlock.language
            .map { " class=\"language-\(escapeAttribute($0))\"" } ?? ""
        var code = codeBlock.code
        while code.hasSuffix("\n") {
            code.removeLast()
        }
        return "<pre><code\(languageClass)>\(escape(code))</code></pre>"
    }

    mutating func visitLink(
        _ link: Link,
    ) -> String {
        let children = render(link.children)
        guard let href = safeURL(link.destination ?? "") else {
            // Unsafe scheme: drop the anchor, keep the visible text inert.
            return children
        }
        return "<a href=\"\(escapeAttribute(href))\">\(children)</a>"
    }

    mutating func visitImage(
        _ image: Image,
    ) -> String {
        guard let source = safeURL(image.source ?? "") else {
            // Unsafe scheme: drop the image, keep the alt text inert.
            return escape(image.plainText)
        }
        let alt = escapeAttribute(image.plainText)
        let title = image.title.map { " title=\"\(escapeAttribute($0))\"" } ?? ""
        return "<img src=\"\(escapeAttribute(source))\" alt=\"\(alt)\"\(title)>"
    }

    mutating func visitUnorderedList(
        _ list: UnorderedList,
    ) -> String {
        "<ul>\(render(list.children))</ul>"
    }

    mutating func visitOrderedList(
        _ list: OrderedList,
    ) -> String {
        let start = list.startIndex == 1 ? "" : " start=\"\(list.startIndex)\""
        return "<ol\(start)>\(render(list.children))</ol>"
    }

    mutating func visitListItem(
        _ listItem: ListItem,
    ) -> String {
        "<li>\(render(listItem.children, separator: "\n"))</li>"
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

    mutating func visitTable(
        _ table: Table,
    ) -> String {
        var html = "<table><thead><tr>"
        for (column, cell) in table.head.cells.enumerated() {
            html += "<th\(alignmentAttribute(table, column: column))>\(render(cell.children))</th>"
        }
        html += "</tr></thead><tbody>"
        for row in table.body.rows {
            html += "<tr>"
            for (column, cell) in row.cells.enumerated() {
                html += "<td\(alignmentAttribute(table, column: column))>\(render(cell.children))</td>"
            }
            html += "</tr>"
        }
        html += "</tbody></table>"
        return html
    }

    /// The ` style="text-align:..."` attribute for a column, or "" when the
    /// column has no alignment marker. Alignment is semantic to the table, so it
    /// is emitted inline and renders correctly without any theme CSS.
    private func alignmentAttribute(
        _ table: Table,
        column: Int,
    ) -> String {
        guard column < table.columnAlignments.count,
              let alignment = table.columnAlignments[column]
        else {
            return ""
        }
        switch alignment {
        case .left:
            return " style=\"text-align:left\""
        case .center:
            return " style=\"text-align:center\""
        case .right:
            return " style=\"text-align:right\""
        }
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

    // MARK: - List looseness

    private func isTightListItemParagraph(
        _ paragraph: Paragraph,
    ) -> Bool {
        guard let item = paragraph.parent as? ListItem,
              let list = item.parent as? ListItemContainer
        else {
            return false
        }
        return !isLoose(list)
    }

    /// A list is loose if any item has more than one block child, or items are
    /// separated by a blank line. Loose lists wrap item paragraphs in `<p>`.
    private func isLoose(
        _ list: ListItemContainer,
    ) -> Bool {
        for case let item as ListItem in list.children {
            // Multiple block children make the list loose.
            if item.childCount > 1 {
                return true
            }
            // A trailing blank line extends the item's range past its content
            // (a blank between items attaches to the preceding item).
            guard let itemEnd = item.range?.upperBound.line,
                  let lastChild = item.child(at: item.childCount - 1),
                  let contentEnd = lastChild.range?.upperBound.line
            else {
                continue
            }
            if itemEnd > contentEnd {
                return true
            }
        }
        return false
    }

    // MARK: - Escaping and URLs

    /// Returns the URL if its scheme is safe to emit, or `nil` if it must be
    /// dropped. Relative URLs and fragments have no scheme and are allowed.
    private func safeURL(
        _ url: String,
    ) -> String? {
        // Strip ASCII control and whitespace, which browsers ignore when
        // resolving a scheme (defeats "java\tscript:" style obfuscation).
        let cleaned = String(
            String.UnicodeScalarView(url.unicodeScalars.filter { $0.value > 0x20 }),
        )
        guard let colon = cleaned.firstIndex(of: ":") else {
            return url
        }
        let scheme = cleaned[..<colon]
        if scheme.contains(where: { $0 == "/" || $0 == "?" || $0 == "#" }) {
            return url
        }
        let lowered = scheme.lowercased()
        let allowed = Self.safeSchemes.contains(lowered) || extraSchemes.contains(lowered)
        return allowed ? url : nil
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
