import Foundation
import TileCore
import TileSource
import TileTile

public extension TileKit.Site {
    /// Generates local redirect target pages for Buttondown subscribe flows.
    struct ButtondownPageGenerator: TilePageGenerating {
        public init() {}

        public func pages(
            for context: TileKit.Site.TilePageGenerationContext,
        ) throws -> [TileKit.Site.Page] {
            guard context.tile.typeID == TileKit.Tile.ButtondownRenderer.typeID,
                  try buttondownGeneratesPages(context.tile)
            else {
                return []
            }

            return try buttondownPages(
                for: context.tile,
                sourcePage: context.sourcePage,
                outputRootPath: context.outputRootPath,
            )
        }
    }
}

private extension TileKit.Site.ButtondownPageGenerator {
    func buttondownGeneratesPages(
        _ tile: TileKit.Tile.Instance,
    ) throws -> Bool {
        try bool(
            tile.property(named: "generatePages"),
            property: "generatePages",
        ) ?? true
    }

    func buttondownPages(
        for tile: TileKit.Tile.Instance,
        sourcePage: TileKit.Site.Page,
        outputRootPath: String,
    ) throws -> [TileKit.Site.Page] {
        let baseSlug = try buttondownBaseSlug(
            tile,
            sourcePage: sourcePage,
        )
        let defaultThanksBody = """
        Buttondown has the address. Open the confirmation email and click the link to finish subscribing.
        """
        return try [
            buttondownPage(
                slug: baseSlug + "/thanks",
                title: string(tile.property(named: "thanksTitle")) ?? "Check your email",
                body: string(tile.property(named: "thanksBody")) ?? defaultThanksBody,
                outputRootPath: outputRootPath,
            ),
            buttondownPage(
                slug: baseSlug + "/confirmed",
                title: string(tile.property(named: "confirmedTitle")) ?? "Subscription confirmed",
                body: string(tile.property(named: "confirmedBody")) ?? "You are on the list.",
                outputRootPath: outputRootPath,
            ),
        ]
    }

    func buttondownBaseSlug(
        _ tile: TileKit.Tile.Instance,
        sourcePage: TileKit.Site.Page,
    ) throws -> String {
        let fallback = sourcePage.slug.isEmpty ? "newsletter" : sourcePage.slug
        let configuredValue = string(tile.property(named: "redirectBasePath"))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let rawValue = configuredValue.flatMap { $0.isEmpty ? nil : $0 } ?? fallback
        return try TileKit.Site.Generator.effectiveSlug(
            folderSlug: fallback,
            frontMatter: ["slug": rawValue],
        )
    }

    func buttondownPage(
        slug: String,
        title: String,
        body: String,
        outputRootPath: String,
    ) throws -> TileKit.Site.Page {
        let document = TileKit.Source.Document(
            frontMatter: [
                "title": title,
                "nav": "false",
                "sitemap": "false",
            ],
            body: """
            # \(title)

            \(body)
            """,
        )
        return .init(
            sourcePath: "",
            outputPath: buttondownOutputPath(
                outputRootPath: outputRootPath,
                slug: slug,
            ),
            sourceSlug: slug,
            slug: slug,
            document: document,
            html: """
            <h1>\(TileKit.HTML.escapeText(title))</h1>
            <p>\(TileKit.HTML.escapeText(body))</p>
            """,
        )
    }

    func buttondownOutputPath(
        outputRootPath: String,
        slug: String,
    ) -> String {
        join(outputRootPath, slug + "/index.html")
    }

    func join(
        _ parent: String,
        _ child: String,
    ) -> String {
        guard !parent.isEmpty else {
            return child
        }

        if parent.hasSuffix("/") {
            return parent + child
        }

        return parent + "/" + child
    }

    func string(
        _ value: TileKit.Tile.Value?,
    ) -> String? {
        guard case let .string(string) = value else {
            return nil
        }
        return string
    }

    func bool(
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
        let raw = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
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
}
