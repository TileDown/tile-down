import Foundation
import TileCore

public extension TileKit.Service {
    /// Validates integration manifests against a capability inventory.
    struct ManifestValidator: Sendable {
        private let inventory: CapabilityInventory

        public init(
            inventory: CapabilityInventory = .current,
        ) {
            self.inventory = inventory
        }

        public func validate(
            _ manifest: Manifest,
        ) -> [ValidationIssue] {
            var issues: [ValidationIssue] = []
            appendIdentityIssues(
                manifest,
                to: &issues,
            )
            appendInputIssues(
                manifest,
                to: &issues,
            )
            appendOutputIssues(
                manifest,
                to: &issues,
            )
            appendCredentialIssues(
                manifest.requirements.credentialRequirements,
                to: &issues,
            )
            return issues
        }

        private func appendIdentityIssues(
            _ manifest: Manifest,
            to issues: inout [ValidationIssue],
        ) {
            if trimmed(manifest.id).isEmpty {
                issues.append(
                    .init(
                        reason: "Manifest id is empty.",
                        recovery: "Set a stable provider-qualified id such as quiz.typeform.",
                    ),
                )
            }

            if trimmed(manifest.provider.name).isEmpty {
                issues.append(
                    .init(
                        reason: "Provider name is empty.",
                        recovery: "Set the human-readable provider name.",
                    ),
                )
            }
        }

        private func appendInputIssues(
            _ manifest: Manifest,
            to issues: inout [ValidationIssue],
        ) {
            for (key, input) in manifest.inputs {
                if !inventory.inputTypes.contains(input.type) {
                    issues.append(unsupportedInputIssue(key: key))
                }
                if input.type == .select {
                    appendSelectInputIssues(
                        key: key,
                        input: input,
                        to: &issues,
                    )
                }
            }
        }

        private func appendSelectInputIssues(
            key: String,
            input: Input,
            to issues: inout [ValidationIssue],
        ) {
            if input.allowedValues.isEmpty {
                issues.append(
                    .init(
                        reason: "Select input \(key) has no allowed values.",
                        recovery: "Add allowedValues for every select input.",
                    ),
                )
            }

            if let defaultValue = input.defaultValue {
                guard !input.allowedValues.contains(defaultValue) else {
                    return
                }

                issues.append(
                    .init(
                        reason: "Default value for \(key) is not allowed.",
                        recovery: "Add the default value to allowedValues or change the default.",
                    ),
                )
            }
        }

        private func appendOutputIssues(
            _ manifest: Manifest,
            to issues: inout [ValidationIssue],
        ) {
            for (key, output) in manifest.outputs {
                if !inventory.outputTypes.contains(output.type) {
                    issues.append(unsupportedOutputIssue(key: key))
                }
                let origin = trimmed(output.origin ?? "")
                if output.type == .iframe, origin.isEmpty {
                    issues.append(
                        .init(
                            reason: "Iframe output \(key) has no origin.",
                            recovery: "Declare the expected iframe origin.",
                        ),
                    )
                }
            }
        }

        private func appendCredentialIssues(
            _ requirements: [CredentialRequirement],
            to issues: inout [ValidationIssue],
        ) {
            for requirement in requirements where trimmed(requirement.id).isEmpty {
                issues.append(
                    .init(
                        reason: "Credential requirement id is empty.",
                        recovery: "Set a stable credential id.",
                    ),
                )
            }
        }

        private func unsupportedInputIssue(
            key: String,
        ) -> ValidationIssue {
            .init(
                reason: "Input \(key) uses an unsupported capability.",
                recovery: "Use a capability from the current inventory or add a new capability.",
            )
        }

        private func unsupportedOutputIssue(
            key: String,
        ) -> ValidationIssue {
            .init(
                reason: "Output \(key) uses an unsupported capability.",
                recovery: "Use a capability from the current inventory or add a new capability.",
            )
        }

        private func trimmed(
            _ value: String,
        ) -> String {
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
