import Foundation
import Testing
import TileCore
import TileService
import TileServiceForm
@testable import TileServiceImpl
import TileTile

@Suite("Local file contract resolver")
struct LocalFileContractResolverTests {
    @Test("resolves a contract from a local file named by a binding")
    func resolvesContractFromFile() throws {
        let path = try writeContract(calculatorContract(), name: "calculator.json")
        defer { remove(path) }

        let resolver = TileKit.Service.LocalFileContractResolver(
            bindings: [
                .init(
                    serviceID: "calculator",
                    source: .localFile(path: path),
                    mode: .proxy,
                    proxyRoute: "/_td/services/calculator",
                    availability: .required,
                ),
            ],
        )

        let contract = try resolver.resolveContract(serviceID: "calculator")
        #expect(contract.id == "calculator")
        #expect(contract.operations.map(\.id) == ["positive-decimal-calculation"])
    }

    @Test("a binding carries an availability policy")
    func bindingCarriesAvailability() {
        let binding = TileKit.Service.Binding(
            serviceID: "calculator",
            source: .localFile(path: "/tmp/x.json"),
            mode: .proxy,
            availability: .optional,
        )

        #expect(binding.availability == .optional)
    }

    @Test("reports an unregistered service")
    func reportsMissingService() {
        let resolver = TileKit.Service.LocalFileContractResolver(bindings: [])

        #expect(
            throws: TileKit.Service.ContractResolutionError.missingService(
                serviceID: "calculator",
            ),
        ) {
            try resolver.resolveContract(serviceID: "calculator")
        }
    }

    @Test("reports an unreadable contract file")
    func reportsUnreadableContract() {
        let path = "/tmp/tiledown-does-not-exist-\(#line).json"
        let resolver = TileKit.Service.LocalFileContractResolver(
            bindings: [
                .init(serviceID: "calculator", source: .localFile(path: path), mode: .proxy),
            ],
        )

        #expect(
            throws: TileKit.Service.ContractResolutionError.unreadableContract(
                serviceID: "calculator",
                path: path,
            ),
        ) {
            try resolver.resolveContract(serviceID: "calculator")
        }
    }

    @Test("reports a malformed contract file")
    func reportsMalformedContract() throws {
        let path = try writeText("{ not a contract", name: "broken.json")
        defer { remove(path) }

        let resolver = TileKit.Service.LocalFileContractResolver(
            bindings: [
                .init(serviceID: "calculator", source: .localFile(path: path), mode: .proxy),
            ],
        )

        #expect(
            throws: TileKit.Service.ContractResolutionError.malformedContract(
                serviceID: "calculator",
                path: path,
            ),
        ) {
            try resolver.resolveContract(serviceID: "calculator")
        }
    }

    @Test("a file-resolved contract renders without leaking server credentials")
    func fileResolvedContractDoesNotLeakSecrets() throws {
        let path = try writeContract(calculatorContract(), name: "calculator.json")
        defer { remove(path) }

        let resolver = TileKit.Service.LocalFileContractResolver(
            bindings: [
                .init(serviceID: "calculator", source: .localFile(path: path), mode: .proxy),
            ],
        )
        let contract = try resolver.resolveContract(serviceID: "calculator")
        let request = TileKit.Tile.ServiceFormRequest(
            id: "price-calculator",
            serviceID: "calculator",
            operationID: "positive-decimal-calculation",
            mode: .proxy,
            submitLabel: "Calculate",
        )
        let binding = try TileKit.ServiceForm.Binder().bind(request, to: contract)
        let rendered = try TileKit.ServiceForm.Renderer().render(binding)

        let browserOutput = [rendered.html, rendered.css, rendered.javascript]
            .joined(separator: "\n")
        #expect(!browserOutput.contains("calculator-api"))
        #expect(rendered.html.contains(#"data-td-service="calculator""#))
    }

    // MARK: - Fixtures

    private func writeContract(
        _ contract: TileKit.Service.Contract,
        name: String,
    ) throws -> String {
        let data = try JSONEncoder().encode(contract)
        return try write(data, name: name)
    }

    private func writeText(
        _ text: String,
        name: String,
    ) throws -> String {
        try write(Data(text.utf8), name: name)
    }

    private func write(
        _ data: Data,
        name: String,
    ) throws -> String {
        // A unique directory per call so tests running in parallel never share a
        // path: a shared filename let one test's cleanup delete a file another
        // was mid-read, which raced only under CI's scheduling.
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tiledown-service-impl-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try data.write(to: url)
        return url.path
    }

    private func remove(
        _ path: String,
    ) {
        try? FileManager.default.removeItem(atPath: path)
    }

    private func calculatorContract() -> TileKit.Service.Contract {
        .init(
            id: "calculator",
            name: "Calculator",
            version: "1.0.0",
            requirements: .init(
                credentials: [
                    .init(id: "calculator-api", type: .bearer, exposure: .server),
                ],
            ),
            operations: [
                calculatorOperation(),
            ],
        )
    }

    private func calculatorOperation() -> TileKit.Service.Operation {
        .init(
            id: "positive-decimal-calculation",
            modes: [.proxy],
            transport: .init(method: .post, path: "/calculate"),
            inputSchema: .init(
                type: .object,
                properties: [
                    "first": .init(type: .string, semanticType: .positiveDecimal),
                ],
                required: ["first"],
            ),
            inputUI: [
                "first": .init(label: "First value", order: 1),
            ],
            outputSchema: .init(
                type: .object,
                properties: [
                    "result": .init(type: .string, semanticType: .decimal),
                ],
                required: ["result"],
            ),
            outputUI: [
                "result": .init(label: "Result", format: "decimal"),
            ],
            auth: .init(credentialID: "calculator-api", exposure: .server),
        )
    }
}
