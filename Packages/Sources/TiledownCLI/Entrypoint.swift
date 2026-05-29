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
        case "build":
            try build()
        default:
            throw CommandError.invalidArguments
        }
    }

    private func build() throws {
        guard arguments.count == 4 else {
            throw CommandError.invalidArguments
        }

        let generator = TileKit.Site.Generator(
            fileSystem: TileKit.Site.LocalFileSystem(
                fileManager: .default,
            ),
            markdownParser: TileKit.Source.FrontMatterParser(),
            markdownRenderer: TileKit.Markdown.BasicHTMLRenderer(),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
        )

        _ = try generator.build(
            .init(
                sourcePath: arguments[1],
                templatePath: arguments[2],
                outputPath: arguments[3],
            ),
        )
    }
}

private enum CommandError: Error, CustomStringConvertible {
    case invalidArguments

    var description: String {
        switch self {
        case .invalidArguments:
            "usage: tiledown build <source.md> <template.html> <output.html>"
        }
    }
}
