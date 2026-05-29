import TileCore

public extension TileKit.Template {
    protocol Rendering {
        func render(
            template: String,
            context: Context,
        ) throws -> String
    }
}
