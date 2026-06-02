import Foundation
import TileCore

extension TileKit.Tile.DirectiveParser {
    func parseHeader(
        from line: String,
        lineNumber: Int,
    ) throws -> (typeID: String, rawDefinitionKey: String?) {
        let line = trimmed(line)
        if line == ":::chart" {
            return ("chart", nil)
        }
        if line == ":::mermaid" {
            return ("mermaid", "definition")
        }

        let prefix = ":::tile"
        let typeID = line.dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespaces)

        guard !typeID.isEmpty else {
            throw TileKit.Tile.DirectiveParserError.invalidHeader(
                line: lineNumber,
                text: line,
            )
        }

        return (typeID, nil)
    }

    func isTileDirectiveStart(
        _ line: String,
    ) -> Bool {
        let line = trimmed(line)
        return line == ":::chart"
            || line == ":::mermaid"
            || line == ":::tile"
            || line.hasPrefix(":::tile ")
            || line.hasPrefix(":::tile\t")
    }

    func isClosingFence(
        _ line: String,
    ) -> Bool {
        trimmed(line) == ":::"
    }

    func invalidPropertyLine(
        _ text: String,
        lineNumber: Int,
    ) -> TileKit.Tile.DirectiveParserError {
        .invalidPropertyLine(
            line: lineNumber,
            text: text,
        )
    }

    func trimmed(
        _ value: String,
    ) -> String {
        value.trimmingCharacters(in: .whitespaces)
    }

    func trimOuterBlankLines(
        _ lines: [String],
    ) -> ArraySlice<String> {
        var startIndex = lines.startIndex
        var endIndex = lines.endIndex

        while startIndex < endIndex, trimmed(lines[startIndex]).isEmpty {
            startIndex += 1
        }

        while endIndex > startIndex, trimmed(lines[lines.index(before: endIndex)]).isEmpty {
            endIndex -= 1
        }

        return lines[startIndex ..< endIndex]
    }
}
