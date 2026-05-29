public extension TileKit.Template {
    enum SimpleMustacheRendererError: Error, Equatable {
        case unterminatedTag(String)
        case missingValue(String)
    }
}
