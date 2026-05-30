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
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: makeHTMLRenderer(),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }

    private func makeHTMLRenderer() -> TileKit.Output.HTMLRenderer {
        .init(
            markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
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
              tiledown fmt [--write | --check] <source.md>
            """
        }
    }
}
