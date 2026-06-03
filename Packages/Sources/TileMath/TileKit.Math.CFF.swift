import MathTypeset
import TileCore

extension TileKit.Math {
    /// The parsed pieces of a CFF table needed to render glyph outlines: the
    /// per-glyph charstrings and the global and local subroutine indexes. Offsets
    /// in CFF dictionaries are relative to the start of the CFF table.
    struct CFF {
        let charStrings: CFFIndex
        let globalSubrs: CFFIndex
        let localSubrs: CFFIndex

        static func parse(
            _ reader: TrueTypeByteReader,
            cffOffset: Int,
        ) throws -> CFF {
            let headerSize = try Int(reader.uint8(at: cffOffset + 2))
            let (_, afterName) = try CFFIndex.parse(reader, at: cffOffset + headerSize)
            let (topDicts, afterTop) = try CFFIndex.parse(reader, at: afterName)
            let (_, afterStrings) = try CFFIndex.parse(reader, at: afterTop)
            let (globalSubrs, _) = try CFFIndex.parse(reader, at: afterStrings)

            guard let top = topDicts.object(0) else {
                throw TileKit.Math.FontError.missingTable("CFF Top DICT")
            }
            let topDict = try parseDict(reader, offset: top.offset, length: top.count)
            guard let charStringsOffset = topDict[17]?.first else {
                throw TileKit.Math.FontError.missingTable("CFF CharStrings")
            }
            let (charStrings, _) = try CFFIndex.parse(reader, at: cffOffset + Int(charStringsOffset))
            let localSubrs = try parseLocalSubrs(reader, cffOffset: cffOffset, topDict: topDict)
            return CFF(charStrings: charStrings, globalSubrs: globalSubrs, localSubrs: localSubrs)
        }

        /// The local subroutine index referenced by the Private DICT, or empty.
        private static func parseLocalSubrs(
            _ reader: TrueTypeByteReader,
            cffOffset: Int,
            topDict: [Int: [Double]],
        ) throws -> CFFIndex {
            guard let priv = topDict[18], priv.count >= 2 else {
                return CFFIndex(bounds: [])
            }
            let privateOffset = cffOffset + Int(priv[1])
            let privateDict = try parseDict(reader, offset: privateOffset, length: Int(priv[0]))
            guard let subrsOffset = privateDict[19]?.first else {
                return CFFIndex(bounds: [])
            }
            return try CFFIndex.parse(reader, at: privateOffset + Int(subrsOffset)).index
        }

        /// Parses a CFF DICT into operator-to-operands, where two-byte (escape)
        /// operators are keyed as `1200 + b`.
        static func parseDict(
            _ reader: TrueTypeByteReader,
            offset: Int,
            length: Int,
        ) throws -> [Int: [Double]] {
            var operands: [Double] = []
            var dict: [Int: [Double]] = [:]
            var index = offset
            let end = offset + length
            while index < end {
                let byte = try Int(reader.uint8(at: index))
                if byte <= 21 {
                    var key = byte
                    index += 1
                    if byte == 12 {
                        key = try 1200 + Int(reader.uint8(at: index))
                        index += 1
                    }
                    dict[key] = operands
                    operands = []
                } else {
                    let (value, next) = try dictOperand(reader, byte: byte, at: index)
                    if let value {
                        operands.append(value)
                    }
                    index = next
                }
            }
            return dict
        }

        /// Decodes one DICT operand starting at `index`, returning its value (if
        /// any) and the offset just past it.
        private static func dictOperand(
            _ reader: TrueTypeByteReader,
            byte: Int,
            at index: Int,
        ) throws -> (value: Double?, next: Int) {
            switch byte {
            case 28:
                try (Double(reader.int16(at: index + 1)), index + 3)
            case 29:
                try (Double(Int32(bitPattern: reader.uint32(at: index + 1))), index + 5)
            case 30:
                try parseReal(reader, at: index + 1)
            case 32 ... 246:
                (Double(byte - 139), index + 1)
            case 247 ... 250:
                try (Double((byte - 247) * 256 + Int(reader.uint8(at: index + 1)) + 108), index + 2)
            case 251 ... 254:
                try (Double(-(byte - 251) * 256 - Int(reader.uint8(at: index + 1)) - 108), index + 2)
            default:
                (nil, index + 1)
            }
        }

        /// Parses a real (operator 30) as packed BCD nibbles ending at `0xf`. The
        /// value is best-effort; offsets this reader cares about are integers.
        private static func parseReal(
            _ reader: TrueTypeByteReader,
            at offset: Int,
        ) throws -> (value: Double?, next: Int) {
            var text = ""
            var index = offset
            let nibbleText = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "E", "E-", "", "-"]
            while true {
                let byte = try Int(reader.uint8(at: index))
                index += 1
                for nibble in [byte >> 4, byte & 0xF] {
                    if nibble == 0xF {
                        return (Double(text), index)
                    }
                    if nibble < nibbleText.count {
                        text += nibbleText[nibble]
                    }
                }
            }
        }
    }
}
