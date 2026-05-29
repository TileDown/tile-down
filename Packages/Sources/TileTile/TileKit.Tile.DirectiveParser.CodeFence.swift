import Foundation
import TileCore

extension TileKit.Tile.DirectiveParser {
    /// Returns the marker and length if the line opens a CommonMark fenced code
    /// block (three or more backticks or tildes); otherwise `nil`. Lines inside
    /// such a fence are Markdown content, even when they look like tile fences.
    func openingCodeFence(
        _ line: String,
    ) -> (marker: Character, length: Int)? {
        let line = line.trimmingCharacters(in: .whitespaces)
        for marker: Character in ["`", "~"] {
            let length = line.prefix(while: { $0 == marker }).count
            if length >= 3 {
                return (marker, length)
            }
        }
        return nil
    }

    /// Whether the line closes the given open code fence: only the fence marker,
    /// at least as many as the opening run, and nothing else.
    func closesCodeFence(
        _ line: String,
        _ fence: (marker: Character, length: Int),
    ) -> Bool {
        let line = line.trimmingCharacters(in: .whitespaces)
        guard !line.isEmpty, line.allSatisfy({ $0 == fence.marker }) else {
            return false
        }
        return line.count >= fence.length
    }
}
