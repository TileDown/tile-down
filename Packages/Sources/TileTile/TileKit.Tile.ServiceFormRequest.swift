import TileCore

public extension TileKit.Tile {
    /// A typed request for a generated service-backed form tile.
    struct ServiceFormRequest: Equatable, Sendable {
        public static let typeID = "service-form"

        public var id: String
        public var serviceID: String
        public var operationID: String
        public var mode: Mode
        public var submitLabel: String?

        public init(
            id: String,
            serviceID: String,
            operationID: String,
            mode: Mode,
            submitLabel: String? = nil,
        ) {
            self.id = id
            self.serviceID = serviceID
            self.operationID = operationID
            self.mode = mode
            self.submitLabel = submitLabel
        }

        public init(
            tile: Instance,
        ) throws {
            guard tile.typeID == Self.typeID else {
                throw ServiceFormRequestError.invalidTileType(actual: tile.typeID)
            }

            id = try Self.requiredString(
                named: "id",
                from: tile,
            )
            serviceID = try Self.requiredString(
                named: "service",
                from: tile,
            )
            operationID = try Self.requiredString(
                named: "operation",
                from: tile,
            )
            mode = try Self.mode(from: tile)
            submitLabel = try Self.optionalString(
                named: "submitLabel",
                from: tile,
            )
        }

        private static func mode(
            from tile: Instance,
        ) throws -> Mode {
            let value = try requiredString(
                named: "mode",
                from: tile,
            )
            guard let mode = Mode(rawValue: value) else {
                throw ServiceFormRequestError.unsupportedMode(value)
            }

            return mode
        }

        private static func requiredString(
            named name: String,
            from tile: Instance,
        ) throws -> String {
            guard let value = tile.property(named: name) else {
                throw ServiceFormRequestError.missingProperty(name)
            }

            let string = try stringValue(
                value,
                propertyName: name,
            )
            guard !string.isEmpty else {
                throw ServiceFormRequestError.emptyProperty(name)
            }

            return string
        }

        private static func optionalString(
            named name: String,
            from tile: Instance,
        ) throws -> String? {
            guard let value = tile.property(named: name) else {
                return nil
            }

            let string = try stringValue(
                value,
                propertyName: name,
            )
            guard !string.isEmpty else {
                throw ServiceFormRequestError.emptyProperty(name)
            }

            return string
        }

        private static func stringValue(
            _ value: Value,
            propertyName: String,
        ) throws -> String {
            guard case let .string(string) = value else {
                throw ServiceFormRequestError.invalidPropertyType(propertyName)
            }

            return string
        }
    }
}
