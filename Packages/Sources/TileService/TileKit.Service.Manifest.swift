import TileCore

public extension TileKit.Service {
    /// A provider-neutral integration manifest.
    struct Manifest: Codable, Equatable, Sendable {
        public var id: String
        public var provider: Provider
        public var requirements: Requirements
        public var inputs: [String: Input]
        public var outputs: [String: Output]
        public var layout: Layout
        public var build: Build

        public init(
            id: String,
            provider: Provider,
            requirements: Requirements = .init(),
            inputs: [String: Input],
            outputs: [String: Output],
            layout: Layout,
            build: Build,
        ) {
            self.id = id
            self.provider = provider
            self.requirements = requirements
            self.inputs = inputs
            self.outputs = outputs
            self.layout = layout
            self.build = build
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: TileKitServiceManifestCodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            provider = try container.decode(Provider.self, forKey: .provider)
            requirements = try container.decodeIfPresent(
                Requirements.self,
                forKey: .requirements,
            ) ?? .init()
            inputs = try container.decode([String: Input].self, forKey: .inputs)
            outputs = try container.decode([String: Output].self, forKey: .outputs)
            layout = try container.decode(Layout.self, forKey: .layout)
            build = try container.decode(Build.self, forKey: .build)
        }
    }
}

private enum TileKitServiceManifestCodingKeys: String, CodingKey {
    case id
    case provider
    case requirements
    case inputs
    case outputs
    case layout
    case build
}
