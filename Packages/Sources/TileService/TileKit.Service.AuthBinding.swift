import TileCore

public extension TileKit.Service {
    /// Declarative auth binding for a service. Records how a credential is
    /// supplied; it does not resolve secrets.
    ///
    /// Only `remote` mode emits a credential to the browser, and only an
    /// intentionally public ``publicKey``. `server` and `build` secrets are
    /// referenced by name and resolved outside the library, so no secret value
    /// ever appears here for ``valueFromEnv`` or ``secretRef``. Currently a
    /// placeholder: nothing consumes it yet.
    enum AuthBinding: Equatable, Sendable {
        case none
        case publicKey(name: String, value: String)
        case valueFromEnv(name: String)
        case secretRef(name: String)
    }
}
