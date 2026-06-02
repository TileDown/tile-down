import Foundation
import TileCore

public extension TileKit.Site {
    /// Site-level overrides for the built-in `--td-*` theme properties.
    ///
    /// The public configuration surface uses short property names such as
    /// `accent` and `surface`; the generated stylesheet writes the corresponding
    /// `--td-accent` and `--td-surface` custom properties after the built-in
    /// theme's defaults so the site can reskin layouts and themed tiles without
    /// replacing templates.
    struct ThemeProperties: Equatable, Sendable {
        public private(set) var light: [String: String]
        public private(set) var dark: [String: String]

        public init() {
            light = [:]
            dark = [:]
        }

        /// Creates validated theme property overrides from short property names.
        ///
        /// Keys are the configuration names, such as `accent` and `surface`, not
        /// the generated CSS custom property names.
        public init(
            light: [String: String],
            dark: [String: String],
        ) throws {
            self.light = [:]
            self.dark = [:]
            for (name, value) in light {
                try setLightProperty(name, value: value)
            }
            for (name, value) in dark {
                try setDarkProperty(name, value: value)
            }
        }

        public var isEmpty: Bool {
            light.isEmpty && dark.isEmpty
        }

        public mutating func setLightProperty(
            _ name: String,
            value: String,
        ) throws {
            let property = try Self.cssPropertyName(for: name)
            let value = try Self.validatedValue(value)
            light[property] = value
        }

        public mutating func setDarkProperty(
            _ name: String,
            value: String,
        ) throws {
            let property = try Self.cssPropertyName(for: name)
            let value = try Self.validatedValue(value)
            dark[property] = value
        }

        func css() -> String {
            var blocks: [String] = []
            if !light.isEmpty {
                blocks.append(Self.cssBlock(selector: ":root", properties: light))
            }
            if !dark.isEmpty {
                let darkProperties = Self.declarations(for: dark)
                blocks.append(
                    """
                    .td-dark-tokens, [data-theme="dark"] {
                    \(darkProperties)
                    }
                    @media (prefers-color-scheme: dark) {
                    :root:not([data-theme="light"]) {
                    \(darkProperties)
                    }
                    }
                    """,
                )
            }
            return blocks.joined(separator: "\n")
        }

        private static let supportedProperties: [String: String] = [
            "accent": "--td-accent",
            "bg": "--td-bg",
            "border": "--td-border",
            "elevated": "--td-elevated",
            "font": "--td-font",
            "ink": "--td-ink",
            "measure": "--td-measure",
            "mono": "--td-mono",
            "muted": "--td-muted",
            "radius": "--td-radius",
            "shadow": "--td-shadow",
            "space": "--td-space",
            "surface": "--td-surface",
        ]

        private static func cssPropertyName(
            for name: String,
        ) throws -> String {
            guard let property = supportedProperties[name] else {
                throw TileKit.Site.ConfigurationFileError.unknownThemeProperty(name)
            }
            return property
        }

        private static func validatedValue(
            _ value: String,
        ) throws -> String {
            let trimmed = value.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.contains("/*"),
                  !trimmed.contains("*/"),
                  trimmed.allSatisfy({ character in
                      character != ";"
                          && character != "{"
                          && character != "}"
                          && !character.isNewline
                  })
            else {
                throw TileKit.Site.ConfigurationFileError.invalidThemePropertyValue(value)
            }
            return trimmed
        }

        private static func cssBlock(
            selector: String,
            properties: [String: String],
        ) -> String {
            """
            \(selector) {
            \(declarations(for: properties))
            }
            """
        }

        private static func declarations(
            for properties: [String: String],
        ) -> String {
            properties
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value);" }
                .joined(separator: "\n")
        }
    }
}
