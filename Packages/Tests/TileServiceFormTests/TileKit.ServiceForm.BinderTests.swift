import Testing
import TileCore
import TileService
@testable import TileServiceForm
import TileTile

@Suite("Service form binder")
struct ServiceFormBinderTests {
    @Test("binds service form requests to contract operations")
    func bindsServiceFormRequestsToContractOperations() throws {
        let request = serviceFormRequest()
        let contract = serviceContract(
            operation: calculatorOperation(
                modes: [.proxy, .build],
                exposure: .server,
            ),
        )

        let binding = try TileKit.ServiceForm.Binder().bind(
            request,
            to: contract,
        )

        #expect(binding.request == request)
        #expect(binding.contract.id == "calculator")
        #expect(binding.operation.id == "positive-decimal-calculation")
    }

    @Test("rejects mismatched services")
    func rejectsMismatchedServices() {
        let contract = serviceContract(id: "different")

        #expect(
            throws: TileKit.ServiceForm.BindingError.serviceMismatch(
                requested: "calculator",
                actual: "different",
            ),
        ) {
            try TileKit.ServiceForm.Binder().bind(
                serviceFormRequest(),
                to: contract,
            )
        }
    }

    @Test("rejects missing operations")
    func rejectsMissingOperations() {
        let contract = serviceContract(operations: [])

        #expect(
            throws: TileKit.ServiceForm.BindingError.missingOperation(
                operationID: "positive-decimal-calculation",
                serviceID: "calculator",
            ),
        ) {
            try TileKit.ServiceForm.Binder().bind(
                serviceFormRequest(),
                to: contract,
            )
        }
    }

    @Test("rejects unsupported modes")
    func rejectsUnsupportedModes() {
        let contract = serviceContract(
            operation: calculatorOperation(
                modes: [.build],
                exposure: .server,
            ),
        )

        #expect(
            throws: TileKit.ServiceForm.BindingError.unsupportedMode(
                mode: "proxy",
                operationID: "positive-decimal-calculation",
            ),
        ) {
            try TileKit.ServiceForm.Binder().bind(
                serviceFormRequest(),
                to: contract,
            )
        }
    }

    @Test("rejects private credentials in remote mode")
    func rejectsPrivateCredentialsInRemoteMode() {
        let contract = serviceContract(
            operation: calculatorOperation(
                modes: [.remote],
                exposure: .server,
            ),
        )

        #expect(
            throws: TileKit.ServiceForm.BindingError.unsafeCredentialExposure(
                mode: "remote",
                exposure: "server",
                operationID: "positive-decimal-calculation",
            ),
        ) {
            try TileKit.ServiceForm.Binder().bind(
                serviceFormRequest(mode: .remote),
                to: contract,
            )
        }
    }

    private func serviceFormRequest(
        mode: TileKit.Tile.Mode = .proxy,
    ) -> TileKit.Tile.ServiceFormRequest {
        .init(
            id: "price-calculator",
            serviceID: "calculator",
            operationID: "positive-decimal-calculation",
            mode: mode,
            submitLabel: "Calculate",
        )
    }

    private func serviceContract(
        id: String = "calculator",
        operation: TileKit.Service.Operation? = nil,
        operations: [TileKit.Service.Operation]? = nil,
    ) -> TileKit.Service.Contract {
        .init(
            id: id,
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
            operations: operations ?? [
                operation ?? calculatorOperation(
                    modes: [.proxy],
                    exposure: .server,
                ),
            ],
        )
    }

    private func calculatorOperation(
        modes: [TileKit.Service.Mode],
        exposure: TileKit.Service.CredentialExposure,
    ) -> TileKit.Service.Operation {
        .init(
            id: "positive-decimal-calculation",
            modes: modes,
            transport: .init(
                method: .post,
                path: "/calculate",
            ),
            inputSchema: .init(
                type: .object,
                properties: [
                    "first": .init(type: .string),
                    "second": .init(type: .string),
                ],
                required: [
                    "first",
                    "second",
                ],
            ),
            outputSchema: .init(
                type: .object,
                properties: [
                    "result": .init(type: .string),
                ],
                required: [
                    "result",
                ],
            ),
            auth: .init(
                credentialID: "calculator-api",
                exposure: exposure,
            ),
        )
    }
}
