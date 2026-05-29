import Foundation
import TileCore

public extension TileKit.Tile {
    /// Parses Tiledown Markdown tile directive blocks into typed tile blocks.
    struct DirectiveParser: Parsing {
        public init() {}

        public func parseBlocks(
            _ source: String,
        ) throws -> [Block] {
            let normalized = source.replacingOccurrences(
                of: "\r\n",
                with: "\n",
            )
            let lines = normalized.split(
                separator: "\n",
                omittingEmptySubsequences: false,
            ).map(String.init)

            var blocks: [Block] = []
            var markdownLines: [String] = []
            var openFence: (marker: Character, length: Int)?
            var index = 0

            while index < lines.count {
                let line = lines[index]

                // Inside a fenced code block everything is Markdown content,
                // including lines that look like tile directives.
                if let fence = openFence {
                    markdownLines.append(line)
                    if closesCodeFence(line, fence) {
                        openFence = nil
                    }
                    index += 1
                    continue
                }

                if let opened = openingCodeFence(line) {
                    markdownLines.append(line)
                    openFence = opened
                    index += 1
                    continue
                }

                if isTileDirectiveStart(line) {
                    flushMarkdown(
                        markdownLines: &markdownLines,
                        blocks: &blocks,
                    )
                    let parsed = try parseDirective(
                        lines: lines,
                        startIndex: index,
                    )
                    blocks.append(.tile(parsed.instance))
                    index = parsed.nextIndex
                } else {
                    markdownLines.append(line)
                    index += 1
                }
            }

            flushMarkdown(
                markdownLines: &markdownLines,
                blocks: &blocks,
            )
            return blocks
        }

        private func parseDirective(
            lines: [String],
            startIndex: Int,
        ) throws -> (instance: Instance, nextIndex: Int) {
            let typeID = try parseTypeID(
                from: lines[startIndex],
                lineNumber: startIndex + 1,
            )
            var bodyLines: [String] = []
            var index = startIndex + 1

            while index < lines.count {
                let line = lines[index]
                if isClosingFence(line) {
                    return try (
                        .init(
                            typeID: typeID,
                            properties: parseProperties(
                                bodyLines,
                                firstLineNumber: startIndex + 2,
                            ),
                            children: [],
                        ),
                        index + 1,
                    )
                }

                bodyLines.append(line)
                index += 1
            }

            throw DirectiveParserError.missingClosingFence(line: startIndex + 1)
        }

        private func parseProperties(
            _ lines: [String],
            firstLineNumber: Int,
        ) throws -> [Property] {
            var properties: [Property] = []
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

        private func parseProperty(
            lines: [String],
            index: Int,
            firstLineNumber: Int,
        ) throws -> (property: Property, nextIndex: Int) {
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

        private func parseList(
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

        private func flushMarkdown(
            markdownLines: inout [String],
            blocks: inout [Block],
        ) {
            guard !markdownLines.isEmpty else {
                return
            }

            let markdown = markdownLines.joined(separator: "\n")
            if !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(.markdown(markdown))
            }
            markdownLines.removeAll()
        }

        private func parseTypeID(
            from line: String,
            lineNumber: Int,
        ) throws -> String {
            let prefix = ":::tile"
            let line = trimmed(line)
            let typeID = line.dropFirst(prefix.count)
                .trimmingCharacters(in: .whitespaces)

            guard !typeID.isEmpty else {
                throw DirectiveParserError.invalidHeader(
                    line: lineNumber,
                    text: line,
                )
            }

            return typeID
        }

        private func isTileDirectiveStart(
            _ line: String,
        ) -> Bool {
            let line = trimmed(line)
            return line == ":::tile"
                || line.hasPrefix(":::tile ")
                || line.hasPrefix(":::tile\t")
        }

        private func isClosingFence(
            _ line: String,
        ) -> Bool {
            trimmed(line) == ":::"
        }

        private func invalidPropertyLine(
            _ text: String,
            lineNumber: Int,
        ) -> DirectiveParserError {
            .invalidPropertyLine(
                line: lineNumber,
                text: text,
            )
        }

        private func trimmed(
            _ value: String,
        ) -> String {
            value.trimmingCharacters(in: .whitespaces)
        }
    }
}
