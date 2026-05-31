import Foundation
import TileKit

@main
struct Entrypoint {
    static func main() throws {
        try Command(
            arguments: Array(CommandLine.arguments.dropFirst()),
        )
        .run()
    }
}

private struct Command {
    var arguments: [String]

    func run() throws {
        guard let subcommand = arguments.first else {
            print(TileKit.Product.commandName)
            return
        }

        switch subcommand {
        case "version", "--version", "-v":
            print("\(TileKit.Product.name) \(TileKit.Product.version)")
        case "build":
            try build()
        case "build-site":
            try buildSite()
        case "json":
            try json()
        case "fmt":
            try format()
        default:
            throw CommandError.invalidArguments
        }
    }

    private func format() throws {
        let mode: FormatMode
        let path: String
        switch arguments.count {
        case 2:
            mode = .stdout
            path = arguments[1]
        case 3:
            switch arguments[1] {
            case "--write":
                mode = .write
            case "--check":
                mode = .check
            default:
                throw CommandError.invalidArguments
            }
            path = arguments[2]
        default:
            throw CommandError.invalidArguments
        }

        let fileSystem = TileKit.Site.LocalFileSystem(
            fileManager: .default,
        )
        let source = try fileSystem.readTextFile(at: path)
        let formatter = makeFormatter()

        switch mode {
        case .stdout:
            // Emit the canonical bytes verbatim, so stdout matches `--write`.
            try print(formatter.format(source), terminator: "")
        case .write:
            try fileSystem.writeTextFile(
                formatter.format(source),
                at: path,
            )
        case .check:
            // A non-canonical file is an expected `--check` outcome (a CI gate),
            // so exit cleanly with a non-zero code rather than trapping.
            if try !formatter.isCanonical(source) {
                let message = "\(path) is not in canonical form. "
                    + "Run tiledown fmt --write \(path) to fix it.\n"
                FileHandle.standardError.write(Data(message.utf8))
                exit(1)
            }
        }
    }

    private enum FormatMode {
        case stdout
        case write
        case check
    }

    private func build() throws {
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

    private func buildSite() throws {
        // Pull the optional --drafts flag out so the rest parse positionally.
        let includeDrafts = arguments.contains("--drafts")
        let positional = arguments.filter { $0 != "--drafts" }
        guard positional.count == 3 || positional.count == 4 else {
            throw CommandError.invalidArguments
        }

        let generator = makeGenerator()
        let configurationFile = try loadConfigurationFile(
            contentRootPath: positional[1],
        )
        try runContentGenerators(
            configurationFile.generators,
            workingDirectory: positional[1],
        )
        let template: TileKit.Site.TemplateSource
        let outputRootPath: String
        if positional.count == 3 {
            template = .layout(configurationFile.layout)
            outputRootPath = positional[2]
        } else {
            template = .file(path: positional[2])
            outputRootPath = positional[3]
        }

        _ = try generator.buildContent(
            .init(
                contentRootPath: positional[1],
                template: template,
                outputRootPath: outputRootPath,
                configuration: configurationFile.configuration,
                includeDrafts: includeDrafts,
            ),
        )
    }

    /// Runs each declared content generator as a subprocess before the build, in
    /// the content directory, so a generator can write into the content tree.
    /// A generator that exits non-zero fails the build. Subprocess use lives here
    /// at the composition root, never in the engine core.
    private func runContentGenerators(
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

    private func loadConfigurationFile(
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

    private func json() throws {
        guard arguments.count == 3 else {
            throw CommandError.invalidArguments
        }

        let fileSystem = TileKit.Site.LocalFileSystem(
            fileManager: .default,
        )
        let source = try fileSystem.readTextFile(at: arguments[1])
        let document = try TileKit.Source.FrontMatterParser().parse(source)
        let blocks = try TileKit.Tile.DirectiveParser().parseBlocks(document.body)

        let artifact = try makeOutputRegistry().render(
            .init(
                frontMatter: document.frontMatter,
                blocks: blocks,
                slug: "",
            ),
            format: TileKit.Output.JSONRenderer.formatID,
        )

        try fileSystem.writeTextFile(
            artifact.contents,
            at: arguments[2],
        )
    }

    private func makeGenerator() -> TileKit.Site.Generator {
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

    private func makeHTMLRenderer() -> TileKit.Output.HTMLRenderer {
        .init(
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(
                passthroughSchemes: TileKit.Site.Reference.schemes,
            ),
            tileRegistry: makeTileRegistry(),
        )
    }

    private func makeFormatter() -> TileKit.Site.DocumentFormatter {
        .init(
            frontMatterSplitter: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            serializer: TileKit.Site.DocumentSerializer(
                markdownFormatter: TileKit.Markdown.CommonMarkFormatter(),
            ),
        )
    }

    private func makeOutputRegistry() -> TileKit.Output.Registry {
        TileKit.Output.Registry()
            .registering(makeHTMLRenderer())
            .registering(TileKit.Output.JSONRenderer())
    }

    private func makeTileRegistry() -> TileKit.Tile.Registry {
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
                TileKit.Tile.CounterRenderer(),
                for: TileKit.Tile.CounterRenderer.typeID,
            )
    }
}

private enum CommandError: Error, CustomStringConvertible {
    case invalidArguments
    case generatorFailed(name: String, status: Int32)

    var description: String {
        switch self {
        case let .generatorFailed(name, status):
            "Content generator `\(name)` failed with exit code \(status)."
        case .invalidArguments:
            """
            usage:
              tiledown build <source.md> <template.html> <output.html>
              tiledown build-site [--drafts] <content-dir> <output-dir>
              tiledown build-site [--drafts] <content-dir> <template.html> <output-dir>
              tiledown json <source.md> <output.json>
              tiledown fmt [--write | --check] <source.md>

            build-site reads optional tiledown.yml settings from <content-dir>.
            --drafts includes draft: true pages, for local preview.
            """
        }
    }
}
