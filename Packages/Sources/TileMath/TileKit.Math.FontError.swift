import TileCore

public extension TileKit.Math {
    /// A failure parsing the vendored OpenType math font.
    enum FontError: Error, Equatable, Sendable {
        /// A required sfnt table was absent from the font directory.
        case missingTable(String)
        /// No Unicode `cmap` subtable in a format this reader understands.
        case noUsableCmap
        /// The bundled font resource could not be located or read.
        case resourceUnavailable
    }
}
