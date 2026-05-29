import TileCore

public extension TileKit.Service {
    /// Resolves service contracts from an in-memory map of service id to contract.
    ///
    /// Pure and deterministic: no I/O, no platform divergence. It is the smallest
    /// concrete that satisfies ``TileKit/Service/ContractResolving``, and the
    /// canonical resolver for tests and for composition roots that already hold
    /// their contracts in memory.
    struct InMemoryContractResolver: ContractResolving {
        private let contracts: [String: Contract]

        public init(
            contracts: [String: Contract] = [:],
        ) {
            self.contracts = contracts
        }

        public func resolveContract(
            serviceID: String,
        ) throws -> Contract {
            guard let contract = contracts[serviceID] else {
                throw ContractResolutionError.missingService(serviceID: serviceID)
            }

            return contract
        }
    }
}
