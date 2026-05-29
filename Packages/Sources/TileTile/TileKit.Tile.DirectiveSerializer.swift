import TileCore

public extension TileKit.Tile {
    /// Serializes a parsed tile block tree back to Tiledown Markdown.
    ///
    /// The inverse of ``DirectiveParser`` (`put` to the parser's `get`). Markdown
    /// blocks pass through verbatim; structural Markdown normalization is a later
    /// phase that needs a structural Markdown model. Tile blocks are emitted in
    /// one canonical form, preserving unknown tile types and unknown properties.
    ///
    /// Byte-identical round-trips are not a goal: the parser trims values and folds
    /// blank lines, so identity holds at the tile-tree level, not the text level.
    /// The serializer is the `put` half of the semantic round-trip the parser tests
    /// assert: `parse(serialize(parse(x))) == parse(x)`.
    struct DirectiveSerializer: Sendable {
        public init() {}

        public func serialize(
            _ blocks: [Block],
        ) -> String {
            blocks.map(serialize).joined(separator: "\n")
        }

        private func serialize(
            _ block: Block,
        ) -> String {
            switch block {
            case let .markdown(text):
                text
            case let .tile(instance):
                serialize(instance)
            }
        }

        private func serialize(
            _ instance: Instance,
        ) -> String {
            var lines = [":::tile \(instance.typeID)"]
            for property in instance.properties {
                lines.append(contentsOf: serialize(property))
            }
            lines.append(":::")
            return lines.joined(separator: "\n")
        }

        private func serialize(
            _ property: Property,
        ) -> [String] {
            switch property.value {
            case let .string(value):
                value.isEmpty
                    ? ["\(property.key):"]
                    : ["\(property.key): \(value)"]
            case let .list(items):
                ["\(property.key):"] + items.map { "- \($0)" }
            }
        }
    }
}
