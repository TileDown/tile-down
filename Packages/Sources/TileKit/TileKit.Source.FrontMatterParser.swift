import Foundation

public extension TileKit.Source {
    struct FrontMatterParser: MarkdownParsing {
        public init() {}

        public func parse(
            _ source: String,
        ) throws -> Document {
            let normalized = source.replacingOccurrences(
                of: "\r\n",
                with: "\n",
            )
            let lines = normalized.split(
                separator: "\n",
                omittingEmptySubsequences: false,
            ).map(String.init)

            guard lines.first == "---" else {
                return .init(
                    frontMatter: [:],
                    body: source,
                )
            }

            guard let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
                throw FrontMatterParserError.missingClosingSeparator
            }

            let frontMatterLines = lines[1 ..< closingIndex]
            let bodyLines = lines[(closingIndex + 1)...]

            var frontMatter: [String: String] = [:]
            for line in frontMatterLines {
                guard let item = try parseFrontMatterLine(line) else {
                    continue
                }
                frontMatter[item.key] = item.value
            }

            return .init(
                frontMatter: frontMatter,
                body: bodyLines.joined(separator: "\n"),
            )
        }

        private func parseFrontMatterLine(
            _ line: String,
        ) throws -> (key: String, value: String)? {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else {
                return nil
            }

            guard let separatorIndex = line.firstIndex(of: ":") else {
                throw FrontMatterParserError.invalidLine(line)
            }

            let key = String(line[..<separatorIndex])
                .trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: separatorIndex)...])
                .trimmingCharacters(in: .whitespaces)

            guard !key.isEmpty else {
                throw FrontMatterParserError.invalidLine(line)
            }

            return (key, value)
        }
    }
}
