import TileCore

public extension TileKit.Tile {
    /// Renders a typed tile instance into static site output fragments.
    protocol Rendering: Sendable {
        func render(
            _ tile: Instance,
        ) throws -> Rendered
    }
}
