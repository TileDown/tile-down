import Foundation
import TileCore

public extension TileKit.Source {
    struct FrontMatterParser: MarkdownParsing, FrontMatterSplitting {
        public init() {}

        /// Separates the raw front matter block (with its `---` fences) from the
        /// body, without decoding either part. The single definition of where front
        /// matter ends; `parse` decodes the block this returns.
        public func split(
            _ source: String,
        ) throws -> Split {
            let lines = Self.normalizedLines(source)

            guard let closingIndex = try Self.frontMatterClosingIndex(lines) else {
                return .init(
                    frontMatter: nil,
                    body: source,
                )
            }

            return .init(
                frontMatter: lines[0 ... closingIndex].joined(separator: "\n"),
                body: lines[(closingIndex + 1)...].joined(separator: "\n"),
            )
        }

        public func parse(
            _ source: String,
        ) throws -> Document {
            let lines = Self.normalizedLines(source)

            guard let closingIndex = try Self.frontMatterClosingIndex(lines) else {
                return .init(
                    frontMatter: [:],
                    body: source,
                )
            }

            var frontMatter: [String: String] = [:]
            for line in lines[1 ..< closingIndex] {
                guard let item = try parseFrontMatterLine(line) else {
                    continue
                }
                frontMatter[item.key] = item.value
            }

            return .init(
                frontMatter: frontMatter,
                body: lines[(closingIndex + 1)...].joined(separator: "\n"),
            )
        }

        /// Splits the source into lines, normalizing CRLF to LF first.
        private static func normalizedLines(
            _ source: String,
        ) -> [String] {
            source
                .replacingOccurrences(of: "\r\n", with: "\n")
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)
        }

        /// The index of the closing `---` fence, or `nil` when the source has no
        /// front matter. The single definition of where front matter ends; both
        /// `split` and `parse` build their result from it.
        private static func frontMatterClosingIndex(
            _ lines: [String],
        ) throws -> Int? {
            guard lines.first == "---" else {
                return nil
            }
            guard let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
                throw FrontMatterParserError.missingClosingSeparator
            }
            return closingIndex
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
