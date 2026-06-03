import MathTypeset
import TileCore

extension TileKit.Math {
    /// A CFF `INDEX`: a count-prefixed array of variable-length objects. Stores
    /// the absolute font offset of each object boundary, so an object's bytes are
    /// `bytes[bounds[i] ..< bounds[i + 1]]`.
    struct CFFIndex {
        let bounds: [Int]

        var count: Int {
            max(bounds.count - 1, 0)
        }

        /// The absolute offset and length of object `i`, or `nil` if out of range.
        func object(_ index: Int) -> (offset: Int, count: Int)? {
            guard index >= 0, index + 1 < bounds.count else {
                return nil
            }
            return (bounds[index], bounds[index + 1] - bounds[index])
        }

        /// Parses an `INDEX` at `offset`, returning it and the offset just past it.
        static func parse(
            _ reader: TrueTypeByteReader,
            at offset: Int,
        ) throws -> (index: CFFIndex, end: Int) {
            let count = try Int(reader.uint16(at: offset))
            guard count > 0 else {
                return (CFFIndex(bounds: []), offset + 2)
            }
            let offSize = try Int(reader.uint8(at: offset + 2))
            let offsetArray = offset + 3
            // Object offsets are 1-based from the byte before the data region.
            let dataBase = offsetArray + (count + 1) * offSize - 1
            var bounds: [Int] = []
            bounds.reserveCapacity(count + 1)
            for entry in 0 ... count {
                var value = 0
                for byte in 0 ..< offSize {
                    value = try value << 8 | Int(reader.uint8(at: offsetArray + entry * offSize + byte))
                }
                bounds.append(dataBase + value)
            }
            return (CFFIndex(bounds: bounds), bounds[count])
        }
    }
}
