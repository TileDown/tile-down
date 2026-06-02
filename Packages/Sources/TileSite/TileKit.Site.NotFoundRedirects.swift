import Foundation
import TileCore

public extension TileKit.Site {
    /// Static-host fallback redirects that run from the generated root `404.html`.
    ///
    /// GitHub Pages and similar hosts can serve `/404.html` for unknown paths but
    /// cannot emit HTTP redirects for wildcard legacy routes. These rules give a
    /// migrated site a static, client-side fallback for those paths.
    struct NotFoundRedirects: Equatable, Sendable {
        /// Exact path redirects checked before prefix redirects.
        public var exact: [Rule]
        /// Prefix redirects checked after all exact redirects.
        public var prefixes: [Rule]

        /// Creates a 404 fallback redirect collection.
        ///
        /// Exact rules match the request path case-insensitively. Prefix rules
        /// match the beginning of the request path case-insensitively. Redirects
        /// preserve the request query string and fragment.
        public init(
            exact: [Rule] = [],
            prefixes: [Rule] = [],
        ) {
            self.exact = exact
            self.prefixes = prefixes
        }

        /// Whether the collection has no redirect rules.
        public var isEmpty: Bool {
            exact.isEmpty && prefixes.isEmpty
        }
    }
}

public extension TileKit.Site.NotFoundRedirects {
    /// One safe 404 fallback redirect rule.
    struct Rule: Equatable, Sendable {
        /// Source path to match, such as `/old-post` or `/tag/`.
        public var source: String
        /// Target path or HTTPS URL to redirect to.
        public var target: String

        /// Creates a redirect rule after validating that source and target are
        /// safe for static client-side emission.
        public init(
            source: String,
            target: String,
        ) throws {
            self.source = try Self.validatedSource(source)
            self.target = try Self.validatedTarget(target)
        }

        private static func validatedSource(
            _ source: String,
        ) throws -> String {
            try validateRootPath(source, allowRoot: false)
        }

        private static func validatedTarget(
            _ target: String,
        ) throws -> String {
            if target.hasPrefix("/") {
                return try validateRootPath(target, allowRoot: true)
            }
            guard
                !target.contains("\\"),
                !target.contains("\n"),
                !target.contains("\r"),
                let components = URLComponents(string: target),
                components.scheme == "https",
                components.host?.isEmpty == false,
                components.user == nil,
                components.password == nil,
                components.query == nil,
                components.fragment == nil
            else {
                throw TileKit.Site.ConfigurationFileError.invalidRedirectTarget(target)
            }
            return target
        }

        private static func validateRootPath(
            _ path: String,
            allowRoot: Bool,
        ) throws -> String {
            guard
                path.hasPrefix("/"),
                !path.hasPrefix("//"),
                !path.contains("\\"),
                !path.contains("?"),
                !path.contains("#"),
                !path.contains("\n"),
                !path.contains("\r")
            else {
                throw TileKit.Site.ConfigurationFileError.invalidRedirectPath(path)
            }
            let parts = path.split(separator: "/", omittingEmptySubsequences: true)
            guard allowRoot || !parts.isEmpty else {
                throw TileKit.Site.ConfigurationFileError.invalidRedirectPath(path)
            }
            guard parts.allSatisfy({ $0 != "." && $0 != ".." }) else {
                throw TileKit.Site.ConfigurationFileError.invalidRedirectPath(path)
            }
            return path
        }
    }
}
