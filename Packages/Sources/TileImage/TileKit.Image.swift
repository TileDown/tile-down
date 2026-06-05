import TileCore

public extension TileKit {
    enum Image {}
}

public extension TileKit.Image {
    /// Build-time image conversion used for PDF assets. Implementations are
    /// platform-native and must not introduce package dependencies.
    struct PDFAssetConverter: Sendable {
        public init() {}
    }
}
