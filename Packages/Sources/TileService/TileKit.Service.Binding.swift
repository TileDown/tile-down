import TileCore

public extension TileKit.Service {
    /// Site-level binding from a service id to its contract source and policy.
    ///
    /// Bindings are site configuration, kept separate from the
    /// ``TileKit/Service/Contract`` they point at. Constructed as direct values
    /// for now; a config file format (YAML/JSON) is deferred until CLI config
    /// loading needs it.
    struct Binding: Equatable, Sendable {
        public var serviceID: String
        public var source: ContractSource
        public var mode: Mode
        public var proxyRoute: String?
        public var availability: Availability
        public var auth: AuthBinding

        public init(
            serviceID: String,
            source: ContractSource,
            mode: Mode,
            proxyRoute: String? = nil,
            availability: Availability = .required,
            auth: AuthBinding = .none,
        ) {
            self.serviceID = serviceID
            self.source = source
            self.mode = mode
            self.proxyRoute = proxyRoute
            self.availability = availability
            self.auth = auth
        }
    }
}
