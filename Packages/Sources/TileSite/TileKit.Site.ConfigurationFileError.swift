import TileCore

public extension TileKit.Site {
    enum ConfigurationFileError: Error, Equatable, CustomStringConvertible {
        case invalidLine(Int)
        case unknownKey(String)
        case unknownLayout(String)
        case unknownTheme(String)
        case unknownAppearance(String)
        case invalidBoolean(String)
        case invalidPath(String)
        case invalidRedirectPath(String)
        case invalidRedirectTarget(String)
        case duplicateSlug(String)
        case duplicateOutputPath(String)
        case invalidLatestPosts(String)
        case invalidFontScale(String)

        public var description: String {
            switch self {
            case let .invalidLine(line):
                "Invalid site configuration line \(line). Expected `key: value`."
            case let .unknownKey(key):
                "Unknown site configuration key `\(key)`."
            case let .unknownLayout(layout):
                "Unknown site layout `\(layout)`."
            case let .unknownTheme(theme):
                "Unknown site theme `\(theme)`."
            case let .unknownAppearance(appearance):
                "Unknown site appearance `\(appearance)`. Expected toggle, auto, light, or dark."
            case let .invalidBoolean(value):
                "Invalid boolean value `\(value)`. Expected `true` or `false`."
            case let .invalidPath(path):
                "Invalid site configuration path `\(path)`."
            case let .invalidRedirectPath(path):
                "Invalid 404 redirect path `\(path)`. Expected a safe root-relative path."
            case let .invalidRedirectTarget(target):
                "Invalid 404 redirect target `\(target)`. Expected a safe root-relative path or HTTPS URL."
            case let .duplicateSlug(slug):
                "Duplicate page slug `\(slug)`. Two pages resolve to the same output path."
            case let .duplicateOutputPath(path):
                "Duplicate output path `\(path)`. Two generated files would overwrite each other."
            case let .invalidLatestPosts(value):
                "Invalid latestPosts value `\(value)`. Expected a non-negative integer."
            case let .invalidFontScale(value):
                "Invalid fontScale value `\(value)`. Expected a positive number."
            }
        }
    }
}
