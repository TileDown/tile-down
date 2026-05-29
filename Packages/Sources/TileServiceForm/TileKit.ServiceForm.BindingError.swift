import Foundation
import TileCore

public extension TileKit.ServiceForm {
    /// A validation error while binding a service form request to a service contract.
    enum BindingError: Error, Equatable, Sendable {
        case serviceMismatch(requested: String, actual: String)
        case missingOperation(operationID: String, serviceID: String)
        case unsupportedMode(mode: String, operationID: String)
        case unsafeCredentialExposure(
            mode: String,
            exposure: String,
            operationID: String,
        )
    }
}

extension TileKit.ServiceForm.BindingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .serviceMismatch(requested, actual):
            "Service form requested \(requested), but contract id is \(actual)."
        case let .missingOperation(operationID, serviceID):
            "Service \(serviceID) has no operation \(operationID)."
        case let .unsupportedMode(mode, operationID):
            "Operation \(operationID) does not support \(mode) mode."
        case let .unsafeCredentialExposure(mode, exposure, operationID):
            "Operation \(operationID) cannot use \(exposure) credentials in \(mode) mode."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .serviceMismatch:
            "Bind the tile request to the service contract named by the tile service property."
        case .missingOperation:
            "Add the operation to the service contract or change the tile operation property."
        case .unsupportedMode:
            "Choose one of the modes declared by the service operation."
        case .unsafeCredentialExposure:
            "Use proxy or build mode for private credentials, or declare a browser-safe credential."
        }
    }
}
