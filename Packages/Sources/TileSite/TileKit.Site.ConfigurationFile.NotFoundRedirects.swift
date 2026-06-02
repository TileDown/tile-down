import TileCore

extension TileKit.Site.ConfigurationFile {
    /// Parses 404 fallback redirect rules:
    /// `notFoundRedirect.exact./old-path: /new-path/`
    /// `notFoundRedirect.prefix./old-prefix/: /new-prefix/`
    static func applyNotFoundRedirect(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) throws -> Bool {
        if item.key.hasPrefix("notFoundRedirect.exact.") {
            let source = String(item.key.dropFirst("notFoundRedirect.exact.".count))
            let rule = try TileKit.Site.NotFoundRedirects.Rule(
                source: source,
                target: item.value,
            )
            result.configuration.notFoundRedirects.exact.append(rule)
            return true
        }
        if item.key.hasPrefix("notFoundRedirect.prefix.") {
            let source = String(item.key.dropFirst("notFoundRedirect.prefix.".count))
            let rule = try TileKit.Site.NotFoundRedirects.Rule(
                source: source,
                target: item.value,
            )
            result.configuration.notFoundRedirects.prefixes.append(rule)
            return true
        }
        return false
    }
}
