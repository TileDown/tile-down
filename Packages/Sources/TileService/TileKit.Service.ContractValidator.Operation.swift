import TileCore

extension TileKit.Service.ContractValidator {
    func appendOperationIssues(
        _ contract: TileKit.Service.Contract,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        if contract.operations.isEmpty {
            issues.append(
                .init(
                    reason: "Service contract has no operations.",
                    recovery: "Declare at least one operation.",
                ),
            )
        }

        let declaredCredentials = Set(
            contract.requirements.credentialRequirements.map(\.id),
        )
        appendDuplicateOperationIssues(
            contract.operations,
            to: &issues,
        )
        for operation in contract.operations {
            appendSingleOperationIssues(
                operation,
                declaredCredentials: declaredCredentials,
                to: &issues,
            )
        }
    }

    private func appendDuplicateOperationIssues(
        _ operations: [TileKit.Service.Operation],
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        var seen: Set<String> = []
        for operation in operations {
            let id = trimmed(operation.id)
            guard !id.isEmpty else {
                continue
            }
            if !seen.insert(id).inserted {
                issues.append(
                    .init(
                        reason: "Operation id \(id) is duplicated.",
                        recovery: "Use a unique id for each operation.",
                    ),
                )
            }
        }
    }

    private func appendSingleOperationIssues(
        _ operation: TileKit.Service.Operation,
        declaredCredentials: Set<String>,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        appendOperationIdentityIssues(
            operation,
            to: &issues,
        )
        appendTransportIssues(
            operation,
            to: &issues,
        )
        appendSchemaIssues(
            operation,
            to: &issues,
        )
        appendUIReferenceIssues(
            operation,
            to: &issues,
        )
        appendAuthIssues(
            operation,
            declaredCredentials: declaredCredentials,
            to: &issues,
        )
    }

    private func appendOperationIdentityIssues(
        _ operation: TileKit.Service.Operation,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        appendRequiredStringIssue(
            value: operation.id,
            reason: "Operation id is empty.",
            recovery: "Set a stable operation id.",
            to: &issues,
        )
        if operation.modes.isEmpty {
            issues.append(
                .init(
                    reason: "Operation \(operation.id) has no modes.",
                    recovery: "Declare at least one supported mode.",
                ),
            )
        }
    }

    private func appendTransportIssues(
        _ operation: TileKit.Service.Operation,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        appendRequiredStringIssue(
            value: operation.transport.path,
            reason: "Operation \(operation.id) transport path is empty.",
            recovery: "Set the operation transport path.",
            to: &issues,
        )
        appendRequiredStringIssue(
            value: operation.transport.requestContentType,
            reason: "Operation \(operation.id) request content type is empty.",
            recovery: "Set requestContentType.",
            to: &issues,
        )
        appendRequiredStringIssue(
            value: operation.transport.responseContentType,
            reason: "Operation \(operation.id) response content type is empty.",
            recovery: "Set responseContentType.",
            to: &issues,
        )
    }

    private func appendAuthIssues(
        _ operation: TileKit.Service.Operation,
        declaredCredentials: Set<String>,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        guard let auth = operation.auth else {
            return
        }

        if trimmed(auth.credentialID).isEmpty {
            issues.append(
                .init(
                    reason: "Operation \(operation.id) auth credential is empty.",
                    recovery: "Set auth.credential to a declared credential id.",
                ),
            )
        }
        if !declaredCredentials.contains(auth.credentialID) {
            issues.append(
                .init(
                    reason: "Operation \(operation.id) references undeclared credential \(auth.credentialID).",
                    recovery: "Declare the credential in requirements.credentials.",
                ),
            )
        }
    }
}
