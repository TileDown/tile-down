import TileCore

public extension TileKit.Service {
    /// Where a service contract is loaded from.
    ///
    /// Only local files are supported today. Remote sources arrive behind the
    /// same ``TileKit/Service/ContractResolving`` seam when HTTP loading lands;
    /// adding a case forces every resolver to handle it.
    enum ContractSource: Equatable, Sendable {
        case localFile(path: String)
    }
}
