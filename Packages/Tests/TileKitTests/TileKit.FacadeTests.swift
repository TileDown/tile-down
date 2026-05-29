import Testing
import TileKit

@Suite("TileKit facade")
struct TileKitFacadeTests {
    @Test("exports domain modules and site implementation")
    func exportsModules() throws {
        let queryRunner = TileKit.Content.QueryRunner()
        let markdownRenderer = TileKit.Markdown.CommonMarkRenderer()
        let manifestValidator = TileKit.Service.ManifestValidator()
        let serviceFormBinder = TileKit.ServiceForm.Binder()
        let serviceFormRenderer = TileKit.ServiceForm.Renderer()
        let tileParser = TileKit.Tile.DirectiveParser()
        let serviceFormBinding = try serviceFormBinder.bind(
            serviceFormRequest(),
            to: serviceContract(),
        )
        let serviceFormOutput = try serviceFormRenderer.render(serviceFormBinding)

        #expect(TileKit.Product.commandName == "tiledown")
        #expect(queryRunner.run(.init(), records: []) == [])
        #expect(markdownRenderer.renderHTML("# Hello") == "<h1>Hello</h1>")
        #expect(manifestValidator.validate(typeformManifest()).isEmpty)
        #expect(serviceFormBinding.operation.id == "positive-decimal-calculation")
        #expect(serviceFormOutput.html.contains(#"data-td-service-form-root"#))
        #expect(try tileParser.parseBlocks("Text") == [.markdown("Text")])
    }

    private func typeformManifest() -> TileKit.Service.Manifest {
        .init(
            id: "quiz.typeform",
            provider: .init(name: "Typeform"),
            inputs: [
                "formId": .init(
                    type: .text,
                    required: true,
                ),
            ],
            outputs: [
                "embed": .init(
                    type: .iframe,
                    origin: "https://form.typeform.com",
                ),
            ],
            layout: .init(mode: .block),
            build: .init(strategy: .providerEmbed),
        )
    }

    private func serviceFormRequest() -> TileKit.Tile.ServiceFormRequest {
        .init(
            id: "price-calculator",
            serviceID: "calculator",
            operationID: "positive-decimal-calculation",
            mode: .proxy,
        )
    }

    private func serviceContract() -> TileKit.Service.Contract {
        .init(
            id: "calculator",
            name: "Calculator",
            version: "1.0.0",
            operations: [
                .init(
                    id: "positive-decimal-calculation",
                    modes: [.proxy],
                    transport: .init(
                        method: .post,
                        path: "/calculate",
                    ),
                    inputSchema: .init(type: .object),
                    outputSchema: .init(type: .object),
                ),
            ],
        )
    }
}
