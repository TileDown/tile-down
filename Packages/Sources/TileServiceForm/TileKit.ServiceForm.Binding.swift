import TileCore
import TileService
import TileTile

public extension TileKit.ServiceForm {
    /// A service form request bound to a service contract operation.
    struct Binding: Equatable, Sendable {
        public var request: TileKit.Tile.ServiceFormRequest
        public var contract: TileKit.Service.Contract
        public var operation: TileKit.Service.Operation

        public init(
            request: TileKit.Tile.ServiceFormRequest,
            contract: TileKit.Service.Contract,
            operation: TileKit.Service.Operation,
        ) {
            self.request = request
            self.contract = contract
            self.operation = operation
        }
    }
}
