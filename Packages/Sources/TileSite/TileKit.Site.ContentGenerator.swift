import TileCore

public extension TileKit.Site {
    /// A pre-build content generator declared in `tiledown.yml` as
    /// `generate.<name>: <command>`.
    ///
    /// The generator is a command the build runs before reading content, so a
    /// custom Swift package (or any executable) can write Tiledown Markdown into
    /// the content tree from structured data (e.g. a CV from JSON). The engine
    /// parses and orders these; the composition root runs them as subprocesses,
    /// since subprocess use belongs at the composition root, not in the core.
    struct ContentGenerator: Equatable, Sendable {
        /// The declared name (the part after `generate.`), used to order
        /// generators deterministically and to label output.
        public let name: String
        /// The command and its arguments, already split on whitespace, e.g.
        /// `["swift", "run", "GenerateCV", "--out", "contents/cv/index.md"]`.
        public let command: [String]

        public init(
            name: String,
            command: [String],
        ) {
            self.name = name
            self.command = command
        }
    }
}
