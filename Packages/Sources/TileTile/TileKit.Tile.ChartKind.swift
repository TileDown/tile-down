import Foundation
import TileCore

enum ChartKind: String {
    case bar
    case line
    case pie
    case doughnut
    case scatter

    init(
        raw: String,
    ) throws {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let kind = Self(rawValue: normalized) else {
            throw TileKit.Tile.ChartRendererError.unsupportedType(raw)
        }
        self = kind
    }
}
