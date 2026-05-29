import TileCore
import TileService
import TileTile

public extension TileKit.ServiceForm {
    /// Binds typed service form tile requests to service contract operations.
    struct Binder: Sendable {
        public init() {}

        public func bind(
            _ request: TileKit.Tile.ServiceFormRequest,
            to contract: TileKit.Service.Contract,
        ) throws -> Binding {
            guard request.serviceID == contract.id else {
                throw BindingError.serviceMismatch(
                    requested: request.serviceID,
                    actual: contract.id,
                )
            }

            let operation = try operation(
                id: request.operationID,
                in: contract,
            )
            try validateMode(
                request.mode,
                operation: operation,
            )
            try validateCredentialExposure(
                operation.auth?.exposure,
                mode: request.mode,
                operationID: operation.id,
            )

            return .init(
                request: request,
                contract: contract,
                operation: operation,
            )
        }

        private func operation(
            id: String,
            in contract: TileKit.Service.Contract,
        ) throws -> TileKit.Service.Operation {
            guard let operation = contract.operations.first(where: { $0.id == id }) else {
                throw BindingError.missingOperation(
                    operationID: id,
                    serviceID: contract.id,
                )
            }

            return operation
        }

        private func validateMode(
            _ mode: TileKit.Tile.Mode,
            operation: TileKit.Service.Operation,
        ) throws {
            guard operation.modes.contains(where: { $0.rawValue == mode.rawValue }) else {
                throw BindingError.unsupportedMode(
                    mode: mode.rawValue,
                    operationID: operation.id,
                )
            }
        }

        private func validateCredentialExposure(
            _ exposure: TileKit.Service.CredentialExposure?,
            mode: TileKit.Tile.Mode,
            operationID: String,
        ) throws {
            guard let exposure else {
                return
            }
            if mode == .remote, exposure != .browser {
                throw BindingError.unsafeCredentialExposure(
                    mode: mode.rawValue,
                    exposure: exposure.rawValue,
                    operationID: operationID,
                )
            }
        }
    }
}
