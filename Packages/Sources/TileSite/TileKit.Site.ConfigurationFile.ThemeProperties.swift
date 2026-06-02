import TileCore

extension TileKit.Site.ConfigurationFile {
    /// Records a `theme.light.<property>` or `theme.dark.<property>` override.
    /// The parser accepts only the curated `--td-*` property surface so a typo
    /// fails before a site publishes a stylesheet that silently does nothing.
    static func applyThemeProperty(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) throws -> Bool {
        let lightPrefix = "theme.light."
        let darkPrefix = "theme.dark."
        if item.key.hasPrefix(lightPrefix) {
            let name = String(item.key.dropFirst(lightPrefix.count))
            try result.configuration.themeProperties.setLightProperty(
                name,
                value: item.value,
            )
            return true
        }
        if item.key.hasPrefix(darkPrefix) {
            let name = String(item.key.dropFirst(darkPrefix.count))
            try result.configuration.themeProperties.setDarkProperty(
                name,
                value: item.value,
            )
            return true
        }
        return false
    }
}
