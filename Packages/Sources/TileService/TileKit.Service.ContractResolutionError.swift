import Foundation
import TileCore

public extension TileKit.Service {
    /// A failure while resolving a service contract by service id.
    enum ContractResolutionError: Error, Equatable, Sendable {
        case missingService(serviceID: String)
        case unreadableContract(serviceID: String, path: String)
        case malformedContract(serviceID: String, path: String)
    }
}

extension TileKit.Service.ContractResolutionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .missingService(serviceID):
            "No service contract is registered for \(serviceID)."
        case let .unreadableContract(serviceID, path):
            "Could not read the contract for \(serviceID) at \(path)."
        case let .malformedContract(serviceID, path):
            "The contract for \(serviceID) at \(path) is not valid contract JSON."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingService:
            "Register the service contract for the id named by the tile service property."
        case .unreadableContract:
            "Check the binding source path exists and is readable."
        case .malformedContract:
            "Check the file contains a valid Tiledown service contract."
        }
    }
}
