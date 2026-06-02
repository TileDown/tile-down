import Foundation
import TileCore

public extension TileKit.Template {
    struct SimpleMustacheRenderer: Rendering {
        public init() {}

        public func render(
            template: String,
            context: Context,
        ) throws -> String {
            try render(
                template: template,
                scopes: [context],
            )
        }

        private func render(
            template: String,
            scopes: [Context],
        ) throws -> String {
            var result = ""
            var cursor = template.startIndex

            while let openRange = template[cursor...].range(of: "{{") {
                result += template[cursor ..< openRange.lowerBound]

                if template[openRange.upperBound...].hasPrefix("{") {
                    let tag = try renderRawTag(
                        template: template,
                        openRange: openRange,
                        scopes: scopes,
                    )
                    result += tag.output
                    cursor = tag.cursor
                } else {
                    let tag = try renderTag(
                        template: template,
                        openRange: openRange,
                        scopes: scopes,
                    )
                    result += tag.output
                    cursor = tag.cursor
                }
            }

            result += template[cursor...]
            return result
        }

        private func renderRawTag(
            template: String,
            openRange: Range<String.Index>,
            scopes: [Context],
        ) throws -> (
            output: String,
            cursor: String.Index
        ) {
            let keyStart = template.index(after: openRange.upperBound)
            guard let closeRange = template[keyStart...].range(of: "}}}") else {
                throw SimpleMustacheRendererError.unterminatedTag(
                    String(template[openRange.lowerBound...]),
                )
            }

            let key = Self.key(
                in: template[keyStart ..< closeRange.lowerBound],
            )
            guard let value = Self.lookup(key, scopes: scopes)?.stringValue else {
                throw SimpleMustacheRendererError.missingValue(key)
            }
            return (value, closeRange.upperBound)
        }

        private func renderTag(
            template: String,
            openRange: Range<String.Index>,
            scopes: [Context],
        ) throws -> (
            output: String,
            cursor: String.Index
        ) {
            guard let closeRange = template[openRange.upperBound...].range(of: "}}") else {
                throw SimpleMustacheRendererError.unterminatedTag(
                    String(template[openRange.lowerBound...]),
                )
            }

            let key = Self.key(
                in: template[openRange.upperBound ..< closeRange.lowerBound],
            )

            if key.hasPrefix("#") {
                return try renderSectionTag(
                    key,
                    template: template,
                    closeRange: closeRange,
                    scopes: scopes,
                )
            }

            if key.hasPrefix("/") {
                throw SimpleMustacheRendererError.unexpectedClosingTag(key)
            }

            guard let value = Self.lookup(key, scopes: scopes)?.stringValue else {
                throw SimpleMustacheRendererError.missingValue(key)
            }
            return (Self.escapeHTML(value), closeRange.upperBound)
        }

        private func renderSectionTag(
            _ key: String,
            template: String,
            closeRange: Range<String.Index>,
            scopes: [Context],
        ) throws -> (
            output: String,
            cursor: String.Index
        ) {
            let sectionName = Self.sectionName(key)
            let sectionEnd = try sectionEnd(
                sectionName,
                template: template,
                after: closeRange.upperBound,
            )
            let sectionBody = String(
                template[closeRange.upperBound ..< sectionEnd.lowerBound],
            )
            let output = try renderSection(
                sectionName,
                body: sectionBody,
                scopes: scopes,
            )
            return (output, sectionEnd.upperBound)
        }

        private func renderSection(
            _ key: String,
            body: String,
            scopes: [Context],
        ) throws -> String {
            // A missing section key is falsey, per Mustache: the section renders
            // nothing. This is what makes an optional field like `page.image`
            // safe in a shared layout. A missing plain interpolation still
            // throws, since that is an authoring error, not an optional.
            guard let value = Self.lookup(key, scopes: scopes) else {
                return ""
            }

            switch value {
            case let .list(items):
                return try items
                    .map { item in
                        try render(
                            template: body,
                            scopes: [item] + scopes,
                        )
                    }
                    .joined()
            case let .object(item):
                return try render(
                    template: body,
                    scopes: [item] + scopes,
                )
            case let .string(value):
                guard Self.stringSectionIsTruthy(value) else {
                    return ""
                }
                return try render(
                    template: body,
                    scopes: scopes,
                )
            }
        }

        private func sectionEnd(
            _ key: String,
            template: String,
            after index: String.Index,
        ) throws -> Range<String.Index> {
            var cursor = index
            var depth = 1

            while let openRange = template[cursor...].range(of: "{{") {
                if template[openRange.upperBound...].hasPrefix("{") {
                    let keyStart = template.index(after: openRange.upperBound)
                    guard let closeRange = template[keyStart...].range(of: "}}}") else {
                        throw SimpleMustacheRendererError.unterminatedTag(
                            String(template[openRange.lowerBound...]),
                        )
                    }
                    cursor = closeRange.upperBound
                    continue
                }

                guard let closeRange = template[openRange.upperBound...].range(of: "}}") else {
                    throw SimpleMustacheRendererError.unterminatedTag(
                        String(template[openRange.lowerBound...]),
                    )
                }

                let tag = Self.key(
                    in: template[openRange.upperBound ..< closeRange.lowerBound],
                )

                if tag.hasPrefix("#"), Self.sectionName(tag) == key {
                    depth += 1
                }

                if tag.hasPrefix("/"), Self.sectionName(tag) == key {
                    depth -= 1
                    if depth == 0 {
                        return openRange.lowerBound ..< closeRange.upperBound
                    }
                }

                cursor = closeRange.upperBound
            }

            throw SimpleMustacheRendererError.missingSectionEnd(key)
        }
    }
}

public extension TileKit.Template.SimpleMustacheRenderer {
    /// Whether a string-valued Mustache section renders its body.
    ///
    /// A section is falsey when its value is `nil`, empty, whitespace-only, or,
    /// after trimming and case-folding, one of `false`, `0`, or `no`. Every
    /// other value is truthy. This is the single source of truth for string
    /// section truthiness; the site generator reuses it so front-matter gates
    /// such as `postList: false` behave the same way the renderer does.
    static func stringSectionIsTruthy(
        _ value: String?,
    ) -> Bool {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case nil, .some(""), .some("false"), .some("0"), .some("no"):
            false
        default:
            true
        }
    }
}

private extension TileKit.Template.SimpleMustacheRenderer {
    static func key(
        in value: Substring,
    ) -> String {
        String(value).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sectionName(
        _ key: String,
    ) -> String {
        String(key.dropFirst())
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func lookup(
        _ key: String,
        scopes: [TileKit.Template.Context],
    ) -> TileKit.Template.Value? {
        for scope in scopes {
            if let direct = scope[key] {
                return direct
            }

            if let nested = nestedValue(
                key,
                in: scope,
            ) {
                return nested
            }
        }

        return nil
    }

    static func nestedValue(
        _ key: String,
        in scope: TileKit.Template.Context,
    ) -> TileKit.Template.Value? {
        let parts = key.split(separator: ".").map(String.init)
        guard
            let first = parts.first,
            var value = scope[first]
        else {
            return nil
        }

        for part in parts.dropFirst() {
            guard case let .object(object) = value else {
                return nil
            }
            guard let next = object[part] else {
                return nil
            }
            value = next
        }

        return value
    }

    static func escapeHTML(
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
