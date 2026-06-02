import TileCore

extension TileKit.Site.ConfigurationFile {
    /// Parses `static.<public-path>: <source-path>` entries. The key declares
    /// where the file or directory publishes, and the value points at the source
    /// path under the content root.
    static func applyStaticPassthrough(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) throws -> Bool {
        guard item.key.hasPrefix("static.") else {
            return false
        }
        let outputPath = String(item.key.dropFirst("static.".count))
        try result.configuration.staticPassthroughs.append(
            .init(
                validatingSourcePath: item.value,
                outputPath: outputPath,
            ),
        )
        return true
    }
}
