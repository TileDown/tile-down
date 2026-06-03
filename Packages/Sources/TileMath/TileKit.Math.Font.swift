import Foundation
import MathTypeset
import TileCore

public extension TileKit.Math {
    /// A parsed OpenType (CFF) math font, exposing the metrics the SVG emitter
    /// needs: units-per-em, glyph advances (via `cmap` + `hmtx`), and the
    /// OpenType `MATH` constants. Glyph-outline extraction (CFF) is layered on
    /// separately; this type owns measurement only, which is the contract the
    /// `MathTypeset` layout puts on the consumer.
    struct Font: Sendable {
        public let unitsPerEm: Double
        let numGlyphs: Int
        let numberOfHMetrics: Int
        let hmtxOffset: Int
        let cffOffset: Int
        let cffLength: Int
        /// The whole font file. Stored (rather than a `TrueTypeByteReader`, which
        /// is not `Sendable` across modules) so `Font` itself is `Sendable` and
        /// can be shared; a bounds-checked reader is built on demand.
        let bytes: [UInt8]
        /// Unicode scalar value to glyph id, built from the font's `cmap`.
        let cmap: [UInt32: Int]
        /// The OpenType `MATH` constants, or `nil` to fall back to heuristic
        /// metrics. Latin Modern Math carries a `MATH` table, so this is set.
        let mathConstants: TrueTypeMathTable.Constants?

        /// Layout metrics for the `MathTypeset` engine: OpenType when the font
        /// has a `MATH` table, heuristic defaults otherwise.
        var metrics: MathLayoutMetrics {
            guard let mathConstants, let unitsPerEmValue = UInt16(exactly: unitsPerEm) else {
                return .default
            }
            return .openType(constants: mathConstants, unitsPerEm: unitsPerEmValue)
        }

        /// A bounds-checked reader over the font bytes.
        var reader: TrueTypeByteReader {
            TrueTypeByteReader(table: "font", bytes: bytes)
        }

        /// The glyph id for a Unicode scalar, or `nil` if the font does not map it.
        func glyphID(
            for scalar: Unicode.Scalar,
        ) -> Int? {
            cmap[scalar.value]
        }

        /// The advance width of a glyph in font units. Glyph ids at or beyond the
        /// horizontal-metrics count reuse the last advance, per the `hmtx` format.
        func advanceWidth(
            glyphID: Int,
        ) throws -> Int {
            let index = min(max(glyphID, 0), numberOfHMetrics - 1)
            return try Int(reader.uint16(at: hmtxOffset + index * 4))
        }

        /// The advance of a run of text at a point size: the sum of per-scalar
        /// advances (no kerning, matching the layout's measurement contract),
        /// scaled from font units to points. Unmapped scalars contribute nothing.
        public func advance(
            of text: String,
            size: Double,
        ) -> Double {
            var fontUnits = 0
            for scalar in text.unicodeScalars {
                guard let glyph = glyphID(for: scalar) else {
                    continue
                }
                fontUnits += (try? advanceWidth(glyphID: glyph)) ?? 0
            }
            return Double(fontUnits) * size / unitsPerEm
        }

        /// The vendored Latin Modern Math font, parsed once and shared.
        static let latinModern: Font? = try? loadBundled()

        /// Loads and parses the font bundled with this module.
        static func loadBundled() throws -> Font {
            guard let url = Bundle.module.url(forResource: "latinmodern-math", withExtension: "otf"),
                  let data = try? Data(contentsOf: url)
            else {
                throw TileKit.Math.FontError.resourceUnavailable
            }
            return try Font(bytes: [UInt8](data))
        }
    }
}
