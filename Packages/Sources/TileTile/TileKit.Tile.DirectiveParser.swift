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
            let header = try parseHeader(
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
                            typeID: header.typeID,
                            properties: parseProperties(
                                bodyLines,
                                rawDefinitionKey: header.rawDefinitionKey,
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
    }
}
