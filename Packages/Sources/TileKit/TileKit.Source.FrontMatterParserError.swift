public extension TileKit.Source {
    enum FrontMatterParserError: Error, Equatable {
        case missingClosingSeparator
        case invalidLine(String)
    }
}
