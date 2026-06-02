import Foundation
import TileCore

struct ChartData: Equatable {
    var kind: ChartKind
    var title: String?
    var labels: [String]
    var series: [ChartSeries]
    var height: Int
    var showsLegend: Bool

    init(
        _ tile: TileKit.Tile.Instance,
    ) throws {
        kind = try ChartKind(raw: Self.requiredString(named: "type", from: tile))
        title = Self.optionalString(named: "title", from: tile)
        labels = try Self.requiredLabels(from: tile)
        series = try Self.series(from: tile)
        height = try Self.height(tile.property(named: "height"))
        showsLegend = try Self.bool(tile.property(named: "legend")) ?? true

        try validate()
    }

    private func validate() throws {
        guard !series.isEmpty else {
            throw TileKit.Tile.ChartRendererError.missingSeries
        }

        for item in series where item.values.count != labels.count {
            throw TileKit.Tile.ChartRendererError.mismatchedSeriesLength(
                series: item.name,
                expected: labels.count,
                actual: item.values.count,
            )
        }

        guard kind == .pie || kind == .doughnut else {
            return
        }
        guard series.count == 1 else {
            throw TileKit.Tile.ChartRendererError.unsupportedSeriesCount(
                type: kind.rawValue,
                expected: "exactly one",
                actual: series.count,
            )
        }

        let values = series[0].values
        for value in values where value <= 0 {
            throw TileKit.Tile.ChartRendererError.invalidPieValue(
                series: series[0].name,
                value: value,
            )
        }
        guard values.reduce(0, +) > 0 else {
            throw TileKit.Tile.ChartRendererError.zeroTotal(type: kind.rawValue)
        }
    }

    private static func requiredString(
        named key: String,
        from tile: TileKit.Tile.Instance,
    ) throws -> String {
        guard let value = optionalString(named: key, from: tile) else {
            throw TileKit.Tile.ChartRendererError.missingProperty(key)
        }
        return value
    }

    private static func optionalString(
        named key: String,
        from tile: TileKit.Tile.Instance,
    ) -> String? {
        guard case let .string(value) = tile.property(named: key) else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func requiredLabels(
        from tile: TileKit.Tile.Instance,
    ) throws -> [String] {
        guard let value = tile.property(named: "labels") else {
            throw TileKit.Tile.ChartRendererError.missingProperty("labels")
        }
        let labels = parseList(value)
        guard !labels.isEmpty else {
            throw TileKit.Tile.ChartRendererError.missingProperty("labels")
        }
        return labels
    }

    private static func series(
        from tile: TileKit.Tile.Instance,
    ) throws -> [ChartSeries] {
        try tile.properties.compactMap { property in
            guard property.key.hasPrefix("series.") else {
                return nil
            }

            let name = property.key.dropFirst("series.".count)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                throw TileKit.Tile.ChartRendererError.emptySeriesName(property.key)
            }

            return try ChartSeries(
                name: name,
                values: numbers(property.value, key: property.key),
            )
        }
    }

    private static func height(
        _ value: TileKit.Tile.Value?,
    ) throws -> Int {
        guard case let .string(raw) = value else {
            return 360
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let height = Int(trimmed), (240 ... 720).contains(height) else {
            throw TileKit.Tile.ChartRendererError.invalidHeight(raw)
        }
        return height
    }

    private static func bool(
        _ value: TileKit.Tile.Value?,
    ) throws -> Bool? {
        guard case let .string(raw) = value else {
            return nil
        }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "true", "yes", "on", "1":
            return true
        case "false", "no", "off", "0":
            return false
        default:
            throw TileKit.Tile.ChartRendererError.invalidBoolean(
                property: "legend",
                value: raw,
            )
        }
    }

    private static func numbers(
        _ value: TileKit.Tile.Value,
        key: String,
    ) throws -> [Double] {
        try parseList(value).map { item in
            guard let number = Double(item), number.isFinite else {
                throw TileKit.Tile.ChartRendererError.invalidNumber(
                    property: key,
                    value: item,
                )
            }
            return number
        }
    }

    private static func parseList(
        _ value: TileKit.Tile.Value,
    ) -> [String] {
        let values: [String] = switch value {
        case let .string(raw):
            raw.split(separator: ",", omittingEmptySubsequences: false)
                .map(String.init)
        case let .list(items):
            items
        }

        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
