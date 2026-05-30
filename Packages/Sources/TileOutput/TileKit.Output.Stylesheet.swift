import TileCore

public extension TileKit.Output {
    /// Tile CSS organized by cascade layer, before it is rendered to text.
    ///
    /// Carries the deduplicated CSS fragments for the `theme` and `tile-override`
    /// layers separately, so they can be merged across pages (for a shared
    /// site-level stylesheet) before being rendered. `text()` renders the canonical
    /// layered form; the layer-order statement is emitted only when there is CSS.
    struct Stylesheet: Equatable, Sendable {
        public var themed: [String]
        public var overriding: [String]

        public init(
            themed: [String] = [],
            overriding: [String] = [],
        ) {
            self.themed = themed
            self.overriding = overriding
        }

        public var isEmpty: Bool {
            themed.isEmpty && overriding.isEmpty
        }

        /// Returns a stylesheet with this one's fragments followed by the other's,
        /// deduplicated within each layer. Used to combine per-page CSS into one
        /// site-wide stylesheet.
        public func merging(
            _ other: Stylesheet,
        ) -> Stylesheet {
            Stylesheet(
                themed: Self.union(themed, other.themed),
                overriding: Self.union(overriding, other.overriding),
            )
        }

        /// Renders the canonical layered CSS, or an empty string when there is none.
        public func text() -> String {
            guard !isEmpty else {
                return ""
            }

            var result = "@layer reset, theme, tile-override;"
            if !themed.isEmpty {
                result += "\n@layer theme {\n\(themed.joined(separator: "\n"))\n}"
            }
            if !overriding.isEmpty {
                result += "\n@layer tile-override {\n\(overriding.joined(separator: "\n"))\n}"
            }
            return result
        }

        private static func union(
            _ first: [String],
            _ second: [String],
        ) -> [String] {
            var result = first
            for item in second where !result.contains(item) {
                result.append(item)
            }
            return result
        }
    }
}
