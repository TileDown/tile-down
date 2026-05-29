import TileCore

public extension TileKit.Markdown {
    protocol Rendering {
        func renderHTML(
            _ markdown: String,
        ) -> String
    }
}
