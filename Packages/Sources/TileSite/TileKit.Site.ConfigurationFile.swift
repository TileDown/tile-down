import Foundation
import TileCore

public extension TileKit.Site {
    /// The small project configuration file consumed by `build-site`.
    ///
    /// This is deliberately a flat YAML subset for now: `key: value`, blank lines,
    /// and comment lines. The site generator already accepts strongly typed
    /// values; this type only decodes the project file into those values plus the
    /// selected built-in layout.
    struct ConfigurationFile: Equatable, Sendable {
        public var configuration: Configuration
        public var layout: Layout
        /// Pre-build content generators (`generate.<name>: <command>`), ordered by
        /// name. The composition root runs these before the content build.
        public var generators: [ContentGenerator]

        public init(
            configuration: Configuration = .init(),
            layout: Layout = .topNav,
            generators: [ContentGenerator] = [],
        ) {
            self.configuration = configuration
            self.layout = layout
            self.generators = generators
        }

        public static func parse(
            _ source: String,
        ) throws -> ConfigurationFile {
            var result = ConfigurationFile()
            var feed = result.configuration.feed
            var feedEnabled: Bool?

            for item in try entries(in: source) {
                if try applySocialLink(item, to: &result) {
                    continue
                }
                if applyOutboundLink(item, to: &result) {
                    continue
                }
                if applyGenerator(item, to: &result) {
                    continue
                }
                if applyAnalytics(item, to: &result) {
                    continue
                }
                if try applyShareLinks(item, to: &result) {
                    continue
                }
                if try applyNotFoundRedirect(item, to: &result) {
                    continue
                }
                if try applyStaticPassthrough(item, to: &result) {
                    continue
                }
                if try applyFeedSetting(
                    item,
                    feed: &feed,
                    feedEnabled: &feedEnabled,
                ) {
                    continue
                }
                try applyScalarSetting(item, to: &result)
            }

            result.configuration.feed = resolvedFeed(
                feed,
                feedEnabled: feedEnabled,
            )
            // Order generators by name so the run order is deterministic.
            result.generators.sort { $0.name < $1.name }
            return result
        }

        private static func applySocialLink(
            _ item: (key: String, value: String),
            to result: inout ConfigurationFile,
        ) throws -> Bool {
            guard item.key.hasPrefix("social.") else {
                return false
            }
            let label = try socialLabel(for: item.key)
            result.configuration.socialLinks.append(
                .init(
                    label: label,
                    url: item.value,
                ),
            )
            return true
        }

        private static func applyFeedSetting(
            _ item: (key: String, value: String),
            feed: inout Feed?,
            feedEnabled: inout Bool?,
        ) throws -> Bool {
            switch item.key {
            case "rss":
                feedEnabled = try boolean(item.value)
            case "rssPath":
                feed = updatingFeed(feed, path: item.value)
            case "rssTitle":
                feed = updatingFeed(feed, title: item.value)
            case "rssDescription":
                feed = updatingFeed(feed, description: item.value)
            default:
                return false
            }
            return true
        }

        /// Applies a single scalar `key: value` setting to the result, throwing on
        /// an unknown key. Split out of `parse` so the per-line dispatch stays
        /// simple and within the complexity budget.
        private static func applyScalarSetting(
            _ item: (key: String, value: String),
            to result: inout ConfigurationFile,
        ) throws {
            switch item.key {
            case "title":
                result.configuration.title = item.value
            case "baseURL":
                result.configuration.baseURL = item.value
            case "layout":
                result.layout = try layout(named: item.value)
            case "theme":
                result.configuration.theme = try theme(named: item.value)
            case "appearance":
                result.configuration.appearance = try appearance(named: item.value)
            case "postsDir":
                result.configuration.postsDirectory = postsDirectory(from: item.value)
            case "latestPosts":
                result.configuration.latestPostCount = try latestPostCount(from: item.value)
            case "postsLabel":
                result.configuration.postsLabel = item.value
            case "fontScale":
                result.configuration.fontScale = try fontScale(from: item.value)
            default:
                throw ConfigurationFileError.unknownKey(item.key)
            }
        }

        private static func resolvedFeed(
            _ feed: Feed?,
            feedEnabled: Bool?,
        ) -> Feed? {
            switch feedEnabled {
            case .some(true):
                feed ?? .init()
            case .some(false):
                nil
            case nil:
                feed
            }
        }

        private static func entries(
            in source: String,
        ) throws -> [(key: String, value: String)] {
            try source
                .replacingOccurrences(of: "\r\n", with: "\n")
                .split(separator: "\n", omittingEmptySubsequences: false)
                .enumerated()
                .compactMap { offset, line in
                    try entry(
                        in: String(line),
                        lineNumber: offset + 1,
                    )
                }
        }

        private static func entry(
            in line: String,
            lineNumber: Int,
        ) throws -> (key: String, value: String)? {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
                return nil
            }

            guard let separatorIndex = line.firstIndex(of: ":") else {
                throw ConfigurationFileError.invalidLine(lineNumber)
            }

            let key = String(line[..<separatorIndex])
                .trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: separatorIndex)...])
                .trimmingCharacters(in: .whitespaces)

            guard !key.isEmpty else {
                throw ConfigurationFileError.invalidLine(lineNumber)
            }

            return (key, value)
        }

        private static func layout(
            named name: String,
        ) throws -> Layout {
            switch name {
            case "top-nav", "topNav":
                .topNav
            case "left-sidebar", "leftSidebar":
                .leftSidebar
            default:
                throw ConfigurationFileError.unknownLayout(name)
            }
        }

        private static func theme(
            named name: String,
        ) throws -> Theme? {
            switch name {
            case "standard":
                .standard
            case "system":
                .system
            case "none", "unstyled":
                nil
            default:
                throw ConfigurationFileError.unknownTheme(name)
            }
        }

        private static func appearance(
            named name: String,
        ) throws -> Appearance {
            guard let appearance = Appearance(rawValue: name) else {
                throw ConfigurationFileError.unknownAppearance(name)
            }
            return appearance
        }

        /// Normalizes a `postsDir` value to a slug-style path: surrounding slashes
        /// trimmed so `blog`, `/blog`, and `blog/` agree. An empty or slash-only
        /// value falls back to the default `posts`.
        private static func postsDirectory(
            from value: String,
        ) -> String {
            var directory = value[...]
            while directory.hasPrefix("/") {
                directory = directory.dropFirst()
            }
            while directory.hasSuffix("/") {
                directory = directory.dropLast()
            }
            return directory.isEmpty ? "posts" : String(directory)
        }

        private static func boolean(
            _ value: String,
        ) throws -> Bool {
            switch value {
            case "true", "yes":
                true
            case "false", "no":
                false
            default:
                throw ConfigurationFileError.invalidBoolean(value)
            }
        }

        private static func updatingFeed(
            _ existing: Feed?,
            path: String? = nil,
            title: String? = nil,
            description: String? = nil,
        ) -> Feed {
            var result = existing ?? .init()
            if let path {
                result.path = path
            }
            if let title {
                result.title = title
            }
            if let description {
                result.description = description
            }
            return result
        }
    }
}

private extension TileKit.Site.ConfigurationFile {
    static func socialLabel(
        for key: String,
    ) throws -> String {
        let value = String(key.dropFirst("social.".count))
        guard !value.isEmpty else {
            throw TileKit.Site.ConfigurationFileError.unknownKey(key)
        }

        return switch value {
        case "github":
            "GitHub"
        case "linkedin":
            "LinkedIn"
        case let value:
            value
        }
    }

    /// Records a `generate.<name>: <command>` content generator, returning true
    /// when the line is a generator setting so the parser stops dispatching it.
    /// The command value is split on whitespace into command + arguments.
    static func applyGenerator(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) -> Bool {
        guard item.key.hasPrefix("generate.") else {
            return false
        }
        let name = String(item.key.dropFirst("generate.".count))
        let command = item.value
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)
        guard !name.isEmpty, !command.isEmpty else {
            return false
        }
        result.generators.append(TileKit.Site.ContentGenerator(name: name, command: command))
        return true
    }

    /// Parses a `latestPosts` count: a non-negative integer. A malformed value
    /// is a typed error rather than a silent default.
    static func latestPostCount(
        from value: String,
    ) throws -> Int {
        guard let count = Int(value), count >= 0 else {
            throw TileKit.Site.ConfigurationFileError.invalidLatestPosts(value)
        }
        return count
    }

    /// Parses a `fontScale` multiplier: a positive number. A malformed or
    /// non-positive value is a typed error rather than a silent default.
    static func fontScale(
        from value: String,
    ) throws -> Double {
        guard let scale = Double(value), scale > 0 else {
            throw TileKit.Site.ConfigurationFileError.invalidFontScale(value)
        }
        return scale
    }

    /// Records a `links.<key>: <url>` outbound link shim, returning true when the
    /// line is a link setting so the parser can stop dispatching it.
    static func applyOutboundLink(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) -> Bool {
        guard item.key.hasPrefix("links.") else {
            return false
        }
        let key = String(item.key.dropFirst("links.".count))
        guard !key.isEmpty else {
            return false
        }
        result.configuration.outboundLinks[key] = item.value
        return true
    }

    /// Records an opt-in analytics snippet (`analytics.head` / `analytics.bodyEnd`),
    /// returning true when the line is an analytics setting. Split out of the scalar
    /// dispatch to keep its complexity within budget.
    static func applyAnalytics(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) -> Bool {
        switch item.key {
        case "analytics.head":
            result.configuration.analyticsHead = item.value
        case "analytics.bodyEnd":
            result.configuration.analyticsBodyEnd = item.value
        default:
            return false
        }
        return true
    }

    /// Parses the opt-in article share-link switch separately from the scalar
    /// dispatch so the scalar switch stays small enough to read.
    static func applyShareLinks(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) throws -> Bool {
        guard item.key == "shareLinks" else {
            return false
        }
        result.configuration.shareLinks = try boolean(item.value)
        return true
    }
}
