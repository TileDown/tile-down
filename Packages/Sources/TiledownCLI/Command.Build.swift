import Foundation
import TileKit

extension Command {
    func build() throws {
        guard arguments.count == 4 else {
            throw CommandError.invalidArguments
        }

        let generator = makeGenerator()

        _ = try generator.build(
            .init(
                sourcePath: arguments[1],
                templatePath: arguments[2],
                outputPath: arguments[3],
            ),
        )
    }

    func buildSite() throws {
        // Pull the optional --drafts flag out so the rest parse positionally.
        let includeDrafts = arguments.contains("--drafts")
        let positional = arguments.filter { $0 != "--drafts" }
        guard positional.count == 3 || positional.count == 4 else {
            throw CommandError.invalidArguments
        }

        if positional.count == 3 {
            try buildContentSite(
                contentRootPath: positional[1],
                outputRootPath: positional[2],
                includeDrafts: includeDrafts,
            )
        } else {
            try buildContentSite(
                contentRootPath: positional[1],
                templatePath: positional[2],
                outputRootPath: positional[3],
                includeDrafts: includeDrafts,
            )
        }
    }

    func buildContentSite(
        contentRootPath: String,
        templatePath: String? = nil,
        outputRootPath: String,
        includeDrafts: Bool,
    ) throws {
        let configurationFile = try loadConfigurationFile(
            contentRootPath: contentRootPath,
        )
        let serviceBindings = try configuredServiceBindings(
            from: configurationFile.serviceBindings,
            contentRootPath: contentRootPath,
        )
        let generator = makeGenerator(
            serviceBindings: serviceBindings.bindings,
        )
        try runContentGenerators(
            configurationFile.generators,
            workingDirectory: contentRootPath,
        )
        let template: TileKit.Site.TemplateSource = if let templatePath {
            .file(path: templatePath)
        } else {
            .layout(configurationFile.layout)
        }
        _ = try generator.buildContent(
            .init(
                contentRootPath: contentRootPath,
                template: template,
                outputRootPath: outputRootPath,
                configuration: configurationFile.configuration,
                privateSourcePaths: serviceBindings.privateSourcePaths,
                includeDrafts: includeDrafts,
            ),
        )
    }

    func makeGenerator(
        serviceBindings: [TileKit.Service.Binding] = [],
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: TileKit.Site.LocalFileSystem(
                fileManager: .default,
            ),
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: makeHTMLRenderer(serviceBindings: serviceBindings),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }

    func makeHTMLRenderer(
        serviceBindings: [TileKit.Service.Binding] = [],
    ) -> TileKit.Output.HTMLRenderer {
        .init(
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(
                passthroughSchemes: TileKit.Site.Reference.schemes,
            ),
            tileRegistry: makeTileRegistry(serviceBindings: serviceBindings),
        )
    }

    /// Runs each declared content generator as a subprocess before the build, in
    /// the content directory, so a generator can write into the content tree.
    /// A generator that exits non-zero fails the build. Subprocess use lives here
    /// at the composition root, never in the engine core.
    func runContentGenerators(
        _ generators: [TileKit.Site.ContentGenerator],
        workingDirectory: String,
    ) throws {
        for generator in generators {
            FileHandle.standardError.write(
                Data("tiledown: generating \(generator.name)...\n".utf8),
            )
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = generator.command
            // Resolve to an absolute directory: Process does not reliably chdir to
            // a relative currentDirectoryURL, and the content path is often relative
            // (e.g. `build-site ../site/content out`).
            process.currentDirectoryURL = URL(
                fileURLWithPath: workingDirectory,
                relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            ).standardizedFileURL
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw CommandError.generatorFailed(
                    name: generator.name,
                    status: process.terminationStatus,
                )
            }
        }
    }

    func loadConfigurationFile(
        contentRootPath: String,
    ) throws -> TileKit.Site.ConfigurationFile {
        let fileManager = FileManager.default
        let root = URL(fileURLWithPath: contentRootPath)
        for fileName in ["tiledown.yml", "tiledown.yaml"] {
            let url = root.appendingPathComponent(fileName)
            guard fileManager.fileExists(atPath: url.path) else {
                continue
            }
            return try TileKit.Site.ConfigurationFile.parse(
                String(contentsOf: url, encoding: .utf8),
            )
        }
        return .init()
    }

    func makeTileRegistry(
        serviceBindings: [TileKit.Service.Binding] = [],
    ) -> TileKit.Tile.Registry {
        let serviceForm = TileKit.ServiceForm.TileRenderer(
            resolver: TileKit.Service.LocalFileContractResolver(
                bindings: serviceBindings,
            ),
        )

        return TileKit.Tile.Registry()
            .registering(
                serviceForm,
                for: TileKit.Tile.ServiceFormRequest.typeID,
            )
            .registering(
                TileKit.Tile.CalloutRenderer(),
                for: TileKit.Tile.CalloutRenderer.typeID,
            )
            .registering(
                TileKit.Tile.ChartRenderer(),
                for: TileKit.Tile.ChartRenderer.typeID,
            )
            .registering(
                TileKit.Tile.CounterRenderer(),
                for: TileKit.Tile.CounterRenderer.typeID,
            )
            .registering(
                TileKit.Tile.EmbedRenderer(),
                for: TileKit.Tile.EmbedRenderer.typeID,
            )
            .registering(
                TileKit.Tile.MermaidRenderer(),
                for: TileKit.Tile.MermaidRenderer.typeID,
            )
    }

    func configuredServiceBindings(
        from configurations: [TileKit.Site.ServiceBindingConfiguration],
        contentRootPath: String,
    ) throws -> (bindings: [TileKit.Service.Binding], privateSourcePaths: Set<String>) {
        let bindings = try configurations.map { configuration in
            try serviceBinding(
                from: configuration,
                contentRootPath: contentRootPath,
            )
        }
        return (
            bindings,
            Set(
                configurations.compactMap {
                    privateSourcePath(
                        $0.contractPath,
                        contentRootPath: contentRootPath,
                    )
                },
            ),
        )
    }

    private func serviceBinding(
        from configuration: TileKit.Site.ServiceBindingConfiguration,
        contentRootPath: String,
    ) throws -> TileKit.Service.Binding {
        guard let mode = TileKit.Service.Mode(rawValue: configuration.mode) else {
            throw TileKit.Site.ConfigurationFileError.invalidServiceBindingMode(
                serviceID: configuration.serviceID,
                mode: configuration.mode,
            )
        }
        guard let availability = TileKit.Service.Availability(
            rawValue: configuration.availability,
        ) else {
            throw TileKit.Site.ConfigurationFileError.invalidServiceBindingAvailability(
                serviceID: configuration.serviceID,
                availability: configuration.availability,
            )
        }
        return .init(
            serviceID: configuration.serviceID,
            source: .localFile(path: serviceContractPath(
                configuration.contractPath,
                contentRootPath: contentRootPath,
            )),
            mode: mode,
            proxyRoute: configuration.proxyRoute,
            availability: availability,
        )
    }

    private func serviceContractPath(
        _ path: String,
        contentRootPath: String,
    ) -> String {
        guard !path.hasPrefix("/") else {
            return URL(fileURLWithPath: path).standardizedFileURL.path
        }
        return contentRootURL(contentRootPath)
            .appendingPathComponent(path)
            .standardizedFileURL
            .path
    }

    private func privateSourcePath(
        _ path: String,
        contentRootPath: String,
    ) -> String? {
        let root = contentRootURL(contentRootPath).path
        let rootPrefix = root.hasSuffix("/") ? root : root + "/"
        let contractPath = serviceContractPath(
            path,
            contentRootPath: contentRootPath,
        )
        guard contractPath.hasPrefix(rootPrefix) else {
            return nil
        }
        let relativePath = String(contractPath.dropFirst(rootPrefix.count))
        return relativePath.isEmpty ? nil : relativePath
    }

    private func contentRootURL(
        _ contentRootPath: String,
    ) -> URL {
        URL(
            fileURLWithPath: contentRootPath,
            relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        )
        .standardizedFileURL
    }
}
