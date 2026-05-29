import Foundation
import TileCore

public extension TileKit.Service {
    /// Validates service contracts before generated service tiles consume them.
    struct ContractValidator: Sendable {
        public init() {}

        public func validate(
            _ contract: Contract,
        ) -> [ValidationIssue] {
            var issues: [ValidationIssue] = []
            appendIdentityIssues(
                contract,
                to: &issues,
            )
            appendHealthIssues(
                contract.health,
                to: &issues,
            )
            appendOperationIssues(
                contract,
                to: &issues,
            )
            return issues
        }

        private func appendIdentityIssues(
            _ contract: Contract,
            to issues: inout [ValidationIssue],
        ) {
            appendRequiredStringIssue(
                value: contract.id,
                reason: "Service contract id is empty.",
                recovery: "Set a stable service id.",
                to: &issues,
            )
            appendRequiredStringIssue(
                value: contract.name,
                reason: "Service contract name is empty.",
                recovery: "Set the human-readable service name.",
                to: &issues,
            )
            appendRequiredStringIssue(
                value: contract.version,
                reason: "Service contract version is empty.",
                recovery: "Set the service contract version.",
                to: &issues,
            )
        }

        private func appendHealthIssues(
            _ health: Health?,
            to issues: inout [ValidationIssue],
        ) {
            guard let health else {
                return
            }

            appendRequiredStringIssue(
                value: health.path,
                reason: "Health check path is empty.",
                recovery: "Set the health check path or omit health.",
                to: &issues,
            )
            if health.timeoutMilliseconds <= 0 {
                issues.append(
                    .init(
                        reason: "Health check timeout must be greater than zero.",
                        recovery: "Set timeoutMilliseconds to a positive value.",
                    ),
                )
            }
        }
    }
}

extension TileKit.Service.ContractValidator {
    func appendRequiredStringIssue(
        value: String,
        reason: String,
        recovery: String,
        to issues: inout [TileKit.Service.ValidationIssue],
    ) {
        if trimmed(value).isEmpty {
            issues.append(
                .init(
                    reason: reason,
                    recovery: recovery,
                ),
            )
        }
    }

    func trimmed(
        _ value: String,
    ) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
