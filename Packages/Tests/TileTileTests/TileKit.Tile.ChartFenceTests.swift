import Testing
import TileCore
@testable import TileTile

@Suite("Chart fence parser")
struct ChartFenceTests {
    @Test("bar chart with categories and multiple value series")
    func barWithCategoriesAndSeries() throws {
        let chart = try ChartFence.parse(
            """
            type: bar
            title: Quarterly Revenue
            categories: Q1, Q2, Q3, Q4
            y-label: USD
            series: Actual = 3, 5, 4, 7
            series: Forecast = 4, 6, 5, 8
            """,
        )

        #expect(chart.kind == .bar)
        #expect(chart.title == "Quarterly Revenue")
        #expect(chart.yLabel == "USD")
        #expect(chart.labels == ["Q1", "Q2", "Q3", "Q4"])
        #expect(chart.series == [
            ChartSeries(name: "Actual", values: [3, 5, 4, 7]),
            ChartSeries(name: "Forecast", values: [4, 6, 5, 8]),
        ])
    }

    @Test("line chart keeps category labels and axis captions")
    func lineWithCategories() throws {
        let chart = try ChartFence.parse(
            """
            type: line
            title: Adoption Trend
            categories: Jan, Feb, Mar, Apr
            x-label: month
            y-label: users
            series: Accounts = 2, 4, 7, 9
            """,
        )

        #expect(chart.kind == .line)
        #expect(chart.xLabel == "month")
        #expect(chart.yLabel == "users")
        #expect(chart.labels == ["Jan", "Feb", "Mar", "Apr"])
        #expect(chart.series == [ChartSeries(name: "Accounts", values: [2, 4, 7, 9])])
    }

    @Test("bar chart without categories auto-numbers labels")
    func barAutoNumbersLabels() throws {
        let chart = try ChartFence.parse(
            """
            type: bar
            series: Counts = 10, 20, 30
            """,
        )

        #expect(chart.labels == ["1", "2", "3"])
    }

    @Test("pie chart from slice entries")
    func pieFromSlices() throws {
        let chart = try ChartFence.parse(
            """
            type: pie
            title: Deployment Share
            slice: Stable = 68
            slice: Canary = 22
            slice: Experimental = 10
            """,
        )

        #expect(chart.kind == .pie)
        #expect(chart.labels == ["Stable", "Canary", "Experimental"])
        #expect(chart.series == [ChartSeries(name: "Slices", values: [68, 22, 10])])
    }

    @Test("pie chart from a single value series plus categories")
    func pieFromValueSeries() throws {
        let chart = try ChartFence.parse(
            """
            type: pie
            categories: Pass, Fail
            series: Results = 5, 1
            """,
        )

        #expect(chart.labels == ["Pass", "Fail"])
        #expect(chart.series == [ChartSeries(name: "Slices", values: [5, 1])])
    }

    @Test("scatter chart parses (x, y) point pairs")
    func scatterPoints() throws {
        let chart = try ChartFence.parse(
            """
            type: scatter
            title: Impact Map
            x-label: effort
            y-label: impact
            series: Trials = (1, 2), (2, 4), (4, 7), (5, 9)
            """,
        )

        #expect(chart.kind == .scatter)
        #expect(chart.labels.isEmpty)
        #expect(chart.series.count == 1)
        #expect(chart.series[0].points == [
            ChartPoint(xPosition: 1, yPosition: 2),
            ChartPoint(xPosition: 2, yPosition: 4),
            ChartPoint(xPosition: 4, yPosition: 7),
            ChartPoint(xPosition: 5, yPosition: 9),
        ])
        #expect(chart.series[0].values == [2, 4, 7, 9])
    }

    @Test("quoted labels and comment lines are handled")
    func quotedLabelsAndComments() throws {
        let chart = try ChartFence.parse(
            """
            # deployment mix
            type: pie
            slice: "Pass, partial" = 3
            slice: 'Fail' = 1
            """,
        )

        #expect(chart.labels == ["Pass, partial", "Fail"])
    }

    @Test("missing type is rejected")
    func missingTypeRejected() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse("series: A = 1, 2, 3")
        }
    }

    @Test("unknown key is rejected")
    func unknownKeyRejected() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: bar
                colour: blue
                series: A = 1, 2
                """,
            )
        }
    }

    @Test("non-numeric series value is rejected")
    func nonNumericValueRejected() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: bar
                series: A = 1, two, 3
                """,
            )
        }
    }

    @Test("mismatched category count is rejected")
    func mismatchedCategoryCount() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: bar
                categories: A, B
                series: S = 1, 2, 3
                """,
            )
        }
    }

    @Test("bar chart rejects numeric x values")
    func barRejectsNumericX() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: bar
                x: 1, 2, 3
                series: S = 1, 2, 3
                """,
            )
        }
    }

    @Test("scatter rejects categories")
    func scatterRejectsCategories() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: scatter
                categories: A, B
                series: S = (1, 2), (3, 4)
                """,
            )
        }
    }

    @Test("too many series is rejected")
    func tooManySeriesRejected() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: line
                categories: A, B
                series: S1 = 1, 2
                series: S2 = 1, 2
                series: S3 = 1, 2
                series: S4 = 1, 2
                series: S5 = 1, 2
                """,
            )
        }
    }

    @Test("pie chart rejects non-positive slice values")
    func pieRejectsNonPositive() {
        #expect(throws: TileKit.Tile.ChartRendererError.self) {
            try ChartFence.parse(
                """
                type: pie
                slice: A = 0
                slice: B = 5
                """,
            )
        }
    }
}

@Suite("Chart fence rendering")
struct ChartFenceRenderingTests {
    @Test("scatter fence renders circles, a numeric x axis, and axis captions")
    func scatterRendersTrueXY() throws {
        let chart = try ChartFence.parse(
            """
            type: scatter
            title: Impact
            x-label: effort
            y-label: impact
            series: Trials = (1, 2), (5, 9)
            """,
        )
        let svg = ChartSVGRenderer().render(chart)

        #expect(svg.contains("td-chart-scatter"))
        #expect(svg.contains("td-chart-point"))
        // True numeric x axis tick (5), not a category index.
        #expect(svg.contains(">5</text>"))
        #expect(svg.contains(">effort</text>"))
        #expect(svg.contains(">impact</text>"))
        #expect(!svg.contains("<script"))
    }

    @Test("legend labels are packed by width without overlapping")
    func legendPacksWithoutOverlap() {
        let renderer = ChartSVGRenderer()
        let labels = ["Configuring the new generator", "Arguing about it online", "Actually writing posts"]
        let placements = renderer.legendPlacements(labels)

        #expect(placements.count == 3)
        // Entries sharing a row advance strictly left to right (no overlap) and
        // start within the plot, unlike the old fixed-width columns.
        for row in 0 ... (placements.map(\.row).max() ?? 0) {
            let inRow = placements.filter { $0.row == row }
            #expect(zip(inRow, inRow.dropFirst()).allSatisfy { $0.xPosition < $1.xPosition })
            #expect(inRow.allSatisfy { $0.xPosition >= renderer.left })
        }
    }

    @Test("an overfull legend wraps to multiple rows")
    func legendWrapsWhenOverfull() {
        let labels = (1 ... 8).map { "Quite a long legend label number \($0)" }
        let placements = ChartSVGRenderer().legendPlacements(labels)
        #expect((placements.map(\.row).max() ?? 0) >= 1)
    }

    @Test("short legend labels stay on one row")
    func legendKeepsShortLabelsOnOneRow() {
        let placements = ChartSVGRenderer().legendPlacements(["A", "B", "C"])
        #expect(placements.allSatisfy { $0.row == 0 })
    }

    @Test("bar fence renders axis captions when provided")
    func barRendersAxisCaptions() throws {
        let chart = try ChartFence.parse(
            """
            type: bar
            categories: A, B
            x-label: group
            y-label: count
            series: S = 1, 2
            """,
        )
        let svg = ChartSVGRenderer().render(chart)

        #expect(svg.contains(">group</text>"))
        #expect(svg.contains(">count</text>"))
    }
}
