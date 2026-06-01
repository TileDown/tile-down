import TileCore

public extension TileKit.Site {
    enum RedirectError: Error, Equatable, CustomStringConvertible {
        case missingTarget(String)

        public var description: String {
            switch self {
            case let .missingTarget(sourcePath):
                "Redirect page `\(sourcePath)` is missing a non-empty `to` front-matter value."
            }
        }
    }
}
