import MathTypeset
import TileCore

extension TileKit.Math {
    /// Interprets a CFF Type2 charstring into a glyph outline. Type2 is a
    /// stack-based language of relative move/line/curve operators with calls into
    /// global and local subroutines; this evaluates one glyph's program (following
    /// subroutine calls) into absolute cubic-curve path elements in font units.
    final class Type2Interpreter {
        let reader: TrueTypeByteReader
        let cff: CFF
        let globalBias: Int
        let localBias: Int

        var stack: [Double] = []
        var penX = 0.0
        var penY = 0.0
        var stemCount = 0
        var haveWidth = false
        var isOpen = false
        var finished = false
        var elements: [TileKit.Math.PathElement] = []

        init(
            reader: TrueTypeByteReader,
            cff: CFF,
        ) {
            self.reader = reader
            self.cff = cff
            globalBias = Self.bias(cff.globalSubrs.count)
            localBias = Self.bias(cff.localSubrs.count)
        }

        /// The outline for a glyph id, or `nil` if the glyph is out of range.
        func outline(
            forGlyph glyph: Int,
        ) throws -> TileKit.Math.GlyphOutline? {
            guard let object = cff.charStrings.object(glyph) else {
                return nil
            }
            try run(reader.bytes(at: object.offset, count: object.count))
            closeContour()
            return TileKit.Math.GlyphOutline(elements: elements)
        }

        private static func bias(
            _ count: Int,
        ) -> Int {
            count < 1240 ? 107 : (count < 33900 ? 1131 : 32768)
        }

        func run(
            _ bytes: [UInt8],
        ) throws {
            var index = 0
            while index < bytes.count, !finished {
                let byte = Int(bytes[index])
                if byte >= 32 || byte == 28 {
                    index = readOperand(bytes, byte: byte, at: index)
                } else if byte == 11 {
                    return
                } else {
                    index = try execute(bytes, operator: byte, at: index)
                }
            }
        }

        private func readOperand(
            _ bytes: [UInt8],
            byte: Int,
            at index: Int,
        ) -> Int {
            switch byte {
            case 28:
                stack.append(Double(Int16(bitPattern: UInt16(bytes[index + 1]) << 8 | UInt16(bytes[index + 2]))))
                return index + 3
            case 255:
                let raw = UInt32(bytes[index + 1]) << 24 | UInt32(bytes[index + 2]) << 16
                    | UInt32(bytes[index + 3]) << 8 | UInt32(bytes[index + 4])
                stack.append(Double(Int32(bitPattern: raw)) / 65536)
                return index + 5
            case 247 ... 250:
                stack.append(Double((byte - 247) * 256 + Int(bytes[index + 1]) + 108))
                return index + 2
            case 251 ... 254:
                stack.append(Double(-(byte - 251) * 256 - Int(bytes[index + 1]) - 108))
                return index + 2
            default:
                stack.append(Double(byte - 139))
                return index + 1
            }
        }
    }
}
