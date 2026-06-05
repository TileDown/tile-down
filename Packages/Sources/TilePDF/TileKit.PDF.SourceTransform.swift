import TileCore

public extension TileKit.PDF {
    /// Rewrites Tiledown source into Markdown the MarkdownPDF engine understands.
    ///
    /// MarkdownPDF renders a ` ```chart ` code fence (in its `categories:` /
    /// `series: Name = ...` form), but it does not know Tiledown's `:::chart`
    /// directive tile (in the `labels:` / `series.Name:` form), so that directive
    /// would otherwise print verbatim in the PDF. This converts each `:::chart`
    /// block into the equivalent ` ```chart ` fence so the chart renders.
    static func markdownForPDF(_ source: String) -> String {
        separateStandaloneImageLines(chartDirectivesAsFences(source))
    }

    private static func chartDirectivesAsFences(
        _ source: String,
    ) -> String {
        var output: [String] = []
        var inChart = false
        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !inChart, trimmed == ":::chart" {
                output.append("```chart")
                inChart = true
                continue
            }
            if inChart {
                if trimmed == ":::" {
                    output.append("```")
                    inChart = false
                } else {
                    output.append(translateChartLine(trimmed))
                }
                continue
            }
            output.append(line)
        }
        // A chart directive left unterminated at end of source: close the fence.
        if inChart {
            output.append("```")
        }
        return output.joined(separator: "\n")
    }

    /// MarkdownPDF embeds only standalone image paragraphs. Existing articles
    /// often put an image token on the next source line after prose without a blank
    /// separator, which Markdown parses as one paragraph with an inline image. Add
    /// paragraph boundaries around image-only lines outside code fences so those
    /// images become embeddable in the PDF.
    private static func separateStandaloneImageLines(
        _ source: String,
    ) -> String {
        var output: [String] = []
        var fence: String?

        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let currentFence = fence {
                output.append(line)
                if trimmed.hasPrefix(currentFence) {
                    fence = nil
                }
                continue
            }

            if let marker = fenceMarker(trimmed) {
                fence = marker
                output.append(line)
                continue
            }

            if isStandaloneImageLine(trimmed) {
                if output.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    output.append("")
                }
                output.append(line)
                output.append("")
                continue
            }

            output.append(line)
        }

        return output.joined(separator: "\n")
    }

    private static func fenceMarker(
        _ trimmed: String,
    ) -> String? {
        let backticks = markerRun("`", in: trimmed)
        if backticks.count >= 3 {
            return backticks
        }
        let tildes = markerRun("~", in: trimmed)
        return tildes.count >= 3 ? tildes : nil
    }

    private static func markerRun(
        _ marker: Character,
        in trimmed: String,
    ) -> String {
        String(trimmed.prefix { $0 == marker })
    }

    private static func isStandaloneImageLine(
        _ trimmed: String,
    ) -> Bool {
        guard trimmed.hasPrefix("![") else {
            return false
        }
        let labelStart = trimmed.index(trimmed.startIndex, offsetBy: 2)
        guard let labelEnd = firstUnescaped("]", in: trimmed, from: labelStart) else {
            return false
        }
        let afterLabel = trimmed.index(after: labelEnd)
        guard afterLabel < trimmed.endIndex, trimmed[afterLabel] == "(" else {
            return false
        }
        return trimmed.last == ")"
    }

    private static func firstUnescaped(
        _ character: Character,
        in source: String,
        from start: String.Index,
    ) -> String.Index? {
        var index = start
        var escaped = false
        while index < source.endIndex {
            let current = source[index]
            if escaped {
                escaped = false
            } else if current == "\\" {
                escaped = true
            } else if current == character {
                return index
            }
            index = source.index(after: index)
        }
        return nil
    }

    /// Translates one line inside a chart directive from the directive vocabulary to
    /// the fence vocabulary: `labels:` -> `categories:`, and `series.Name: values`
    /// -> `series: Name = values`. Other lines (type, title, x-label, y-label) pass
    /// through unchanged.
    private static func translateChartLine(_ trimmed: String) -> String {
        if trimmed.hasPrefix("labels:") {
            return "categories:" + trimmed.dropFirst("labels:".count)
        }
        if trimmed.hasPrefix("series."), let colon = trimmed.firstIndex(of: ":") {
            let name = trimmed[trimmed.index(trimmed.startIndex, offsetBy: "series.".count) ..< colon]
            let values = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            return "series: \(name) = \(values)"
        }
        return trimmed
    }
}
