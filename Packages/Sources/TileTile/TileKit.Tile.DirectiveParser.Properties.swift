import Foundation
import TileCore

extension TileKit.Tile.DirectiveParser {
    func parseProperties(
        _ lines: [String],
        rawDefinitionKey: String? = nil,
        firstLineNumber: Int,
    ) throws -> [TileKit.Tile.Property] {
        if let rawDefinitionKey {
            return [
                .init(
                    key: rawDefinitionKey,
                    value: .string(trimOuterBlankLines(lines).joined(separator: "\n")),
                ),
            ]
        }

        var properties: [TileKit.Tile.Property] = []
        var index = 0

        while index < lines.count {
            guard !trimmed(lines[index]).isEmpty else {
                index += 1
                continue
            }

            let parsed = try parseProperty(
                lines: lines,
                index: index,
                firstLineNumber: firstLineNumber,
            )
            properties.append(parsed.property)
            index = parsed.nextIndex
        }

        return properties
    }

    func parseProperty(
        lines: [String],
        index: Int,
        firstLineNumber: Int,
    ) throws -> (property: TileKit.Tile.Property, nextIndex: Int) {
        let line = lines[index]
        guard let separatorIndex = line.firstIndex(of: ":") else {
            throw invalidPropertyLine(
                line,
                lineNumber: firstLineNumber + index,
            )
        }

        let key = trimmed(String(line[..<separatorIndex]))
        guard !key.isEmpty else {
            throw invalidPropertyLine(
                line,
                lineNumber: firstLineNumber + index,
            )
        }

        let rawValue = trimmed(String(line[line.index(after: separatorIndex)...]))
        return try parsePropertyValue(
            key: key,
            rawValue: rawValue,
            lines: lines,
            index: index,
        )
    }

    func parsePropertyValue(
        key: String,
        rawValue: String,
        lines: [String],
        index: Int,
    ) throws -> (property: TileKit.Tile.Property, nextIndex: Int) {
        if rawValue == "|" {
            let parsedLiteral = parseLiteral(
                lines: lines,
                startIndex: index + 1,
            )
            return (
                .init(
                    key: key,
                    value: .string(parsedLiteral.value),
                ),
                parsedLiteral.nextIndex,
            )
        }

        guard rawValue.isEmpty else {
            return (
                .init(
                    key: key,
                    value: .string(rawValue),
                ),
                index + 1,
            )
        }

        let parsedList = parseList(
            lines: lines,
            startIndex: index + 1,
        )
        guard !parsedList.items.isEmpty else {
            return (
                .init(
                    key: key,
                    value: .string(""),
                ),
                index + 1,
            )
        }

        return (
            .init(
                key: key,
                value: .list(parsedList.items),
            ),
            parsedList.nextIndex,
        )
    }

    func parseList(
        lines: [String],
        startIndex: Int,
    ) -> (items: [String], nextIndex: Int) {
        var items: [String] = []
        var index = startIndex

        while index < lines.count {
            let line = trimmed(lines[index])
            guard line.hasPrefix("- ") else {
                break
            }

            let item = String(line.dropFirst(2))
                .trimmingCharacters(in: .whitespaces)
            items.append(item)
            index += 1
        }

        return (items, index)
    }

    func parseLiteral(
        lines: [String],
        startIndex: Int,
    ) -> (value: String, nextIndex: Int) {
        var literalLines: [String] = []
        var index = startIndex

        while index < lines.count {
            let line = lines[index]
            if line.isEmpty {
                literalLines.append("")
                index += 1
                continue
            }

            guard let unindented = unindentedLiteralLine(line) else {
                break
            }

            literalLines.append(unindented)
            index += 1
        }

        return (literalLines.joined(separator: "\n"), index)
    }

    func unindentedLiteralLine(
        _ line: String,
    ) -> String? {
        if line.hasPrefix("  ") {
            return String(line.dropFirst(2))
        }
        if line.hasPrefix("\t") {
            return String(line.dropFirst())
        }

        return nil
    }
}
