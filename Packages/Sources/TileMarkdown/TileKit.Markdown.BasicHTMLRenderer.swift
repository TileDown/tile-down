import Foundation
import TileCore

public extension TileKit.Markdown {
    struct BasicHTMLRenderer: Rendering {
        public init() {}

        public func renderHTML(
            _ markdown: String,
        ) -> String {
            let normalized = markdown.replacingOccurrences(
                of: "\r\n",
                with: "\n",
            )
            let lines = normalized.split(
                separator: "\n",
                omittingEmptySubsequences: false,
            ).map(String.init)

            var output: [String] = []
            var paragraph: [String] = []

            func flushParagraph() {
                guard !paragraph.isEmpty else {
                    return
                }
                let text = paragraph
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .joined(separator: " ")
                output.append("<p>\(Self.escapeHTML(text))</p>")
                paragraph.removeAll()
            }

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                guard !trimmed.isEmpty else {
                    flushParagraph()
                    continue
                }

                if let heading = Self.heading(from: trimmed) {
                    flushParagraph()
                    output.append(
                        "<h\(heading.level)>\(Self.escapeHTML(heading.text))</h\(heading.level)>",
                    )
                    continue
                }

                paragraph.append(line)
            }

            flushParagraph()
            return output.joined(separator: "\n")
        }

        private static func heading(
            from line: String,
        ) -> (level: Int, text: String)? {
            let hashes = line.prefix(while: { $0 == "#" })
            guard
                1 ... 6 ~= hashes.count,
                line.dropFirst(hashes.count).first == " "
            else {
                return nil
            }

            let text = line
                .dropFirst(hashes.count + 1)
                .trimmingCharacters(in: .whitespaces)
            return (hashes.count, text)
        }

        private static func escapeHTML(
            _ value: String,
        ) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
    }
}
