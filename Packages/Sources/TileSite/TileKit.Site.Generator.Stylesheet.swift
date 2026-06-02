import TileCore
import TileOutput

extension TileKit.Site.Generator {
    static let sharedStylesheetFileName = "styles.css"

    /// Merges every page's CSS into one site stylesheet, writes it to the output
    /// root, records it in `outputPaths`, and returns the URL to link it from
    /// each page. Returns "" and writes nothing when no page has any CSS, so a
    /// site without styled tiles emits no stray stylesheet.
    func writeSharedStylesheet(
        pages: [TileKit.Site.Page],
        outputRootPath: String,
        configuration: TileKit.Site.Configuration,
        outputPaths: inout [String],
    ) throws -> String {
        let tiles = pages.reduce(TileKit.Output.Stylesheet()) { result, page in
            result.merging(page.stylesheet)
        }
        let css = Self.composeStylesheet(
            theme: configuration.theme,
            tiles: tiles,
            fontScale: configuration.fontScale,
            themeProperties: configuration.themeProperties,
        )
        guard !css.isEmpty else {
            return ""
        }

        let outputPath = join(outputRootPath, Self.sharedStylesheetFileName)
        try fileSystem.writeTextFile(
            css,
            at: outputPath,
        )
        outputPaths.append(outputPath)
        return stylesheetURL(
            baseURL: configuration.baseURL,
            fileName: Self.sharedStylesheetFileName,
        )
    }

    func stylesheetURL(
        baseURL: String,
        fileName: String,
    ) -> String {
        guard !baseURL.isEmpty else {
            return "/" + fileName
        }
        return baseURL.hasSuffix("/") ? baseURL + fileName : baseURL + "/" + fileName
    }

    /// Composes the shared stylesheet from the theme and the merged tile CSS.
    /// With no theme this is exactly the tile stylesheet; with a theme it adds
    /// the theme properties (unlayered) and the theme's reset and base styles
    /// into the `reset` and `theme` cascade layers, beside the tiles.
    static func composeStylesheet(
        theme: TileKit.Site.Theme?,
        tiles: TileKit.Output.Stylesheet,
        fontScale: Double,
        themeProperties: TileKit.Site.ThemeProperties,
    ) -> String {
        // A non-default font scale sets the root font size, so every rem-based
        // size (the body and the whole type scale) grows or shrinks together.
        // Emitted unlayered and only when set, so a default site is unaffected.
        let scalePrefix = fontScale == 1
            ? ""
            : "html { font-size: \(percent(fontScale)); }\n"
        let propertyOverrides = themeProperties.css()

        guard let theme else {
            let base = tiles.text()
            let overrides = propertyOverrides.isEmpty ? "" : "\(propertyOverrides)\n"
            return [scalePrefix, overrides, base]
                .filter { !$0.isEmpty }
                .joined()
        }

        var result = scalePrefix + theme.tokens
        if !propertyOverrides.isEmpty {
            result += "\n" + propertyOverrides
        }
        result += "\n@layer reset, theme, tile-override;"
        if !theme.reset.isEmpty {
            result += "\n@layer reset {\n\(theme.reset)\n}"
        }
        let themeLayer = ([theme.base] + tiles.themed)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        if !themeLayer.isEmpty {
            result += "\n@layer theme {\n\(themeLayer)\n}"
        }
        if !tiles.overriding.isEmpty {
            result += "\n@layer tile-override {\n\(tiles.overriding.joined(separator: "\n"))\n}"
        }
        return result
    }

    /// Formats a font scale as a CSS percentage with no trailing zeros, so `1.1`
    /// becomes `110%` and `1.25` becomes `125%`.
    private static func percent(
        _ scale: Double,
    ) -> String {
        let value = scale * 100
        if value == value.rounded() {
            return "\(Int(value))%"
        }
        return "\(value)%"
    }
}
