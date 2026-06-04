import TileCore

public extension TileKit.Site {
    /// Renders Tiledown Markdown source as syntax-highlighted HTML for the
    /// "View Markdown source" disclosure.
    ///
    /// The highlighting is built here, in Swift, at build time: the page ships
    /// static colored markup and the reader downloads no client-side highlighter.
    /// It is line-oriented and intentionally approximate, coloring the constructs a
    /// reader is learning rather than parsing Markdown exactly: front matter,
    /// headings, fenced blocks, list and quote markers, inline code, emphasis,
    /// links, and math. Every span of text is escaped, so the result is safe to
    /// drop into a `<pre><code>` with a raw template tag.
    enum SourceHighlighter {
        /// The highlighted HTML for a verbatim source file. Lines are preserved and
        /// rejoined with newlines so the listing reads exactly as authored.
        static func html(for source: String) -> String {
            var output: [String] = []
            var inFrontMatter = false
            var fenceMarker: Character?
            var fenceLanguage: String?
            let lines = source.components(separatedBy: "\n")

            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if index == 0, trimmed == "---" {
                    inFrontMatter = true
                    output.append(span("tok-fm-delim", line))
                    continue
                }
                if inFrontMatter {
                    if trimmed == "---" {
                        inFrontMatter = false
                        output.append(span("tok-fm-delim", line))
                    } else {
                        output.append(frontMatterLine(line))
                    }
                    continue
                }

                if let marker = fenceMarker {
                    if isFenceLine(trimmed, marker: marker) {
                        fenceMarker = nil
                        fenceLanguage = nil
                        output.append(fenceLine(line))
                    } else {
                        output.append(rawSpan(
                            "tok-fence-body",
                            TileKit.SyntaxHighlighter.html(for: line, language: fenceLanguage),
                        ))
                    }
                    continue
                }
                if let marker = openingFenceMarker(trimmed) {
                    fenceMarker = marker
                    fenceLanguage = languageForFence(trimmed)
                    output.append(fenceLine(line))
                    continue
                }

                output.append(contentLine(line))
            }

            return output.joined(separator: "\n")
        }

        /// A `key: value` front-matter line, coloring the key and value separately.
        private static func frontMatterLine(_ line: String) -> String {
            let (lead, body) = splitLeadingWhitespace(line)
            guard let colon = body.firstIndex(of: ":") else {
                return lead + inline(body)
            }
            let key = body[..<colon]
            let rest = body[body.index(after: colon)...]
            return lead
                + span("tok-fm-key", String(key))
                + escape(":")
                + (rest.isEmpty ? "" : span("tok-fm-value", String(rest)))
        }

        /// A fence open or close line: the marker run, then any info string.
        private static func fenceLine(_ line: String) -> String {
            let (lead, body) = splitLeadingWhitespace(line)
            guard let markerChar = body.first else {
                return lead
            }
            let run = body.prefix { $0 == markerChar }
            let info = body[body.index(body.startIndex, offsetBy: run.count)...]
            return lead
                + span("tok-fence", String(run))
                + (info.isEmpty ? "" : span("tok-fence-lang", String(info)))
        }

        /// A normal content line: a leading block marker (heading, quote, or list),
        /// then inline highlighting of the remainder.
        private static func contentLine(_ line: String) -> String {
            let (lead, body) = splitLeadingWhitespace(line)
            guard !body.isEmpty else {
                return lead
            }
            if isHeading(body) {
                return lead + span("tok-heading", body)
            }
            if body.hasPrefix(">") {
                return lead + span("tok-quote", ">") + inline(String(body.dropFirst()))
            }
            if let marker = listMarker(body) {
                return lead + span("tok-list", marker) + inline(String(body.dropFirst(marker.count)))
            }
            return lead + inline(body)
        }

        /// Inline highlighting within a line: code spans, math, links and images,
        /// strong, and emphasis. Anything else is escaped verbatim.
        private static func inline(_ text: String) -> String {
            let chars = Array(text)
            let count = chars.count
            var output = ""
            var cursor = 0

            while cursor < count {
                let character = chars[cursor]

                if character == "`", let close = firstIndex(of: "`", in: chars, from: cursor + 1) {
                    output += span("tok-code", String(chars[cursor ... close]))
                    cursor = close + 1
                    continue
                }
                if character == "$", let close = firstIndex(of: "$", in: chars, from: cursor + 1), close > cursor + 1 {
                    output += span("tok-math", String(chars[cursor ... close]))
                    cursor = close + 1
                    continue
                }
                if character == "!", cursor + 1 < count, let end = linkEnd(in: chars, from: cursor + 1) {
                    output += span("tok-link", String(chars[cursor ... end]))
                    cursor = end + 1
                    continue
                }
                if character == "[", let end = linkEnd(in: chars, from: cursor) {
                    output += span("tok-link", String(chars[cursor ... end]))
                    cursor = end + 1
                    continue
                }
                if character == "*" || character == "_" {
                    let isDouble = cursor + 1 < count && chars[cursor + 1] == character
                    if isDouble, let close = doubleMarker(character, in: chars, from: cursor + 2) {
                        output += span("tok-strong", String(chars[cursor ... (close + 1)]))
                        cursor = close + 2
                        continue
                    }
                    if let close = firstIndex(of: character, in: chars, from: cursor + 1), close > cursor + 1 {
                        output += span("tok-em", String(chars[cursor ... close]))
                        cursor = close + 1
                        continue
                    }
                }

                output += escape(String(character))
                cursor += 1
            }

            return output
        }

        /// Whether a line body is an ATX heading (one to six `#` then a space or the
        /// end of the line).
        private static func isHeading(_ body: String) -> Bool {
            let hashes = body.prefix { $0 == "#" }
            guard (1 ... 6).contains(hashes.count) else {
                return false
            }
            return body.count == hashes.count || body[body.index(body.startIndex, offsetBy: hashes.count)] == " "
        }

        /// The leading list marker (`- `, `* `, `+ `, or `1. ` / `1) `) if present.
        private static func listMarker(_ body: String) -> String? {
            let chars = Array(body)
            if let first = chars.first, "-*+".contains(first), chars.count >= 2, chars[1] == " " {
                return String(body.prefix(2))
            }
            let digits = body.prefix { $0.isNumber }
            guard !digits.isEmpty, digits.count < body.count else {
                return nil
            }
            let afterDigits = body[body.index(body.startIndex, offsetBy: digits.count)]
            guard afterDigits == "." || afterDigits == ")" else {
                return nil
            }
            let spaceIndex = body.index(body.startIndex, offsetBy: digits.count + 1)
            guard spaceIndex < body.endIndex, body[spaceIndex] == " " else {
                return nil
            }
            return String(body[..<body.index(after: spaceIndex)])
        }

        private static func openingFenceMarker(_ trimmed: String) -> Character? {
            if trimmed.hasPrefix("```") {
                return "`"
            }
            if trimmed.hasPrefix("~~~") {
                return "~"
            }
            return nil
        }

        private static func isFenceLine(_ trimmed: String, marker: Character) -> Bool {
            trimmed.hasPrefix(String(repeating: marker, count: 3))
        }

        private static func languageForFence(_ trimmed: String) -> String? {
            guard let marker = openingFenceMarker(trimmed) else {
                return nil
            }
            let body = trimmed.drop { $0 == marker }
            let language = body.trimmingCharacters(in: .whitespaces)
            return language.isEmpty ? nil : language
        }

        /// The index of the closing `)` of a `[..](..)` link starting at `start`,
        /// or `nil` if the text is not a well-formed inline link from there.
        private static func linkEnd(in chars: [Character], from start: Int) -> Int? {
            guard start < chars.count, chars[start] == "[",
                  let closeBracket = firstIndex(of: "]", in: chars, from: start + 1)
            else {
                return nil
            }
            let parenOpen = closeBracket + 1
            guard parenOpen < chars.count, chars[parenOpen] == "(",
                  let closeParen = firstIndex(of: ")", in: chars, from: parenOpen + 1)
            else {
                return nil
            }
            return closeParen
        }

        private static func firstIndex(of target: Character, in chars: [Character], from start: Int) -> Int? {
            var index = start
            while index < chars.count {
                if chars[index] == target {
                    return index
                }
                index += 1
            }
            return nil
        }

        private static func doubleMarker(_ marker: Character, in chars: [Character], from start: Int) -> Int? {
            var index = start
            while index + 1 < chars.count {
                if chars[index] == marker, chars[index + 1] == marker {
                    return index
                }
                index += 1
            }
            return nil
        }

        private static func splitLeadingWhitespace(_ line: String) -> (lead: String, body: String) {
            let lead = line.prefix { $0 == " " || $0 == "\t" }
            return (String(lead), String(line.dropFirst(lead.count)))
        }

        private static func span(_ className: String, _ raw: String) -> String {
            "<span class=\"\(className)\">\(escape(raw))</span>"
        }

        private static func rawSpan(_ className: String, _ html: String) -> String {
            "<span class=\"\(className)\">\(html)</span>"
        }

        private static func escape(_ raw: String) -> String {
            TileKit.HTML.escapeText(raw)
        }
    }
}
