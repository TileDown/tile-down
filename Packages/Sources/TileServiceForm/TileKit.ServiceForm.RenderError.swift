import Foundation
import TileCore

public extension TileKit.ServiceForm {
    /// A validation error while rendering a generated service form.
    enum RenderError: Error, Equatable, Sendable {
        case unsupportedMode(mode: String)
        case unsupportedInputSchema(kind: String)
        case unsupportedOutputSchema(kind: String)
        case unsupportedInputField(fieldID: String, kind: String)
        case unsupportedOutputField(fieldID: String, kind: String)
        case runtimeConfigurationEncoding
    }
}

extension TileKit.ServiceForm.RenderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unsupportedMode(mode):
            "Service form rendering does not support \(mode) mode yet."
        case let .unsupportedInputSchema(kind):
            "Service form inputSchema must be an object, but it is \(kind)."
        case let .unsupportedOutputSchema(kind):
            "Service form outputSchema must be an object, but it is \(kind)."
        case let .unsupportedInputField(fieldID, kind):
            "Service form input field \(fieldID) cannot render \(kind) schema yet."
        case let .unsupportedOutputField(fieldID, kind):
            "Service form output field \(fieldID) cannot render \(kind) schema yet."
        case .runtimeConfigurationEncoding:
            "Service form runtime configuration could not be encoded as UTF-8."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unsupportedMode:
            "Use remote or proxy mode for the generated browser form."
        case .unsupportedInputSchema:
            "Declare inputSchema as an object with named properties."
        case .unsupportedOutputSchema:
            "Declare outputSchema as an object with named properties."
        case .unsupportedInputField:
            "Use a string, number, integer, boolean, or enum field for this first renderer."
        case .unsupportedOutputField:
            "Use a primitive output field until object, array, and table outputs are added."
        case .runtimeConfigurationEncoding:
            "Use UTF-8 compatible service, operation, and field identifiers."
        }
    }
}
