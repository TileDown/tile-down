import TileCore

extension TileKit.Site.Generator {
    func appendingGeneratedTilePages(
        to pages: [TileKit.Site.Page],
        request: TileKit.Site.ContentBuildRequest,
    ) throws -> [TileKit.Site.Page] {
        guard !tilePageGenerators.isEmpty else {
            return pages
        }

        var result = pages
        var occupiedSlugs = Set(pages.map(\.slug))

        for page in pages {
            let tiles = try tileInstances(in: page)
            for tile in tiles {
                let context = TileKit.Site.TilePageGenerationContext(
                    tile: tile,
                    sourcePage: page,
                    outputRootPath: request.outputRootPath,
                )
                for generator in tilePageGenerators {
                    let generatedPages = try generator.pages(for: context)
                    for generatedPage in generatedPages {
                        guard occupiedSlugs.insert(generatedPage.slug).inserted else {
                            continue
                        }
                        result.append(generatedPage)
                    }
                }
            }
        }

        return result
    }
}

private extension TileKit.Site.Generator {
    func tileInstances(
        in page: TileKit.Site.Page,
    ) throws -> [TileKit.Tile.Instance] {
        try tileParser.parseBlocks(page.document.body).compactMap { block in
            guard case let .tile(tile) = block else {
                return nil
            }
            return tile
        }
    }
}
