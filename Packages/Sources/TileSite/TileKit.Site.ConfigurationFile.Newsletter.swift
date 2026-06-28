import TileCore

extension TileKit.Site.ConfigurationFile {
    /// Dispatches the prefix-keyed settings whose keys share a namespace
    /// (`social.*`, `newsletter.*`). Grouped into one handler so the per-line
    /// dispatch in `parse` stays within its complexity budget.
    static func applyPrefixedSetting(
        _ item: (key: String, value: String),
        to result: inout TileKit.Site.ConfigurationFile,
    ) throws -> Bool {
        if try applySocialLink(item, to: &result) {
            return true
        }
        if try applyNewsletterSetting(item, to: &result) {
            return true
        }
        return false
    }

    /// Accumulates the site-wide newsletter signup from `newsletter.<field>` keys,
    /// returning true when the line is a newsletter setting. The signup is created
    /// on the first such key; `resolvedNewsletter` validates it once all lines are
    /// read.
    static func applyNewsletterSetting(
        _ item: (key: String, value: String),
        to result: inout TileKit.Site.ConfigurationFile,
    ) throws -> Bool {
        guard item.key.hasPrefix("newsletter.") else {
            return false
        }
        let field = String(item.key.dropFirst("newsletter.".count))
        var value = result.configuration.newsletter ?? .init(username: "")
        switch field {
        case "username":
            value.username = item.value
        case "title":
            value.title = item.value
        case "body":
            value.body = item.value
        case "buttonLabel":
            value.buttonLabel = item.value
        case "placeholder":
            value.placeholder = item.value
        case "note":
            value.note = item.value
        case "endOfPost":
            value.endOfPost = try boolean(item.value)
        case "footer":
            value.footer = try boolean(item.value)
        default:
            throw TileKit.Site.ConfigurationFileError.unknownKey(item.key)
        }
        result.configuration.newsletter = value
        return true
    }

    /// Validates an accumulated newsletter: a configured signup must name a
    /// username, since the embed endpoint is built from it. Returns `nil`
    /// unchanged when no newsletter was configured.
    static func resolvedNewsletter(
        _ newsletter: TileKit.Site.Newsletter?,
    ) throws -> TileKit.Site.Newsletter? {
        guard let newsletter else {
            return nil
        }
        guard !newsletter.username.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TileKit.Site.ConfigurationFileError.newsletterMissingUsername
        }
        return newsletter
    }
}
