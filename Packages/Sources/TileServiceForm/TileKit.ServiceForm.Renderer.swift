import TileCore
import TileService
import TileTile

public extension TileKit.ServiceForm {
    /// Renders bound service form operations into deterministic browser output.
    struct Renderer: Sendable {
        public init() {}

        public func render(
            _ binding: Binding,
        ) throws -> Rendered {
            try validateMode(binding.request.mode)

            let inputFields = try fields(
                schema: binding.operation.inputSchema,
                fieldUI: binding.operation.inputUI,
                role: .input,
            )
            let outputFields = try fields(
                schema: binding.operation.outputSchema,
                fieldUI: binding.operation.outputUI,
                role: .output,
            )
            let config = runtimeConfig(
                binding: binding,
                inputFields: inputFields,
                outputFields: outputFields,
            )

            return try .init(
                html: html(
                    binding: binding,
                    inputFields: inputFields,
                    outputFields: outputFields,
                    config: config,
                ),
                css: Self.defaultCSS,
                javascript: Self.defaultJavaScript,
            )
        }
    }
}
