import Foundation
import Markdown
import TileCore

/// Capability-block rendering for the HTML visitor: fenced charts/diagrams and
/// `$$...$$` display math, plus the shared collection of their page-local assets.
/// These delegate to injected seams, so the Markdown layer never imports a
/// capability producer or a math engine.
extension HTMLVisitor {
    /// The capability render of a fenced block, or `nil` if no renderer claims
    /// its info-string language (so it falls back to the default code block).
    func renderedFence(
        for codeBlock: CodeBlock,
    ) -> TileKit.FencedBlock? {
        guard let language = codeBlock.language?.split(whereSeparator: \.isWhitespace).first.map(String.init) else {
            return nil
        }
        return fencedRenderer?.rendered(language: language, source: codeBlock.code)
    }

    /// The typeset result of a paragraph that is a single `$$...$$` display-math
    /// block, or `nil` if the paragraph is not display math or no renderer claims
    /// it (so it falls back to ordinary paragraph rendering). The whole paragraph
    /// must be one delimited block: a paragraph mixing prose and `$$` is not math.
    mutating func renderedDisplayMath(
        _ paragraph: Paragraph,
    ) -> String? {
        guard let mathRenderer else {
            return nil
        }
        // The raw source preserves TeX backslash sequences (`\\`, `\{`) that the
        // visited text would have collapsed; fall back to the visited text only
        // when the source range is unavailable.
        let text = (rawSource(of: paragraph) ?? paragraph.plainText)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("$$"), text.hasSuffix("$$"), text.count > 4 else {
            return nil
        }
        let inner = String(text.dropFirst(2).dropLast(2))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inner.isEmpty, !inner.contains("$$") else {
            return nil
        }
        guard let block = mathRenderer.rendered(tex: inner, display: true) else {
            return nil
        }
        collect(block)
        return block.html
    }

    /// The verbatim Markdown source for a node, recovered from its source range,
    /// or `nil` if the range is absent or out of bounds.
    private func rawSource(
        of markup: some Markup,
    ) -> String? {
        guard let range = markup.range,
              let start = sourceIndex(line: range.lowerBound.line, column: range.lowerBound.column),
              let end = sourceIndex(line: range.upperBound.line, column: range.upperBound.column),
              start <= end
        else {
            return nil
        }
        return String(source[start ..< end])
    }

    /// Maps a 1-based (line, column) source location to a `String.Index`.
    private func sourceIndex(
        line: Int,
        column: Int,
    ) -> String.Index? {
        var index = source.startIndex
        var currentLine = 1
        while currentLine < line, index < source.endIndex {
            if source[index] == "\n" {
                currentLine += 1
            }
            index = source.index(after: index)
        }
        return source.index(index, offsetBy: column - 1, limitedBy: source.endIndex)
    }

    /// Records a rendered block's page-local CSS and JavaScript, each once.
    mutating func collect(
        _ block: TileKit.FencedBlock,
    ) {
        if !block.css.isEmpty, !fencedCSS.contains(block.css) {
            fencedCSS.append(block.css)
        }
        if !block.javascript.isEmpty, !fencedJS.contains(block.javascript) {
            fencedJS.append(block.javascript)
        }
    }
}
