import Foundation
import TileCore

public extension TileKit.Service {
    /// A failure while resolving a service contract by service id.
    enum ContractResolutionError: Error, Equatable, Sendable {
        case missingService(serviceID: String)
    }
}

extension TileKit.Service.ContractResolutionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .missingService(serviceID):
            "No service contract is registered for \(serviceID)."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingService:
            "Register the service contract for the id named by the tile service property."
        }
    }
}
