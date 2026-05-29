import TileCore

extension TileKit.Service.ContractValidator {
    func appendSchemaIssues(
        _ operation: TileKit.Service.Operation,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        appendObjectSchemaIssue(
            operation.inputSchema,
            label: "inputSchema",
            operationID: operation.id,
            to: &issues,
        )
        appendObjectSchemaIssue(
            operation.outputSchema,
            label: "outputSchema",
            operationID: operation.id,
            to: &issues,
        )
        appendRequiredPropertyIssues(
            operation.inputSchema,
            label: "inputSchema",
            operationID: operation.id,
            to: &issues,
        )
        appendRequiredPropertyIssues(
            operation.outputSchema,
            label: "outputSchema",
            operationID: operation.id,
            to: &issues,
        )
    }

    func appendUIReferenceIssues(
        _ operation: TileKit.Service.Operation,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        appendUnknownUIReferenceIssues(
            operation.inputUI,
            properties: operation.inputSchema.properties,
            label: "inputUi",
            operationID: operation.id,
            to: &issues,
        )
        appendUnknownUIReferenceIssues(
            operation.outputUI,
            properties: operation.outputSchema.properties,
            label: "outputUi",
            operationID: operation.id,
            to: &issues,
        )
    }

    private func appendObjectSchemaIssue(
        _ schema: TileKit.Service.Schema,
        label: String,
        operationID: String,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        if schema.type != .object {
            issues.append(
                .init(
                    reason: "Operation \(operationID) \(label) must be an object.",
                    recovery: "Declare an object schema with properties.",
                ),
            )
        }
    }

    private func appendRequiredPropertyIssues(
        _ schema: TileKit.Service.Schema,
        label: String,
        operationID: String,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        for requiredProperty in schema.required where schema.properties[requiredProperty] == nil {
            issues.append(
                .init(
                    reason: "Operation \(operationID) \(label) requires missing property \(requiredProperty).",
                    recovery: "Add the required property to properties or remove it from required.",
                ),
            )
        }
    }

    private func appendUnknownUIReferenceIssues(
        _ fields: [String: TileKit.Service.FieldUI],
        properties: [String: TileKit.Service.Schema],
        label: String,
        operationID: String,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        for key in fields.keys where properties[key] == nil {
            issues.append(
                .init(
                    reason: "Operation \(operationID) \(label) references unknown field \(key).",
                    recovery: "Reference a schema property or remove the UI hint.",
                ),
            )
        }
    }
}
