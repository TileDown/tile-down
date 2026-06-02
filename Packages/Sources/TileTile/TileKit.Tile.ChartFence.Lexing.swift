import Foundation
import TileCore

/// Depth- and quote-aware lexing for ``ChartFence`` plus the per-entry parsers.
/// Split from the main file to keep each declaration focused.
extension ChartFence {
    static func parseKind(
        _ text: String,
        line: SourceLine,
    ) throws -> ChartKind {
        let normalized = sanitizedLabel(text).lowercased()
        if normalized == "xy" {
            return .scatter
        }
        do {
            return try ChartKind(raw: normalized)
        } catch {
            throw fenceError(line, "unknown chart type `\(text)`")
        }
    }

    static func parseSeriesInput(
        _ value: String,
        line: SourceLine,
    ) throws -> SeriesInput {
        guard let split = splitAssignment(value) else {
            throw fenceError(line, "expected `Name = values`")
        }
        let name = sanitizedLabel(split.key)
        guard !name.isEmpty else {
            throw fenceError(line, "series name must not be empty")
        }
        return SeriesInput(line: line.number, name: name, payload: split.value)
    }

    static func parseSliceInput(
        _ value: String,
        line: SourceLine,
    ) throws -> SliceInput {
        guard let split = splitAssignment(value), let number = parseNumber(split.value) else {
            throw fenceError(line, "expected `Label = value`")
        }
        return SliceInput(line: line.number, label: sanitizedLabel(split.key), value: number)
    }

    static func contentLines(
        _ source: String,
    ) -> [SourceLine] {
        source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .compactMap { offset, raw in
                let text = raw.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty, !text.hasPrefix("#") else {
                    return nil
                }
                return SourceLine(number: offset + 1, text: text)
            }
    }

    static func splitKeyValue(
        _ text: String,
    ) -> (key: String, value: String)? {
        split(text, separator: ":")
    }

    static func splitAssignment(
        _ text: String,
    ) -> (key: String, value: String)? {
        split(text, separator: "=") ?? split(text, separator: ":")
    }

    static func split(
        _ text: String,
        separator: Character,
    ) -> (key: String, value: String)? {
        var inQuote: Character?
        var depth = 0
        for index in text.indices {
            let character = text[index]
            if let quote = inQuote {
                if character == quote {
                    inQuote = nil
                }
                continue
            }
            if character == "\"" || character == "'" {
                inQuote = character
            } else if character == "(" {
                depth += 1
            } else if character == ")" {
                depth = max(0, depth - 1)
            } else if depth == 0, character == separator {
                let key = sanitizedLabel(String(text[..<index]))
                let value = String(text[text.index(after: index)...]).trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty, !value.isEmpty else {
                    return nil
                }
                return (key, value)
            }
        }
        return nil
    }

    static func splitList(
        _ text: String,
    ) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuote: Character?
        var depth = 0
        for character in text {
            if let quote = inQuote {
                current.append(character)
                if character == quote {
                    inQuote = nil
                }
                continue
            }
            switch character {
            case "\"", "'":
                inQuote = character
                current.append(character)
            case "(":
                depth += 1
                current.append(character)
            case ")":
                depth = max(0, depth - 1)
                current.append(character)
            case "," where depth == 0:
                let value = current.trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    values.append(value)
                }
                current = ""
            default:
                current.append(character)
            }
        }
        let value = current.trimmingCharacters(in: .whitespaces)
        if !value.isEmpty {
            values.append(value)
        }
        return values
    }

    static func parsePointList(
        _ text: String,
    ) -> [ChartPoint]? {
        var points: [ChartPoint] = []
        for item in splitList(text) {
            let trimmed = item.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("("), trimmed.hasSuffix(")") else {
                return nil
            }
            let pair = splitList(String(trimmed.dropFirst().dropLast()))
            guard pair.count == 2, let xValue = parseNumber(pair[0]), let yValue = parseNumber(pair[1]) else {
                return nil
            }
            points.append(ChartPoint(xPosition: xValue, yPosition: yValue))
        }
        return points
    }

    static func parseNumberList(
        _ text: String,
    ) -> [Double]? {
        let items = splitList(text)
        guard !items.isEmpty else {
            return nil
        }
        var numbers: [Double] = []
        for item in items {
            guard let number = parseNumber(item) else {
                return nil
            }
            numbers.append(number)
        }
        return numbers
    }

    static func parseNumber(
        _ text: String,
    ) -> Double? {
        guard let value = Double(text.trimmingCharacters(in: .whitespaces)), value.isFinite else {
            return nil
        }
        return value
    }

    /// Whether a ` ```mermaid ` source is a pie chart (`pie` or `pie title ...`),
    /// which MarkdownPDF renders as a static chart rather than a diagram.
    static func isMermaidPie(
        _ source: String,
    ) -> Bool {
        guard let header = mermaidLines(source).first else {
            return false
        }
        let lower = header.lowercased()
        return lower == "pie" || lower.hasPrefix("pie ")
    }

    /// Parses a mermaid `pie`/`pie title ...` block (`"Label" : value` lines) into
    /// a pie ``ChartData``, matching MarkdownPDF's mermaid-pie handling.
    static func parseMermaidPie(
        _ source: String,
    ) throws -> ChartData {
        let lines = mermaidLines(source)
        guard let header = lines.first else {
            throw fenceError("empty mermaid pie chart")
        }
        let title: String?
        let lower = header.lowercased()
        if lower == "pie" {
            title = nil
        } else if lower.hasPrefix("pie title ") {
            title = sanitizedLabel(String(header.dropFirst("pie title ".count)))
        } else {
            throw fenceError("expected `pie` or `pie title ...`")
        }

        var labels: [String] = []
        var values: [Double] = []
        for line in lines.dropFirst() {
            let text = stripTrailingSemicolon(line)
            guard let split = splitKeyValue(text), let value = parseNumber(split.value), value >= 0 else {
                throw fenceError("expected `\"label\" : value`")
            }
            labels.append(sanitizedLabel(split.key))
            values.append(value)
        }
        guard !labels.isEmpty, values.reduce(0, +) > 0 else {
            throw fenceError("pie chart needs slices with a total greater than zero")
        }
        return ChartData(
            kind: .pie,
            title: title,
            labels: labels,
            series: [ChartSeries(name: "Slices", values: values)],
        )
    }

    private static func mermaidLines(
        _ source: String,
    ) -> [String] {
        source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("%%") }
    }

    private static func stripTrailingSemicolon(
        _ text: String,
    ) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasSuffix(";") else {
            return trimmed
        }
        return String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces)
    }

    static func sanitizedLabel(
        _ text: String,
    ) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, let first = trimmed.first, let last = trimmed.last else {
            return trimmed
        }
        let quoted = (first == "\"" && last == "\"") || (first == "'" && last == "'")
        guard quoted else {
            return trimmed
        }
        return String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
