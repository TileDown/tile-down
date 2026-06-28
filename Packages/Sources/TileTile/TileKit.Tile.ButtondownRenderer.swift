import Foundation
import TileCore

public extension TileKit.Tile {
    /// A static newsletter signup form backed by Buttondown's embedded subscribe
    /// endpoint. Reads required `username` plus optional copy, tag, metadata, and
    /// attribution properties.
    struct ButtondownRenderer: Rendering {
        public static let typeID = "buttondown"

        public init() {}

        public func render(
            _ tile: Instance,
        ) throws -> Rendered {
            guard tile.typeID == Self.typeID else {
                throw ButtondownRendererError.invalidTileType(actual: tile.typeID)
            }

            let configuration = try Self.configuration(from: tile)
            return .init(
                html: html(configuration),
                css: Self.css,
            )
        }
    }
}

private extension TileKit.Tile.ButtondownRenderer {
    struct Configuration {
        var username: String
        var title: String
        var body: String
        var emailLabel: String
        var placeholder: String
        var buttonLabel: String
        var note: String
        var poweredBy: Bool
        var tags: [String]
        var metadata: [(key: String, value: String)]
    }

    static func configuration(
        from tile: TileKit.Tile.Instance,
    ) throws -> Configuration {
        let username = try requiredString(named: "username", from: tile)
        guard isValidUsername(username) else {
            throw TileKit.Tile.ButtondownRendererError.invalidUsername(username)
        }

        return try .init(
            username: username,
            title: string(tile.property(named: "title")) ?? "Subscribe",
            body: string(tile.property(named: "body")) ?? "",
            emailLabel: string(tile.property(named: "emailLabel")) ?? "Email",
            placeholder: string(tile.property(named: "placeholder")) ?? "you@example.com",
            buttonLabel: string(tile.property(named: "buttonLabel")) ?? "Subscribe",
            note: string(tile.property(named: "note")) ?? "",
            poweredBy: bool(
                tile.property(named: "poweredBy"),
                property: "poweredBy",
            ) ?? true,
            tags: tags(from: tile.property(named: "tags")),
            metadata: metadata(from: tile),
        )
    }

    static func requiredString(
        named key: String,
        from tile: TileKit.Tile.Instance,
    ) throws -> String {
        guard let value = string(tile.property(named: key)),
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw TileKit.Tile.ButtondownRendererError.missingProperty(key)
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func string(
        _ value: TileKit.Tile.Value?,
    ) -> String? {
        guard case let .string(string) = value else {
            return nil
        }
        return string
    }

    static func bool(
        _ value: TileKit.Tile.Value?,
        property: String,
    ) throws -> Bool? {
        guard let value else {
            return nil
        }
        guard let rawValue = string(value) else {
            throw TileKit.Tile.ButtondownRendererError.invalidBoolean(
                property: property,
                value: "list",
            )
        }
        let raw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty
        else {
            return nil
        }
        switch raw {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            throw TileKit.Tile.ButtondownRendererError.invalidBoolean(
                property: property,
                value: rawValue,
            )
        }
    }

    static func tags(
        from value: TileKit.Tile.Value?,
    ) -> [String] {
        let rawTags: [String] = switch value {
        case let .list(items):
            items
        case let .string(value):
            value.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        case .none:
            []
        }

        return rawTags.compactMap { tag in
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    static func metadata(
        from tile: TileKit.Tile.Instance,
    ) throws -> [(key: String, value: String)] {
        try tile.properties.compactMap { property in
            guard property.key.hasPrefix("metadata.") else {
                return nil
            }

            let key = String(property.key.dropFirst("metadata.".count))
            guard isValidMetadataKey(key) else {
                throw TileKit.Tile.ButtondownRendererError.invalidMetadataKey(key)
            }
            guard let value = string(property.value) else {
                throw TileKit.Tile.ButtondownRendererError.invalidMetadataValue(key)
            }
            return (key, value)
        }
    }

    private static func isValidUsername(
        _ username: String,
    ) -> Bool {
        !username.isEmpty && username.allSatisfy { character in
            character.isASCII
                && (character.isLetter || character.isNumber || character == "-" || character == "_")
        }
    }

    private static func isValidMetadataKey(
        _ key: String,
    ) -> Bool {
        !key.isEmpty && key.allSatisfy { character in
            character.isASCII
                && (
                    character.isLetter
                        || character.isNumber
                        || character == "-"
                        || character == "_"
                        || character == "."
                )
        }
    }
}

private extension TileKit.Tile.ButtondownRenderer {
    func html(
        _ configuration: Configuration,
    ) -> String {
        let header = header(configuration)
        let hiddenInputs = hiddenInputs(configuration)
        let note = paragraph(
            configuration.note,
            className: "td-buttondown-note",
        )
        let poweredBy = poweredBy(configuration)
        let username = escapeAttribute(configuration.username)
        return """
        <section class="td-buttondown" data-td-buttondown>
        \(header)<form
          action="https://buttondown.com/api/emails/embed-subscribe/\(username)"
          method="post"
          class="embeddable-buttondown-form td-buttondown-form"
        >
        <input type="hidden" name="embed" value="1">
        \(hiddenInputs)<label class="td-buttondown-label">
        <span>\(escapeText(configuration.emailLabel))</span>
        <input
          class="td-buttondown-input"
          type="email"
          name="email"
          placeholder="\(escapeAttribute(configuration.placeholder))"
          autocomplete="email"
          required
        >
        </label>
        <button class="td-buttondown-submit" type="submit">\(escapeText(configuration.buttonLabel))</button>
        </form>
        \(note)\(poweredBy)</section>
        """
    }

    func header(
        _ configuration: Configuration,
    ) -> String {
        guard !configuration.title.isEmpty || !configuration.body.isEmpty else {
            return ""
        }
        let title = configuration.title.isEmpty
            ? ""
            : "<h2 class=\"td-buttondown-title\">\(escapeText(configuration.title))</h2>\n"
        let body = paragraph(
            configuration.body,
            className: "td-buttondown-body",
        )
        return """
        <header class="td-buttondown-header">
        \(title)\(body)</header>

        """
    }

    func hiddenInputs(
        _ configuration: Configuration,
    ) -> String {
        let tags = configuration.tags.map { tag in
            """
            <input type="hidden" name="tag" value="\(escapeAttribute(tag))">
            """
        }
        let metadata = configuration.metadata.map { item in
            let key = escapeAttribute(item.key)
            let value = escapeAttribute(item.value)
            return #"<input type="hidden" name="metadata__\#(key)" value="\#(value)">"#
        }
        let inputs = tags + metadata
        return inputs.isEmpty ? "" : inputs.joined(separator: "\n") + "\n"
    }

    func poweredBy(
        _ configuration: Configuration,
    ) -> String {
        guard configuration.poweredBy else {
            return ""
        }
        let username = escapeAttribute(configuration.username)
        return """
        <p class="td-buttondown-powered">
        <a
          href="https://buttondown.com/refer/\(username)"
          target="_blank"
          rel="noopener"
        >Powered by Buttondown.</a>
        </p>
        """
    }

    func paragraph(
        _ text: String,
        className: String,
    ) -> String {
        guard !text.isEmpty else {
            return ""
        }
        return "<p class=\"\(className)\">\(escapeText(text))</p>\n"
    }

    func escapeText(
        _ value: String,
    ) -> String {
        TileKit.HTML.escapeText(value)
    }

    func escapeAttribute(
        _ value: String,
    ) -> String {
        TileKit.HTML.escapeAttribute(value)
    }

    // Tile CSS is authored as CSS. Keep line_length disabled only for the
    // embedded payload, then restore it for Swift code.
    // swiftlint:disable line_length
    static let css = """
    .td-buttondown { border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-surface); padding: 1.25rem; margin-block: 1.5rem; }
    .td-buttondown-header { margin-block-end: 1rem; }
    .td-buttondown-title { margin: 0 0 0.35rem; color: var(--td-ink); font-size: 1.25rem; line-height: 1.25; }
    .td-buttondown-body,
    .td-buttondown-note,
    .td-buttondown-powered { margin: 0; color: var(--td-muted); }
    .td-buttondown-form { display: grid; gap: 0.75rem; }
    .td-buttondown-label { display: grid; gap: 0.35rem; color: var(--td-ink); font-weight: 700; }
    .td-buttondown-input { box-sizing: border-box; width: 100%; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-background); color: var(--td-ink); font: inherit; padding: 0.7rem 0.85rem; }
    .td-buttondown-submit { cursor: pointer; border: 1px solid var(--td-accent); border-radius: var(--td-radius); background: var(--td-accent); color: #fff; font: inherit; font-weight: 700; padding: 0.7rem 1rem; }
    .td-buttondown-note { margin-block-start: 0.85rem; font-size: 0.95rem; }
    .td-buttondown-powered { margin-block-start: 0.65rem; font-size: 0.85rem; }
    .td-buttondown-powered a { color: var(--td-muted); }
    @media (min-width: 38rem) {
      .td-buttondown-form { align-items: end; grid-template-columns: minmax(0, 1fr) auto; }
    }
    """
    // swiftlint:enable line_length
}
