import Foundation
import Testing
import TileCore
@testable import TileService

@Suite("Service contract")
struct ServiceContractTests {
    @Test("decodes calculator operation contracts")
    func decodesCalculatorOperationContract() throws {
        let contract = try JSONDecoder().decode(
            TileKit.Service.Contract.self,
            from: calculatorContractData(),
        )

        let operation = try #require(contract.operations.first)
        let firstInput = try #require(operation.inputSchema.properties["first"])
        let resultOutput = try #require(operation.outputSchema.properties["result"])

        #expect(contract.id == "calculator")
        #expect(contract.health?.timeoutMilliseconds == 750)
        #expect(operation.id == "positive-decimal-calculation")
        #expect(operation.modes == [.proxy, .build])
        #expect(operation.transport.path == "/calculate")
        #expect(firstInput.semanticType == .positiveDecimal)
        #expect(operation.inputUI["first"]?.label == "First value")
        #expect(resultOutput.semanticType == .decimal)
        #expect(operation.outputUI["result"]?.format == "decimal")
        #expect(operation.auth?.credentialID == "calculator-api")
    }

    @Test("validates service operation contracts")
    func validatesServiceOperationContracts() throws {
        let contract = try JSONDecoder().decode(
            TileKit.Service.Contract.self,
            from: calculatorContractData(),
        )

        let issues = TileKit.Service.ContractValidator().validate(contract)

        #expect(issues.isEmpty)
    }

    @Test("reports invalid service operation contracts")
    func reportsInvalidServiceOperationContracts() {
        let contract = TileKit.Service.Contract(
            id: " ",
            name: "",
            version: "",
            health: .init(
                path: "",
                timeoutMilliseconds: 0,
            ),
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
                invalidOperation(id: "calculate"),
                invalidOperation(id: "calculate"),
            ],
        )

        let reasons = Set(
            TileKit.Service.ContractValidator()
                .validate(contract)
                .map(\.reason),
        )

        #expect(reasons.contains("Service contract id is empty."))
        #expect(reasons.contains("Service contract name is empty."))
        #expect(reasons.contains("Service contract version is empty."))
        #expect(reasons.contains("Health check path is empty."))
        #expect(reasons.contains("Health check timeout must be greater than zero."))
        #expect(reasons.contains("Operation id calculate is duplicated."))
        #expect(reasons.contains("Operation calculate has no modes."))
        #expect(reasons.contains("Operation calculate transport path is empty."))
        #expect(reasons.contains("Operation calculate inputSchema must be an object."))
        #expect(reasons.contains("Operation calculate outputSchema requires missing property missing."))
        #expect(reasons.contains("Operation calculate inputUi references unknown field ghost."))
        #expect(reasons.contains("Operation calculate references undeclared credential missing-api."))
    }

    private func invalidOperation(
        id: String,
    ) -> TileKit.Service.Operation {
        .init(
            id: id,
            modes: [],
            transport: .init(
                method: .post,
                path: " ",
                requestContentType: "",
                responseContentType: "",
            ),
            inputSchema: .init(type: .string),
            inputUI: [
                "ghost": .init(label: "Ghost"),
            ],
            outputSchema: .init(
                type: .object,
                properties: [
                    "result": .init(type: .string),
                ],
                required: [
                    "missing",
                ],
            ),
            outputUI: [
                "result": .init(label: "Result"),
            ],
            auth: .init(
                credentialID: "missing-api",
                exposure: .server,
            ),
        )
    }

    private func calculatorContractData() -> Data {
        Data(calculatorContractJSON.utf8)
    }
}

private let calculatorContractJSON = """
{
  "id": "calculator",
  "name": "Calculator",
  "version": "1.0.0",
  "health": {
    "path": "/health",
    "timeoutMilliseconds": 750
  },
  "requirements": {
    "credentials": [
      {
        "id": "calculator-api",
        "type": "bearer",
        "exposure": "server"
      }
    ]
  },
  "operations": [
    {
      "id": "positive-decimal-calculation",
      "modes": [
        "proxy",
        "build"
      ],
      "transport": {
        "method": "POST",
        "path": "/calculate",
        "requestContentType": "application/json",
        "responseContentType": "application/json"
      },
      "inputSchema": {
        "type": "object",
        "required": [
          "first",
          "second"
        ],
        "properties": {
          "first": {
            "type": "string",
            "pattern": "^(?=.*[1-9])(?:0|[1-9][0-9]*)(?:\\\\.[0-9]+)?$",
            "x-tiledownType": "positiveDecimal"
          },
          "second": {
            "type": "string",
            "pattern": "^(?=.*[1-9])(?:0|[1-9][0-9]*)(?:\\\\.[0-9]+)?$",
            "x-tiledownType": "positiveDecimal"
          }
        }
      },
      "inputUi": {
        "first": {
          "label": "First value",
          "control": "text",
          "order": 1
        },
        "second": {
          "label": "Second value",
          "control": "text",
          "order": 2
        }
      },
      "outputSchema": {
        "type": "object",
        "required": [
          "result"
        ],
        "properties": {
          "result": {
            "type": "string",
            "x-tiledownType": "decimal"
          }
        }
      },
      "outputUi": {
        "result": {
          "label": "Result",
          "format": "decimal"
        }
      },
      "auth": {
        "credential": "calculator-api",
        "exposure": "server"
      },
      "errors": {
        "format": "problem-details"
      },
      "cache": {
        "enabled": false
      }
    }
  ]
}
"""
