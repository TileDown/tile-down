import TileCore

public extension TileKit.Markdown {
    protocol Rendering: Sendable {
        func renderHTML(
            _ markdown: String,
        ) -> String
    }
}
