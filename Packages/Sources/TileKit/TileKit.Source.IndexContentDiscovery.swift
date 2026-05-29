public extension TileKit.Source {
    struct IndexContentDiscovery: Sendable {
        private let indexFileNames: Set<String>

        public init(
            indexFileNames: Set<String> = ["index.md", "index.markdown"],
        ) {
            self.indexFileNames = indexFileNames
        }

        public func discover(
            relativePaths: [String],
        ) -> [ContentLocation] {
            relativePaths
                .compactMap(location)
                .sorted {
                    $0.slug < $1.slug
                }
        }

        private func location(
            relativePath: String,
        ) -> ContentLocation? {
            let parts = relativePath
                .split(separator: "/")
                .map(String.init)

            guard
                let fileName = parts.last,
                indexFileNames.contains(fileName)
            else {
                return nil
            }

            let slug = parts.dropLast().joined(separator: "/")
            return .init(
                sourceRelativePath: relativePath,
                slug: slug,
            )
        }
    }
}
