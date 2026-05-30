import TileCore

public extension TileKit.Site {
    /// A build-time pass over the site's image assets.
    ///
    /// The seam exists so image validation (missing references, oversize files,
    /// missing alt text) can land later without changing the generator. The
    /// default `PassthroughImageChecker` does nothing, so wiring it in now is
    /// inert until a real checker replaces it.
    protocol ImageChecking: Sendable {
        /// Inspects the given image asset paths (relative to the content root)
        /// and throws if the site should not build. The default implementation
        /// performs no checks.
        func check(
            imagePaths: [String],
        ) throws
    }
}
