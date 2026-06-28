import TileCore
import TileTile

extension TileKit.Site.Generator {
    /// Renders the site-wide newsletter signup once per build, reusing the
    /// `buttondown` tile renderer so its markup and CSS match the inline tile.
    /// Returns `nil` when no newsletter is configured.
    func renderedNewsletter(
        _ configuration: TileKit.Site.Configuration,
    ) throws -> TileKit.Tile.Rendered? {
        guard let newsletter = configuration.newsletter else {
            return nil
        }
        let instance = TileKit.Tile.Instance(
            typeID: TileKit.Tile.ButtondownRenderer.typeID,
            properties: [
                .init(key: "username", value: .string(newsletter.username)),
                .init(key: "title", value: .string(newsletter.title)),
                .init(key: "body", value: .string(newsletter.body)),
                .init(key: "buttonLabel", value: .string(newsletter.buttonLabel)),
                .init(key: "placeholder", value: .string(newsletter.placeholder)),
                .init(key: "note", value: .string(newsletter.note)),
            ],
        )
        return try TileKit.Tile.ButtondownRenderer().render(instance)
    }
}
