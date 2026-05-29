import Testing
import TileCore
import TileService
@testable import TileServiceForm
import TileTile

@Suite("Service form tile renderer")
struct ServiceFormTileRendererTests {
    @Test("renders a service-form tile instance through the registry seam")
    func rendersServiceFormTileInstance() throws {
        let rendered = try makeRenderer().render(serviceFormTile())

        #expect(rendered.html.contains(#"data-td-tile-id="price-calculator""#))
        #expect(rendered.css.contains(".td-service-form"))
        #expect(rendered.javascript.contains("fetch(config.endpoint"))
    }

    @Test("propagates a missing service as a typed resolution error")
    func propagatesMissingService() throws {
        let renderer = TileKit.ServiceForm.TileRenderer(
            resolver: TileKit.Service.InMemoryContractResolver(),
        )

        #expect(
            throws: TileKit.Service.ContractResolutionError.missingService(
                serviceID: "calculator",
            ),
        ) {
            try renderer.render(serviceFormTile())
        }
    }

    @Test("propagates a missing operation as a typed binding error")
    func propagatesMissingOperation() throws {
        let renderer = makeRenderer(operationID: "different-operation")

        #expect(
            throws: TileKit.ServiceForm.BindingError.missingOperation(
                operationID: "positive-decimal-calculation",
                serviceID: "calculator",
            ),
        ) {
            try renderer.render(serviceFormTile())
        }
    }

    @Test("propagates unsafe credential exposure as a typed binding error")
    func propagatesUnsafeCredentialExposure() throws {
        let renderer = makeRenderer(
            modes: [.remote],
            exposure: .server,
        )

        #expect(
            throws: TileKit.ServiceForm.BindingError.unsafeCredentialExposure(
                mode: "remote",
                exposure: "server",
                operationID: "positive-decimal-calculation",
            ),
        ) {
            try renderer.render(serviceFormTile(mode: "remote"))
        }
    }

    @Test("rejects a tile of the wrong type")
    func rejectsWrongTileType() throws {
        #expect(
            throws: TileKit.Tile.ServiceFormRequestError.invalidTileType(actual: "poll"),
        ) {
            try makeRenderer().render(
                .init(
                    typeID: "poll",
                    properties: [],
                ),
            )
        }
    }

    private func makeRenderer(
        operationID: String = "positive-decimal-calculation",
        modes: [TileKit.Service.Mode] = [.proxy],
        exposure: TileKit.Service.CredentialExposure = .server,
    ) -> TileKit.ServiceForm.TileRenderer {
        .init(
            resolver: TileKit.Service.InMemoryContractResolver(
                contracts: [
                    "calculator": calculatorContract(
                        operationID: operationID,
                        modes: modes,
                        exposure: exposure,
                    ),
                ],
            ),
        )
    }

    private func serviceFormTile(
        mode: String = "proxy",
    ) -> TileKit.Tile.Instance {
        .init(
            typeID: "service-form",
            properties: [
                .init(key: "id", value: .string("price-calculator")),
                .init(key: "service", value: .string("calculator")),
                .init(key: "operation", value: .string("positive-decimal-calculation")),
                .init(key: "mode", value: .string(mode)),
                .init(key: "submitLabel", value: .string("Calculate")),
            ],
        )
    }

    private func calculatorContract(
        operationID: String,
        modes: [TileKit.Service.Mode],
        exposure: TileKit.Service.CredentialExposure,
    ) -> TileKit.Service.Contract {
        .init(
            id: "calculator",
            name: "Calculator",
            version: "1.0.0",
            requirements: .init(
                credentials: [
                    .init(
                        id: "calculator-api",
                        type: .bearer,
                        exposure: .server,
                    ),
                ],
            ),
            operations: [
                calculatorOperation(
                    operationID: operationID,
                    modes: modes,
                    exposure: exposure,
                ),
            ],
        )
    }

    private func calculatorOperation(
        operationID: String,
        modes: [TileKit.Service.Mode],
        exposure: TileKit.Service.CredentialExposure,
    ) -> TileKit.Service.Operation {
        .init(
            id: operationID,
            modes: modes,
            transport: .init(
                method: .post,
                path: "/calculate",
            ),
            inputSchema: .init(
                type: .object,
                properties: [
                    "first": .init(type: .string, semanticType: .positiveDecimal),
                ],
                required: [
                    "first",
                ],
            ),
            inputUI: [
                "first": .init(label: "First value", order: 1),
            ],
            outputSchema: .init(
                type: .object,
                properties: [
                    "result": .init(type: .string, semanticType: .decimal),
                ],
                required: [
                    "result",
                ],
            ),
            outputUI: [
                "result": .init(label: "Result", format: "decimal"),
            ],
            auth: .init(
                credentialID: "calculator-api",
                exposure: exposure,
            ),
        )
    }
}
