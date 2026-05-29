import TileCore

public extension TileKit.Template {
    enum SimpleMustacheRendererError: Error, Equatable {
        case unterminatedTag(String)
        case unexpectedClosingTag(String)
        case missingValue(String)
        case missingSectionEnd(String)
    }
}
