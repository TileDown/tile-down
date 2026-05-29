import Foundation
import TileCore
import TileTile

public extension TileKit.Output {
    /// Projects a parsed document into derived JSON.
    ///
    /// JSON is a derived view of the canonical tile tree, never the source of
    /// truth, useful for tests, debugging, interchange, and future editor work. The
    /// projection preserves tile type ids, source property order (properties are an
    /// ordered array, not an object), and unknown tile data (an unknown tile type
    /// projects like any other, so its type and properties survive). Output is
    /// deterministic: object keys are sorted and the same document always yields the
    /// same bytes.
    ///
    /// The wire shape is defined by the private `Encodable` data-transfer types
    /// below, deliberately decoupled from the in-memory tile model so the schema is
    /// an explicit interface rather than an accident of synthesized `Codable`.
    struct JSONRenderer: Rendering {
        /// The output format id this renderer produces.
        public static let formatID = "json"

        /// The self-describing schema marker emitted in the `tiledown.format` field.
        public static let schemaFormat = "tile-document"

        public var formatID: String {
            Self.formatID
        }

        public init() {}

        public func render(
            _ document: Document,
        ) throws -> Artifact {
            let dto = DocumentDTO(
                tiledown: HeaderDTO(
                    version: TileKit.Product.version,
                    format: Self.schemaFormat,
                ),
                slug: document.slug,
                frontMatter: document.frontMatter,
                blocks: document.blocks.map(BlockDTO.init),
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys,
                .withoutEscapingSlashes,
            ]

            let data = try encoder.encode(dto)
            guard let json = String(bytes: data, encoding: .utf8) else {
                throw RenderingError.invalidTextEncoding(format: Self.formatID)
            }

            return Artifact(
                contents: json + "\n",
                fileExtension: "json",
            )
        }
    }
}

private struct DocumentDTO: Encodable {
    let tiledown: HeaderDTO
    let slug: String
    let frontMatter: [String: String]
    let blocks: [BlockDTO]
}

private struct HeaderDTO: Encodable {
    let version: String
    let format: String
}

private enum BlockDTO: Encodable {
    case markdown(text: String)
    case tile(type: String, props: [PropertyDTO], children: [BlockDTO])

    init(_ block: TileKit.Tile.Block) {
        switch block {
        case let .markdown(text):
            self = .markdown(text: text)
        case let .tile(instance):
            self = .tile(
                type: instance.typeID,
                props: instance.properties.map(PropertyDTO.init),
                children: instance.children.map(BlockDTO.init),
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case text
        case type
        case props
        case children
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .markdown(text):
            try container.encode("markdown", forKey: .kind)
            try container.encode(text, forKey: .text)
        case let .tile(type, props, children):
            try container.encode("tile", forKey: .kind)
            try container.encode(type, forKey: .type)
            try container.encode(props, forKey: .props)
            try container.encode(children, forKey: .children)
        }
    }
}

private struct PropertyDTO: Encodable {
    let key: String
    let value: ValueDTO

    init(_ property: TileKit.Tile.Property) {
        key = property.key
        value = ValueDTO(property.value)
    }
}

private enum ValueDTO: Encodable {
    case string(String)
    case list([String])

    init(_ value: TileKit.Tile.Value) {
        switch value {
        case let .string(text):
            self = .string(text)
        case let .list(items):
            self = .list(items)
        }
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case string
        case list
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(text):
            try container.encode("string", forKey: .kind)
            try container.encode(text, forKey: .string)
        case let .list(items):
            try container.encode("list", forKey: .kind)
            try container.encode(items, forKey: .list)
        }
    }
}
