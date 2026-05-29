import TileCore

public extension TileKit.Output {
    /// Projects a parsed document into a serialized output format.
    ///
    /// The Strategy of the output seam: each renderer owns one `formatID` (for
    /// example `json`) and produces an ``TileKit/Output/Artifact``. Renderers are
    /// registered in an ``TileKit/Output/Registry`` and selected by id, so adding a
    /// format never edits a switch in the core pipeline.
    protocol Rendering: Sendable {
        /// The output format this renderer produces, for example `json`.
        var formatID: String { get }

        func render(
            _ document: Document,
        ) throws -> Artifact
    }
}
