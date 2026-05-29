import Foundation

public extension TileKit.Template {
    struct SimpleMustacheRenderer: Rendering {
        public init() {}

        public func render(
            template: String,
            context: [String: String],
        ) throws -> String {
            var result = ""
            var cursor = template.startIndex

            while let openRange = template[cursor...].range(of: "{{") {
                result += template[cursor ..< openRange.lowerBound]

                if template[openRange.upperBound...].hasPrefix("{") {
                    let keyStart = template.index(after: openRange.upperBound)
                    guard let closeRange = template[keyStart...].range(of: "}}}") else {
                        throw SimpleMustacheRendererError.unterminatedTag(
                            String(template[openRange.lowerBound...]),
                        )
                    }

                    let key = Self.key(
                        in: template[keyStart ..< closeRange.lowerBound],
                    )
                    guard let value = context[key] else {
                        throw SimpleMustacheRendererError.missingValue(key)
                    }
                    result += value
                    cursor = closeRange.upperBound
                } else {
                    guard let closeRange = template[openRange.upperBound...].range(of: "}}") else {
                        throw SimpleMustacheRendererError.unterminatedTag(
                            String(template[openRange.lowerBound...]),
                        )
                    }

                    let key = Self.key(
                        in: template[openRange.upperBound ..< closeRange.lowerBound],
                    )
                    guard let value = context[key] else {
                        throw SimpleMustacheRendererError.missingValue(key)
                    }
                    result += Self.escapeHTML(value)
                    cursor = closeRange.upperBound
                }
            }

            result += template[cursor...]
            return result
        }

        private static func key(
            in value: Substring,
        ) -> String {
            String(value).trimmingCharacters(in: .whitespacesAndNewlines)
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
