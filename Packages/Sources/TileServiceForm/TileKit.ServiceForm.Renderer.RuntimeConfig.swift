import Foundation
import TileCore
import TileService
import TileTile

extension TileKit.ServiceForm.Renderer {
    func runtimeConfig(
        binding: TileKit.ServiceForm.Binding,
        inputFields: [RenderField],
        outputFields: [RenderField],
    ) -> RuntimeConfig {
        .init(
            tileID: binding.request.id,
            service: binding.contract.id,
            operation: binding.operation.id,
            mode: binding.request.mode.rawValue,
            endpoint: endpoint(for: binding),
            method: binding.operation.transport.method.rawValue,
            inputFields: inputFields.map(runtimeField),
            outputFields: outputFields.map(runtimeField),
        )
    }

    func scriptSafeJSON(
        _ config: RuntimeConfig,
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(config)
        guard let json = String(bytes: data, encoding: .utf8) else {
            throw TileKit.ServiceForm.RenderError.runtimeConfigurationEncoding
        }

        return json
            .replacingOccurrences(of: "<", with: "\\u003C")
            .replacingOccurrences(of: ">", with: "\\u003E")
            .replacingOccurrences(of: "&", with: "\\u0026")
    }

    private func runtimeField(
        _ field: RenderField,
    ) -> RuntimeField {
        .init(
            name: field.id,
            required: field.required,
            schemaType: field.schema.type.rawValue,
            format: field.schema.format,
            semanticType: field.schema.semanticType?.rawValue,
            pattern: field.schema.pattern,
            enumValues: field.schema.enumValues,
            minimum: field.schema.minimum,
            exclusiveMinimum: field.schema.exclusiveMinimum,
            maximum: field.schema.maximum,
            exclusiveMaximum: field.schema.exclusiveMaximum,
            outputFormat: field.fieldUI.format,
        )
    }

    private func endpoint(
        for binding: TileKit.ServiceForm.Binding,
    ) -> String {
        switch binding.request.mode {
        case .proxy:
            "/_td/services/"
                + pathSegment(binding.contract.id)
                + "/"
                + pathSegment(binding.operation.id)
        case .remote:
            binding.operation.transport.path
        case .build, .local, .static:
            binding.operation.transport.path
        }
    }

    private func pathSegment(
        _ value: String,
    ) -> String {
        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~",
        )
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
