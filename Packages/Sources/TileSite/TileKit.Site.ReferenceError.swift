import TileCore

public extension TileKit.Site {
    /// Build error raised when Markdown references name targets the site does not
    /// contain. Aggregated so one build reports every broken reference at once
    /// rather than failing on the first.
    enum ReferenceError: Error, Equatable, CustomStringConvertible {
        case unresolved([UnresolvedReference])

        public var description: String {
            switch self {
            case let .unresolved(references):
                let lines = references
                    .map { "  \($0.scheme):\($0.key) (in \($0.sourcePath))" }
                    .joined(separator: "\n")
                return "Unresolved references:\n\(lines)"
            }
        }
    }
}
