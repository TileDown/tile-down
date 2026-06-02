import TileCore

public extension TileKit.Site {
    /// Project-file declaration of one service contract binding.
    ///
    /// The site layer keeps this as configuration data only. The CLI composition
    /// root maps it to `TileKit.Service.Binding` so `TileSite` stays independent
    /// of the service domain target.
    struct ServiceBindingConfiguration: Equatable, Sendable {
        public var serviceID: String
        public var contractPath: String
        public var mode: String
        public var proxyRoute: String?
        public var availability: String

        public init(
            serviceID: String,
            contractPath: String,
            mode: String,
            proxyRoute: String? = nil,
            availability: String = "required",
        ) {
            self.serviceID = serviceID
            self.contractPath = contractPath
            self.mode = mode
            self.proxyRoute = proxyRoute
            self.availability = availability
        }
    }
}
