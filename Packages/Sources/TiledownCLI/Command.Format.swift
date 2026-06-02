import Foundation
import TileKit

extension Command {
    func format() throws {
        let parsed = try parseFormatArguments()
        let fileSystem = TileKit.Site.LocalFileSystem(
            fileManager: .default,
        )
        let source = try fileSystem.readTextFile(at: parsed.path)
        let formatter = makeFormatter()

        switch parsed.mode {
        case .stdout:
            // Emit the canonical bytes verbatim, so stdout matches `--write`.
            try print(formatter.format(source), terminator: "")
        case .write:
            try fileSystem.writeTextFile(
                formatter.format(source),
                at: parsed.path,
            )
        case .check:
            // A non-canonical file is an expected `--check` outcome (a CI gate),
            // so exit cleanly with a non-zero code rather than trapping.
            if try !formatter.isCanonical(source) {
                let message = "\(parsed.path) is not in canonical form. "
                    + "Run tiledown fmt --write \(parsed.path) to fix it.\n"
                FileHandle.standardError.write(Data(message.utf8))
                exit(1)
            }
        }
    }

    func makeFormatter() -> TileKit.Site.DocumentFormatter {
        .init(
            frontMatterSplitter: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            serializer: TileKit.Site.DocumentSerializer(
                markdownFormatter: TileKit.Markdown.CommonMarkFormatter(),
            ),
        )
    }

    private func parseFormatArguments() throws -> FormatArguments {
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
        return .init(mode: mode, path: path)
    }
}

private enum FormatMode {
    case stdout
    case write
    case check
}

private struct FormatArguments {
    var mode: FormatMode
    var path: String
}
