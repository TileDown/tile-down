import Foundation
import MathTypeset
import TileCore

extension TileKit.Math.Font {
    /// Parses an OpenType font's sfnt directory and the tables the emitter needs.
    /// All offsets are absolute into `bytes`, read through one bounds-checked
    /// `TrueTypeByteReader`; CFF semantics are layered on separately.
    init(
        bytes: [UInt8],
    ) throws {
        let reader = TrueTypeByteReader(table: "sfnt", bytes: bytes)
        let tables = try Self.tableDirectory(reader)
        func require(_ tag: String) throws -> (offset: Int, length: Int) {
            guard let entry = tables[tag] else {
                throw TileKit.Math.FontError.missingTable(tag)
            }
            return entry
        }

        let head = try require("head")
        let maxp = try require("maxp")
        let hhea = try require("hhea")
        let hmtx = try require("hmtx")
        let cmap = try require("cmap")
        let cff = try require("CFF ")
        let glyphCount = try Int(reader.uint16(at: maxp.offset + 4))

        unitsPerEm = try Double(reader.uint16(at: head.offset + 18))
        numGlyphs = glyphCount
        numberOfHMetrics = try Int(reader.uint16(at: hhea.offset + 34))
        hmtxOffset = hmtx.offset
        cffOffset = cff.offset
        cffLength = cff.length
        self.cmap = try Self.parseCmap(reader, at: cmap.offset)
        mathConstants = Self.mathConstants(bytes: bytes, table: tables["MATH"], numGlyphs: glyphCount)
        cffTable = try TileKit.Math.CFF.parse(reader, cffOffset: cff.offset)
        self.bytes = bytes
    }

    /// The OpenType `MATH` constants, or `nil` if the font has no `MATH` table
    /// or it fails to parse (the caller falls back to heuristic metrics).
    private static func mathConstants(
        bytes: [UInt8],
        table: (offset: Int, length: Int)?,
        numGlyphs: Int,
    ) -> TrueTypeMathTable.Constants? {
        guard let table,
              table.offset + table.length <= bytes.count,
              let glyphCount = UInt16(exactly: numGlyphs)
        else {
            return nil
        }
        let slice = Array(bytes[table.offset ..< table.offset + table.length])
        return try? TrueTypeMathTableParser(bytes: slice, numGlyphs: glyphCount).parse().constants
    }

    /// The sfnt table directory: tag to (offset, length).
    private static func tableDirectory(
        _ reader: TrueTypeByteReader,
    ) throws -> [String: (offset: Int, length: Int)] {
        let count = try Int(reader.uint16(at: 4))
        var tables: [String: (offset: Int, length: Int)] = [:]
        for index in 0 ..< count {
            let base = 12 + index * 16
            let tag = try reader.tag(at: base)
            let offset = try Int(reader.uint32(at: base + 8))
            let length = try Int(reader.uint32(at: base + 12))
            tables[tag] = (offset, length)
        }
        return tables
    }
}
