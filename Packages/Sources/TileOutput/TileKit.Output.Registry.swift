import TileCore

public extension TileKit.Output {
    /// Dispatches documents to output renderers by format id.
    ///
    /// The injected registry of the output seam, the structural twin of
    /// ``TileKit/Tile/Registry``. It is an immutable value: `registering` returns a
    /// copy with one more renderer, and the composition root builds the registry it
    /// wants. Unlike tile dispatch, an unregistered format has no sensible fallback,
    /// so `render` throws ``TileKit/Output/RenderingError/unknownFormat(_:)`` rather
    /// than guessing.
    struct Registry: Sendable {
        private var renderers: [String: any Rendering]

        public init(
            renderers: [String: any Rendering] = [:],
        ) {
            self.renderers = renderers
        }

        /// Returns a copy with the renderer registered for its `formatID`.
        public func registering(
            _ renderer: any Rendering,
        ) -> Self {
            registering(renderer, for: renderer.formatID)
        }

        /// Returns a copy with the renderer registered for an output format id.
        public func registering(
            _ renderer: any Rendering,
            for formatID: String,
        ) -> Self {
            var copy = self
            copy.renderers[formatID] = renderer
            return copy
        }

        /// Renders a document with the renderer registered for the format id.
        ///
        /// Throws ``TileKit/Output/RenderingError/unknownFormat(_:)`` when no
        /// renderer is registered for `formatID`.
        public func render(
            _ document: Document,
            format formatID: String,
        ) throws -> Artifact {
            guard let renderer = renderers[formatID] else {
                throw RenderingError.unknownFormat(formatID)
            }

            return try renderer.render(document)
        }
    }
}
