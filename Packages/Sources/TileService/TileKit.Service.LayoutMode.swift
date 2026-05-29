import TileCore

public extension TileKit.Service {
    /// A layout mode supported by manifest-driven integrations.
    enum LayoutMode: String, CaseIterable, Codable, Equatable, Sendable {
        case inline
        case block
        case fullWidth = "full-width"
        case responsive
    }
}
