import MathTypeset
import TileCore

extension TileKit.Math.Font {
    /// Builds the Unicode-scalar-to-glyph map from the font's `cmap`. Prefers a
    /// segmented format 12 subtable (covers astral planes), falling back to a
    /// format 4 BMP subtable.
    static func parseCmap(
        _ reader: TrueTypeByteReader,
        at cmapOffset: Int,
    ) throws -> [UInt32: Int] {
        let count = try Int(reader.uint16(at: cmapOffset + 2))
        var format4: Int?
        var format12: Int?
        for index in 0 ..< count {
            let record = cmapOffset + 4 + index * 8
            let platform = try reader.uint16(at: record)
            let encoding = try reader.uint16(at: record + 2)
            guard isUnicode(platform: platform, encoding: encoding) else {
                continue
            }
            let subtable = try cmapOffset + Int(reader.uint32(at: record + 4))
            switch try reader.uint16(at: subtable) {
            case 12 where format12 == nil:
                format12 = subtable
            case 4 where format4 == nil:
                format4 = subtable
            default:
                break
            }
        }
        if let format12 {
            return try cmapFormat12(reader, at: format12)
        }
        if let format4 {
            return try cmapFormat4(reader, at: format4)
        }
        throw TileKit.Math.FontError.noUsableCmap
    }

    /// Whether a `cmap` subtable's platform/encoding pair addresses Unicode.
    private static func isUnicode(
        platform: UInt16,
        encoding: UInt16,
    ) -> Bool {
        platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10))
    }

    /// Parses a format 12 (segmented coverage) subtable.
    private static func cmapFormat12(
        _ reader: TrueTypeByteReader,
        at offset: Int,
    ) throws -> [UInt32: Int] {
        let groups = try Int(reader.uint32(at: offset + 12))
        var map: [UInt32: Int] = [:]
        for index in 0 ..< groups {
            let base = offset + 16 + index * 12
            let start = try reader.uint32(at: base)
            let end = try reader.uint32(at: base + 4)
            let startGlyph = try Int(reader.uint32(at: base + 8))
            guard end >= start, end - start < 0x10000 else {
                continue
            }
            for scalar in start ... end {
                map[scalar] = startGlyph + Int(scalar - start)
            }
        }
        return map
    }

    /// Parses a format 4 (segment mapping to delta values) BMP subtable.
    private static func cmapFormat4(
        _ reader: TrueTypeByteReader,
        at offset: Int,
    ) throws -> [UInt32: Int] {
        let segX2 = try Int(reader.uint16(at: offset + 6))
        let endBase = offset + 14
        let startBase = endBase + segX2 + 2
        let deltaBase = startBase + segX2
        let rangeBase = deltaBase + segX2
        var map: [UInt32: Int] = [:]
        for segment in stride(from: 0, to: segX2, by: 2) {
            let end = try Int(reader.uint16(at: endBase + segment))
            let start = try Int(reader.uint16(at: startBase + segment))
            let delta = try Int(reader.int16(at: deltaBase + segment))
            let rangeOffset = try Int(reader.uint16(at: rangeBase + segment))
            guard start <= end else { continue }
            // 0 means "map through idDelta"; otherwise it's the absolute address
            // of this segment's slot in the glyph-index array.
            let glyphArrayBase = rangeOffset == 0 ? nil : rangeBase + segment + rangeOffset
            for code in start ... end where code != 0xFFFF {
                let glyph = try cmapFormat4Glyph(
                    reader, code: code, start: start, delta: delta, glyphArrayBase: glyphArrayBase,
                )
                if glyph != 0 {
                    map[UInt32(code)] = glyph
                }
            }
        }
        return map
    }

    /// Resolves one character's glyph id within a format 4 segment.
    /// `glyphArrayBase` is `nil` when the segment maps directly through `delta`.
    private static func cmapFormat4Glyph(
        _ reader: TrueTypeByteReader,
        code: Int,
        start: Int,
        delta: Int,
        glyphArrayBase: Int?,
    ) throws -> Int {
        guard let glyphArrayBase else {
            return (code + delta) & 0xFFFF
        }
        let glyph = try Int(reader.uint16(at: glyphArrayBase + 2 * (code - start)))
        return glyph == 0 ? 0 : (glyph + delta) & 0xFFFF
    }
}
