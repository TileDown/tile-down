import TileCore

public extension TileKit.Output {
    /// A serialized output produced by an output renderer.
    ///
    /// The `contents` are the rendered bytes as text; `fileExtension` names the
    /// file suffix the composition root uses when writing the artifact (for
    /// example `json`), without a leading dot; `assets` carries any page-local CSS
    /// and JavaScript the renderer collected (empty for renderers that have none).
    struct Artifact: Equatable, Sendable {
        public var contents: String
        public var fileExtension: String
        public var assets: Assets

        public init(
            contents: String,
            fileExtension: String,
            assets: Assets = .init(),
        ) {
            self.contents = contents
            self.fileExtension = fileExtension
            self.assets = assets
        }
    }
}
