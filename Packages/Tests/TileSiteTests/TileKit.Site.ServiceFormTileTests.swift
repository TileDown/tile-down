import Testing
import TileCore
import TileMarkdown
import TileService
import TileServiceForm
import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site generator service-form tile")
struct SiteGeneratorServiceFormTests {
    @Test("renders a service-form tile and exposes its assets")
    func rendersServiceFormTile() throws {
        let fileSystem = serviceFormFileSystem()
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: registry(
                resolver: .init(
                    contracts: [
                        "calculator": calculatorContract(),
                    ],
                ),
            ),
        )

        _ = try generator.build(buildRequest())

        let output = try #require(fileSystem.files["dist/index.html"])
        // Generated form HTML in source order.
        #expect(output.contains(#"data-td-tile-id="price-calculator""#))
        #expect(output.contains(#"data-td-service="calculator""#))
        #expect(output.contains(#"data-td-operation="positive-decimal-calculation""#))
        // CSS exposed through page.assets.css.
        #expect(output.contains("<style>.td-service-form"))
        // Browser JavaScript exposed through page.assets.javascript.
        #expect(output.contains("fetch(config.endpoint"))
        // No server credential leaks into browser output.
        #expect(!output.contains("calculator-api"))
    }

    @Test("fails a service-form tile when the service is not registered")
    func failsServiceFormTileWithMissingService() throws {
        let generator = makeGenerator(
            fileSystem: serviceFormFileSystem(),
            tileRegistry: registry(resolver: .init()),
        )

        #expect(
            throws: TileKit.Service.ContractResolutionError.missingService(
                serviceID: "calculator",
            ),
        ) {
            try generator.build(buildRequest())
        }
    }

    private func registry(
        resolver: TileKit.Service.InMemoryContractResolver,
    ) -> TileKit.Tile.Registry {
        TileKit.Tile.Registry()
            .registering(
                TileKit.ServiceForm.TileRenderer(resolver: resolver),
                for: TileKit.Tile.ServiceFormRequest.typeID,
            )
    }

    private func buildRequest() -> TileKit.Site.BuildRequest {
        .init(
            sourcePath: "content/index.md",
            templatePath: "templates/page.html",
            outputPath: "dist/index.html",
        )
    }

    private func serviceFormFileSystem() -> MemoryFileSystem {
        let template = [
            #"<style>{{{ page.assets.css }}}</style>"#,
            #"{{{ page.contents.html }}}"#,
            #"<script>{{{ page.assets.javascript }}}</script>"#,
        ].joined()

        return MemoryFileSystem(
            files: [
                "content/index.md": """
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
                """,
                "templates/page.html": template,
            ],
        )
    }

    private func calculatorContract() -> TileKit.Service.Contract {
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
                calculatorOperation(),
            ],
        )
    }

    private func calculatorOperation() -> TileKit.Service.Operation {
        .init(
            id: "positive-decimal-calculation",
            modes: [.proxy],
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
                exposure: .server,
            ),
        )
    }

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
        tileRegistry: TileKit.Tile.Registry,
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            markdownRenderer: TileKit.Markdown.BasicHTMLRenderer(),
            tileParser: TileKit.Tile.DirectiveParser(),
            tileRegistry: tileRegistry,
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
