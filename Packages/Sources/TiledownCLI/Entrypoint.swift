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
        default:
            throw CommandError.invalidArguments
        }
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
        guard arguments.count == 4 else {
            throw CommandError.invalidArguments
        }

        let generator = makeGenerator()

        _ = try generator.buildContent(
            .init(
                contentRootPath: arguments[1],
                templatePath: arguments[2],
                outputRootPath: arguments[3],
            ),
        )
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
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
            tileParser: TileKit.Tile.DirectiveParser(),
            tileRegistry: makeTileRegistry(),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }

    private func makeOutputRegistry() -> TileKit.Output.Registry {
        TileKit.Output.Registry()
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
    }
}

private enum CommandError: Error, CustomStringConvertible {
    case invalidArguments

    var description: String {
        switch self {
        case .invalidArguments:
            """
            usage:
              tiledown build <source.md> <template.html> <output.html>
              tiledown build-site <content-dir> <template.html> <output-dir>
              tiledown json <source.md> <output.json>
            """
        }
    }
}
