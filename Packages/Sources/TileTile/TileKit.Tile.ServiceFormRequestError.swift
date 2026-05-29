import Foundation
import TileCore

public extension TileKit.Tile {
    /// A validation error while building a service form request from a tile.
    enum ServiceFormRequestError: Error, Equatable, Sendable {
        case invalidTileType(actual: String)
        case missingProperty(String)
        case emptyProperty(String)
        case invalidPropertyType(String)
        case unsupportedMode(String)
    }
}

extension TileKit.Tile.ServiceFormRequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidTileType(actual):
            "Tile type \(actual) is not service-form."
        case let .missingProperty(name):
            "Service form tile is missing \(name)."
        case let .emptyProperty(name):
            "Service form tile property \(name) is empty."
        case let .invalidPropertyType(name):
            "Service form tile property \(name) must be a string."
        case let .unsupportedMode(value):
            "Service form tile mode \(value) is unsupported."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidTileType:
            "Build service form requests only from service-form tiles."
        case let .missingProperty(name):
            "Add the \(name) property to the service-form tile."
        case let .emptyProperty(name):
            "Set a non-empty value for \(name)."
        case let .invalidPropertyType(name):
            "Use a single scalar value for \(name), not a list."
        case .unsupportedMode:
            "Use static, local, remote, proxy, or build."
        }
    }
}
