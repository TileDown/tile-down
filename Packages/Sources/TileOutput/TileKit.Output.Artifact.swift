import TileCore

public extension TileKit.Output {
    /// A serialized output produced by an output renderer.
    ///
    /// The `contents` are the rendered bytes as text; `fileExtension` names the
    /// file suffix the composition root uses when writing the artifact (for
    /// example `json`), without a leading dot.
    struct Artifact: Equatable, Sendable {
        public var contents: String
        public var fileExtension: String

        public init(
            contents: String,
            fileExtension: String,
        ) {
            self.contents = contents
            self.fileExtension = fileExtension
        }
    }
}
