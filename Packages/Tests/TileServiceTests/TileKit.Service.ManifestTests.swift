import Foundation
import Testing
import TileCore
@testable import TileService

@Suite("Service manifest")
struct ServiceManifestTests {
    @Test("decodes provider integration manifests")
    func decodesProviderIntegrationManifest() throws {
        let manifest = try JSONDecoder().decode(
            TileKit.Service.Manifest.self,
            from: typeformManifestData(),
        )

        #expect(manifest.id == "quiz.typeform")
        #expect(manifest.provider.name == "Typeform")
        #expect(manifest.inputs["formId"]?.type == .text)
        #expect(manifest.inputs["theme"]?.type == .select)
        #expect(manifest.inputs["theme"]?.defaultValue == "light")
        #expect(manifest.outputs["embed"]?.type == .iframe)
        #expect(manifest.build.strategy == .providerEmbed)
        #expect(
            manifest.requirements.credentialRequirements == [
                .init(
                    id: "apiKey",
                    type: .apiKey,
                    exposure: .server,
                    environmentVariable: "TYPEFORM_API_KEY",
                ),
            ],
        )
    }

    @Test("validates manifests against the capability inventory")
    func validatesManifestCapabilities() throws {
        let manifest = try JSONDecoder().decode(
            TileKit.Service.Manifest.self,
            from: typeformManifestData(),
        )

        let issues = TileKit.Service.ManifestValidator().validate(manifest)

        #expect(issues.isEmpty)
    }

    @Test("reports invalid select and iframe output")
    func reportsInvalidSelectAndIframeOutput() {
        let manifest = TileKit.Service.Manifest(
            id: "quiz.typeform",
            provider: .init(name: "Typeform"),
            inputs: [
                "theme": .init(
                    type: .select,
                    required: false,
                    defaultValue: "light",
                ),
            ],
            outputs: [
                "embed": .init(type: .iframe),
            ],
            layout: .init(mode: .block),
            build: .init(strategy: .providerEmbed),
        )

        let issues = TileKit.Service.ManifestValidator().validate(manifest)

        #expect(
            issues.map(\.reason) == [
                "Select input theme has no allowed values.",
                "Default value for theme is not allowed.",
                "Iframe output embed has no origin.",
            ],
        )
    }

    private func typeformManifestData() -> Data {
        Data(
            """
            {
              "id": "quiz.typeform",
              "provider": {
                "name": "Typeform",
                "website": "https://typeform.com"
              },
              "requirements": {
                "apiKey": {
                  "environmentVariable": "TYPEFORM_API_KEY"
                }
              },
              "inputs": {
                "formId": {
                  "type": "text",
                  "required": true
                },
                "theme": {
                  "type": "select",
                  "required": false,
                  "default": "light",
                  "allowedValues": [
                    "light",
                    "dark"
                  ]
                }
              },
              "outputs": {
                "embed": {
                  "type": "iframe",
                  "responsive": true,
                  "origin": "https://form.typeform.com"
                }
              },
              "layout": {
                "mode": "block"
              },
              "build": {
                "strategy": "provider-embed"
              }
            }
            """.utf8,
        )
    }
}
