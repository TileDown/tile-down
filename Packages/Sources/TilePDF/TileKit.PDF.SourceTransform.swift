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
