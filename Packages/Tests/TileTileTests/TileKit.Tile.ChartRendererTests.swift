import Testing
import TileCore
@testable import TileTile

@Suite("Chart tile renderer")
struct ChartRendererTests {
    @Test("chart tile renders escaped SVG with an interactive hover runtime")
    func chartRendersInteractiveSVG() throws {
        let rendered = try TileKit.Tile.ChartRenderer().render(chartTile(type: "bar"))

        // The chart tile is the interactive form (the static, zero-JavaScript
        // form is the ` ```chart ` Markdown fence, covered separately).
        #expect(rendered.html.contains(#"<figure class="td-chart td-chart-bar" data-td-chart-interactive>"#))
        #expect(rendered.html.contains(#"class="td-chart-svg""#))
        #expect(rendered.html.contains("Releases &lt;monthly&gt;"))
        #expect(rendered.html.contains("Downloads"))
        #expect(rendered.html.contains("<title>"))
        #expect(rendered.css.contains(".td-chart-frame"))
        #expect(rendered.css.contains(".td-chart-tip"))
        #expect(rendered.javascript.contains("data-td-chart-interactive"))
    }

    @Test("chart renders line pie doughnut and scatter variants")
    func chartRendersSupportedVariants() throws {
        for type in ["line", "scatter", "pie", "doughnut"] {
            let rendered = try TileKit.Tile.ChartRenderer().render(
                chartTile(
                    type: type,
                    singleSeries: type == "pie" || type == "doughnut",
                ),
            )
            #expect(rendered.html.contains("td-chart-\(type)"))
            #expect(rendered.html.contains("td-chart-svg"))
            #expect(!rendered.javascript.isEmpty)
        }
    }

    @Test("chart hides radial legend when disabled")
    func chartHidesRadialLegend() throws {
        let rendered = try TileKit.Tile.ChartRenderer().render(
            chartTile(
                type: "pie",
                singleSeries: true,
                extraProperties: [
                    .init(key: "legend", value: .string("false")),
                ],
            ),
        )

        #expect(!rendered.html.contains("td-chart-legend-text"))
        #expect(!rendered.html.contains(">Jan<"))
    }

    @Test("chart rejects wrong type and missing labels")
    func chartRejectsWrongTypeAndMissingLabels() {
        #expect(throws: TileKit.Tile.ChartRendererError.invalidTileType(actual: "counter")) {
            try TileKit.Tile.ChartRenderer().render(.init(typeID: "counter", properties: []))
        }
        #expect(throws: TileKit.Tile.ChartRendererError.missingProperty("labels")) {
            try TileKit.Tile.ChartRenderer().render(
                .init(
                    typeID: "chart",
                    properties: [
                        .init(key: "type", value: .string("bar")),
                        .init(key: "series.Downloads", value: .string("1, 2")),
                    ],
                ),
            )
        }
    }

    @Test("chart rejects malformed values")
    func chartRejectsMalformedValues() {
        #expect(
            throws: TileKit.Tile.ChartRendererError.invalidNumber(
                property: "series.Downloads",
                value: "many",
            ),
        ) {
            try TileKit.Tile.ChartRenderer().render(
                chartTile(
                    type: "bar",
                    seriesValue: "1, many",
                ),
            )
        }
        #expect(
            throws: TileKit.Tile.ChartRendererError.mismatchedSeriesLength(
                series: "Downloads",
                expected: 2,
                actual: 1,
            ),
        ) {
            try TileKit.Tile.ChartRenderer().render(
                chartTile(
                    type: "bar",
                    seriesValue: "1",
                ),
            )
        }
    }

    @Test("chart rejects invalid legend values")
    func chartRejectsInvalidLegendValues() {
        #expect(
            throws: TileKit.Tile.ChartRendererError.invalidBoolean(
                property: "legend",
                value: "maybe",
            ),
        ) {
            try TileKit.Tile.ChartRenderer().render(
                chartTile(
                    type: "bar",
                    extraProperties: [
                        .init(key: "legend", value: .string("maybe")),
                    ],
                ),
            )
        }
    }

    private func chartTile(
        type: String,
        singleSeries: Bool = false,
        seriesValue: String = "12, 19",
        extraProperties: [TileKit.Tile.Property] = [],
    ) -> TileKit.Tile.Instance {
        var properties: [TileKit.Tile.Property] = [
            .init(key: "type", value: .string(type)),
            .init(key: "title", value: .string("Releases <monthly>")),
            .init(key: "labels", value: .string("Jan, Feb")),
            .init(key: "series.Downloads", value: .string(seriesValue)),
        ]
        if !singleSeries {
            properties.append(.init(key: "series.Stars", value: .string("3, 8")))
        }
        properties.append(contentsOf: extraProperties)
        return .init(typeID: "chart", properties: properties)
    }
}
