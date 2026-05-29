import Foundation
import TileCore
import TileService

public extension TileKit.Service {
    /// Resolves service contracts from local JSON files named by site bindings.
    ///
    /// The concrete, file-backed implementation of
    /// ``TileKit/Service/ContractResolving``. It is a thin adapter: it maps a
    /// service id to its ``TileKit/Service/Binding``, reads the bound file, and
    /// decodes a ``TileKit/Service/Contract``. Remote and cached resolvers arrive
    /// later behind the same protocol.
    struct LocalFileContractResolver: ContractResolving {
        private let bindings: [String: Binding]
        private let decoder: JSONDecoder

        public init(
            bindings: [Binding],
            decoder: JSONDecoder = JSONDecoder(),
        ) {
            self.bindings = Dictionary(
                bindings.map { ($0.serviceID, $0) },
                uniquingKeysWith: { _, latest in latest },
            )
            self.decoder = decoder
        }

        public func resolveContract(
            serviceID: String,
        ) throws -> Contract {
            guard let binding = bindings[serviceID] else {
                throw ContractResolutionError.missingService(serviceID: serviceID)
            }

            switch binding.source {
            case let .localFile(path):
                let data = try readFile(
                    at: path,
                    serviceID: serviceID,
                )
                do {
                    return try decoder.decode(Contract.self, from: data)
                } catch {
                    throw ContractResolutionError.malformedContract(
                        serviceID: serviceID,
                        path: path,
                    )
                }
            }
        }

        private func readFile(
            at path: String,
            serviceID: String,
        ) throws -> Data {
            do {
                return try Data(contentsOf: URL(fileURLWithPath: path))
            } catch {
                throw ContractResolutionError.unreadableContract(
                    serviceID: serviceID,
                    path: path,
                )
            }
        }
    }
}
