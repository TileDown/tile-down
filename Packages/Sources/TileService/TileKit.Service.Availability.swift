import TileCore

public extension TileKit.Service {
    /// Build-time availability policy for a bound service.
    ///
    /// Represented now so site config can carry it; health checks are not
    /// executed yet.
    enum Availability: String, Equatable, Sendable {
        /// Fail the build if the contract or health check fails.
        case required
        /// Warn and render a fallback if the service is unavailable.
        case optional
        /// Do not check the service during build.
        case unchecked
    }
}
