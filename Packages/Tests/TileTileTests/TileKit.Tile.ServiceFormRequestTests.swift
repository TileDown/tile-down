import Testing
import TileCore
@testable import TileTile

@Suite("Service form request")
struct ServiceFormRequestTests {
    @Test("builds service form requests from tile directives")
    func buildsServiceFormRequestsFromTileDirectives() throws {
        let tile = try serviceFormTile(
            """
            :::tile service-form
            id: price-calculator
            service: calculator
            operation: positive-decimal-calculation
            mode: proxy
            submitLabel: Calculate
            :::
            """,
        )

        let request = try TileKit.Tile.ServiceFormRequest(tile: tile)

        #expect(request.id == "price-calculator")
        #expect(request.serviceID == "calculator")
        #expect(request.operationID == "positive-decimal-calculation")
        #expect(request.mode == .proxy)
        #expect(request.submitLabel == "Calculate")
    }

    @Test("reports missing required properties")
    func reportsMissingRequiredProperties() throws {
        let tile = try serviceFormTile(
            """
            :::tile service-form
            id: price-calculator
            operation: positive-decimal-calculation
            mode: proxy
            :::
            """,
        )

        #expect(throws: TileKit.Tile.ServiceFormRequestError.missingProperty("service")) {
            try TileKit.Tile.ServiceFormRequest(tile: tile)
        }
    }

    @Test("reports unsupported modes")
    func reportsUnsupportedModes() throws {
        let tile = try serviceFormTile(
            """
            :::tile service-form
            id: price-calculator
            service: calculator
            operation: positive-decimal-calculation
            mode: server
            :::
            """,
        )

        #expect(throws: TileKit.Tile.ServiceFormRequestError.unsupportedMode("server")) {
            try TileKit.Tile.ServiceFormRequest(tile: tile)
        }
    }

    @Test("reports list values where scalar values are required")
    func reportsListValuesWhereScalarValuesAreRequired() throws {
        let tile = try serviceFormTile(
            """
            :::tile service-form
            id:
              - price-calculator
            service: calculator
            operation: positive-decimal-calculation
            mode: proxy
            :::
            """,
        )

        #expect(throws: TileKit.Tile.ServiceFormRequestError.invalidPropertyType("id")) {
            try TileKit.Tile.ServiceFormRequest(tile: tile)
        }
    }

    private func serviceFormTile(
        _ source: String,
    ) throws -> TileKit.Tile.Instance {
        let blocks = try TileKit.Tile.DirectiveParser().parseBlocks(source)

        guard case let .tile(tile) = blocks.first else {
            Issue.record("Expected a service form tile")
            throw TileKit.Tile.ServiceFormRequestError.invalidTileType(actual: "missing")
        }

        return tile
    }
}
