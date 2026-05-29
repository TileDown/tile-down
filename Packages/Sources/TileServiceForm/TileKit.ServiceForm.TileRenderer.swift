import TileCore
import TileService
import TileTile

public extension TileKit.ServiceForm {
    /// Adapts service form generation to the tile rendering registry seam.
    ///
    /// Converts a generic tile instance into a ``TileKit/Tile/ServiceFormRequest``,
    /// resolves the referenced service contract through an injected resolver, binds
    /// the request to an operation, and delegates browser output generation to
    /// ``TileKit/ServiceForm/Renderer``. Registering this renderer for the
    /// `service-form` type id is what lets the generic site generator emit
    /// service-backed forms without depending on this module.
    struct TileRenderer: TileKit.Tile.Rendering {
        private let resolver: any TileKit.Service.ContractResolving
        private let binder: Binder
        private let renderer: Renderer

        public init(
            resolver: any TileKit.Service.ContractResolving,
            binder: Binder = .init(),
            renderer: Renderer = .init(),
        ) {
            self.resolver = resolver
            self.binder = binder
            self.renderer = renderer
        }

        public func render(
            _ tile: TileKit.Tile.Instance,
        ) throws -> TileKit.Tile.Rendered {
            let request = try TileKit.Tile.ServiceFormRequest(tile: tile)
            let contract = try resolver.resolveContract(serviceID: request.serviceID)
            let binding = try binder.bind(
                request,
                to: contract,
            )
            let rendered = try renderer.render(binding)

            return .init(
                html: rendered.html,
                css: rendered.css,
                javascript: rendered.javascript,
            )
        }
    }
}
