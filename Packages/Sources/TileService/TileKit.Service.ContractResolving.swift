import TileCore

public extension TileKit.Service {
    /// Resolves a service contract by its service id.
    ///
    /// The seam between a tile that names a service and the contract that
    /// describes that service's operations. The first concrete resolver keeps
    /// contracts in memory; file and network resolvers arrive behind this same
    /// protocol when later slices need them.
    protocol ContractResolving: Sendable {
        func resolveContract(
            serviceID: String,
        ) throws -> Contract
    }
}
