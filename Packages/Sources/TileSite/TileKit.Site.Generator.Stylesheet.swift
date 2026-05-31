import TileCore
import TileOutput

extension TileKit.Site.Generator {
    /// Composes the shared stylesheet from the theme and the merged tile CSS.
    /// With no theme this is exactly the tile stylesheet; with a theme it adds
    /// the theme properties (unlayered) and the theme's reset and base styles
    /// into the `reset` and `theme` cascade layers, beside the tiles.
    static func composeStylesheet(
        theme: TileKit.Site.Theme?,
        tiles: TileKit.Output.Stylesheet,
        fontScale: Double,
    ) -> String {
        // A non-default font scale sets the root font size, so every rem-based
        // size (the body and the whole type scale) grows or shrinks together.
        // Emitted unlayered and only when set, so a default site is unaffected.
        let scalePrefix = fontScale == 1
            ? ""
            : "html { font-size: \(percent(fontScale)); }\n"

        guard let theme else {
            let base = tiles.text()
            return base.isEmpty ? base : scalePrefix + base
        }

        var result = scalePrefix + theme.tokens
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
