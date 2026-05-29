import Testing
import TileCore
import TileService
@testable import TileServiceForm
import TileTile

@Suite("Service form renderer")
struct ServiceFormRendererTests {
    @Test("renders generated service form output")
    func rendersGeneratedServiceFormOutput() throws {
        let rendered = try TileKit.ServiceForm.Renderer().render(binding())

        #expect(rendered.html.contains(#"data-td-tile-id="price-calculator""#))
        #expect(rendered.html.contains(#"data-td-service="calculator""#))
        #expect(rendered.html.contains(#"data-td-operation="positive-decimal-calculation""#))
        #expect(rendered.html.contains(#"name="first""#))
        #expect(rendered.html.contains(#"inputmode="decimal""#))
        #expect(rendered.html.contains(#"pattern="^(?=.*[1-9])"#))
        #expect(rendered.html.contains(#"data-td-output-value="result" data-td-output-format="decimal""#))
        #expect(rendered.html.contains(#""endpoint":"/_td/services/calculator/positive-decimal-calculation""#))
        #expect(rendered.html.contains(#""method":"POST""#))
        #expect(rendered.css.contains(".td-service-form"))
        #expect(rendered.javascript.contains("fetch(config.endpoint"))

        let firstRange = try #require(rendered.html.range(of: #"name="first""#))
        let secondRange = try #require(rendered.html.range(of: #"name="second""#))
        #expect(firstRange.lowerBound < secondRange.lowerBound)

        let browserOutput = [
            rendered.html,
            rendered.css,
            rendered.javascript,
        ].joined(separator: "\n")
        #expect(!browserOutput.contains("calculator-api"))
    }

    @Test("uses operation transport path for remote mode")
    func usesOperationTransportPathForRemoteMode() throws {
        let rendered = try TileKit.ServiceForm.Renderer().render(
            binding(
                mode: .remote,
                modes: [.remote],
                exposure: .browser,
            ),
        )

        #expect(rendered.html.contains(#""endpoint":"/calculate""#))
    }

    @Test("escapes generated HTML and script configuration")
    func escapesGeneratedHTMLAndScriptConfiguration() throws {
        let rendered = try TileKit.ServiceForm.Renderer().render(
            binding(
                tileID: "price</script>",
                operationID: "calculate</script>",
                submitLabel: "Run <now>",
                inputLabel: "First <value>",
            ),
        )

        #expect(rendered.html.contains("Run &lt;now&gt;"))
        #expect(rendered.html.contains("First &lt;value&gt;"))
        #expect(rendered.html.contains(#""tileID":"price\u003C/script\u003E""#))
        #expect(rendered.html.contains(#""operation":"calculate\u003C/script\u003E""#))
        #expect(!rendered.html.contains(#""tileID":"price</script>""#))
    }

    @Test("rejects build mode in browser renderer")
    func rejectsBuildModeInBrowserRenderer() throws {
        #expect(throws: TileKit.ServiceForm.RenderError.unsupportedMode(mode: "build")) {
            try TileKit.ServiceForm.Renderer().render(
                binding(
                    mode: .build,
                    modes: [.build],
                    exposure: .build,
                ),
            )
        }
    }

    @Test("rejects unsupported nested input fields")
    func rejectsUnsupportedNestedInputFields() throws {
        #expect(
            throws: TileKit.ServiceForm.RenderError.unsupportedInputField(
                fieldID: "details",
                kind: "object",
            ),
        ) {
            try TileKit.ServiceForm.Renderer().render(
                binding(
                    inputSchema: .init(
                        type: .object,
                        properties: [
                            "details": .init(type: .object),
                        ],
                        required: [
                            "details",
                        ],
                    ),
                ),
            )
        }
    }

    private func binding(
        tileID: String = "price-calculator",
        operationID: String = "positive-decimal-calculation",
        mode: TileKit.Tile.Mode = .proxy,
        modes: [TileKit.Service.Mode] = [.proxy],
        exposure: TileKit.Service.CredentialExposure = .server,
        submitLabel: String = "Calculate",
        inputLabel: String = "First value",
        inputSchema: TileKit.Service.Schema? = nil,
    ) throws -> TileKit.ServiceForm.Binding {
        let request = TileKit.Tile.ServiceFormRequest(
            id: tileID,
            serviceID: "calculator",
            operationID: operationID,
            mode: mode,
            submitLabel: submitLabel,
        )
        let contract = serviceContract(
            operation: calculatorOperation(
                id: operationID,
                modes: modes,
                exposure: exposure,
                inputLabel: inputLabel,
                inputSchema: inputSchema,
            ),
        )

        return try TileKit.ServiceForm.Binder().bind(
            request,
            to: contract,
        )
    }

    private func serviceContract(
        operation: TileKit.Service.Operation,
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
                operation,
            ],
        )
    }

    private func calculatorOperation(
        id: String,
        modes: [TileKit.Service.Mode],
        exposure: TileKit.Service.CredentialExposure,
        inputLabel: String,
        inputSchema: TileKit.Service.Schema?,
    ) -> TileKit.Service.Operation {
        .init(
            id: id,
            modes: modes,
            transport: .init(
                method: .post,
                path: "/calculate",
            ),
            inputSchema: inputSchema ?? positiveDecimalInputSchema(),
            inputUI: [
                "first": .init(
                    label: inputLabel,
                    placeholder: "0.00",
                    unit: "USD",
                    order: 1,
                ),
                "second": .init(
                    label: "Second value",
                    order: 2,
                ),
            ],
            outputSchema: .init(
                type: .object,
                properties: [
                    "result": .init(
                        type: .string,
                        semanticType: .decimal,
                    ),
                ],
                required: [
                    "result",
                ],
            ),
            outputUI: [
                "result": .init(
                    label: "Result",
                    format: "decimal",
                ),
            ],
            auth: .init(
                credentialID: "calculator-api",
                exposure: exposure,
            ),
        )
    }

    private func positiveDecimalInputSchema() -> TileKit.Service.Schema {
        .init(
            type: .object,
            properties: [
                "first": positiveDecimalField(),
                "second": positiveDecimalField(),
            ],
            required: [
                "first",
                "second",
            ],
        )
    }

    private func positiveDecimalField() -> TileKit.Service.Schema {
        .init(
            type: .string,
            semanticType: .positiveDecimal,
            pattern: #"^(?=.*[1-9])(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$"#,
        )
    }
}
