public extension TileKit.Template {
    protocol Rendering {
        func render(
            template: String,
            context: [String: String],
        ) throws -> String
    }
}
