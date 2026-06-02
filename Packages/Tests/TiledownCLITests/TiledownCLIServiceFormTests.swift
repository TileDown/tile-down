import Foundation
import Testing

extension TiledownCLITests {
    @Test("build-site loads service form contracts from project config")
    func buildSiteLoadsServiceFormContractsFromProjectConfig() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeServiceFormProject(to: fixture.content)

        let result = try runTiledown(
            arguments: ["build-site", fixture.content.path, fixture.output.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")

        try assertServiceFormBuildOutput(in: fixture)
    }

    @Test("build-site keeps absolute in-root service contracts private")
    func buildSiteKeepsAbsoluteInRootServiceContractsPrivate() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        let contractPath = fixture.content
            .appendingPathComponent("contracts/calculator.json")
            .path
        try writeServiceFormProject(to: fixture.content, contractPath: contractPath)

        let result = try runTiledown(
            arguments: ["build-site", fixture.content.path, fixture.output.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        try assertServiceFormBuildOutput(in: fixture)
    }

    private func writeServiceFormProject(
        to content: URL,
        contractPath: String = "./contracts/calculator.json",
    ) throws {
        try """
        title: Configured Service Form
        service.calculator.contract: \(contractPath)
        service.calculator.mode: proxy
        service.calculator.proxyRoute: /_td/services/calculator
        """.write(
            to: content.appendingPathComponent("tiledown.yml"),
            atomically: true,
            encoding: .utf8,
        )

        try """
        ---
        title: Calculator
        ---
        # Calculator

        :::tile service-form
        id: price-calculator
        service: calculator
        operation: positive-decimal-calculation
        mode: proxy
        submitLabel: Calculate
        :::
        """.write(
            to: content.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )

        let contracts = content.appendingPathComponent(
            "contracts",
            isDirectory: true,
        )
        try FileManager.default.createDirectory(
            at: contracts,
            withIntermediateDirectories: true,
        )
        try calculatorContractJSON.write(
            to: contracts.appendingPathComponent("calculator.json"),
            atomically: true,
            encoding: .utf8,
        )
    }

    private func assertServiceFormBuildOutput(
        in fixture: ContentFixture,
    ) throws {
        let home = try String(
            contentsOf: fixture.output.appendingPathComponent("index.html"),
            encoding: .utf8,
        )
        #expect(home.contains(#"data-td-service="calculator""#))
        #expect(home.contains(#"data-td-operation="positive-decimal-calculation""#))
        #expect(home.contains("First value"))
        #expect(home.contains("Second value"))
        #expect(
            !FileManager.default.fileExists(
                atPath: fixture.output
                    .appendingPathComponent("contracts/calculator.json")
                    .path,
            ),
        )
        #expect(!home.contains("calculator-api"))
    }
}

private let calculatorContractJSON = """
{
  "id": "calculator",
  "name": "Calculator",
  "version": "1.0.0",
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
        "proxy"
      ],
      "transport": {
        "method": "POST",
        "path": "/calculate"
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
            "x-tiledownType": "positiveDecimal"
          },
          "second": {
            "type": "string",
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
      }
    }
  ]
}
"""
