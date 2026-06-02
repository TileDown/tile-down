import Foundation

public extension TileKit {
    /// Shared escaping helpers for generated HTML.
    enum HTML {
        /// Escapes a value with the full table (`&`, `<`, `>`, `"`, `'`).
        ///
        /// This matches the escaping the per-renderer helpers applied before they
        /// were hoisted here, so it stays safe in both text and double-quoted
        /// attribute contexts. Prefer ``escapeText(_:)`` for text nodes and
        /// ``escapeAttribute(_:)`` for attribute values where the distinction
        /// matters.
        public static func escape(
            _ value: String,
        ) -> String {
            escapeAttribute(value)
        }

        /// Escapes text for safe insertion into an HTML text node.
        public static func escapeText(
            _ value: String,
        ) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
        }

        /// Escapes text for safe insertion into a double-quoted HTML attribute.
        public static func escapeAttribute(
            _ value: String,
        ) -> String {
            escapeText(value)
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
    }
}
