import TileCore

public extension TileKit.Site {
    struct ContentBuildRequest: Equatable, Sendable {
        public var contentRootPath: String
        public var template: TemplateSource
        public var outputRootPath: String
        public var configuration: Configuration
        /// Include `draft: true` pages in the build, for local preview. Off by
        /// default, so a normal build never publishes drafts.
        public var includeDrafts: Bool

        public init(
            contentRootPath: String,
            template: TemplateSource,
            outputRootPath: String,
            configuration: Configuration = .init(),
            includeDrafts: Bool = false,
        ) {
            self.contentRootPath = contentRootPath
            self.template = template
            self.outputRootPath = outputRootPath
            self.configuration = configuration
            self.includeDrafts = includeDrafts
        }
    }
}
