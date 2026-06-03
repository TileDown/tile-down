import TileCore
import TileTemplate

extension TileKit.Site.Generator {
    /// The "View Markdown source" disclosure values for a page, merged into the
    /// `page` context: the syntax-highlighted source HTML (already escaped, so the
    /// layout emits it with a raw tag), the source file name for the window title,
    /// and a flag that is non-empty only when there is a backing source file. A page
    /// with no source (such as the synthesized 404) yields empty values, so the
    /// disclosure does not render for it even when the site opts in.
    func sourceDisclosureContext(
        _ page: TileKit.Site.Page,
    ) -> [String: TileKit.Template.Value] {
        guard !page.rawSource.isEmpty else {
            return [
                "sourceHTML": .string(""),
                "sourceName": .string(""),
                "hasSource": .string(""),
            ]
        }
        return [
            "sourceHTML": .string(TileKit.Site.SourceHighlighter.html(for: page.rawSource)),
            "sourceName": .string(sourceFileName(page.sourcePath)),
            "hasSource": .string("true"),
        ]
    }

    /// The last path component of a source path, for the source-disclosure window
    /// title (e.g. `index.md`). Empty when the page has no backing file.
    private func sourceFileName(_ sourcePath: String) -> String {
        sourcePath.split(separator: "/").last.map(String.init) ?? ""
    }
}
