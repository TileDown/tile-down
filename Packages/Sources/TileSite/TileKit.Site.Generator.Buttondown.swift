import Foundation
import TileCore
import TileSource
import TileTile

extension TileKit.Site.Generator {
    func appendingButtondownPages(
        to pages: [TileKit.Site.Page],
        request: TileKit.Site.ContentBuildRequest,
    ) throws -> [TileKit.Site.Page] {
        var result = pages
        var occupiedSlugs = Set(pages.map(\.slug))

        for page in pages {
            let tiles = try buttondownTiles(in: page)
            for tile in tiles where buttondownGeneratesPages(tile) {
                for generatedPage in try buttondownPages(
                    for: tile,
                    sourcePage: page,
                    outputRootPath: request.outputRootPath,
                ) where occupiedSlugs.insert(generatedPage.slug).inserted {
                    result.append(generatedPage)
                }
            }
        }

        return result
    }
}

private extension TileKit.Site.Generator {
    func buttondownTiles(
        in page: TileKit.Site.Page,
    ) throws -> [TileKit.Tile.Instance] {
        try tileParser.parseBlocks(page.document.body).compactMap { block in
            guard case let .tile(tile) = block,
                  tile.typeID == TileKit.Tile.ButtondownRenderer.typeID
            else {
                return nil
            }
            return tile
        }
    }

    func buttondownGeneratesPages(
        _ tile: TileKit.Tile.Instance,
    ) -> Bool {
        bool(tile.property(named: "generatePages")) ?? true
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
        return try effectiveSlug(
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
    ) -> Bool? {
        guard let raw = string(value)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
            !raw.isEmpty
        else {
            return nil
        }
        switch raw {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            return nil
        }
    }
}
