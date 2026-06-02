import TileCore

extension TileKit.Site.Generator {
    /// Whether a page is a draft, from a truthy `draft` front-matter value.
    /// Unset or any non-truthy value publishes as normal.
    func isDraft(
        _ page: TileKit.Site.Page,
    ) -> Bool {
        switch page.document.frontMatter["draft"]?.lowercased() {
        case "true", "yes":
            true
        default:
            false
        }
    }
}
