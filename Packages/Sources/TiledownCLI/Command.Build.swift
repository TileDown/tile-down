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
        let generator = makeGenerator()
        let configurationFile = try loadConfigurationFile(
            contentRootPath: contentRootPath,
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
                includeDrafts: includeDrafts,
            ),
        )
    }

    func makeGenerator() -> TileKit.Site.Generator {
        .init(
            fileSystem: TileKit.Site.LocalFileSystem(
                fileManager: .default,
            ),
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: makeHTMLRenderer(),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }

    func makeHTMLRenderer() -> TileKit.Output.HTMLRenderer {
        .init(
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(
                passthroughSchemes: TileKit.Site.Reference.schemes,
            ),
            tileRegistry: makeTileRegistry(),
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

    func makeTileRegistry() -> TileKit.Tile.Registry {
        // The resolver is empty until config loading can populate service contracts.
        // A service-form tile therefore fails with a typed missing-service error
        // rather than silently rendering nothing.
        let serviceForm = TileKit.ServiceForm.TileRenderer(
            resolver: TileKit.Service.InMemoryContractResolver(),
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
}
